/// Shared, Firebase-independent contracts for the closet and outfit screens.
class ClothingTags {
  const ClothingTags({
    required this.category,
    required this.color,
    required this.pattern,
    required this.formality,
    required this.season,
  });

  static const categories = [
    'top',
    'bottom',
    'dress',
    'shoes',
    'outerwear',
    'accessory',
  ];
  final String category;
  final String color;
  final String pattern;
  final String formality;
  final String season;

  Map<String, dynamic> toMap() => {
    'category': category,
    'color': color,
    'pattern': pattern,
    'formality': formality,
    'season': season,
  };

  /// Throws a [FormatException] if a tag is missing or not text.
  factory ClothingTags.fromMap(Map<String, dynamic> map) => ClothingTags(
    category: _required<String>(map, 'category'),
    color: _required<String>(map, 'color'),
    pattern: _required<String>(map, 'pattern'),
    formality: _required<String>(map, 'formality'),
    season: _required<String>(map, 'season'),
  );
}

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.photoPath,
    required this.tags,
    required this.createdAt,
    this.isSample = false,
    this.inLaundry = false,
  });
  final String id;

  /// A path on this device or an asset path; image bytes never enter Firestore.
  final String photoPath;
  final ClothingTags tags;
  final DateTime createdAt;
  final bool isSample;
  final bool inLaundry;

  ClothingItem copyWith({
    String? photoPath,
    ClothingTags? tags,
    bool? inLaundry,
  }) => ClothingItem(
    id: id,
    photoPath: photoPath ?? this.photoPath,
    tags: tags ?? this.tags,
    createdAt: createdAt,
    isSample: isSample,
    inLaundry: inLaundry ?? this.inLaundry,
  );

  Map<String, dynamic> toMap() => {
    'photoPath': photoPath,
    'tags': tags.toMap(),
    'createdAt': createdAt.toUtc().toIso8601String(),
    'isSample': isSample,
    'inLaundry': inLaundry,
  };

  /// Throws a [FormatException] if the stored document is malformed.
  factory ClothingItem.fromMap(String id, Map<String, dynamic> map) =>
      ClothingItem(
        id: id,
        photoPath: _required<String>(map, 'photoPath'),
        tags: ClothingTags.fromMap(_map(map, 'tags')),
        createdAt: _date(map, 'createdAt'),
        isSample: _optional<bool>(map, 'isSample') ?? false,
        inLaundry: _optional<bool>(map, 'inLaundry') ?? false,
      );
}

class Outfit {
  Outfit({
    required this.id,
    required List<String> itemIds,
    required this.reason,
    required this.occasion,
    required this.createdAt,
  }) : itemIds = List.unmodifiable(itemIds);
  final String id;
  final List<String> itemIds;
  final String reason;
  final String occasion;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => {
    'itemIds': itemIds,
    'reason': reason,
    'occasion': occasion,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  /// Throws a [FormatException] if the stored document is malformed.
  factory Outfit.fromMap(String id, Map<String, dynamic> map) => Outfit(
    id: id,
    itemIds: _stringList(map, 'itemIds'),
    reason: _required<String>(map, 'reason'),
    occasion: _required<String>(map, 'occasion'),
    createdAt: _date(map, 'createdAt'),
  );
}

class WearLog {
  WearLog({
    required this.id,
    required this.outfitId,
    required List<String> itemIds,
    required this.wornAt,
  }) : itemIds = List.unmodifiable(itemIds);
  final String id;
  final String outfitId;
  final List<String> itemIds;
  final DateTime wornAt;
  Map<String, dynamic> toMap() => {
    'outfitId': outfitId,
    'itemIds': itemIds,
    'wornAt': wornAt.toUtc().toIso8601String(),
  };

  /// Throws a [FormatException] if the stored document is malformed.
  factory WearLog.fromMap(String id, Map<String, dynamic> map) => WearLog(
    id: id,
    outfitId: _required<String>(map, 'outfitId'),
    itemIds: _stringList(map, 'itemIds'),
    wornAt: _date(map, 'wornAt'),
  );
}

class StyleProfile {
  StyleProfile({
    this.style = '',
    List<String> colorsToAvoid = const [],
    List<String> regularOccasions = const [],
  }) : colorsToAvoid = List.unmodifiable(colorsToAvoid),
       regularOccasions = List.unmodifiable(regularOccasions);
  final String style;
  final List<String> colorsToAvoid;
  final List<String> regularOccasions;
  Map<String, dynamic> toMap() => {
    'style': style,
    'colorsToAvoid': colorsToAvoid,
    'regularOccasions': regularOccasions,
  };

  /// Every field is optional. Throws a [FormatException] if one has the wrong
  /// type.
  factory StyleProfile.fromMap(Map<String, dynamic> map) => StyleProfile(
    style: _optional<String>(map, 'style') ?? '',
    colorsToAvoid: map.containsKey('colorsToAvoid')
        ? _stringList(map, 'colorsToAvoid')
        : const [],
    regularOccasions: map.containsKey('regularOccasions')
        ? _stringList(map, 'regularOccasions')
        : const [],
  );
}

class WeatherSummary {
  const WeatherSummary({
    required this.temperatureC,
    required this.rainChancePercent,
    this.locationLabel = '',
  });
  final double temperatureC;
  final int rainChancePercent;
  final String locationLabel;
  Map<String, dynamic> toMap() => {
    'temperatureC': temperatureC,
    'rainChancePercent': rainChancePercent,
    'locationLabel': locationLabel,
  };
}

class OutfitRequest {
  OutfitRequest({
    required List<ClothingItem> closet,
    required this.occasion,
    this.note = '',
    this.weather,
  }) : closet = List.unmodifiable(closet);
  final List<ClothingItem> closet;
  final String occasion;
  final String note;
  final WeatherSummary? weather;

  List<String> get missingCategories {
    final categories = closet
        .where((i) => !i.inLaundry)
        .map((i) => i.tags.category)
        .toSet();
    return [
      if (!categories.contains('shoes')) 'shoes',
      if (!categories.contains('dress')) ...[
        if (!categories.contains('top')) 'top',
        if (!categories.contains('bottom')) 'bottom',
      ],
    ];
  }
}

// Readers for stored documents. Each throws a FormatException naming the
// field, so callers can catch one exception type for any malformed document.

T? _optional<T extends Object>(Map<String, dynamic> map, String key) =>
    switch (map[key]) {
      null => null,
      final T value => value,
      final other => throw FormatException(
        'Expected "$key" to be a $T, got ${other.runtimeType}.',
      ),
    };

T _required<T extends Object>(Map<String, dynamic> map, String key) =>
    _optional<T>(map, key) ??
    (throw FormatException('Missing required field "$key".'));

Map<String, dynamic> _map(Map<String, dynamic> map, String key) {
  final stored = _required<Map<Object?, Object?>>(map, key);
  final result = <String, dynamic>{};
  for (final MapEntry(key: name, :value) in stored.entries) {
    if (name is! String) {
      throw FormatException('Expected "$key" to have only text keys.');
    }
    result[name] = value;
  }
  return result;
}

List<String> _stringList(Map<String, dynamic> map, String key) {
  final values = _required<List<Object?>>(map, key);
  return [
    for (final value in values)
      if (value is String)
        value
      else
        throw FormatException('Expected "$key" to contain only text.'),
  ];
}

DateTime _date(Map<String, dynamic> map, String key) {
  final text = _required<String>(map, key);
  return DateTime.tryParse(text) ??
      (throw FormatException('Expected "$key" to be an ISO 8601 date.', text));
}
