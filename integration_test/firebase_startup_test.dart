import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitcheck_ai/app/app.dart';
import 'package:fitcheck_ai/core/data/firebase_backend.dart';
import 'package:fitcheck_ai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real app startup initializes Firebase before showing welcome', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 45),
    );
    expect(find.text('I am 18 or older, continue'), findsOneWidget);
    expect(FirebaseAuth.instance.currentUser, isNotNull);
    final services = BackendScope.of(tester.element(find.byType(FitCheckApp)));
    expect(await services.closet.getItems(), isNotNull);
  }, timeout: const Timeout(Duration(minutes: 1)));
}
