import 'package:fitcheck_ai/app/age_confirmation.dart';
import 'package:fitcheck_ai/app/app.dart';
import 'package:fitcheck_ai/app/welcome_screen.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/firebase_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_test_helpers.dart';

const homeHeadline = 'Good outfits start here.';

void main() {
  testWidgets('first launch shows welcome and remembers the answer', (
    tester,
  ) async {
    mockSavedSettings(ageConfirmed: false);
    await pumpFitCheckApp(tester);

    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text(homeHeadline), findsNothing);

    await tester.scrollUntilVisible(
      find.text('I am 18 or older, continue'),
      200,
    );
    await tester.tap(find.text('I am 18 or older, continue'));
    await tester.pumpAndSettle();

    expect(find.text(homeHeadline), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(AgeConfirmation.key), isTrue);
  });

  testWidgets('repeat launch opens the app without the welcome screen', (
    tester,
  ) async {
    mockSavedSettings(ageConfirmed: true);
    await pumpFitCheckApp(tester);

    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.text(homeHeadline), findsOneWidget);
  });

  testWidgets('a failed startup shows Retry, and retrying opens the app', (
    tester,
  ) async {
    mockSavedSettings(ageConfirmed: true);
    var attempts = 0;
    await tester.pumpWidget(
      FirebaseBackend(
        load: () async {
          attempts++;
          if (attempts == 1) throw Exception('no network');
          return BackendServices.fake();
        },
        child: FitCheckApp(connection: FakeConnectionStatus()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Could not connect. Check your connection and try again.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(attempts, 2);
    expect(find.text(homeHeadline), findsOneWidget);
  });

  test('clearing the confirmation shows the welcome screen again', () async {
    mockSavedSettings(ageConfirmed: true);
    const confirmation = AgeConfirmation();

    expect(await confirmation.isConfirmed(), isTrue);
    await confirmation.clear();
    expect(await confirmation.isConfirmed(), isFalse);
  });
}
