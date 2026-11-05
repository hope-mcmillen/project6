import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/firebase_options.dart';

/// Explicit, live Gemini calls. Register this emulator's debug token first.
/// --no-uninstall keeps that device credential stable for later local testing.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('live verified clothing tagging and outfit generation', (
    tester,
  ) async {
    final services = await BackendServices.connect(
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
    // Timing is evidence, not an invariant: model/network load can vary.
    // ignore: avoid_print
    print('Clothing tagging completed in ${timer.elapsedMilliseconds} ms.');
    final closet = sampleCloset();
    final request = OutfitRequest(
      closet: closet,
      occasion: 'casual class',
      weather: const WeatherSummary(temperatureC: 22, rainChancePercent: 10),
    );
    final outfits = await services.ai.generateOutfits(request);
    expect(outfits.length, inInclusiveRange(1, 3));
    expect(
      outfits.every(
        (o) => o.itemIds.every((id) => closet.any((i) => i.id == id)),
      ),
      isTrue,
    );
    expect(outfits.every((o) => o.reason.isNotEmpty), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
