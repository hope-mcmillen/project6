import 'dart:io';

import 'package:fitcheck_ai/features/closet/closet_photo_picker.dart';
import 'package:fitcheck_ai/features/closet/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'closet_test_helpers.dart';

final shoes = testItem(
  'shoes',
  category: 'shoes',
  color: 'black',
  pattern: '',
  formality: '',
  season: '',
);

void main() {
  late TestClosetRepository repository;
  late List<String> deletedPhotos;

  setUp(() async {
    repository = TestClosetRepository();
    deletedPhotos = [];
    await repository.saveItem(shoes);
  });

  Future<void> openDetail(WidgetTester tester) async {
    await pumpClosetScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ItemDetailScreen(
                  item: shoes,
                  repository: repository,
                  deletePhoto: (path) async => deletedPhotos.add(path),
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
  }

  Future<void> deleteAndConfirm(WidgetTester tester, String choice) async {
    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(choice));
    await tester.pumpAndSettle();
  }

  testWidgets('shows readable tags and marks blank ones', (tester) async {
    await openDetail(tester);
    expect(find.text('Black shoes'), findsOneWidget);
    expect(find.text('Shoes'), findsOneWidget);
    expect(find.text('Not set'), findsNWidgets(3));
  });

  testWidgets('cancelling keeps the item and its photo', (tester) async {
    await openDetail(tester);

    await deleteAndConfirm(tester, 'Cancel');

    expect(repository.items, hasLength(1));
    expect(deletedPhotos, isEmpty);
    expect(find.text('Delete item'), findsOneWidget);
  });

  testWidgets('deleting removes the item and its photo, then goes back', (
    tester,
  ) async {
    await openDetail(tester);

    await deleteAndConfirm(tester, 'Delete');

    expect(repository.items, isEmpty);
    expect(deletedPhotos, ['/photos/shoes.jpg']);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Item deleted'), findsOneWidget);
  });

  testWidgets('a rejected delete keeps the photo and says so', (tester) async {
    await openDetail(tester);
    repository.failWrites = true;

    await deleteAndConfirm(tester, 'Delete');

    expect(repository.items, hasLength(1));
    expect(deletedPhotos, isEmpty);
    expect(find.text('Could not delete that item. Try again.'), findsOneWidget);
  });

  test(
    'deleteClosetPhoto removes the file and tolerates a missing one',
    () async {
      final directory = await Directory.systemTemp.createTemp('closet_delete');
      addTearDown(() => directory.delete(recursive: true));
      final photo = File('${directory.path}/photo.jpg');
      await photo.writeAsBytes([1, 2, 3]);

      await deleteClosetPhoto(photo.path);
      expect(await photo.exists(), isFalse);

      await deleteClosetPhoto(photo.path);
    },
  );
}
