import 'dart:async';

import 'clothing_item.dart';

/// Stores the user's closet. Swap in the Firestore version in M1-05.
abstract class ClosetRepository {
  Stream<List<ClothingItem>> watchItems();

  Future<void> addItem(ClothingItem item);

  Future<void> deleteItem(String id);
}

/// A fake that keeps items in memory, so they are lost when the app closes.
class InMemoryClosetRepository implements ClosetRepository {
  final List<ClothingItem> _items = [];
  final StreamController<List<ClothingItem>> _changes =
      StreamController.broadcast();

  List<ClothingItem> get _snapshot => List.unmodifiable(_items);

  @override
  Stream<List<ClothingItem>> watchItems() async* {
    yield _snapshot;
    yield* _changes.stream;
  }

  @override
  Future<void> addItem(ClothingItem item) async {
    _items.add(item);
    _changes.add(_snapshot);
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    _changes.add(_snapshot);
  }
}

final ClosetRepository defaultClosetRepository = InMemoryClosetRepository();
