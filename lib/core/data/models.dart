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

  factory ClothingTags.fromMap(Map<String, dynamic> map) => ClothingTags(
    category: map['category'] as String,
    color: map['color'] as String,
    pattern: map['pattern'] as String,
    formality: map['formality'] as String,
    season: map['season'] as String,
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

  factory ClothingItem.fromMap(String id, Map<String, dynamic> map) =>
      ClothingItem(
        id: id,
        photoPath: map['photoPath'] as String,
        tags: ClothingTags.fromMap(
          Map<String, dynamic>.from(map['tags'] as Map),
        ),
        createdAt: DateTime.parse(map['createdAt'] as String),
        isSample: map['isSample'] as bool? ?? false,
        inLaundry: map['inLaundry'] as bool? ?? false,
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
  factory Outfit.fromMap(String id, Map<String, dynamic> map) => Outfit(
    id: id,
    itemIds: List<String>.from(map['itemIds'] as List),
    reason: map['reason'] as String,
    occasion: map['occasion'] as String,
    createdAt: DateTime.parse(map['createdAt'] as String),
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
  factory WearLog.fromMap(String id, Map<String, dynamic> map) => WearLog(
    id: id,
    outfitId: map['outfitId'] as String,
    itemIds: List<String>.from(map['itemIds'] as List),
    wornAt: DateTime.parse(map['wornAt'] as String),
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
  factory StyleProfile.fromMap(Map<String, dynamic> map) => StyleProfile(
    style: map['style'] as String? ?? '',
    colorsToAvoid: List<String>.from(map['colorsToAvoid'] as List? ?? []),
    regularOccasions: List<String>.from(map['regularOccasions'] as List? ?? []),
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
