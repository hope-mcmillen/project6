import 'dart:convert';
import 'dart:typed_data';

import 'package:fitcheck_ai/core/ai/ai_service.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/core/logging/logging_backend.dart';
import 'package:fitcheck_ai/features/fit_check/fit_check_service.dart'
    as feature;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'structured feedback trims text and accepts zero to three suggestions',
    () {
      for (var count = 0; count <= 3; count++) {
        final result = FitCheckFeedback.fromMap(
          jsonDecode(
            jsonEncode({
              'verdict': '  The colors coordinate.  ',
              'suggestions': List.filled(count, '  Add a matching layer.  '),
            }),
          ),
        );
        expect(result.verdict, 'The colors coordinate.');
        expect(result.suggestions, List.filled(count, 'Add a matching layer.'));
        expect(
          () => result.suggestions.add('Another layer.'),
          throwsUnsupportedError,
        );
      }
    },
  );

  for (final invalid in [
    null,
    [],
    {},
    {'verdict': 'Looks coordinated.', 'suggestions': null},
    {'verdict': 'Looks coordinated.', 'suggestions': 'Add a layer.'},
    {'verdict': 12, 'suggestions': []},
    {'verdict': '   ', 'suggestions': []},
    {'verdict': List.filled(601, 'x').join(), 'suggestions': []},
    {
      'verdict': 'Looks coordinated.',
      'suggestions': [null],
    },
    {
      'verdict': 'Looks coordinated.',
      'suggestions': ['   '],
    },
    {
      'verdict': 'Looks coordinated.',
      'suggestions': [List.filled(201, 'x').join()],
    },
    {
      'verdict': 'Looks coordinated.',
      'suggestions': ['a', 'b', 'c', 'd'],
    },
  ]) {
    test('untrusted feedback rejects invalid shape or values: $invalid', () {
      expect(() => FitCheckFeedback.fromMap(invalid), throwsFormatException);
    });
  }

  test('malformed structured JSON produces a format error', () {
    expect(
      () => FitCheckFeedback.fromMap(jsonDecode('{"verdict":')),
      throwsFormatException,
    );
  });

  test('the existing display constructor retains its cap and snapshot', () {
    final suggestions = ['a', 'b', 'c', 'd'];
    final feedback = feature.FitCheckFeedback(
      verdict: 'The colors coordinate.',
      suggestions: suggestions,
    );
    suggestions[0] = 'changed';
    expect(feedback.suggestions, ['a', 'b', 'c']);
    expect(feedback, isA<FitCheckFeedback>());
  });

  test(
    'shared fake implements the screen contract and retains photo context',
    () async {
      final photo = Uint8List.fromList([1, 2, 3]);
      const weather = WeatherSummary(temperatureC: 12, rainChancePercent: 80);
      final request = feature.FitCheckRequest(
        photo: photo,
        occasion: 'Class',
        weather: weather,
        clothingOnlyConfirmed: true,
      );
      final ai = FakeAiService();
      final feature.FitCheckService screenService = ai;
      final feedback = await screenService.checkFit(request);
      expect(feedback.verdict, isNotEmpty);
      expect(feedback.suggestions, hasLength(3));
      expect(ai.fitCheckCalls, 1);
      expect(ai.lastFitCheckRequest, same(request));
      expect(ai.lastFitCheckRequest!.photo, same(photo));
      expect(ai.lastFitCheckRequest!.weather, same(weather));
    },
  );

  test('shared fake failures expose the normal AI error contract', () async {
    final ai = FakeAiService(failFitCheck: true);
    await expectLater(
      ai.checkFit(
        FitCheckRequest(
          photo: Uint8List(1),
          occasion: 'Class',
          clothingOnlyConfirmed: true,
        ),
      ),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('retry'),
        ),
      ),
    );
    expect(ai.fitCheckCalls, 1);
  });

  test('logging wrapper forwards Fit Check requests and failures', () async {
    final request = FitCheckRequest(
      photo: Uint8List(1),
      occasion: 'Class',
      clothingOnlyConfirmed: true,
    );
    final ai = FakeAiService();
    final AiService logging = LoggingAiService(ai);
    expect((await logging.checkFit(request)).suggestions, hasLength(3));
    expect(ai.lastFitCheckRequest, same(request));
    await expectLater(
      LoggingAiService(FakeAiService(failFitCheck: true)).checkFit(request),
      throwsA(isA<AiServiceException>()),
    );
  });
}
