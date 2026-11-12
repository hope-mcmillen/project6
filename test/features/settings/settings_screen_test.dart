import 'package:fitcheck_ai/app/welcome_screen.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/features/closet/sample_closet.dart';
import 'package:fitcheck_ai/features/settings/my_data_deleter.dart';
import 'package:fitcheck_ai/features/settings/settings_screen.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../app/app_test_helpers.dart';

class FakeSampleLoader extends SampleClosetLoader {
  FakeSampleLoader() : super(repository: FakeClosetRepository());

  int loads = 0;

  @override
  Future<void> load() async => loads++;
}

class FakeDeleter extends MyDataDeleter {
  FakeDeleter() : super(services: BackendServices.fake());

  int calls = 0;

  @override
  Future<void> deleteAll() async => calls++;
}

BackendServices servicesWithCloset(List<ClothingItem> items) => BackendServices(
  closet: FakeClosetRepository(items: items),
  outfits: FakeOutfitRepository(),
  profile: FakeProfileRepository(),
  wearLogs: FakeWearLogRepository(),
  ai: FakeAiService(),
);

void main() {
  setUp(() => mockSavedSettings(ageConfirmed: true));

  testWidgets('Load sample closet uses the closet loader', (tester) async {
    final loader = FakeSampleLoader();
    await pumpWithAppServices(tester, SettingsScreen(sampleLoader: loader));

    await tester.tap(find.text('Load sample closet'));
    await tester.pumpAndSettle();

    expect(loader.loads, 1);
    expect(
      find.text('Sample closet loaded. Find it in the Wardrobe tab.'),
      findsOneWidget,
    );
  });

  testWidgets('Load sample closet does not load it twice', (tester) async {
    final loader = FakeSampleLoader();
    await pumpWithAppServices(
      tester,
      SettingsScreen(sampleLoader: loader),
      services: servicesWithCloset([
        ClothingItem(
          id: 'sample-top',
          photoPath: '/photos/top.png',
          tags: const ClothingTags(
            category: 'top',
            color: 'blue',
            pattern: 'solid',
            formality: 'casual',
            season: 'summer',
          ),
          createdAt: DateTime(2026, 11, 1),
          isSample: true,
        ),
      ]),
    );

    await tester.tap(find.text('Load sample closet'));
    await tester.pumpAndSettle();

    expect(loader.loads, 0);
    expect(find.text('The sample closet is already loaded.'), findsOneWidget);
  });

  testWidgets('Delete all my data asks first, and Cancel deletes nothing', (
    tester,
  ) async {
    final deleter = FakeDeleter();
    await pumpWithAppServices(tester, SettingsScreen(deleter: deleter));

    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    expect(find.text('Delete all your data?'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(deleter.calls, 0);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('confirming deletes the data and returns to the welcome screen', (
    tester,
  ) async {
    final deleter = FakeDeleter();
    await pumpWithAppServices(tester, SettingsScreen(deleter: deleter));

    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    // The real deleter clears the 18+ confirmation.
    mockSavedSettings(ageConfirmed: false);
    await tester.tap(find.text('Delete everything'));
    await tester.pumpAndSettle();

    expect(deleter.calls, 1);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('no Settings option says Not built', (tester) async {
    await pumpWithAppServices(
      tester,
      SettingsScreen(sampleLoader: FakeSampleLoader(), deleter: FakeDeleter()),
    );

    await tester.tap(find.text('Load sample closet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete all my data'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Not built'), findsNothing);
  });
}
