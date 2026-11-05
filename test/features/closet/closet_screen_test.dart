import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/features/closet/add_item_screen.dart';
import 'package:fitcheck_ai/features/closet/closet_photo.dart';
import 'package:fitcheck_ai/features/closet/closet_screen.dart';
import 'package:fitcheck_ai/features/closet/sample_closet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'closet_test_helpers.dart';

class StubSampleLoader extends SampleClosetLoader {
  StubSampleLoader(this.onLoad) : super(repository: FakeClosetRepository());

  final Future<void> Function() onLoad;

  @override
  Future<void> load() => onLoad();
}

void main() {
  late TestClosetRepository repository;

  setUp(() => repository = TestClosetRepository());

  Future<void> openCloset(
    WidgetTester tester, {
    SampleClosetLoader? sampleLoader,
    VoidCallback? onAddItem,
  }) async {
    await pumpClosetScreen(
      tester,
      ClosetScreen(
        repository: repository,
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
}
