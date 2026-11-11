import 'dart:async';
import 'dart:io';

import 'package:fitcheck_ai/app/age_confirmation.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/features/settings/my_data_deleter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/app_test_helpers.dart';

/// A closet whose deletes never finish, like Firestore while offline, or are
/// rejected.
class StuckClosetRepository extends FakeClosetRepository {
  StuckClosetRepository({super.items, this.reject = false});

  final bool reject;

  @override
  Future<void> deleteItem(String id) => reject
      ? Future.error(Exception('permission denied'))
      : Completer<void>().future;
}

ClothingItem item(String id, String photoPath) => ClothingItem(
  id: id,
  photoPath: photoPath,
  tags: const ClothingTags(
    category: 'top',
    color: 'blue',
    pattern: 'solid',
    formality: 'casual',
    season: 'summer',
  ),
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  late Directory documents;

  setUp(() async {
    mockSavedSettings(ageConfirmed: true);
    documents = await Directory.systemTemp.createTemp('fitcheck_delete_test');
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  Future<File> photo(String folder, String name) async {
    final file = File('${documents.path}/$folder/$name');
    await file.create(recursive: true);
    await file.writeAsBytes([1, 2, 3]);
    return file;
  }

  test('removes Firestore data, saved photos, and the 18+ answer', () async {
    final closetPhoto = await photo('closet_photos', 'shirt.jpg');
    final fitCheckPhoto = await photo('fit_check_photos', 'outfit.jpg');
    final services = BackendServices(
      closet: FakeClosetRepository(items: [item('shirt', closetPhoto.path)]),
      outfits: FakeOutfitRepository(),
      profile: FakeProfileRepository(),
      wearLogs: FakeWearLogRepository(),
      ai: FakeAiService(),
    );
    await services.outfits.saveOutfit(
      Outfit(
        id: 'outfit-1',
        itemIds: const ['shirt'],
        reason: 'Works for class.',
        occasion: 'Class',
        createdAt: DateTime(2026, 11, 2),
      ),
    );
    await services.profile.saveProfile(
      StyleProfile(style: 'minimal', colorsToAvoid: const ['orange']),
    );

    await MyDataDeleter(
      services: services,
      photosDirectory: () async => documents,
    ).deleteAll();

    expect(await services.closet.getItems(), isEmpty);
    expect(await services.outfits.watchOutfits().first, isEmpty);
    final profile = await services.profile.getProfile();
    expect(profile.style, isEmpty);
    expect(profile.colorsToAvoid, isEmpty);
    expect(await closetPhoto.exists(), isFalse);
    expect(await fitCheckPhoto.exists(), isFalse);
    expect(await const AgeConfirmation().isConfirmed(), isFalse);
  });

  test('offline deletes stay queued instead of blocking forever', () async {
    final services = BackendServices.fake();
    final stuck = BackendServices(
      closet: StuckClosetRepository(items: [item('shirt', '/gone.jpg')]),
      outfits: services.outfits,
      profile: services.profile,
      wearLogs: services.wearLogs,
      ai: services.ai,
    );

    await MyDataDeleter(
      services: stuck,
      photosDirectory: () async => documents,
      firestoreWait: const Duration(milliseconds: 50),
    ).deleteAll();

    expect(await const AgeConfirmation().isConfirmed(), isFalse);
  });

  test('a rejected delete is reported and keeps the 18+ answer', () async {
    final services = BackendServices.fake();
    final rejecting = BackendServices(
      closet: StuckClosetRepository(
        items: [item('shirt', '/gone.jpg')],
        reject: true,
      ),
      outfits: services.outfits,
      profile: services.profile,
      wearLogs: services.wearLogs,
      ai: services.ai,
    );

    await expectLater(
      MyDataDeleter(
        services: rejecting,
        photosDirectory: () async => documents,
      ).deleteAll(),
      throwsA(isA<Exception>()),
    );
    expect(await const AgeConfirmation().isConfirmed(), isTrue);
  });
}
