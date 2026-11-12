import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/ai/ai_service.dart';
import '../../core/data/models.dart';
import '../../core/weather/open_meteo_weather_service.dart';
import '../../core/weather/weather_service.dart';
import 'outfit_results_screen.dart';

typedef WeatherCoordinates = ({double latitude, double longitude});

Future<WeatherCoordinates?> _deviceLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) return null;
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.unableToDetermine) {
    permission = await Geolocator.requestPermission();
  }
  if (permission != LocationPermission.whileInUse &&
      permission != LocationPermission.always) {
    return null;
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.low,
      timeLimit: Duration(seconds: 10),
    ),
  );
  return (latitude: position.latitude, longitude: position.longitude);
}

class OutfitRequestScreen extends StatefulWidget {
  const OutfitRequestScreen({
    required this.loadCloset,
    required this.ai,
    this.initialOccasion = 'Class',
    this.weatherService,
    this.locate = _deviceLocation,
    super.key,
  });

  final Future<List<ClothingItem>> Function() loadCloset;
  final AiService ai;
  final String initialOccasion;
  final WeatherService? weatherService;
  final Future<WeatherCoordinates?> Function() locate;

  @override
  State<OutfitRequestScreen> createState() => _OutfitRequestScreenState();
}

class _OutfitRequestScreenState extends State<OutfitRequestScreen> {
  static const _occasions = [
    'Everyday',
    'Class',
    'Work',
    'Party',
    'Picnic',
    'Going out',
    'Interview',
  ];
  final _city = TextEditingController();
  final _note = TextEditingController();
  late String _occasion = widget.initialOccasion;
  late final _ownedService = widget.weatherService == null
      ? OpenMeteoWeatherService()
      : null;
  WeatherService get _service => widget.weatherService ?? _ownedService!;
  WeatherSummary? _weather;
  String? _weatherError;
  String? _requestError;
  bool _loadingWeather = false;
  bool _requesting = false;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  @override
  void dispose() {
    _city.dispose();
    _note.dispose();
    _ownedService?.close();
    super.dispose();
  }

  Future<void> _loadWeather({String? city}) async {
    if (_loadingWeather || _requesting) return;
    setState(() {
      _loadingWeather = true;
      _weather = null;
      _weatherError = null;
    });
    try {
      final WeatherSummary weather;
      if (city != null) {
        weather = await _service.weatherForCity(city);
      } else {
        final position = await widget.locate();
        if (!mounted) return;
        if (position == null) {
          throw const WeatherServiceException(
            'Location is unavailable. Enter a city to see its weather.',
          );
        }
        weather = await _service.weatherAt(
          latitude: position.latitude,
          longitude: position.longitude,
        );
      }
      if (mounted) setState(() => _weather = weather);
    } on WeatherServiceException catch (error) {
      if (mounted) setState(() => _weatherError = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _weatherError =
              'Could not get local weather. Try again or enter a city.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingWeather = false);
    }
  }

  Future<void> _requestOutfits() async {
    final weather = _weather;
    if (_requesting || _loadingWeather) return;
    final occasion = _occasion;
    final note = _note.text.trim();
    setState(() {
      _requesting = true;
      _requestError = null;
    });
    try {
      final closet = await widget.loadCloset();
      if (!mounted) return;
      final request = OutfitRequest(
        closet: closet,
        occasion: occasion,
        note: note,
        weather: weather,
      );
      final missing = request.missingCategories;
      if (missing.isNotEmpty) {
        throw AiServiceException(
          'Add ${missing.join(', ')} to your wardrobe first.',
        );
      }
      final outfits = await widget.ai.generateOutfits(request);
      if (!mounted) return;
      if (outfits.isEmpty) {
        throw const AiServiceException(
          'No outfits found. Try a different occasion or note.',
        );
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OutfitResultsScreen(outfits: outfits, closet: closet),
        ),
      );
    } on AiServiceException catch (error) {
      if (mounted) setState(() => _requestError = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _requestError = 'Could not get outfits. Try again.');
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }

  Widget _weatherCard() {
    final weather = _weather;
    final controlsEnabled = !_loadingWeather && !_requesting;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weather', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (_loadingWeather)
              const LinearProgressIndicator(semanticsLabel: 'Loading weather'),
            if (_weatherError case final error?) Text(error),
            if (weather != null) ...[
              Text(
                weather.locationLabel.isEmpty
                    ? 'Current location'
                    : weather.locationLabel,
              ),
              Text('${weather.temperatureC} °C'),
              Text('${weather.rainChancePercent}% chance of rain'),
              const Text(
                'Location rounded to 0.01° and rain chance rounded to whole percent.',
              ),
              Wrap(
                children: [
                  TextButton(
                    onPressed: () => launchUrl(Uri.https('open-meteo.com')),
                    child: const Text('Weather data by Open-Meteo.com'),
                  ),
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.https('creativecommons.org', '/licenses/by/4.0/'),
                    ),
                    child: const Text('CC BY 4.0'),
                  ),
                  if (weather.locationLabel.isNotEmpty)
                    TextButton(
                      onPressed: () => launchUrl(Uri.https('www.geonames.org')),
                      child: const Text('City data by GeoNames'),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _city,
              enabled: controlsEnabled,
              decoration: const InputDecoration(labelText: 'City'),
              textInputAction: TextInputAction.search,
              onSubmitted: controlsEnabled
                  ? (city) => _loadWeather(city: city.trim())
                  : null,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: controlsEnabled
                      ? () => _loadWeather(city: _city.text.trim())
                      : null,
                  child: const Text('Check city weather'),
                ),
                TextButton(
                  onPressed: controlsEnabled ? () => _loadWeather() : null,
                  child: const Text('Use my location'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Plan an outfit')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _weatherCard(),
        const SizedBox(height: 16),
        Text('Occasion', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final occasion in _occasions)
              ChoiceChip(
                label: Text(occasion),
                selected: occasion == _occasion,
                onSelected: _requesting
                    ? null
                    : (_) => setState(() => _occasion = occasion),
              ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _note,
          enabled: !_requesting,
          decoration: const InputDecoration(labelText: 'Optional note'),
        ),
        const SizedBox(height: 16),
        if (_requestError case final error?) Text(error),
        FilledButton(
          onPressed: _loadingWeather || _requesting ? null : _requestOutfits,
          child: Text(
            _requesting
                ? 'Getting outfits…'
                : _weather == null
                ? 'Get outfits without weather'
                : 'Get outfits',
          ),
        ),
      ],
    ),
  );
}
