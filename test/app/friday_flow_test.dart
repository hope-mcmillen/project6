import 'dart:io';

import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/features/closet/add_item_screen.dart';
import 'package:fitcheck_ai/features/closet/closet_photo_picker.dart';
import 'package:fitcheck_ai/features/closet/tag_review_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'app_test_helpers.dart';

/// Returns a photo already on disk instead of opening the camera.
class FakePhotoPicker extends ClosetPhotoPicker {
  FakePhotoPicker(this.photoPath);

  final String photoPath;

  @override
  Future<String?> pickAndSave(ImageSource source) async => photoPath;
}

ClothingItem existing(String id, String category) => ClothingItem(
  id: id,
  photoPath: '/photos/$id.jpg',
  tags: ClothingTags(
    category: category,
    color: 'black',
    pattern: 'solid',
    formality: 'casual',
    season: 'all year',
  ),
  createdAt: DateTime(2026, 11, 1),
);

/// The Friday MVP flow on fakes: add a clothing photo, get AI tags, save the
/// item, and get an outfit that uses it. CI runs this with every test, so a
/// merge that breaks any step fails the build.
void main() {
  testWidgets('add a photo, review AI tags, save, and get an outfit', (
    tester,
  ) async {
    // The closet already has a bottom and shoes; the new photo is the top.
    final closet = FakeClosetRepository(
      items: [existing('jeans', 'bottom'), existing('sneakers', 'shoes')],
    );
    final ai = FakeAiService();
    final services = BackendServices(
      closet: closet,
      outfits: FakeOutfitRepository(),
      profile: FakeProfileRepository(),
      wearLogs: FakeWearLogRepository(),
      ai: ai,
    );
    final photo = (await tester.runAsync(() async {
      final folder = await Directory.systemTemp.createTemp('friday_flow');
      final file = File('${folder.path}/shirt.jpg');
      await file.writeAsBytes([1, 2, 3]);
      return file;
    }))!;
    addTearDown(() => photo.parent.deleteSync(recursive: true));

    // 1. Add a clothing photo.
    await pumpWithAppServices(
      tester,
      AddItemScreen(photoPicker: FakePhotoPicker(photo.path)),
      services: services,
    );
    await tester.tap(find.text('Take photo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    // Let the real file read and AI tagging finish.
    for (
      var i = 0;
      i < 40 && find.text('Suggesting tags...').evaluate().isNotEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    // 2. Review the AI tags.
    expect(find.byType(TagReviewScreen), findsOneWidget);
    expect(ai.taggingCalls, 1);
    expect(find.text('Suggesting tags...'), findsNothing);
    expect(find.text('blue'), findsOneWidget);

    // 3. Save to the closet.
    await tester.ensureVisible(find.text('Save to closet'));
    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    expect(find.byType(TagReviewScreen), findsNothing);
    final items = await closet.getItems();
    expect(items, hasLength(3));
    final shirt = items.singleWhere((item) => item.tags.category == 'top');
    expect(shirt.photoPath, photo.path);
    expect(shirt.tags.color, 'blue');

    // 4. Request an outfit. Member 2's request and results screens call this
    // same shared AiService; switch this step to tapping through them once
    // M2-01 and M2-02 are merged.
    final request = OutfitRequest(closet: items, occasion: 'Class');
    expect(request.missingCategories, isEmpty);
    final outfits = await ai.generateOutfits(request);

    // 5. The results use the item that was just added.
    expect(outfits, isNotEmpty);
    expect(outfits.length, lessThanOrEqualTo(3));
    expect(outfits.first.itemIds, containsAll(['jeans', 'sneakers', shirt.id]));
    expect(outfits.first.reason, isNotEmpty);
  });
}
