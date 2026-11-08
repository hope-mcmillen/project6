import '../data/models.dart';

abstract interface class WeatherService {
  /// Uses a coarse location. Implementations round coordinates before sending.
  Future<WeatherSummary> weatherAt({
    required double latitude,
    required double longitude,
  });

  /// Resolves a city name, optionally qualified by country or region.
  /// Show the returned locationLabel so users can confirm the selected place.
  Future<WeatherSummary> weatherForCity(String city);
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
