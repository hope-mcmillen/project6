import 'dart:async';

import 'models.dart';
import 'repositories.dart';

/// An in-memory fake. It deliberately does not claim persistence across restarts.
class FakeClosetRepository implements ClosetRepository {
  FakeClosetRepository({Iterable<ClothingItem> items = const []})
    : _items = {for (final item in items) item.id: item};
  final Map<String, ClothingItem> _items;
  final _changes = StreamController<List<ClothingItem>>.broadcast();
  List<ClothingItem> get _snapshot => List.unmodifiable(_items.values);
  @override
  Stream<List<ClothingItem>> watchItems() => Stream.multi((sink) {
    final sub = _changes.stream.listen(sink.add, onError: sink.addError);
    sink.add(_snapshot);
    sink.onCancel = sub.cancel;
  });
  @override
  Future<List<ClothingItem>> getItems() async => _snapshot;
  @override
  Future<void> saveItem(ClothingItem item) async {
    _items[item.id] = item;
    _changes.add(_snapshot);
  }

  @override
  Future<void> deleteItem(String id) async {
    _items.remove(id);
    _changes.add(_snapshot);
  }

  Future<void> dispose() => _changes.close();
}

class FakeOutfitRepository implements OutfitRepository {
  final Map<String, Outfit> _items = {};
  final _changes = StreamController<List<Outfit>>.broadcast();
  List<Outfit> get _snapshot => List.unmodifiable(_items.values);
  @override
  Stream<List<Outfit>> watchOutfits() => Stream.multi((sink) {
    final sub = _changes.stream.listen(sink.add, onError: sink.addError);
    sink.add(_snapshot);
    sink.onCancel = sub.cancel;
  });
  @override
  Future<void> saveOutfit(Outfit outfit) async {
    _items[outfit.id] = outfit;
    _changes.add(_snapshot);
  }

  @override
  Future<void> deleteOutfit(String id) async {
    _items.remove(id);
    _changes.add(_snapshot);
  }

  Future<void> dispose() => _changes.close();
}

class FakeProfileRepository implements ProfileRepository {
  StyleProfile _profile = StyleProfile();
  @override
  Future<StyleProfile> getProfile() async => _profile;
  @override
  Future<void> saveProfile(StyleProfile profile) async {
    _profile = profile;
  }
}

class FakeWearLogRepository implements WearLogRepository {
  final Map<String, WearLog> _logs = {};
  @override
  Future<List<WearLog>> getWearLogs() async => List.unmodifiable(_logs.values);
  @override
  Future<void> saveWearLog(WearLog log) async {
    _logs[log.id] = log;
  }
}

/// Metadata fixtures only; Member 1 supplies licensed sample photo assets.
List<ClothingItem> sampleCloset() => [
  for (final category in ['top', 'bottom', 'shoes', 'dress'])
    ClothingItem(
      id: 'sample-$category',
      photoPath: 'assets/sample_closet/$category.jpg',
      tags: ClothingTags(
        category: category,
        color: 'blue',
        pattern: 'solid',
        formality: 'casual',
        season: 'all year',
      ),
      createdAt: DateTime.utc(2026, 11, 4),
      isSample: true,
    ),
];
