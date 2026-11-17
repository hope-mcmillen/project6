import '../../core/data/models.dart';

/// How often and how recently one closet item was worn.
class ItemWear {
  const ItemWear({this.count = 0, this.lastWorn});

  final int count;

  /// In local time, or null if the item has never been worn.
  final DateTime? lastWorn;
}

/// Wear counts per item, built from the user's wear logs. A log that names an
/// item twice still counts as one wear of it.
class WearStats {
  WearStats(Iterable<WearLog> logs) {
    for (final log in logs) {
      final wornAt = log.wornAt.toLocal();
      for (final id in log.itemIds.toSet()) {
        final current = _byItem[id] ?? const ItemWear();
        final last = current.lastWorn;
        _byItem[id] = ItemWear(
          count: current.count + 1,
          lastWorn: last == null || wornAt.isAfter(last) ? wornAt : last,
        );
      }
    }
  }

  /// Items count as not worn lately after this many days.
  static const staleDays = 30;

  final Map<String, ItemWear> _byItem = {};

  ItemWear forItem(String itemId) => _byItem[itemId] ?? const ItemWear();

  bool wornOn(String itemId, DateTime day) {
    final last = forItem(itemId).lastWorn;
    return last != null && _sameDay(last, day.toLocal());
  }

  /// True when [item] has gone [staleDays] without being worn. An item added
  /// more recently than that is not flagged, even if it was never worn.
  bool notWornLately(ClothingItem item, DateTime now) {
    final cutoff = now.subtract(const Duration(days: staleDays));
    final since = forItem(item.id).lastWorn ?? item.createdAt;
    return !since.isAfter(cutoff);
  }
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Short text for when an item was last worn, such as "Today" or "12 days ago".
String lastWornLabel(DateTime? lastWorn, DateTime now) {
  if (lastWorn == null) return 'Never';
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(lastWorn.year, lastWorn.month, lastWorn.day);
  // Rounded, because a daylight saving change makes a day 23 or 25 hours.
  final days = (today.difference(day).inHours / 24).round();
  if (days <= 0) return 'Today';
  if (days == 1) return 'Yesterday';
  return '$days days ago';
}

String timesWornLabel(int count) => switch (count) {
  0 => 'Not worn yet',
  1 => 'Once',
  _ => '$count times',
};
