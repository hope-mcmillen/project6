import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/firestore_repositories.dart';
import 'package:fitcheck_ai/firebase_options.dart';

/// Opt-in: creates disposable anonymous accounts and a sample record in the real
/// development project. Cleans up only data/accounts created by this test.
/// Run: flutter test integration_test/firebase_backend_test.dart -d emulator-5554
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'live anonymous storage, reload, and cross-user rule enforcement',
    (tester) async {
      final services = await BackendServices.connect(
        options: DefaultFirebaseOptions.android,
      );
      final auth = FirebaseAuth.instance;
      final uid = auth.currentUser!.uid;
      final id = 'smoke-${DateTime.now().microsecondsSinceEpoch}';
      final source = sampleCloset().first;
      final item = source.copyWith(photoPath: 'test-only/no-photo.jpg');
      // Use the unique test ID, leaving the regular sample fixture untouched.
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('items')
          .doc(id);
      FirebaseApp? otherApp;
      FirebaseAuth? otherAuth;
      try {
        await ref.set(item.toMap()).timeout(const Duration(seconds: 30));
        expect(
          (await ref.get(const GetOptions(source: Source.server)))
              .get('tags.color'),
          item.tags.color,
        );
        final reloaded = await services.closet.getItems();
        expect(reloaded.any((i) => i.id == id), isTrue);

        otherApp = await Firebase.initializeApp(
          name: 'isolation-probe',
          options: DefaultFirebaseOptions.android,
        );
        otherAuth = FirebaseAuth.instanceFor(app: otherApp);
        final otherUser = await ensureAnonymousSignIn(otherAuth);
        expect(otherUser.uid, isNot(uid));
        final otherDb = FirebaseFirestore.instanceFor(app: otherApp);
        final denied = throwsA(
          isA<FirebaseException>().having(
            (e) => e.code,
            'code',
            'permission-denied',
          ),
        );
        final foreign = otherDb.doc('users/$uid/items/$id');
        await expectLater(
          foreign.get(const GetOptions(source: Source.server)),
          denied,
        );
        await expectLater(
          otherDb
              .collection('users/$uid/items')
              .get(const GetOptions(source: Source.server)),
          denied,
        );
        await expectLater(foreign.set(item.toMap()), denied);
        await expectLater(
          foreign.update({'photoPath': 'test-only/blocked.jpg'}),
          denied,
        );
        await expectLater(foreign.delete(), denied);
      } finally {
        await ref.delete();
        await otherAuth?.currentUser?.delete();
        await otherApp?.delete();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
