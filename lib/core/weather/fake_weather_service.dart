import '../data/models.dart';
import 'weather_service.dart';

/// Fixed weather for screen tests and previews, with no network or permissions.
class FakeWeatherService implements WeatherService {
  const FakeWeatherService({
    this.weather = const WeatherSummary(
      temperatureC: 22,
      rainChancePercent: 10,
      locationLabel: 'Sample city',
    ),
    this.failRequests = false,
  });

  final WeatherSummary weather;
  final bool failRequests;

  @override
  Future<WeatherSummary> weatherAt({
    required double latitude,
    required double longitude,
  }) async => _result();

  @override
  Future<WeatherSummary> weatherForCity(String city) async => _result();

  WeatherSummary _result() {
    if (failRequests) {
      throw const WeatherServiceException(
        'Weather is unavailable. Please try again.',
      );
    }
    return weather;
  }
}
