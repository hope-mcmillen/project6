import 'dart:typed_data';

import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/logging/app_log.dart';
import 'package:fitcheck_ai/core/logging/logging_backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../features/closet/closet_test_helpers.dart';

void main() {
  late List<String> lines;

  setUp(() {
    lines = [];
    AppLog.enabled = true;
    AppLog.sink = lines.add;
  });

  tearDown(() {
    AppLog.enabled = false;
    AppLog.sink = debugPrint;
  });

  test('lines carry the FitCheck prefix and a kind', () {
    AppLog.tap('Save to closet', screen: 'Review Tags');
    expect(
      lines.single,
      matches(
        RegExp(
          r'^\[FitCheck\] \d\d:\d\d:\d\d\.\d{3} TAP  '
          r'"Save to closet" on Review Tags$',
        ),
      ),
    );
  });

  test('nothing is written when logging is off', () {
    AppLog.enabled = false;
    AppLog.data('hidden');
    expect(lines, isEmpty);
  });

  test('closet calls log the start, the result, and failures', () async {
    final repository = TestClosetRepository();
    final services = withLogging(
      BackendServices.fake().copyWithCloset(repository),
    );

    await services.closet.saveItem(testItem('a', category: 'top'));
    expect(lines[0], contains('DATA Closet: saving item a (top / '));
    expect(lines[1], contains('confirmed by Firestore'));

    repository.failWrites = true;
    await expectLater(
      services.closet.deleteItem('a'),
      throwsA(isA<Exception>()),
    );
    expect(lines.last, contains('Closet: deleting item a FAILED after'));
  });

  test('closet updates list the item count by category', () async {
    final services = withLogging(
      BackendServices.fake().copyWithCloset(
        FakeClosetRepository(
          items: [
            testItem('a', category: 'top'),
            testItem('b', category: 'top'),
            testItem('c', category: 'shoes'),
          ],
        ),
      ),
    );

    await services.closet.watchItems().first;

    expect(lines.first, contains('Closet: listening for changes'));
    expect(lines.last, contains('Closet update: 3 items (2 top, 1 shoes)'));
  });

  test(
    'AI tagging logs the photo size and the tags, never the photo',
    () async {
      final services = withLogging(BackendServices.fake());

      await services.ai.tagClothing(Uint8List(2048));

      expect(lines.first, contains('AI   Tagging a 2 KB photo...'));
      expect(lines.last, contains('done in'));
      expect(lines.last, contains('top'));
    },
  );

  test('AI failures are logged with their message', () async {
    final services = withLogging(
      BackendServices.fake().copyWithAi(FakeAiService(failTagging: true)),
    );

    await expectLater(
      services.ai.tagClothing(Uint8List(10)),
      throwsA(anything),
    );
    expect(lines.last, contains('FAILED'));
  });

  testWidgets('the navigator observer logs pages and dialogs', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [AppNavigatorObserver()],
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                settings: const RouteSettings(name: '/review-tags'),
                builder: (_) => const Text('review'),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();

    final nav = lines.where((line) => line.contains('NAV')).toList();
    expect(nav, [
      contains('Opened the app home (tabs)'),
      contains('Opened Review Tags from the app home (tabs)'),
      contains('Closed Review Tags, back on the app home (tabs)'),
    ]);
  });
}

extension on BackendServices {
  BackendServices copyWithCloset(FakeClosetRepository closet) =>
      BackendServices(
        closet: closet,
        outfits: outfits,
        profile: profile,
        wearLogs: wearLogs,
        ai: ai,
      );

  BackendServices copyWithAi(FakeAiService ai) => BackendServices(
    closet: closet,
    outfits: outfits,
    profile: profile,
    wearLogs: wearLogs,
    ai: ai,
  );
}
