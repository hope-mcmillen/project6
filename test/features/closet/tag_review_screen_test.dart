import 'dart:io';
import 'dart:typed_data';

import 'package:fitcheck_ai/core/ai/ai_service.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/features/closet/tag_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'closet_test_helpers.dart';

class StubAi implements AiService {
  StubAi(this.onTag);

  final Future<ClothingTags> Function() onTag;
  Uint8List? lastPhoto;

  @override
  Future<ClothingTags> tagClothing(Uint8List photoBytes) {
    lastPhoto = photoBytes;
    return onTag();
  }

  @override
  Future<List<Outfit>> generateOutfits(OutfitRequest request) =>
      throw UnimplementedError();
}

const suggestedTags = ClothingTags(
  category: 'top',
  color: 'blue',
  pattern: 'solid',
  formality: 'casual',
  season: 'all year',
);

final photoBytes = Uint8List.fromList([1, 2, 3]);

void main() {
  late TestClosetRepository repository;
  late List<String> deletedPhotos;

  setUp(() {
    repository = TestClosetRepository();
    deletedPhotos = [];
  });

  Future<void> openScreen(
    WidgetTester tester,
    AiService ai, {
    ReadPhoto? readPhoto,
    VoidCallback? onSaved,
  }) {
    return pumpClosetScreen(
      tester,
      TagReviewScreen(
        photoPath: '/photos/shirt.jpg',
        repository: repository,
        ai: ai,
        readPhoto: readPhoto ?? (_) async => photoBytes,
        deletePhoto: (path) async => deletedPhotos.add(path),
        onSaved: onSaved,
      ),
    );
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  Future<void> chooseCategory(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('sends the photo to the AI and fills in its tags', (
    tester,
  ) async {
    final ai = StubAi(
      () => Future.delayed(const Duration(seconds: 1), () => suggestedTags),
    );
    await openScreen(tester, ai);
    await tester.pump();

    expect(find.text('Suggesting tags...'), findsOneWidget);
    expect(find.text('Save to closet'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(ai.lastPhoto, photoBytes);
    expect(find.text('Top'), findsOneWidget);
    expect(find.text('blue'), findsOneWidget);
    expect(find.text('solid'), findsOneWidget);
    expect(find.text('casual'), findsOneWidget);
    expect(find.text('all year'), findsOneWidget);
  });

  testWidgets('saves the values the user changed', (tester) async {
    var savedCalls = 0;
    await openScreen(
      tester,
      StubAi(() async => suggestedTags),
      onSaved: () => savedCalls++,
    );
    await tester.pumpAndSettle();

    await tester.enterText(field('Color'), 'Green ');
    await tester.enterText(field('Pattern'), 'Striped');
    await chooseCategory(tester, 'Outerwear');
    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    final saved = repository.items.single;
    expect(saved.photoPath, '/photos/shirt.jpg');
    expect(saved.tags.category, 'outerwear');
    expect(saved.tags.color, 'Green');
    expect(saved.tags.pattern, 'Striped');
    expect(saved.tags.formality, 'casual');
    expect(saved.tags.season, 'all year');
    expect(saved.isSample, isFalse);
    expect(savedCalls, 1);
    expect(find.text('Added to your closet'), findsOneWidget);
  });

  testWidgets('an AI failure shows its message and opens manual entry', (
    tester,
  ) async {
    await openScreen(tester, FakeAiService(failTagging: true));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tags unavailable.'), findsOneWidget);
    expect(find.text('blue'), findsNothing);

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a category'), findsOneWidget);
    expect(repository.items, isEmpty);

    await chooseCategory(tester, 'Shoes');
    await tester.enterText(field('Color'), 'Black');
    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    final saved = repository.items.single;
    expect(saved.tags.category, 'shoes');
    expect(saved.tags.color, 'Black');
  });

  testWidgets('an unreadable photo also opens manual entry', (tester) async {
    await openScreen(
      tester,
      StubAi(() async => suggestedTags),
      readPhoto: (_) async => throw const FileSystemException('gone'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('could not suggest tags'), findsOneWidget);
    expect(find.text('Save to closet'), findsOneWidget);
  });

  testWidgets('an unknown suggested category must be chosen by hand', (
    tester,
  ) async {
    await openScreen(
      tester,
      StubAi(
        () async => const ClothingTags(
          category: 'spaceship',
          color: '',
          pattern: '',
          formality: '',
          season: '',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);
    expect(repository.items, isEmpty);
  });

  testWidgets('a rejected save tells the user', (tester) async {
    repository.failWrites = true;
    await openScreen(tester, StubAi(() async => suggestedTags));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    expect(find.text('Could not save that item. Try again.'), findsOneWidget);
  });

  testWidgets('without injected services it uses the app backend', (
    tester,
  ) async {
    final closet = FakeClosetRepository();
    final ai = FakeAiService();
    await pumpClosetScreen(
      tester,
      TagReviewScreen(
        photoPath: '/photos/shirt.jpg',
        readPhoto: (_) async => photoBytes,
      ),
      services: BackendServices(
        closet: closet,
        outfits: FakeOutfitRepository(),
        profile: FakeProfileRepository(),
        wearLogs: FakeWearLogRepository(),
        ai: ai,
      ),
    );
    await tester.pumpAndSettle();
    expect(ai.taggingCalls, 1);

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    final items = await tester.runAsync(closet.getItems);
    expect(items!.single.tags.category, 'top');
  });

  testWidgets('saving keeps the photo', (tester) async {
    await openScreen(tester, StubAi(() async => suggestedTags));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());

    expect(repository.items, hasLength(1));
    expect(deletedPhotos, isEmpty);
  });

  testWidgets('backing out without saving deletes the copied photo', (
    tester,
  ) async {
    await pumpClosetScreen(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TagReviewScreen(
                photoPath: '/photos/shirt.jpg',
                repository: repository,
                ai: StubAi(() async => suggestedTags),
                readPhoto: (_) async => photoBytes,
                deletePhoto: (path) async => deletedPhotos.add(path),
              ),
            ),
          ),
          child: const Text('Open'),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(deletedPhotos, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(repository.items, isEmpty);
    expect(deletedPhotos, ['/photos/shirt.jpg']);
  });

  testWidgets('a rejected save also deletes the photo', (tester) async {
    repository.failWrites = true;
    await openScreen(tester, StubAi(() async => suggestedTags));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    expect(deletedPhotos, ['/photos/shirt.jpg']);
  });
}
