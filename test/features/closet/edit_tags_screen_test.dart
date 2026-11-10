import 'package:fitcheck_ai/features/closet/edit_tags_screen.dart';
import 'package:fitcheck_ai/features/closet/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'closet_test_helpers.dart';

final shirt = testItem('shirt', color: 'blue', season: 'summer');

void main() {
  late TestClosetRepository repository;

  setUp(() async {
    repository = TestClosetRepository();
    await repository.saveItem(shirt);
  });

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> openDetail(WidgetTester tester) async {
    await pumpClosetScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(
                  item: shirt,
                  repository: repository,
                  deletePhoto: (_) async {},
                ),
              ),
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit tags'));
    await tester.pumpAndSettle();
  }

  testWidgets('starts from the saved tags', (tester) async {
    await openDetail(tester);

    expect(find.byType(EditTagsScreen), findsOneWidget);
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('blue'), findsOneWidget);
    expect(find.text('summer'), findsOneWidget);
  });

  testWidgets('saving keeps the item and shows the new tags', (tester) async {
    await openDetail(tester);

    await tester.enterText(field('Color'), ' Red ');
    await tester.enterText(field('Season'), 'Fall');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outerwear').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    final saved = repository.items.single;
    expect(saved.id, shirt.id);
    expect(saved.photoPath, shirt.photoPath);
    expect(saved.createdAt, shirt.createdAt);
    expect(saved.tags.category, 'outerwear');
    expect(saved.tags.color, 'Red');
    expect(saved.tags.season, 'Fall');
    expect(saved.tags.pattern, 'solid');

    // Back on the details screen, with the new values.
    expect(find.byType(EditTagsScreen), findsNothing);
    expect(find.text('Red outerwear'), findsOneWidget);
    expect(find.text('Fall'), findsOneWidget);
    expect(find.text('Tags updated'), findsOneWidget);
  });

  testWidgets('backing out changes nothing', (tester) async {
    await openDetail(tester);

    await tester.enterText(field('Color'), 'Red');
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repository.items.single.tags.color, 'blue');
    expect(find.text('Blue top'), findsOneWidget);
  });

  testWidgets('a rejected save says so', (tester) async {
    await openDetail(tester);
    repository.failWrites = true;

    await tester.enterText(field('Color'), 'Red');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(repository.items.single.tags.color, 'blue');
    expect(
      find.text('Could not save your changes. Try again.'),
      findsOneWidget,
    );
  });
}
