import 'package:fitcheck_ai/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(360, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const FitCheckApp());
  await tester.tap(find.text('I am 18 or older, continue'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('welcome screen leads to the closet', (tester) async {
    await openApp(tester);
    expect(find.text('My Closet'), findsOneWidget);
  });

  testWidgets('every tab opens', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Outfits'));
    await tester.pumpAndSettle();
    expect(find.text('Get an Outfit'), findsOneWidget);
    await tester.tap(find.text('Lookbook').last);
    await tester.pumpAndSettle();
    expect(find.text('Class outfit'), findsOneWidget);
    await tester.tap(find.text('Fit Check').last);
    await tester.pumpAndSettle();
    expect(find.text('Check my fit'), findsOneWidget);
  });

  testWidgets('add item button opens the add item screen', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
  });

  testWidgets('outfit flow reaches results', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Outfits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get outfits'));
    await tester.pumpAndSettle();
    expect(find.text('Your Outfits'), findsOneWidget);
  });

  testWidgets('fit check flow reaches results', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Fit Check').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check my fit'));
    await tester.pumpAndSettle();
    expect(find.text('Fit Check Result'), findsOneWidget);
  });

  testWidgets('settings opens its sub-screens', (tester) async {
    await openApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Style profile'));
    await tester.pumpAndSettle();
    expect(find.text('Style Profile'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Privacy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Placeholder privacy'), findsOneWidget);
  });
}
