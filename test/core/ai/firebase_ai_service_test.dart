import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:fitcheck_ai/core/ai/ai_service.dart';
import 'package:fitcheck_ai/core/ai/clothing_photo_preparer.dart';
import 'package:fitcheck_ai/core/ai/firebase_ai_service.dart';
import 'package:fitcheck_ai/core/ai/firebase_json_client.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';

class ScriptedClient implements AiJsonClient {
  ScriptedClient(this.replies);
  final List<String> replies;
  final prompts = <String>[];
  Uint8List? photo;
  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) async {
    prompts.add(prompt);
    photo = jpeg;
    return replies[(prompts.length - 1).clamp(0, replies.length - 1)];
  }
}

class SlowClient implements AiJsonClient {
  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) => Completer<String>().future;
}

class DelayedOutfitClient implements AiJsonClient {
  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) => Future.delayed(
    const Duration(seconds: 11),
    () =>
        '{"outfits":[{"itemIds":["sample-dress","sample-shoes"],'
        '"reason":"The dress and shoes suit the occasion."}]}',
  );
}

final tags = jsonEncode({
  'category': 'top',
  'color': 'blue',
  'pattern': 'solid',
  'formality': 'casual',
  'season': 'summer',
});
FirebaseAiService service(AiJsonClient client) =>
    FirebaseAiService(client: client, preparePhoto: (b) async => b);

void main() {
  test('malformed tagging JSON retries once and then succeeds', () async {
    final client = ScriptedClient(['not json', tags]);
    expect(
      (await service(client).tagClothing(Uint8List.fromList([1]))).category,
      'top',
    );
    expect(client.prompts.length, 2);
    expect(client.photo, [1]);
  });
  for (final invalid in [
    '{}',
    '[]',
    '{"category":"hat"}',
    '{"category":"top","color":1,"pattern":"solid","formality":"casual","season":"summer"}',
  ]) {
    test(
      'invalid tags fail clearly after exactly two attempts: $invalid',
      () async {
        final client = ScriptedClient([invalid]);
        await expectLater(
          service(client).tagClothing(Uint8List(1)),
          throwsA(isA<AiServiceException>()),
        );
        expect(client.prompts.length, 2);
      },
    );
  }
  test('timeout has a user-facing message', () async {
    final ai = FirebaseAiService(
      client: SlowClient(),
      tagTimeout: const Duration(milliseconds: 5),
      preparePhoto: (b) async => b,
    );
    await expectLater(
      ai.tagClothing(Uint8List(1)),
      throwsA(
        isA<AiServiceException>().having(
          (e) => e.message,
          'message',
          contains('too long'),
        ),
      ),
    );
  });
  testWidgets('outfits can finish after the shorter tagging deadline', (
    tester,
  ) async {
    final result = service(
      DelayedOutfitClient(),
    ).generateOutfits(OutfitRequest(closet: sampleCloset(), occasion: 'work'));
    final check = expectLater(result, completion(hasLength(1)));
    await tester.pump(const Duration(seconds: 11));
    await check;
  });
  testWidgets('a stalled outfit request still ends with a retry message', (
    tester,
  ) async {
    final result = service(
      SlowClient(),
    ).generateOutfits(OutfitRequest(closet: sampleCloset(), occasion: 'work'));
    final check = expectLater(
      result,
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          contains('too long'),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 20));
    await check;
  });
  test('empty or unreadable photo makes no AI request', () async {
    final client = ScriptedClient([tags]);
    final ai = FirebaseAiService(client: client);
    await expectLater(
      ai.tagClothing(Uint8List(0)),
      throwsA(isA<AiServiceException>()),
    );
    await expectLater(
      ai.tagClothing(Uint8List.fromList([1, 2])),
      throwsA(isA<AiServiceException>()),
    );
    expect(client.prompts, isEmpty);
  });
  test('incomplete closet makes no AI call', () async {
    final client = ScriptedClient(['{}']);
    await expectLater(
      service(client)
          .generateOutfits(OutfitRequest(closet: [], occasion: 'work')),
      throwsA(isA<AiServiceException>()),
    );
    expect(client.prompts, isEmpty);
  });
  test(
    'unknown, repeated, incomplete and laundry item outfits are discarded',
    () async {
      final items = sampleCloset();
      final laundry = items.first.copyWith(inLaundry: true);
      final request = OutfitRequest(
        closet: [laundry, ...items.skip(1)],
        occasion: 'work',
        note: 'raincoat',
        weather: const WeatherSummary(temperatureC: 12, rainChancePercent: 80),
      );
      final client = ScriptedClient([
        jsonEncode({
          'outfits': [
            {
              'itemIds': ['imaginary', 'sample-shoes'],
              'reason': 'Bad.',
            },
            {
              'itemIds': ['sample-top', 'sample-bottom', 'sample-shoes'],
              'reason': 'Laundry.',
            },
            {
              'itemIds': ['sample-dress', 'sample-shoes'],
              'reason': 'A coordinated outfit for rain.',
            },
          ],
        }),
      ]);
      final result = await service(client).generateOutfits(request);
      expect(result.single.itemIds, ['sample-dress', 'sample-shoes']);
      expect(client.prompts.single, contains('raincoat'));
      expect(client.prompts.single, contains('rainChancePercent'));
      expect(client.prompts.single, isNot(contains('assets/sample_closet')));
      expect(client.photo, isNull);
    },
  );
  for (final ids in [
    ['unknown'],
    ['sample-shoes'],
    ['sample-dress', 'sample-shoes', 'sample-shoes'],
  ]) {
    test('no valid outfits retries once then fails for $ids', () async {
      final client = ScriptedClient([
        jsonEncode({
          'outfits': [
            {'itemIds': ids, 'reason': 'Invalid.'},
          ],
        }),
      ]);
      await expectLater(
        service(client).generateOutfits(
          OutfitRequest(closet: sampleCloset(), occasion: 'work'),
        ),
        throwsA(isA<AiServiceException>()),
      );
      expect(client.prompts.length, 2);
    });
  }
  for (final size in [(1600, 800), (400, 200), (800, 1600)]) {
    test(
      'photo preparation keeps aspect ratio and never enlarges $size',
      () async {
        final input = Uint8List.fromList(
          img.encodePng(img.Image(width: size.$1, height: size.$2)),
        );
        final jpeg = await prepareClothingPhoto(input);
        final output = img.decodeJpg(jpeg)!;
        expect(output.width / output.height, closeTo(size.$1 / size.$2, 0.01));
        expect(output.width <= 1024 && output.height <= 1024, isTrue);
        expect(output.width <= size.$1 && output.height <= size.$2, isTrue);
      },
    );
  }
}
