import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/data/models.dart';
import '../../core/data/repositories.dart';
import 'closet_photo_picker.dart';

class SampleClothing {
  const SampleClothing(this.imageName, this.tags);

  final String imageName;
  final ClothingTags tags;

  String get assetPath => 'assets/sample_closet/$imageName.png';
}

/// Sample pieces with tags already written, so loading them needs no AI call.
const sampleClothes = [
  SampleClothing(
    'blue_tee',
    ClothingTags(
      category: 'top',
      color: 'blue',
      pattern: 'solid',
      formality: 'casual',
      season: 'summer',
    ),
  ),
  SampleClothing(
    'white_tee',
    ClothingTags(
      category: 'top',
      color: 'white',
      pattern: 'solid',
      formality: 'casual',
      season: 'all year',
    ),
  ),
  SampleClothing(
    'navy_striped_tee',
    ClothingTags(
      category: 'top',
      color: 'navy',
      pattern: 'striped',
      formality: 'casual',
      season: 'spring',
    ),
  ),
  SampleClothing(
    'red_tee',
    ClothingTags(
      category: 'top',
      color: 'red',
      pattern: 'solid',
      formality: 'casual',
      season: 'summer',
    ),
  ),
  SampleClothing(
    'light_blue_shirt',
    ClothingTags(
      category: 'top',
      color: 'light blue',
      pattern: 'solid',
      formality: 'business casual',
      season: 'all year',
    ),
  ),
  SampleClothing(
    'gray_hoodie',
    ClothingTags(
      category: 'top',
      color: 'gray',
      pattern: 'solid',
      formality: 'casual',
      season: 'fall',
    ),
  ),
  SampleClothing(
    'black_jeans',
    ClothingTags(
      category: 'bottom',
      color: 'black',
      pattern: 'solid',
      formality: 'casual',
      season: 'all year',
    ),
  ),
  SampleClothing(
    'blue_jeans',
    ClothingTags(
      category: 'bottom',
      color: 'blue',
      pattern: 'solid',
      formality: 'casual',
      season: 'all year',
    ),
  ),
  SampleClothing(
    'khaki_chinos',
    ClothingTags(
      category: 'bottom',
      color: 'khaki',
      pattern: 'solid',
      formality: 'business casual',
      season: 'all year',
    ),
  ),
  SampleClothing(
    'gray_dress_pants',
    ClothingTags(
      category: 'bottom',
      color: 'gray',
      pattern: 'solid',
      formality: 'formal',
      season: 'all year',
    ),
  ),
  SampleClothing(
    'navy_shorts',
    ClothingTags(
      category: 'bottom',
      color: 'navy',
      pattern: 'solid',
      formality: 'casual',
      season: 'summer',
    ),
  ),
  SampleClothing(
    'green_dress',
    ClothingTags(
      category: 'dress',
      color: 'green',
      pattern: 'solid',
      formality: 'business casual',
      season: 'spring',
    ),
  ),
  SampleClothing(
    'black_jacket',
    ClothingTags(
      category: 'outerwear',
      color: 'black',
      pattern: 'solid',
      formality: 'casual',
      season: 'fall',
    ),
  ),
  SampleClothing(
    'olive_jacket',
    ClothingTags(
      category: 'outerwear',
      color: 'olive',
      pattern: 'solid',
      formality: 'casual',
      season: 'winter',
    ),
  ),
  SampleClothing(
    'white_sneakers',
    ClothingTags(
      category: 'shoes',
      color: 'white',
      pattern: 'solid',
      formality: 'casual',
      season: 'all year',
    ),
  ),
  SampleClothing(
    'red_sneakers',
    ClothingTags(
      category: 'shoes',
      color: 'red',
      pattern: 'solid',
      formality: 'casual',
      season: 'summer',
    ),
  ),
  SampleClothing(
    'brown_boots',
    ClothingTags(
      category: 'shoes',
      color: 'brown',
      pattern: 'solid',
      formality: 'casual',
      season: 'winter',
    ),
  ),
  SampleClothing(
    'black_dress_shoes',
    ClothingTags(
      category: 'shoes',
      color: 'black',
      pattern: 'solid',
      formality: 'formal',
      season: 'all year',
    ),
  ),
];

/// Fills the closet with [sampleClothes], using tags already written so no AI
/// call is needed. Settings can reuse this for its Load sample closet option.
class SampleClosetLoader {
  SampleClosetLoader({
    required this.repository,
    AssetBundle? bundle,
    PhotosDirectory? photosDirectory,
  }) : _bundle = bundle ?? rootBundle,
       _photosDirectory = photosDirectory ?? getApplicationDocumentsDirectory;

  final ClosetRepository repository;
  final AssetBundle _bundle;
  final PhotosDirectory _photosDirectory;

  Future<void> load() async {
    final photosDirectory = await _photosDirectory();
    final closetPhotos = Directory('${photosDirectory.path}/closet_photos');
    await closetPhotos.create(recursive: true);

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final saved = <File>[];
    try {
      for (final sample in sampleClothes) {
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

    final now = DateTime.now();
    await Future.wait([
      for (var i = 0; i < sampleClothes.length; i++)
        repository.saveItem(
          ClothingItem(
            id: 'sample_${stamp}_${sampleClothes[i].imageName}',
            photoPath: saved[i].path,
            tags: sampleClothes[i].tags,
            // Spaced out so the closet keeps the list's order, newest first.
            createdAt: now.subtract(Duration(seconds: i)),
            isSample: true,
          ),
        ),
    ]);
  }
}
