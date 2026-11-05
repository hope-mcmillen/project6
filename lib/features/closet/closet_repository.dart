import 'dart:async';

import 'clothing_item.dart';

/// Stores the user's closet. Swap in the Firestore version in M1-05.
abstract class ClosetRepository {
  /// The current items, newest first, followed by every later change.
  Stream<List<ClothingItem>> watchItems();

  Future<void> addItem(ClothingItem item);

  Future<void> deleteItem(String id);
}

/// A fake that keeps items in memory, so they are lost when the app closes.
class InMemoryClosetRepository implements ClosetRepository {
  final List<ClothingItem> _items = [];
  final StreamController<List<ClothingItem>> _changes =
      StreamController.broadcast();

  List<ClothingItem> get items => List.unmodifiable(_items);

  @override
  Stream<List<ClothingItem>> watchItems() {
    return Stream.multi((controller) {
      controller.add(items);
      final subscription = _changes.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }

  @override
  Future<void> addItem(ClothingItem item) async {
    _items.insert(0, item);
    _changes.add(items);
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    _changes.add(items);
  }
}

final ClosetRepository defaultClosetRepository = InMemoryClosetRepository();
