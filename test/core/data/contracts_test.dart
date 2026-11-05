import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/ai/ai_service.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';

void main() {
  test('models round trip user edits and dates without photo bytes', () {
    final item = sampleCloset().first.copyWith(
      tags: const ClothingTags(
        category: 'top',
        color: 'green',
        pattern: 'striped',
        formality: 'formal',
        season: 'winter',
      ),
      inLaundry: true,
    );
    final restored = ClothingItem.fromMap(item.id, item.toMap());
    expect(restored.tags.color, 'green');
    expect(restored.inLaundry, isTrue);
    expect(restored.createdAt, item.createdAt);
    expect(item.toMap().keys, isNot(contains('photoBytes')));
    final outfit = Outfit(
      id: 'one',
      itemIds: ['top', 'shoes'],
      reason: 'Coordinated.',
      occasion: 'work',
      createdAt: DateTime.utc(2026),
    );
    expect(Outfit.fromMap(outfit.id, outfit.toMap()).itemIds, outfit.itemIds);
    final log = WearLog(
      id: 'log',
      outfitId: outfit.id,
      itemIds: outfit.itemIds,
      wornAt: DateTime.utc(2026),
    );
    expect(WearLog.fromMap(log.id, log.toMap()).wornAt, log.wornAt);
    final profile = StyleProfile(
      style: 'classic',
      colorsToAvoid: ['red'],
      regularOccasions: ['work'],
    );
    expect(StyleProfile.fromMap(profile.toMap()).colorsToAvoid, ['red']);
  });

  test('fake closet streams saves and deletes without Firebase', () async {
    final repo = FakeClosetRepository();
    final stream = repo.watchItems();
    final received = <List<ClothingItem>>[];
    final sub = stream.listen(received.add);
    await Future<void>.delayed(Duration.zero);
    await repo.saveItem(sampleCloset().first);
    await repo.deleteItem(sampleCloset().first.id);
    await Future<void>.delayed(Duration.zero);
    expect(received.map((items) => items.length), [0, 1, 0]);
    await sub.cancel();
    await repo.dispose();
  });

  test('closet completeness supports separates or a dress plus shoes', () {
    final items = sampleCloset();
    expect(OutfitRequest(closet: [], occasion: 'work').missingCategories, [
      'shoes',
      'top',
      'bottom',
    ]);
    expect(
      OutfitRequest(
        closet: items.where((i) => i.tags.category != 'dress').toList(),
        occasion: 'work',
      ).missingCategories,
      isEmpty,
    );
    expect(
      OutfitRequest(
        closet: items
            .where((i) => ['dress', 'shoes'].contains(i.tags.category))
            .toList(),
        occasion: 'work',
      ).missingCategories,
      isEmpty,
    );
    expect(
      OutfitRequest(
        closet: items.map((i) => i.copyWith(inLaundry: true)).toList(),
        occasion: 'work',
      ).missingCategories,
      contains('shoes'),
    );
  });

  for (final count in [1, 2, 3]) {
    test(
      'fake AI returns $count outfits with actual closet IDs and preserves request',
      () async {
        final ai = FakeAiService(outfitCount: count);
        final request = OutfitRequest(
          closet: sampleCloset(),
          occasion: 'work',
          note: 'raincoat',
          weather: const WeatherSummary(
            temperatureC: 12,
            rainChancePercent: 80,
          ),
        );
        final outfits = await ai.generateOutfits(request);
        expect(outfits.length, count);
        expect(ai.lastRequest, same(request));
        expect(
          outfits.first.itemIds.every(
            (id) => request.closet.any((i) => i.id == id),
          ),
          isTrue,
        );
      },
    );
  }
  test('fake tagging failure supports the manual entry UI', () async {
    await expectLater(
      FakeAiService(failTagging: true).tagClothing(Uint8List(1)),
      throwsA(isA<AiServiceException>()),
    );
  });
}
