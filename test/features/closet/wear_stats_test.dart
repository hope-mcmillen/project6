import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/features/closet/wear_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import 'closet_test_helpers.dart';

WearLog wore(List<String> itemIds, DateTime wornAt) => WearLog(
  id: '${wornAt.toIso8601String()}-$itemIds',
  outfitId: '',
  itemIds: itemIds,
  wornAt: wornAt,
);

void main() {
  final now = DateTime(2026, 11, 16, 12);

  group('WearStats', () {
    test('counts each wear and keeps the latest date', () {
      final stats = WearStats([
        wore(['shirt', 'jeans'], DateTime(2026, 11, 2)),
        wore(['shirt'], DateTime(2026, 11, 10)),
        wore(['shirt'], DateTime(2026, 11, 5)),
      ]);

      expect(stats.forItem('shirt').count, 3);
      expect(stats.forItem('shirt').lastWorn, DateTime(2026, 11, 10));
      expect(stats.forItem('jeans').count, 1);
    });

    test('reports an unknown item as never worn', () {
      final wear = WearStats([]).forItem('missing');

      expect(wear.count, 0);
      expect(wear.lastWorn, isNull);
    });

    test('counts an item listed twice in one log once', () {
      final stats = WearStats([
        wore(['shirt', 'shirt'], DateTime(2026, 11, 2)),
      ]);

      expect(stats.forItem('shirt').count, 1);
    });

    test('compares stored UTC times in local time', () {
      final localEvening = DateTime(2026, 11, 16, 21);
      final stats = WearStats([
        wore(['shirt'], localEvening.toUtc()),
      ]);

      expect(stats.wornOn('shirt', now), isTrue);
      expect(stats.wornOn('shirt', DateTime(2026, 11, 15)), isFalse);
    });

    test('flags items not worn in 30 days', () {
      final old = testItem('old', createdAt: DateTime(2026, 9, 1));
      final stats = WearStats([
        wore(['old'], DateTime(2026, 10, 1)),
      ]);

      expect(stats.notWornLately(old, now), isTrue);
    });

    test('does not flag an item worn recently', () {
      final worn = testItem('worn', createdAt: DateTime(2026, 9, 1));
      final stats = WearStats([
        wore(['worn'], DateTime(2026, 11, 1)),
      ]);

      expect(stats.notWornLately(worn, now), isFalse);
    });

    test('flags a never-worn item only once it is 30 days old', () {
      final stats = WearStats([]);
      final newItem = testItem('new', createdAt: DateTime(2026, 11, 1));
      final oldItem = testItem('old', createdAt: DateTime(2026, 10, 1));

      expect(stats.notWornLately(newItem, now), isFalse);
      expect(stats.notWornLately(oldItem, now), isTrue);
    });
  });

  group('labels', () {
    test('describe when an item was last worn', () {
      expect(lastWornLabel(null, now), 'Never');
      expect(lastWornLabel(DateTime(2026, 11, 16, 8), now), 'Today');
      expect(lastWornLabel(DateTime(2026, 11, 15, 23), now), 'Yesterday');
      expect(lastWornLabel(DateTime(2026, 11, 4), now), '12 days ago');
    });

    test('describe how often an item was worn', () {
      expect(timesWornLabel(0), 'Not worn yet');
      expect(timesWornLabel(1), 'Once');
      expect(timesWornLabel(4), '4 times');
    });
  });
}
