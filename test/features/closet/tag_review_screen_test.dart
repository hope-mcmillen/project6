import 'package:fitcheck_ai/features/closet/closet_repository.dart';
import 'package:fitcheck_ai/features/closet/clothing_item.dart';
import 'package:fitcheck_ai/features/closet/clothing_tagger.dart';
import 'package:fitcheck_ai/features/closet/tag_review_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class StubTagger implements ClothingTagger {
  StubTagger(this.onSuggest);

  final Future<ClothingTags> Function() onSuggest;

  @override
  Future<ClothingTags> suggestTags(String photoPath) => onSuggest();
}

const suggestedTags = ClothingTags(
  category: 'Top',
  color: 'Blue',
  pattern: 'Solid',
  formality: 'Casual',
  season: 'All year',
);

void main() {
  late InMemoryClosetRepository repository;

  setUp(() => repository = InMemoryClosetRepository());

  Future<void> openScreen(WidgetTester tester, ClothingTagger tagger) async {
    tester.view.physicalSize = const Size(600, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: TagReviewScreen(
          photoPath: '/photos/shirt.jpg',
          repository: repository,
          tagger: tagger,
        ),
      ),
    );
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  testWidgets('shows loading, then fills in the suggested tags', (
    tester,
  ) async {
    await openScreen(
      tester,
      StubTagger(
        () => Future.delayed(const Duration(seconds: 1), () => suggestedTags),
      ),
    );
    await tester.pump();

    expect(find.text('Suggesting tags...'), findsOneWidget);
    expect(find.text('Save to closet'), findsNothing);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Solid'), findsOneWidget);
    expect(find.text('Casual'), findsOneWidget);
    expect(find.text('All year'), findsOneWidget);
  });

  testWidgets('saves the values the user changed', (tester) async {
    await openScreen(tester, StubTagger(() async => suggestedTags));
    await tester.pumpAndSettle();

    await tester.enterText(field('Color'), 'Green');
    await tester.enterText(field('Pattern'), 'Striped');
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Outerwear').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    final saved = repository.items.single;
    expect(saved.photoPath, '/photos/shirt.jpg');
    expect(saved.tags.category, 'Outerwear');
    expect(saved.tags.color, 'Green');
    expect(saved.tags.pattern, 'Striped');
    expect(saved.tags.formality, 'Casual');
    expect(saved.tags.season, 'All year');
    expect(find.text('Added to your closet'), findsOneWidget);
  });

  testWidgets('a failed suggestion opens empty fields to fill in', (
    tester,
  ) async {
    await openScreen(tester, StubTagger(() async => throw Exception('down')));
    await tester.pumpAndSettle();

    expect(find.textContaining('could not suggest tags'), findsOneWidget);
    expect(find.text('Blue'), findsNothing);

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a category'), findsOneWidget);
    expect(repository.items, isEmpty);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Shoes').last);
    await tester.pumpAndSettle();
    await tester.enterText(field('Color'), 'Black');
    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    final saved = repository.items.single;
    expect(saved.tags.category, 'Shoes');
    expect(saved.tags.color, 'Black');
    expect(saved.name, 'Black Shoes');
  });

  testWidgets('an unknown suggested category must be chosen by hand', (
    tester,
  ) async {
    await openScreen(
      tester,
      StubTagger(() async => const ClothingTags(category: 'Spaceship')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save to closet'));
    await tester.pumpAndSettle();

    expect(find.text('Choose a category'), findsOneWidget);
    expect(repository.items, isEmpty);
  });
}
