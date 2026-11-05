import 'dart:io';

import 'package:fitcheck_ai/features/closet/closet_photo_picker.dart';
import 'package:fitcheck_ai/features/closet/closet_repository.dart';
import 'package:fitcheck_ai/features/closet/clothing_item.dart';
import 'package:fitcheck_ai/features/closet/item_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const shoes = ClothingItem(
  id: 'shoes',
  photoPath: '/photos/shoes.jpg',
  tags: ClothingTags(category: 'Shoes'),
);

void main() {
  late InMemoryClosetRepository repository;
  late List<String> deletedPhotos;

  setUp(() async {
    repository = InMemoryClosetRepository();
    deletedPhotos = [];
    await repository.addItem(shoes);
  });

  Future<void> openDetail(WidgetTester tester) async {
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
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a blank tag reads as not set', (tester) async {
    await openDetail(tester);
    expect(find.text('Not set'), findsNWidgets(4));
  });

  testWidgets('cancelling keeps the item and its photo', (tester) async {
    await openDetail(tester);

    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.items, hasLength(1));
    expect(deletedPhotos, isEmpty);
    expect(find.text('Delete item'), findsOneWidget);
  });

  testWidgets('deleting removes the item and its photo, then goes back', (
    tester,
  ) async {
    await openDetail(tester);

    await tester.tap(find.text('Delete item'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(repository.items, isEmpty);
    expect(deletedPhotos, ['/photos/shoes.jpg']);
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Item deleted'), findsOneWidget);
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
