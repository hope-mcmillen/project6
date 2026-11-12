import 'package:fitcheck_ai/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/outfits/test_lookbook_storage.dart';

Future<void> openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(FitCheckApp(lookbook: TestLookbookStorage().open()));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('navigation and wardrobe wear tracking work', (tester) async {
    await openApp(tester);
    expect(find.text('Good outfits start here.'), findsOneWidget);
    await tester.tap(find.text('Wardrobe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daisy tee'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('I wore this today'));
    await tester.pumpAndSettle();
    expect(find.text('Worn today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sample clothing can be added without a camera', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -350));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Try a sample photo'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add to wardrobe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to wardrobe'));
    await tester.pumpAndSettle();
    expect(find.textContaining('7 pieces'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('demo chat produces a selectable sample outfit', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Outfits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A picnic in the park'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
