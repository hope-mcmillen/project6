import 'dart:async';
import 'dart:convert';

import 'package:fitcheck_ai/core/weather/open_meteo_weather_service.dart';
import 'package:fitcheck_ai/core/weather/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> forecast({
  Object? temperature = 22.5,
  Object? probability = 35,
}) => {
  'current': {
    'temperature_2m': temperature,
    'precipitation_probability': probability,
  },
};

http.Response weatherResponse(Map<String, dynamic> data) =>
    http.Response(jsonEncode(data), 200);

OpenMeteoWeatherService service(
  Future<http.Response> Function(http.Request) handler, {
  Duration timeout = const Duration(seconds: 10),
}) {
  final weather = OpenMeteoWeatherService(
    client: MockClient(handler),
    timeout: timeout,
  );
  addTearDown(weather.close);
  return weather;
}

Matcher weatherError(String text) => throwsA(
  isA<WeatherServiceException>().having(
    (error) => error.message,
    'message',
    contains(text),
  ),
);

void main() {
  test(
    'sends only rounded coordinates and requests Celsius and chance',
    () async {
      final weather = service((request) async {
        expect(request.method, 'GET');
        expect(request.url.scheme, 'https');
        expect(request.url.host, 'api.open-meteo.com');
        expect(request.url.path, '/v1/forecast');
        expect(request.url.queryParameters, {
          'latitude': '30.41',
          'longitude': '-91.18',
          'current': 'temperature_2m,precipitation_probability',
          'temperature_unit': 'celsius',
        });
        return weatherResponse(forecast());
      });
      final result = await weather.weatherAt(
        latitude: 30.41121,
        longitude: -91.18131,
      );
      expect(result.temperatureC, 22.5);
      expect(result.rainChancePercent, 35);
      expect(result.locationLabel, isEmpty);
    },
  );

  for (final coordinates in [(90.0, 180.0), (-90.0, -180.0), (0.0, 0.0)]) {
    test('accepts coordinate boundaries $coordinates', () async {
      final weather = service((_) async => weatherResponse(forecast()));
      final result = await weather.weatherAt(
        latitude: coordinates.$1,
        longitude: coordinates.$2,
      );
      expect(result.temperatureC, 22.5);
    });
  }

  for (final coordinates in [
    (90.001, 0.0),
    (-90.001, 0.0),
    (0.0, 180.001),
    (0.0, -180.001),
    (double.nan, 0.0),
    (0.0, double.nan),
    (double.infinity, 0.0),
    (0.0, double.negativeInfinity),
  ]) {
    test('invalid coordinates $coordinates make no request', () async {
      var requests = 0;
      final weather = service((_) async {
        requests++;
        return weatherResponse(forecast());
      });
      await expectLater(
        weather.weatherAt(latitude: coordinates.$1, longitude: coordinates.$2),
        weatherError('valid location'),
      );
      expect(requests, 0);
    });
  }

  test('preserves freezing temperature and rounds fractional chance', () async {
    final weather = service(
      (_) async =>
          weatherResponse(forecast(temperature: -8, probability: 12.6)),
    );
    final result = await weather.weatherAt(latitude: 0, longitude: 0);
    expect(result.temperatureC, -8.0);
    expect(result.rainChancePercent, 13);
  });

  for (final probability in [0, 100]) {
    test('preserves chance boundary $probability', () async {
      final weather = service(
        (_) async => weatherResponse(forecast(probability: probability)),
      );
      final result = await weather.weatherAt(latitude: 0, longitude: 0);
      expect(result.rainChancePercent, probability);
    });
  }

  for (final status in [400, 403, 500, 503]) {
    test('HTTP $status produces a clear error', () async {
      final weather = service((_) async => http.Response('error', status));
      await expectLater(
        weather.weatherAt(latitude: 0, longitude: 0),
        weatherError('unavailable'),
      );
    });
  }

  test('rate limiting asks the caller to wait', () async {
    final weather = service((_) async => http.Response('busy', 429));
    await expectLater(
      weather.weatherAt(latitude: 0, longitude: 0),
      weatherError('try again later'),
    );
  });

  test('network failure gives a connection message', () async {
    final weather = service((_) async {
      throw http.ClientException('Network unavailable');
    });
    await expectLater(
      weather.weatherAt(latitude: 0, longitude: 0),
      weatherError('Check your connection'),
    );
  });

  test('timeout returns a clear error and allows a later request', () async {
    var requests = 0;
    final weather = service((_) {
      requests++;
      if (requests == 1) return Completer<http.Response>().future;
      return Future.value(weatherResponse(forecast()));
    }, timeout: const Duration(milliseconds: 5));
    await expectLater(
      weather.weatherAt(latitude: 0, longitude: 0),
      weatherError('took too long'),
    );
    expect(
      (await weather.weatherAt(latitude: 0, longitude: 0)).temperatureC,
      22.5,
    );
    expect(requests, 2);
  });

  test(
    'deadline includes a stalled body and aborts the HTTP request',
    () async {
      final aborted = Completer<void>();
      final client = MockClient.streaming((request, _) async {
        Stream<List<int>> body() async* {
          yield utf8.encode('{"current":');
          await (request as http.Abortable).abortTrigger;
          aborted.complete();
          throw http.RequestAbortedException();
        }

        return http.StreamedResponse(body(), 200);
      });
      final weather = OpenMeteoWeatherService(
        client: client,
        timeout: const Duration(milliseconds: 5),
      );
      addTearDown(weather.close);
      await expectLater(
        weather.weatherAt(latitude: 0, longitude: 0),
        weatherError('took too long'),
      );
      await aborted.future.timeout(const Duration(seconds: 1));
    },
  );

  for (final body in [
    'not JSON',
    '[]',
    '{}',
    '{"current":[]}',
    jsonEncode(forecast(temperature: null)),
    jsonEncode(forecast(temperature: '22.5')),
    jsonEncode(forecast(probability: null)),
    jsonEncode(forecast(probability: '35')),
    jsonEncode(forecast(probability: -0.1)),
    jsonEncode(forecast(probability: 100.1)),
    '{"current":{"temperature_2m":1e400,"precipitation_probability":20}}',
    '{"current":{"temperature_2m":20,"precipitation_probability":1e400}}',
  ]) {
    test('invalid response $body is rejected', () async {
      final weather = service((_) async => http.Response(body, 200));
      await expectLater(
        weather.weatherAt(latitude: 0, longitude: 0),
        weatherError('invalid data'),
      );
    });
  }
}
