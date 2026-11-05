import 'dart:io';

import 'package:fitcheck_ai/features/closet/closet_repository.dart';
import 'package:fitcheck_ai/features/closet/clothing_item.dart';
import 'package:fitcheck_ai/features/closet/sample_closet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class BrokenBundle extends CachingAssetBundle {
  BrokenBundle(this.failOn);

  final String failOn;

  @override
  Future<ByteData> load(String key) async {
    if (key == failOn) throw Exception('missing asset');
    return ByteData(4);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late InMemoryClosetRepository repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sample_closet');
    repository = InMemoryClosetRepository();
  });

  tearDown(() => directory.delete(recursive: true));

  test('the sample has enough of each type for the outfit flow', () {
    expect(sampleCloset.length, inInclusiveRange(15, 20));
    final categories = sampleCloset.map((sample) => sample.tags.category);
    for (final needed in ['Top', 'Bottom', 'Shoes']) {
      expect(categories, contains(needed));
    }
    expect(clothingCategories, containsAll(categories.toSet()));
    expect(
      sampleCloset.map((sample) => sample.imageName).toSet(),
      hasLength(sampleCloset.length),
    );
  });

  test('load copies every bundled photo and adds its written tags', () async {
    final loader = SampleClosetLoader(
      repository: repository,
      photosDirectory: () async => directory,
    );

    await loader.load();

    expect(repository.items, hasLength(sampleCloset.length));
    for (final sample in sampleCloset) {
      final item = repository.items.singleWhere(
        (item) => item.id.endsWith(sample.imageName),
      );
      expect(item.tags, same(sample.tags));
      expect(item.photoPath, startsWith('${directory.path}/closet_photos/'));
      final bundled = await rootBundle.load(sample.assetPath);
      expect(await File(item.photoPath).length(), bundled.lengthInBytes);
    }
  });

  test('a failed load adds nothing and leaves no files behind', () async {
    final loader = SampleClosetLoader(
      repository: repository,
      bundle: BrokenBundle(sampleCloset.last.assetPath),
      photosDirectory: () async => directory,
    );

    await expectLater(loader.load(), throwsException);

    expect(repository.items, isEmpty);
    final leftovers = Directory('${directory.path}/closet_photos').listSync();
    expect(leftovers, isEmpty);
  });
}
