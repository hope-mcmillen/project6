import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:fitcheck_ai/app/app.dart';
import 'package:fitcheck_ai/core/data/firebase_backend.dart';
import 'package:fitcheck_ai/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('real app startup connects Firebase before showing the app', (
    tester,
  ) async {
    app.main();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 45),
    );
    final appWidget = find.byType(FitCheckApp);
    expect(appWidget, findsOneWidget);
    final services = BackendScope.of(tester.element(appWidget));
    expect(FirebaseAuth.instance.currentUser?.isAnonymous, isTrue);
    expect(await services.closet.getItems(), isNotNull);
  }, timeout: const Timeout(Duration(minutes: 1)));
}
