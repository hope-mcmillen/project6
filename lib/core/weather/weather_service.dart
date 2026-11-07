import '../data/models.dart';

abstract interface class WeatherService {
  /// Uses a coarse location. Implementations round coordinates before sending.
  Future<WeatherSummary> weatherAt({
    required double latitude,
    required double longitude,
  });
}

class WeatherServiceException implements Exception {
  const WeatherServiceException(this.message);
  final String message;

  @override
  String toString() => message;
}
