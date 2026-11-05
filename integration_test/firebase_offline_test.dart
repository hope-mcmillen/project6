import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/firebase_options.dart';

/// Two separate invocations prove on-disk cache persistence across app launches.
/// First: flutter test integration_test/firebase_offline_test.dart -d emulator-5554 --no-uninstall
/// Then: same command with --dart-define=FIREBASE_OFFLINE_PHASE=verify
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const phase = String.fromEnvironment(
    'FIREBASE_OFFLINE_PHASE',
    defaultValue: 'seed',
  );
  testWidgets('live offline cache across launches: $phase', (tester) async {
    final services = await BackendServices.connect(
      options: DefaultFirebaseOptions.android,
    );
    final db = FirebaseFirestore.instance;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final directory = await getApplicationSupportDirectory();
    final evidence = File('${directory.path}/firebase-offline-smoke.json');
    if (phase == 'seed') {
      final sample = sampleCloset().first;
      final item = ClothingItem(
        id: 'offline-smoke-${DateTime.now().microsecondsSinceEpoch}',
        photoPath: 'test-only/offline.jpg',
        tags: sample.tags,
        createdAt: DateTime.now(),
        isSample: true,
      );
      await services.closet.saveItem(item).timeout(const Duration(seconds: 30));
      final ref = db.doc('users/$uid/items/${item.id}');
      expect(
        (await ref.get(const GetOptions(source: Source.server))).exists,
        isTrue,
      );
      await evidence.writeAsString(
        jsonEncode({'uid': uid, 'id': item.id}),
        flush: true,
      );
    } else {
      expect(phase, 'verify');
      expect(
        await evidence.exists(),
        isTrue,
        reason: 'Run the seed phase first.',
      );
      final saved =
          jsonDecode(await evidence.readAsString()) as Map<String, dynamic>;
      expect(
        uid,
        saved['uid'],
        reason: 'The anonymous account must survive restart.',
      );
      final ref = db.doc('users/$uid/items/${saved['id']}');
      await db.disableNetwork();
      try {
        final snapshot = await ref.get(const GetOptions(source: Source.cache));
        expect(snapshot.exists, isTrue);
        expect(snapshot.metadata.isFromCache, isTrue);
        expect(
          (await services.closet.getItems()).any(
            (item) => item.id == saved['id'],
          ),
          isTrue,
        );
      } finally {
        await db.enableNetwork();
        await ref.delete();
        await evidence.delete();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 2)));
}
