import 'package:fitcheck_ai/features/closet/add_item_screen.dart';
import 'package:fitcheck_ai/features/closet/closet_photo.dart';
import 'package:fitcheck_ai/features/closet/closet_repository.dart';
import 'package:fitcheck_ai/features/closet/closet_screen.dart';
import 'package:fitcheck_ai/features/closet/clothing_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const shirt = ClothingItem(
  id: 'shirt',
  photoPath: '/photos/shirt.jpg',
  tags: ClothingTags(
    category: 'Top',
    color: 'Blue',
    pattern: 'Solid',
    formality: 'Casual',
    season: 'Summer',
  ),
);

void main() {
  late InMemoryClosetRepository repository;

  setUp(() => repository = InMemoryClosetRepository());

  Future<void> openCloset(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(home: ClosetScreen(repository: repository)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty closet says so', (tester) async {
    await openCloset(tester);
    expect(find.textContaining('Your closet is empty'), findsOneWidget);
  });

  testWidgets('a new item shows up in the grid with its photo', (tester) async {
    await openCloset(tester);

    await repository.addItem(shirt);
    await tester.pumpAndSettle();

    expect(find.textContaining('Your closet is empty'), findsNothing);
    expect(find.text('Blue Top'), findsOneWidget);
    expect(
      tester.widget<ClosetPhoto>(find.byType(ClosetPhoto)).photoPath,
      '/photos/shirt.jpg',
    );
  });

  testWidgets('tapping an item opens its real tags', (tester) async {
    await repository.addItem(shirt);
    await openCloset(tester);

    await tester.tap(find.text('Blue Top'));
    await tester.pumpAndSettle();

    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Solid'), findsOneWidget);
    expect(find.text('Casual'), findsOneWidget);
    expect(find.text('Summer'), findsOneWidget);
  });

  testWidgets('add item saves to the same closet', (tester) async {
    await openCloset(tester);

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<AddItemScreen>(find.byType(AddItemScreen)).repository,
      same(repository),
    );
  });
}
