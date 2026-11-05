import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/firebase_options.dart';

/// Explicit live Gemini calls using the app's default model and timeout.
/// Register this emulator's debug token first, then run with --no-uninstall
/// to preserve its authorized development credential between launches.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late BackendServices services;
  setUpAll(() async {
    services = await BackendServices.connect(
      options: DefaultFirebaseOptions.android,
    );
    final token = await FirebaseAppCheck.instance
        .getToken(true)
        .timeout(const Duration(seconds: 30));
    expect(
      token,
      isNotEmpty,
      reason: 'Authorize the emulator debug token in Firebase App Check first.',
    );
    // Never print App Check tokens or the SDK's private debug credential.
  });
  testWidgets('live clothing tagging with the production timeout', (
    tester,
  ) async {
    final photo = (await rootBundle.load(
      'assets/backend_test/black_tshirt.jpg',
    )).buffer.asUint8List();
    final timer = Stopwatch()..start();
    final tags = await services.ai.tagClothing(photo);
    timer.stop();
    expect(tags.category, 'top');
    expect(tags.color, isNotEmpty);
    expect(tags.pattern, isNotEmpty);
    expect(tags.formality, isNotEmpty);
    expect(tags.season, isNotEmpty);
    // Explicit public fixture: record latency and clothing tags, never credentials.
    // ignore: avoid_print
    print('Clothing tags in ${timer.elapsedMilliseconds} ms: ${tags.toMap()}');
  }, timeout: const Timeout(Duration(minutes: 1)));
  testWidgets('live outfits with the production timeout and closet ID checks', (
    tester,
  ) async {
    final closet = sampleCloset();
    final request = OutfitRequest(
      closet: closet,
      occasion: 'casual class',
      weather: const WeatherSummary(temperatureC: 22, rainChancePercent: 10),
    );
    final timer = Stopwatch()..start();
    final outfits = await services.ai.generateOutfits(request);
    timer.stop();
    expect(outfits.length, inInclusiveRange(1, 3));
    expect(
      outfits.every(
        (o) => o.itemIds.every((id) => closet.any((i) => i.id == id)),
      ),
      isTrue,
    );
    expect(outfits.every((o) => o.reason.isNotEmpty), isTrue);
    // These reasons refer only to the explicit sample fixture.
    // ignore: avoid_print
    print(
      'Outfits in ${timer.elapsedMilliseconds} ms: ${outfits.map((o) => o.reason).join(' | ')}',
    );
  }, timeout: const Timeout(Duration(minutes: 1)));
}
