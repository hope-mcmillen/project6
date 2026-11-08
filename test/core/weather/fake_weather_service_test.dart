import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/core/weather/fake_weather_service.dart';
import 'package:fitcheck_ai/core/weather/weather_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fake supplies the configured weather through either lookup', () async {
    const fixture = WeatherSummary(
      temperatureC: 12,
      rainChancePercent: 80,
      locationLabel: 'Test city',
    );
    const WeatherService weather = FakeWeatherService(weather: fixture);
    expect(
      await weather.weatherAt(latitude: 30, longitude: -91),
      same(fixture),
    );
    expect(await weather.weatherForCity('Test city'), same(fixture));
  });

  test('fake failures support both weather entry points', () async {
    const WeatherService weather = FakeWeatherService(failRequests: true);
    await expectLater(
      weather.weatherAt(latitude: 30, longitude: -91),
      throwsA(isA<WeatherServiceException>()),
    );
    await expectLater(
      weather.weatherForCity('Test city'),
      throwsA(isA<WeatherServiceException>()),
    );
  });
}
