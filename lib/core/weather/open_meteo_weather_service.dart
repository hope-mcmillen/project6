import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models.dart';
import 'weather_service.dart';

/// Current modelled conditions from Open-Meteo's non-commercial forecast API.
/// Display credit and a licence link with weather, as described in the handoff.
class OpenMeteoWeatherService implements WeatherService {
  OpenMeteoWeatherService({
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final Duration timeout;

  @override
  Future<WeatherSummary> weatherAt({
    required double latitude,
    required double longitude,
  }) async {
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const WeatherServiceException(
        'Choose a valid location for weather.',
      );
    }
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toStringAsFixed(2),
      'longitude': longitude.toStringAsFixed(2),
      'current': 'temperature_2m,precipitation_probability',
      'temperature_unit': 'celsius',
    });
    final abort = Completer<void>();
    final request = http.AbortableRequest(
      'GET',
      uri,
      abortTrigger: abort.future,
    );
    try {
      final response = await _client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(timeout);
      if (response.statusCode == 429) {
        throw const WeatherServiceException(
          'Weather is busy. Please try again later.',
        );
      }
      if (response.statusCode != 200) {
        throw const WeatherServiceException(
          'Weather is unavailable. Please try again.',
        );
      }
      return _decodeWeather(jsonDecode(utf8.decode(response.bodyBytes)));
    } on TimeoutException {
      abort.complete();
      throw const WeatherServiceException(
        'Weather took too long. Check your connection and retry.',
      );
    } on http.ClientException {
      throw const WeatherServiceException(
        'Could not load weather. Check your connection and retry.',
      );
    } on FormatException {
      throw const WeatherServiceException(
        'Weather returned invalid data. Please try again.',
      );
    }
  }

  /// Close when the service is no longer needed, including an injected client.
  void close() => _client.close();
}

WeatherSummary _decodeWeather(dynamic data) {
  if (data is! Map<String, dynamic> ||
      data['current'] is! Map<String, dynamic>) {
    throw const FormatException('Expected current weather.');
  }
  final current = data['current'] as Map<String, dynamic>;
  final temperature = current['temperature_2m'];
  final probability = current['precipitation_probability'];
  if (temperature is! num ||
      !temperature.isFinite ||
      probability is! num ||
      !probability.isFinite ||
      probability < 0 ||
      probability > 100) {
    throw const FormatException(
      'Expected temperature and precipitation chance.',
    );
  }
  return WeatherSummary(
    temperatureC: temperature.toDouble(),
    rainChancePercent: probability.round(),
  );
}
