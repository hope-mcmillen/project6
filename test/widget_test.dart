import 'package:fitcheck_ai/app/app.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/firebase_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> openApp(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BackendScope(services: BackendServices.fake(), child: const FitCheckApp()),
  );
}

void main() {
  testWidgets('wardrobe tab shows the real closet', (tester) async {
    await openApp(tester);
    expect(find.text('Good outfits start here.'), findsOneWidget);
    await tester.tap(find.text('Wardrobe'));
    await tester.pumpAndSettle();
    expect(find.text('Your wardrobe'), findsOneWidget);
    expect(find.text('Load sample closet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('add item tab offers camera and gallery', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose from gallery'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the closet add button switches to the add item tab', (
    tester,
  ) async {
    await openApp(tester);
    await tester.tap(find.text('Wardrobe'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add item'));
    await tester.pumpAndSettle();
    expect(find.text('Take photo'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('demo chat produces a selectable sample outfit', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('Outfits'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('A picnic in the park'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Choose this outfit'));
    await tester.tap(find.text('Choose this outfit'));
    await tester.pumpAndSettle();
    expect(find.text('Outfit selected'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
