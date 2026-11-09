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
    if (!_validCoordinates(latitude, longitude)) {
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
    return _getJson(uri, _decodeWeather);
  }

  @override
  Future<WeatherSummary> weatherForCity(String city) async {
    final search = city.trim();
    if (search.runes.length < 2) {
      throw const WeatherServiceException(
        'Enter a city name with at least two characters.',
      );
    }
    final uri = Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
      'name': search,
      'count': '1',
      'language': 'en',
      'format': 'json',
    });
    final location = await _getJson(uri, _decodeCity);
    final weather = await weatherAt(
      latitude: location.latitude,
      longitude: location.longitude,
    );
    return WeatherSummary(
      temperatureC: weather.temperatureC,
      rainChancePercent: weather.rainChancePercent,
      locationLabel: location.label,
    );
  }

  Future<T> _getJson<T>(Uri uri, T Function(dynamic) decode) async {
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
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map && data['error'] == true) {
        throw const FormatException('The provider returned an error.');
      }
      return decode(data);
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
      data['current'] is! Map<String, dynamic> ||
      data['current_units'] is! Map<String, dynamic>) {
    throw const FormatException('Expected current weather.');
  }
  final current = data['current'] as Map<String, dynamic>;
  final units = data['current_units'] as Map<String, dynamic>;
  final temperature = current['temperature_2m'];
  final probability = current['precipitation_probability'];
  if (units['temperature_2m'] != '°C' ||
      units['precipitation_probability'] != '%' ||
      temperature is! num ||
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

bool _validCoordinates(num latitude, num longitude) =>
    latitude.isFinite &&
    longitude.isFinite &&
    latitude >= -90 &&
    latitude <= 90 &&
    longitude >= -180 &&
    longitude <= 180;

({double latitude, double longitude, String label}) _decodeCity(dynamic data) {
  if (data is! Map<String, dynamic>) {
    throw const FormatException('Expected city search results.');
  }
  final results = data['results'];
  if (results == null || (results is List && results.isEmpty)) {
    throw const WeatherServiceException(
      'No city found. Try a city with its country or region.',
    );
  }
  if (results is! List || results.first is! Map<String, dynamic>) {
    throw const FormatException('Expected a city.');
  }
  final city = results.first as Map<String, dynamic>;
  final latitude = city['latitude'];
  final longitude = city['longitude'];
  final name = city['name'];
  final labels = [name, city['admin1'], city['country']];
  if (latitude is! num ||
      longitude is! num ||
      !_validCoordinates(latitude, longitude) ||
      name is! String ||
      name.trim().isEmpty ||
      labels.any((label) => label != null && label is! String)) {
    throw const FormatException('Expected valid city coordinates and names.');
  }
  return (
    latitude: latitude.toDouble(),
    longitude: longitude.toDouble(),
    label: labels
        .whereType<String>()
        .map((label) => label.trim())
        .where((label) => label.isNotEmpty)
        .toSet()
        .join(', '),
  );
}
