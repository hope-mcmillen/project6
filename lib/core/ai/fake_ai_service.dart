import 'dart:typed_data';

import '../data/models.dart';
import 'ai_service.dart';

class FakeAiService implements AiService {
  FakeAiService({
    this.failTagging = false,
    this.failOutfits = false,
    this.outfitCount = 3,
    this.failFitCheck = false,
  });
  final bool failTagging;
  final bool failOutfits;
  final int outfitCount;
  final bool failFitCheck;
  int taggingCalls = 0;
  int outfitCalls = 0;
  OutfitRequest? lastRequest;
  int fitCheckCalls = 0;
  FitCheckRequest? lastFitCheckRequest;

  @override
  Future<FitCheckFeedback> checkFit(FitCheckRequest request) async {
    fitCheckCalls++;
    lastFitCheckRequest = request;
    if (failFitCheck) {
      throw const AiServiceException('Fit Check unavailable. Please retry.');
    }
    return FitCheckFeedback(
      verdict: 'The clothing has coordinated colors and a consistent style.',
      suggestions: const [
        'Pair the outfit with shoes in a matching formality.',
        'Add a layer suited to the weather.',
        'Choose an accessory that repeats a clothing color.',
      ],
    );
  }

  @override
  Future<ClothingTags> tagClothing(Uint8List photoBytes) async {
    taggingCalls++;
    if (failTagging) {
      throw const AiServiceException(
        'Tags unavailable. Enter the tags manually.',
      );
    }
    return const ClothingTags(
      category: 'top',
      color: 'blue',
      pattern: 'solid',
      formality: 'casual',
      season: 'all year',
    );
  }

  @override
  Future<List<Outfit>> generateOutfits(OutfitRequest request) async {
    outfitCalls++;
    lastRequest = request;
    if (failOutfits) {
      throw const AiServiceException('Outfits unavailable. Please retry.');
    }
    if (request.missingCategories.isNotEmpty) {
      throw AiServiceException(
        'Add ${request.missingCategories.join(', ')} to your closet.',
      );
    }
    final items = request.closet.where((i) => !i.inLaundry).toList();
    final hasDress = items.any((i) => i.tags.category == 'dress');
    final categories = hasDress
        ? ['dress', 'shoes']
        : ['top', 'bottom', 'shoes'];
    final ids = [
      for (final c in categories)
        items.firstWhere((i) => i.tags.category == c).id,
    ];
    return [
      for (var i = 0; i < outfitCount.clamp(1, 3); i++)
        Outfit(
          id: 'fake-outfit-$i',
          itemIds: ids,
          occasion: request.occasion,
          reason:
              'These clothes suit ${request.occasion} with coordinated colors.',
          createdAt: DateTime.utc(2026, 11, 4),
        ),
    ];
  }
}
