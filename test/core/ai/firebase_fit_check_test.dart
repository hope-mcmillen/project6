import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:fitcheck_ai/core/ai/ai_service.dart';
import 'package:fitcheck_ai/core/ai/daily_ai_allowance.dart';
import 'package:fitcheck_ai/core/ai/fake_ai_service.dart';
import 'package:fitcheck_ai/core/ai/firebase_ai_service.dart';
import 'package:fitcheck_ai/core/ai/firebase_json_client.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingClient implements AiJsonClient {
  RecordingClient(this.reply);

  final Future<String> Function(int attempt) reply;
  final prompts = <String>[];
  Uint8List? jpeg;
  Schema? schema;

  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) {
    prompts.add(prompt);
    this.jpeg = jpeg;
    this.schema = schema;
    return reply(prompts.length);
  }
}

FitCheckRequest request({
  Uint8List? photo,
  String occasion = ' Class ',
  WeatherSummary? weather,
  bool clothingOnlyConfirmed = true,
}) => FitCheckRequest(
  photo: photo ?? Uint8List.fromList([1]),
  occasion: occasion,
  weather: weather,
  clothingOnlyConfirmed: clothingOnlyConfirmed,
);

final feedback = jsonEncode({
  'verdict': 'The blue shirt and dark trousers suit class.',
  'suggestions': ['Add a rain-resistant layer.'],
});

FirebaseAiService service(AiJsonClient client) =>
    FirebaseAiService(client: client, preparePhoto: (bytes) async => bytes);

void main() {
  test(
    'requires confirmation before photo preparation or provider use',
    () async {
      final client = RecordingClient((_) async => feedback);
      var prepared = false;
      final ai = FirebaseAiService(
        client: client,
        preparePhoto: (bytes) async {
          prepared = true;
          return bytes;
        },
      );
      // The compatibility default must fail closed for existing screen callers.
      final unconfirmed = FitCheckRequest(
        photo: Uint8List(1),
        occasion: 'Class',
      );
      await expectLater(
        ai.checkFit(unconfirmed),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            FitCheckRequest.photoPolicyMessage,
          ),
        ),
      );
      expect(prepared, isFalse);
      expect(client.prompts, isEmpty);
      await expectLater(
        FakeAiService().checkFit(unconfirmed),
        throwsA(isA<AiServiceException>()),
      );
    },
  );

  for (final (index, invalid) in [
    request(photo: Uint8List(0)),
    request(occasion: '   '),
    request(occasion: List.filled(161, 'x').join()),
    request(
      weather: const WeatherSummary(
        temperatureC: double.nan,
        rainChancePercent: 10,
      ),
    ),
    request(
      weather: const WeatherSummary(temperatureC: 10, rainChancePercent: 101),
    ),
  ].indexed) {
    test('invalid context $index fails before any provider call', () async {
      final client = RecordingClient((_) async => feedback);
      await expectLater(
        service(client).checkFit(invalid),
        throwsA(isA<AiServiceException>()),
      );
      expect(client.prompts, isEmpty);
    });
  }

  test('sends prepared photo, schema, occasion and numeric weather', () async {
    final client = RecordingClient((_) async => feedback);
    final prepared = Uint8List.fromList([9, 8]);
    final ai = FirebaseAiService(
      client: client,
      preparePhoto: (_) async => prepared,
    );
    final result = await ai.checkFit(
      request(
        weather: const WeatherSummary(
          temperatureC: 12,
          rainChancePercent: 80,
          locationLabel: 'Not needed in the prompt',
        ),
      ),
    );
    expect(result.verdict, contains('shirt'));
    expect(result.suggestions, ['Add a rain-resistant layer.']);
    expect(client.jpeg, same(prepared));
    expect(client.schema, same(FirebaseAiService.fitCheckSchema));
    final prompt = client.prompts.single;
    expect(prompt, contains('Never evaluate or describe a person'));
    expect(prompt, contains('body shape, weight, skin'));
    expect(prompt, isNot(contains('Not needed in the prompt')));
    expect(jsonDecode(prompt.split('\n').last), {
      'occasion': 'Class',
      'weather': {'temperatureC': 12.0, 'rainChancePercent': 80},
    });
  });

  test(
    'unreadable or empty prepared photos never reach the provider',
    () async {
      for (final emptyResult in [false, true]) {
        final client = RecordingClient((_) async => feedback);
        final ai = FirebaseAiService(
          client: client,
          preparePhoto: (_) async {
            if (emptyResult) return Uint8List(0);
            throw const FormatException('Unreadable image');
          },
        );
        await expectLater(
          ai.checkFit(request()),
          throwsA(isA<AiServiceException>()),
        );
        expect(client.prompts, isEmpty);
      }
    },
  );

  test('malformed reply retries once and can recover', () async {
    final client = RecordingClient(
      (attempt) async => attempt == 1 ? 'not JSON' : feedback,
    );
    expect(
      (await service(client).checkFit(request())).suggestions,
      hasLength(1),
    );
    expect(client.prompts, hasLength(2));
  });

  test(
    'invalid feedback stops after two attempts with a Fit Check error',
    () async {
      final client = RecordingClient(
        (_) async => jsonEncode({
          'verdict': 'Coordinated clothing.',
          'suggestions': ['a', 'b', 'c', 'd'],
        }),
      );
      await expectLater(
        service(client).checkFit(request()),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            'AI returned invalid Fit Check feedback. Please retry.',
          ),
        ),
      );
      expect(client.prompts, hasLength(2));
    },
  );

  test('provider failures are not retried or leaked to the UI', () async {
    final client = RecordingClient(
      (_) async => throw StateError('private detail'),
    );
    await expectLater(
      service(client).checkFit(request()),
      throwsA(
        isA<AiServiceException>().having(
          (error) => error.message,
          'message',
          'AI is unavailable. Check your connection and retry.',
        ),
      ),
    );
    expect(client.prompts, hasLength(1));
  });

  testWidgets('a stalled Fit Check ends at its own deadline', (tester) async {
    final client = RecordingClient((_) => Completer<String>().future);
    final result = service(client).checkFit(request());
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
    await tester.pump();
    await tester.pump(const Duration(seconds: 20));
    await check;
    expect(client.prompts, hasLength(1));
  });

  test(
    'Fit Check retries consume the shared allowance; policy failures do not',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'fit-check-quota-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final provider = RecordingClient(
        (attempt) async => attempt == 1 ? '{}' : feedback,
      );
      final allowance = DailyAiAllowance(directory: directory, limit: 2);
      final ai = service(
        DailyLimitedAiJsonClient(client: provider, allowance: allowance),
      );
      await expectLater(
        ai.checkFit(request(clothingOnlyConfirmed: false)),
        throwsA(isA<AiServiceException>()),
      );
      expect((await ai.checkFit(request())).verdict, isNotEmpty);
      expect(provider.prompts, hasLength(2));
      await expectLater(
        ai.checkFit(request()),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            contains('Daily AI limit of 2'),
          ),
        ),
      );
      // Other AI operations use the very same exhausted client/ledger.
      await expectLater(
        ai.tagClothing(Uint8List(1)),
        throwsA(isA<AiServiceException>()),
      );
      expect(provider.prompts, hasLength(2));
    },
  );
}
