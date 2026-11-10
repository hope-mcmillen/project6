import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/features/closet/add_item_screen.dart';
import 'package:fitcheck_ai/features/closet/closet_photo.dart';
import 'package:fitcheck_ai/features/closet/closet_screen.dart';
import 'package:fitcheck_ai/features/closet/sample_closet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'closet_test_helpers.dart';

class StubSampleLoader extends SampleClosetLoader {
  StubSampleLoader(this.onLoad, {this.onClear})
    : super(repository: FakeClosetRepository());

  final Future<void> Function() onLoad;
  final Future<int> Function()? onClear;

  @override
  Future<void> load() => onLoad();

  @override
  Future<int> clear() => onClear!();
}

/// A closet whose first read fails, like a Firestore listener that is refused.
class FlakyClosetRepository extends TestClosetRepository {
  int watchCalls = 0;

  @override
  Stream<List<ClothingItem>> watchItems() {
    watchCalls++;
    if (watchCalls == 1) return Stream.error(Exception('listen refused'));
    return super.watchItems();
  }
}

ClothingItem sampleItem(String id, {String category = 'top'}) {
  final item = testItem(id, category: category);
  return ClothingItem(
    id: item.id,
    photoPath: item.photoPath,
    tags: item.tags,
    createdAt: item.createdAt,
    isSample: true,
  );
}

void main() {
  late TestClosetRepository repository;

  setUp(() => repository = TestClosetRepository());

  Future<void> openCloset(
    WidgetTester tester, {
    SampleClosetLoader? sampleLoader,
    VoidCallback? onAddItem,
    TestClosetRepository? closet,
  }) async {
    await pumpClosetScreen(
      tester,
      ClosetScreen(
        repository: closet ?? repository,
        sampleLoader: sampleLoader,
        onAddItem: onAddItem,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty closet offers the sample closet', (tester) async {
    await openCloset(tester);
    expect(find.textContaining('Your closet is empty'), findsOneWidget);
    expect(find.text('Load sample closet'), findsOneWidget);
  });

  testWidgets('a new item shows up in the grid with its photo', (tester) async {
    await openCloset(tester);

    await repository.saveItem(testItem('shirt'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Your closet is empty'), findsNothing);
    expect(find.text('Blue top'), findsOneWidget);
    expect(find.text('Casual · Summer'), findsOneWidget);
    expect(
      tester.widget<ClosetPhoto>(find.byType(ClosetPhoto)).photoPath,
      '/photos/shirt.jpg',
    );
  });

  testWidgets('the newest item comes first', (tester) async {
    await repository.saveItem(
      testItem('old', color: 'red', createdAt: DateTime(2026, 11, 1)),
    );
    await repository.saveItem(
      testItem('new', color: 'green', createdAt: DateTime(2026, 11, 3)),
    );
    await openCloset(tester);

    final photos = tester.widgetList<ClosetPhoto>(find.byType(ClosetPhoto));
    expect(photos.map((photo) => photo.photoPath), [
      '/photos/new.jpg',
      '/photos/old.jpg',
    ]);
  });

  testWidgets('filters show one category at a time', (tester) async {
    await repository.saveItem(testItem('shirt'));
    await repository.saveItem(
      testItem('boots', category: 'shoes', color: 'brown'),
    );
    await openCloset(tester);

    await tester.tap(find.text('Shoes'));
    await tester.pumpAndSettle();
    expect(find.text('Brown shoes'), findsOneWidget);
    expect(find.text('Blue top'), findsNothing);

    await tester.tap(find.text('Dresses'));
    await tester.pumpAndSettle();
    expect(find.text('No dresses in your closet.'), findsOneWidget);

    await tester.tap(find.text('All'));
    await tester.pumpAndSettle();
    expect(find.byType(ClosetPhoto), findsNWidgets(2));
  });

  testWidgets('tapping an item opens its tags', (tester) async {
    await repository.saveItem(testItem('shirt'));
    await openCloset(tester);

    await tester.tap(find.text('Blue top'));
    await tester.pumpAndSettle();

    expect(find.text('Top'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);
    expect(find.text('Solid'), findsOneWidget);
    expect(find.text('Casual'), findsOneWidget);
    expect(find.text('Summer'), findsOneWidget);
  });

  testWidgets('add item uses the app tab when one is given', (tester) async {
    var opened = 0;
    await openCloset(tester, onAddItem: () => opened++);

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(find.byType(AddItemScreen), findsNothing);
  });

  testWidgets('otherwise add item opens a screen for the same closet', (
    tester,
  ) async {
    await openCloset(tester);

    await tester.tap(find.text('Add item'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<AddItemScreen>(find.byType(AddItemScreen)).repository,
      same(repository),
    );
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('without an injected closet it uses the app backend', (
    tester,
  ) async {
    final services = BackendServices(
      closet: FakeClosetRepository(items: [testItem('shirt')]),
      outfits: FakeOutfitRepository(),
      profile: FakeProfileRepository(),
      wearLogs: FakeWearLogRepository(),
      ai: FakeAiService(),
    );
    await pumpClosetScreen(tester, const ClosetScreen(), services: services);
    await tester.pumpAndSettle();

    expect(find.text('Blue top'), findsOneWidget);
  });

  testWidgets('load button fills an empty closet, then goes away', (
    tester,
  ) async {
    await openCloset(
      tester,
      sampleLoader: StubSampleLoader(
        () => repository.saveItem(testItem('shirt')),
      ),
    );

    await tester.tap(find.text('Load sample closet'));
    await tester.pumpAndSettle();

    expect(find.text('Blue top'), findsOneWidget);
    expect(find.text('Load sample closet'), findsNothing);
  });

  testWidgets('a failed sample load says so and can be retried', (
    tester,
  ) async {
    await openCloset(
      tester,
      sampleLoader: StubSampleLoader(() async => throw Exception('no disk')),
    );

    await tester.tap(find.text('Load sample closet'));
    await tester.pumpAndSettle();

    expect(find.text('Could not load the sample closet.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Load sample closet'),
    );
    expect(button.onPressed, isNotNull);
  });

  Future<void> chooseFilter(WidgetTester tester, String filter, String value) {
    return tester
        .tap(find.byKey(ValueKey('$filter filter')))
        .then((_) => tester.pumpAndSettle())
        .then((_) => tester.tap(find.text(value).last))
        .then((_) => tester.pumpAndSettle());
  }

  List<String> shownPhotos(WidgetTester tester) => [
    for (final photo in tester.widgetList<ClosetPhoto>(
      find.byType(ClosetPhoto),
    ))
      photo.photoPath,
  ];

  testWidgets('the color filter lists closet colors and narrows the grid', (
    tester,
  ) async {
    await repository.saveItem(testItem('shirt', color: 'Blue '));
    await repository.saveItem(testItem('tee', color: 'red'));
    await repository.saveItem(
      testItem('boots', category: 'shoes', color: 'blue'),
    );
    await openCloset(tester);

    expect(find.text('Color: Any'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('Color filter')));
    await tester.pumpAndSettle();
    // Each color is offered once, whatever its spacing or case.
    expect(find.text('Any color'), findsWidgets);
    expect(find.text('Blue'), findsWidgets);
    expect(find.text('Red'), findsWidgets);
    await tester.tap(find.text('Blue').last);
    await tester.pumpAndSettle();

    expect(find.text('Color: Blue'), findsOneWidget);
    expect(
      shownPhotos(tester),
      unorderedEquals(['/photos/shirt.jpg', '/photos/boots.jpg']),
    );

    // Filters combine with the category chips.
    await tester.tap(find.text('Shoes'));
    await tester.pumpAndSettle();
    expect(shownPhotos(tester), ['/photos/boots.jpg']);
  });

  testWidgets('a season filter also shows all-year pieces', (tester) async {
    await repository.saveItem(testItem('tee', season: 'summer'));
    await repository.saveItem(testItem('coat', season: 'winter'));
    await repository.saveItem(testItem('jeans', season: 'all year'));
    await openCloset(tester);

    await chooseFilter(tester, 'Season', 'Summer');
    expect(
      shownPhotos(tester),
      unorderedEquals(['/photos/tee.jpg', '/photos/jeans.jpg']),
    );

    await chooseFilter(tester, 'Season', 'All year');
    expect(shownPhotos(tester), ['/photos/jeans.jpg']);

    await chooseFilter(tester, 'Season', 'Any season');
    expect(shownPhotos(tester), hasLength(3));
  });

  testWidgets('no matches offers to clear every filter', (tester) async {
    await repository.saveItem(testItem('shirt', color: 'blue'));
    await repository.saveItem(
      testItem('boots', category: 'shoes', color: 'brown'),
    );
    await openCloset(tester);

    await chooseFilter(tester, 'Color', 'Blue');
    await tester.tap(find.text('Shoes'));
    await tester.pumpAndSettle();
    expect(
      find.text('Nothing in your closet matches these filters.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Clear filters'));
    await tester.pumpAndSettle();
    expect(find.text('Color: Any'), findsOneWidget);
    expect(shownPhotos(tester), hasLength(2));
  });

  testWidgets('a chosen color stops filtering once no item has it', (
    tester,
  ) async {
    await repository.saveItem(testItem('shirt', color: 'blue'));
    await repository.saveItem(testItem('tee', color: 'red'));
    await openCloset(tester);
    await chooseFilter(tester, 'Color', 'Red');

    await repository.deleteItem('tee');
    await tester.pumpAndSettle();

    expect(find.text('Color: Any'), findsOneWidget);
    expect(shownPhotos(tester), ['/photos/shirt.jpg']);
  });

  testWidgets('clear sample closet only shows with sample items', (
    tester,
  ) async {
    await repository.saveItem(testItem('shirt'));
    await openCloset(tester);
    expect(find.text('Clear sample closet'), findsNothing);

    await repository.saveItem(sampleItem('sample-tee'));
    await tester.pumpAndSettle();
    expect(find.text('Clear sample closet'), findsOneWidget);
  });

  testWidgets('clearing the sample closet asks first, then clears it', (
    tester,
  ) async {
    await repository.saveItem(testItem('shirt'));
    await repository.saveItem(sampleItem('sample-tee'));
    await repository.saveItem(sampleItem('sample-shoes', category: 'shoes'));
    var clears = 0;
    await openCloset(
      tester,
      sampleLoader: StubSampleLoader(
        () async {},
        onClear: () async {
          clears++;
          await repository.deleteItem('sample-tee');
          await repository.deleteItem('sample-shoes');
          return 2;
        },
      ),
    );

    await tester.tap(find.text('Clear sample closet'));
    await tester.pumpAndSettle();
    expect(find.textContaining('removes the 2 sample pieces'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(clears, 0);

    await tester.tap(find.text('Clear sample closet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(clears, 1);
    expect(repository.items.map((item) => item.id), ['shirt']);
    expect(find.text('Sample closet cleared'), findsOneWidget);
    expect(find.text('Clear sample closet'), findsNothing);
  });

  testWidgets('a failed sample clear says so', (tester) async {
    await repository.saveItem(sampleItem('sample-tee'));
    await openCloset(
      tester,
      sampleLoader: StubSampleLoader(
        () async {},
        onClear: () async => throw Exception('write rejected'),
      ),
    );

    await tester.tap(find.text('Clear sample closet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not clear the sample closet. Try again.'),
      findsOneWidget,
    );
  });

  testWidgets('a closet that fails to load can be retried', (tester) async {
    final closet = FlakyClosetRepository();
    await closet.saveItem(testItem('shirt'));
    await openCloset(tester, closet: closet);

    expect(find.text('Could not load your closet.'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(closet.watchCalls, 2);
    expect(find.text('Could not load your closet.'), findsNothing);
    expect(find.text('Blue top'), findsOneWidget);
  });
}
