import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/features/settings/style_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Opens the profile from a home page, so saving can return to it.
Future<void> openProfile(
  WidgetTester tester,
  FakeProfileRepository repository,
) async {
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => StyleProfileScreen(repository: repository),
              ),
            ),
            child: const Text('Open profile'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open profile'));
  await tester.pumpAndSettle();
}

Finder field(String label) => find.widgetWithText(TextField, label);

void main() {
  test('splitList trims entries and drops blanks', () {
    expect(splitList(' orange, neon green ,, '), ['orange', 'neon green']);
    expect(splitList(''), isEmpty);
  });

  testWidgets('saves the answers', (tester) async {
    final repository = FakeProfileRepository();
    await openProfile(tester, repository);

    await tester.enterText(field('What is your style?'), 'Minimal');
    await tester.enterText(
      field('Which colors should we avoid?'),
      'orange, neon green',
    );
    await tester.enterText(
      field('What occasions do you dress for?'),
      'class, work',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final profile = await repository.getProfile();
    expect(profile.style, 'Minimal');
    expect(profile.colorsToAvoid, ['orange', 'neon green']);
    expect(profile.regularOccasions, ['class', 'work']);
    expect(find.byType(StyleProfileScreen), findsNothing);
  });

  testWidgets('every question can be left blank', (tester) async {
    final repository = FakeProfileRepository();
    await openProfile(tester, repository);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final profile = await repository.getProfile();
    expect(profile.style, isEmpty);
    expect(profile.colorsToAvoid, isEmpty);
    expect(profile.regularOccasions, isEmpty);
  });

  testWidgets('shows saved answers so they can be edited', (tester) async {
    final repository = FakeProfileRepository();
    await repository.saveProfile(
      StyleProfile(style: 'Sporty', colorsToAvoid: const ['brown']),
    );
    await openProfile(tester, repository);

    expect(find.text('Sporty'), findsOneWidget);
    expect(find.text('brown'), findsOneWidget);

    await tester.enterText(field('What is your style?'), 'Preppy');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect((await repository.getProfile()).style, 'Preppy');
  });

  testWidgets('Skip leaves without saving', (tester) async {
    final repository = FakeProfileRepository();
    await openProfile(tester, repository);

    await tester.enterText(field('What is your style?'), 'Minimal');
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    expect((await repository.getProfile()).style, isEmpty);
    expect(find.byType(StyleProfileScreen), findsNothing);
  });
}
