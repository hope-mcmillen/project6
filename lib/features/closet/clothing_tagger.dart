import 'clothing_item.dart';

/// Suggests tags for a clothing photo. Swap in the real AI service in M1-05.
abstract class ClothingTagger {
  Future<ClothingTags> suggestTags(String photoPath);
}

/// A fake that always suggests the same tags without calling any AI service.
class FakeClothingTagger implements ClothingTagger {
  const FakeClothingTagger();

  @override
  Future<ClothingTags> suggestTags(String photoPath) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return const ClothingTags(
      category: 'Top',
      color: 'Blue',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'All year',
    );
  }
}

const ClothingTagger defaultClothingTagger = FakeClothingTagger();
