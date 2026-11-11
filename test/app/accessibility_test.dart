import 'dart:typed_data';

import 'package:fitcheck_ai/app/welcome_screen.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/features/fit_check/fit_check_result_screen.dart';
import 'package:fitcheck_ai/features/fit_check/fit_check_screen.dart';
import 'package:fitcheck_ai/features/fit_check/fit_check_service.dart';
import 'package:fitcheck_ai/features/settings/privacy_screen.dart';
import 'package:fitcheck_ai/features/settings/settings_screen.dart';
import 'package:fitcheck_ai/features/settings/style_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_test_helpers.dart';

/// A phone screen at twice the normal text size.
const phone = Size(390, 844);
const largeText = 2.0;

/// Pumps [screen] at a large text size, then checks that nothing overflowed
/// and that every tappable control has a label a screen reader can read.
Future<void> checkScreen(WidgetTester tester, Widget screen) async {
  final semantics = tester.ensureSemantics();
  await pumpWithAppServices(tester, screen, size: phone, textScale: largeText);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  expect(tester.takeException(), isNull);
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  semantics.dispose();
}

void main() {
  setUp(() => mockSavedSettings(ageConfirmed: true));

  testWidgets('welcome screen', (tester) async {
    await checkScreen(tester, WelcomeScreen(onConfirmed: () async {}));
  });

  testWidgets('Fit Check tab', (tester) async {
    await checkScreen(
      tester,
      Scaffold(body: FitCheckScreen(service: FakeFitCheckService())),
    );
  });

  testWidgets('Fit Check result', (tester) async {
    await checkScreen(
      tester,
      FitCheckResultScreen(
        photoPath: '/picked/outfit.jpg',
        occasion: 'Work',
        service: FakeFitCheckService(),
        readPhoto: (_) async => Uint8List(0),
        preparePhoto: (bytes) async => bytes,
        savePhoto: (path) async => path,
        discardPhoto: (_) async {},
      ),
    );
    expect(find.text('Works well for work.'), findsOneWidget);
  });

  testWidgets('settings', (tester) async {
    await checkScreen(tester, const SettingsScreen());
  });

  testWidgets('privacy notice', (tester) async {
    await checkScreen(tester, const PrivacyScreen());
  });

  testWidgets('style profile', (tester) async {
    await checkScreen(
      tester,
      StyleProfileScreen(repository: FakeProfileRepository()),
    );
  });

  testWidgets('photos and icons have screen reader labels', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpWithAppServices(tester, WelcomeScreen(onConfirmed: () async {}));

    expect(find.bySemanticsLabel('FitCheck AI logo'), findsOneWidget);
    semantics.dispose();
  });
}
