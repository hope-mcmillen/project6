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
  final now = DateTime(2026, 11, 16, 12);
  late TestClosetRepository repository;
  late TestWearLogRepository wearLogs;
  late List<String> deletedPhotos;

  setUp(() async {
    repository = TestClosetRepository();
    wearLogs = TestWearLogRepository();
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
                  wearLogs: wearLogs,
                  now: () => now,
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

  group('wear history', () {
    testWidgets('shows an unworn item as never worn', (tester) async {
      await openDetail(tester);

      expect(find.text('Not worn yet'), findsOneWidget);
      expect(find.text('Never'), findsOneWidget);
      expect(find.text('Wore this today'), findsOneWidget);
    });

    testWidgets('shows how often and how recently it was worn', (tester) async {
      await wearLogs.saveWearLog(testWear('shoes', DateTime(2026, 11, 1)));
      await wearLogs.saveWearLog(testWear('shoes', DateTime(2026, 11, 4)));
      await wearLogs.saveWearLog(testWear('other', DateTime(2026, 11, 15)));

      await openDetail(tester);

      expect(find.text('2 times'), findsOneWidget);
      expect(find.text('12 days ago'), findsOneWidget);
    });

    testWidgets('logging a wear saves it and updates the stats', (
      tester,
    ) async {
      await openDetail(tester);

      await tester.tap(find.text('Wore this today'));
      await tester.pumpAndSettle();

      expect(wearLogs.saved, hasLength(1));
      expect(wearLogs.saved.single.itemIds, ['shoes']);
      expect(wearLogs.saved.single.wornAt, now);
      expect(find.text('Once'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Worn today'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('a rejected wear is undone and says so', (tester) async {
      await openDetail(tester);
      wearLogs.failWrites = true;

      await tester.tap(find.text('Wore this today'));
      await tester.pumpAndSettle();

      expect(find.text('Could not log that wear. Try again.'), findsOneWidget);
      expect(find.text('Not worn yet'), findsOneWidget);
      expect(find.text('Wore this today'), findsOneWidget);
    });

    testWidgets('a failed load offers a retry', (tester) async {
      wearLogs.failReads = true;
      await openDetail(tester);

      expect(find.text('Could not load wear history.'), findsOneWidget);

      wearLogs.failReads = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Not worn yet'), findsOneWidget);
    });
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
