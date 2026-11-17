import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/firebase_backend.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A fake closet whose contents tests can read directly, and that can be told
/// to fail like a rejected Firestore write.
class TestClosetRepository extends FakeClosetRepository {
  final List<ClothingItem> items = [];
  bool failWrites = false;

  @override
  Future<void> saveItem(ClothingItem item) async {
    if (failWrites) throw Exception('write rejected');
    items
      ..removeWhere((saved) => saved.id == item.id)
      ..add(item);
    await super.saveItem(item);
  }

  @override
  Future<void> deleteItem(String id) async {
    if (failWrites) throw Exception('write rejected');
    items.removeWhere((saved) => saved.id == id);
    await super.deleteItem(id);
  }
}

/// A fake wear history that tests can read, and that can fail like Firestore.
class TestWearLogRepository extends FakeWearLogRepository {
  final List<WearLog> saved = [];
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<List<WearLog>> getWearLogs() async {
    if (failReads) throw Exception('read rejected');
    return super.getWearLogs();
  }

  @override
  Future<void> saveWearLog(WearLog log) async {
    if (failWrites) throw Exception('write rejected');
    saved.add(log);
    await super.saveWearLog(log);
  }
}

WearLog testWear(String itemId, DateTime wornAt) => WearLog(
  id: '$itemId-${wornAt.toIso8601String()}',
  outfitId: '',
  itemIds: [itemId],
  wornAt: wornAt,
);

ClothingItem testItem(
  String id, {
  String category = 'top',
  String color = 'blue',
  String pattern = 'solid',
  String formality = 'casual',
  String season = 'summer',
  DateTime? createdAt,
}) {
  return ClothingItem(
    id: id,
    photoPath: '/photos/$id.jpg',
    tags: ClothingTags(
      category: category,
      color: color,
      pattern: pattern,
      formality: formality,
      season: season,
    ),
    createdAt: createdAt ?? DateTime(2026, 11, 1),
  );
}

/// Pumps [home] inside the app's backend scope on a tall test screen.
Future<void> pumpClosetScreen(
  WidgetTester tester,
  Widget home, {
  BackendServices? services,
}) async {
  tester.view.physicalSize = const Size(600, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BackendScope(
      services: services ?? BackendServices.fake(),
      child: MaterialApp(home: home),
    ),
  );
}
