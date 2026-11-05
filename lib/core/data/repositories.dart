import 'models.dart';

abstract interface class ClosetRepository {
  Stream<List<ClothingItem>> watchItems();
  Future<List<ClothingItem>> getItems();
  Future<void> saveItem(ClothingItem item);

  /// Deletes metadata only. The screen's photo owner deletes the local file.
  Future<void> deleteItem(String id);
}

abstract interface class OutfitRepository {
  Stream<List<Outfit>> watchOutfits();
  Future<void> saveOutfit(Outfit outfit);
  Future<void> deleteOutfit(String id);
}

abstract interface class ProfileRepository {
  Future<StyleProfile> getProfile();
  Future<void> saveProfile(StyleProfile profile);
}

abstract interface class WearLogRepository {
  Future<List<WearLog>> getWearLogs();
  Future<void> saveWearLog(WearLog log);
}
