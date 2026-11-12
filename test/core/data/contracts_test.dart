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

  group('malformed stored documents throw FormatException', () {
    final valid = sampleCloset().first.toMap();
    final cases = <String, Map<String, dynamic>>{
      'missing tags': {...valid}..remove('tags'),
      'photo path is a number': {...valid, 'photoPath': 42},
      'tags are not a map': {...valid, 'tags': 'blue top'},
      'a tag is missing': {
        ...valid,
        'tags': {...valid['tags'] as Map<String, dynamic>}..remove('color'),
      },
      'date is not ISO 8601': {...valid, 'createdAt': 'yesterday'},
      'laundry flag is text': {...valid, 'inLaundry': 'yes'},
    };
    for (final MapEntry(key: name, value: map) in cases.entries) {
      test('closet item: $name', () {
        expect(
          () => ClothingItem.fromMap('bad', map),
          throwsA(isA<FormatException>()),
        );
      });
    }

    test('outfit item IDs must all be text', () {
      expect(
        () => Outfit.fromMap('bad', {
          'itemIds': ['top', 7],
          'reason': 'Coordinated.',
          'occasion': 'work',
          'createdAt': '2026-01-01T00:00:00.000Z',
        }),
        throwsA(isA<FormatException>()),
      );
    });

    test('style profile tolerates missing fields but not wrong types', () {
      expect(StyleProfile.fromMap({}).colorsToAvoid, isEmpty);
      expect(
        () => StyleProfile.fromMap({'colorsToAvoid': 'red'}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  test('optional closet flags default to false when absent', () {
    final map = sampleCloset().first.toMap()
      ..remove('isSample')
      ..remove('inLaundry');
    final item = ClothingItem.fromMap('item', map);
    expect(item.isSample, isFalse);
    expect(item.inLaundry, isFalse);
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
