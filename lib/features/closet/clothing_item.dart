/// The clothing types the closet and outfit checks understand.
const clothingCategories = [
  'Top',
  'Bottom',
  'Dress',
  'Shoes',
  'Outerwear',
  'Accessory',
];

class ClothingTags {
  const ClothingTags({
    required this.category,
    this.color = '',
    this.pattern = '',
    this.formality = '',
    this.season = '',
  });

  final String category;
  final String color;
  final String pattern;
  final String formality;
  final String season;
}

class ClothingItem {
  const ClothingItem({
    required this.id,
    required this.photoPath,
    required this.tags,
  });

  final String id;
  final String photoPath;
  final ClothingTags tags;

  String get name => '${tags.color} ${tags.category}'.trim();
}
