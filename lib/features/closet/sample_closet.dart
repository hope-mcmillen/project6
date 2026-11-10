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
/// call is needed, and clears them out again. Settings can reuse this for its
/// sample closet options.
class SampleClosetLoader {
  SampleClosetLoader({
    required this.repository,
    AssetBundle? bundle,
    PhotosDirectory? photosDirectory,
    DeletePhoto? deletePhoto,
  }) : _bundle = bundle ?? rootBundle,
       _photosDirectory = photosDirectory ?? getApplicationDocumentsDirectory,
       _deletePhoto = deletePhoto ?? deleteClosetPhoto;

  final ClosetRepository repository;
  final AssetBundle _bundle;
  final PhotosDirectory _photosDirectory;
  final DeletePhoto _deletePhoto;

  /// Deletes every item marked `isSample`, and each one's photo once its
  /// delete is confirmed. The user's own items stay. Returns how many sample
  /// items were removed.
  ///
  /// The items leave the closet right away, but offline the returned future
  /// waits until the phone reconnects, so screens should not wait on it.
  Future<int> clear() async {
    // The first closet snapshot comes from the phone's cache when offline,
    // where a one-time server read would stall.
    final items = await repository.watchItems().first;
    final samples = [
      for (final item in items)
        if (item.isSample) item,
    ];
    await Future.wait([for (final item in samples) _clearItem(item)]);
    return samples.length;
  }

  Future<void> _clearItem(ClothingItem item) async {
    await repository.deleteItem(item.id);
    try {
      await _deletePhoto(item.photoPath);
    } on FileSystemException {
      // The item is already gone, so a leftover file is not worth failing for.
    }
  }

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
