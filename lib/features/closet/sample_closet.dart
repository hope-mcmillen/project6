import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'closet_photo_picker.dart';
import 'closet_repository.dart';
import 'clothing_item.dart';

class SampleClothing {
  const SampleClothing(this.imageName, this.tags);

  final String imageName;
  final ClothingTags tags;

  String get assetPath => 'assets/sample_closet/$imageName.png';
}

const sampleCloset = [
  SampleClothing(
    'blue_tee',
    ClothingTags(
      category: 'Top',
      color: 'Blue',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Summer',
    ),
  ),
  SampleClothing(
    'white_tee',
    ClothingTags(
      category: 'Top',
      color: 'White',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'All year',
    ),
  ),
  SampleClothing(
    'navy_striped_tee',
    ClothingTags(
      category: 'Top',
      color: 'Navy',
      pattern: 'Striped',
      formality: 'Casual',
      season: 'Spring',
    ),
  ),
  SampleClothing(
    'red_tee',
    ClothingTags(
      category: 'Top',
      color: 'Red',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Summer',
    ),
  ),
  SampleClothing(
    'light_blue_shirt',
    ClothingTags(
      category: 'Top',
      color: 'Light blue',
      pattern: 'Solid',
      formality: 'Business casual',
      season: 'All year',
    ),
  ),
  SampleClothing(
    'gray_hoodie',
    ClothingTags(
      category: 'Top',
      color: 'Gray',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Fall',
    ),
  ),
  SampleClothing(
    'black_jeans',
    ClothingTags(
      category: 'Bottom',
      color: 'Black',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'All year',
    ),
  ),
  SampleClothing(
    'blue_jeans',
    ClothingTags(
      category: 'Bottom',
      color: 'Blue',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'All year',
    ),
  ),
  SampleClothing(
    'khaki_chinos',
    ClothingTags(
      category: 'Bottom',
      color: 'Khaki',
      pattern: 'Solid',
      formality: 'Business casual',
      season: 'All year',
    ),
  ),
  SampleClothing(
    'gray_dress_pants',
    ClothingTags(
      category: 'Bottom',
      color: 'Gray',
      pattern: 'Solid',
      formality: 'Formal',
      season: 'All year',
    ),
  ),
  SampleClothing(
    'navy_shorts',
    ClothingTags(
      category: 'Bottom',
      color: 'Navy',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Summer',
    ),
  ),
  SampleClothing(
    'green_dress',
    ClothingTags(
      category: 'Dress',
      color: 'Green',
      pattern: 'Solid',
      formality: 'Business casual',
      season: 'Spring',
    ),
  ),
  SampleClothing(
    'black_jacket',
    ClothingTags(
      category: 'Outerwear',
      color: 'Black',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Fall',
    ),
  ),
  SampleClothing(
    'olive_jacket',
    ClothingTags(
      category: 'Outerwear',
      color: 'Olive',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Winter',
    ),
  ),
  SampleClothing(
    'white_sneakers',
    ClothingTags(
      category: 'Shoes',
      color: 'White',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'All year',
    ),
  ),
  SampleClothing(
    'red_sneakers',
    ClothingTags(
      category: 'Shoes',
      color: 'Red',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Summer',
    ),
  ),
  SampleClothing(
    'brown_boots',
    ClothingTags(
      category: 'Shoes',
      color: 'Brown',
      pattern: 'Solid',
      formality: 'Casual',
      season: 'Winter',
    ),
  ),
  SampleClothing(
    'black_dress_shoes',
    ClothingTags(
      category: 'Shoes',
      color: 'Black',
      pattern: 'Solid',
      formality: 'Formal',
      season: 'All year',
    ),
  ),
];

/// Fills the closet with [sampleCloset], using tags already written so no AI
/// call is needed. Settings can reuse this for its Load sample closet option.
class SampleClosetLoader {
  SampleClosetLoader({
    ClosetRepository? repository,
    AssetBundle? bundle,
    PhotosDirectory? photosDirectory,
  }) : _repository = repository ?? defaultClosetRepository,
       _bundle = bundle ?? rootBundle,
       _photosDirectory = photosDirectory ?? getApplicationDocumentsDirectory;

  final ClosetRepository _repository;
  final AssetBundle _bundle;
  final PhotosDirectory _photosDirectory;

  Future<void> load() async {
    final photosDirectory = await _photosDirectory();
    final closetPhotos = Directory('${photosDirectory.path}/closet_photos');
    await closetPhotos.create(recursive: true);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final saved = <File>[];
    try {
      for (final sample in sampleCloset) {
        final data = await _bundle.load(sample.assetPath);
        final file = File(
          '${closetPhotos.path}/sample_${stamp}_${sample.imageName}.png',
        );
        saved.add(file);
        await file.writeAsBytes(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
      }
    } on Exception {
      for (final file in saved) {
        await deleteClosetPhoto(file.path);
      }
      rethrow;
    }

    for (var i = 0; i < sampleCloset.length; i++) {
      await _repository.addItem(
        ClothingItem(
          id: 'sample_${stamp}_${sampleCloset[i].imageName}',
          photoPath: saved[i].path,
          tags: sampleCloset[i].tags,
        ),
      );
    }
  }
}
