import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:fitcheck_ai/core/ai/ai_service.dart';
import 'package:fitcheck_ai/core/ai/daily_ai_allowance.dart';
import 'package:fitcheck_ai/core/ai/firebase_ai_service.dart';
import 'package:fitcheck_ai/core/ai/firebase_json_client.dart';
import 'package:fitcheck_ai/core/data/fake_repositories.dart';
import 'package:fitcheck_ai/core/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

const tags =
    '{"category":"top","color":"blue","pattern":"solid",'
    '"formality":"casual","season":"summer"}';
const outfits =
    '{"outfits":[{"itemIds":["sample-dress","sample-shoes"],'
    '"reason":"The dress and shoes suit the occasion."}]}';

class RecordingClient implements AiJsonClient {
  String reply = tags;
  bool fail = false;
  int calls = 0;

  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) async {
    calls++;
    if (fail) throw StateError('Provider failed.');
    return reply;
  }
}

Matcher limitError = throwsA(
  isA<AiServiceException>().having(
    (error) => error.message,
    'message',
    contains('Daily AI limit'),
  ),
);

Future<bool> reserveOrReject(DailyAiAllowance allowance) async {
  try {
    await allowance.reserve();
    return true;
  } on AiServiceException catch (error) {
    if (!error.message.startsWith('Daily AI limit')) rethrow;
    return false;
  }
}

void main() {
  late Directory directory;
  late DateTime now;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('daily-ai-test-');
    now = DateTime(2026, 11, 10, 12);
  });
  tearDown(() => directory.delete(recursive: true));

  DailyAiAllowance allowance({int limit = 2}) =>
      DailyAiAllowance(directory: directory, limit: limit, now: () => now);

  FirebaseAiService service(RecordingClient client, {int limit = 2}) =>
      FirebaseAiService(
        client: DailyLimitedAiJsonClient(
          client: client,
          allowance: allowance(limit: limit),
        ),
        preparePhoto: (bytes) async => bytes,
      );

  test(
    'usage survives new service instances and blocks the next request',
    () async {
      await allowance().reserve();
      await allowance().reserve();
      await expectLater(allowance().reserve(), limitError);
    },
  );

  test(
    'simultaneous instances cannot reserve beyond the shared limit',
    () async {
      final accepted = await Future.wait([
        for (var request = 0; request < 20; request++)
          reserveOrReject(allowance(limit: 5)),
      ]);
      expect(accepted.where((value) => value).length, 5);
      await expectLater(allowance(limit: 5).reserve(), limitError);
    },
  );

  test('reservations are also exclusive across isolates', () async {
    final path = directory.path;
    final accepted = await Future.wait([
      for (var request = 0; request < 8; request++)
        Isolate.run(
          () => reserveOrReject(
            DailyAiAllowance(
              directory: Directory(path),
              limit: 3,
              now: () => DateTime(2026, 11, 10),
            ),
          ),
        ),
    ]);
    expect(accepted.where((value) => value).length, 3);
    await expectLater(allowance(limit: 3).reserve(), limitError);
  });

  test('local midnight restores allowance across a year boundary', () async {
    now = DateTime(2026, 12, 31, 23, 59);
    await allowance(limit: 1).reserve();
    await expectLater(allowance(limit: 1).reserve(), limitError);
    now = DateTime(2027, 1, 1);
    await allowance(limit: 1).reserve();
    await expectLater(allowance(limit: 1).reserve(), limitError);
  });

  test('moving the clock backwards never restores requests', () async {
    await allowance(limit: 1).reserve();
    now = DateTime(2026, 11, 9);
    await expectLater(allowance(limit: 1).reserve(), limitError);
    now = DateTime(2026, 11, 10, 23, 59);
    await expectLater(allowance(limit: 1).reserve(), limitError);
    now = DateTime(2026, 11, 11);
    await allowance(limit: 1).reserve();
  });

  test('a reserved file remains consumed regardless of its contents', () async {
    final today = await Directory('${directory.path}/20261110').create();
    await File('${today.path}/0')
        .writeAsString('interrupted or altered contents');
    await expectLater(allowance(limit: 1).reserve(), limitError);
  });

  test('invalid limits are rejected at construction', () {
    expect(() => allowance(limit: 0), throwsArgumentError);
    expect(() => allowance(limit: -1), throwsArgumentError);
  });

  test(
    'tagging and outfits share the allowance and expose its error',
    () async {
      final client = RecordingClient();
      final ai = service(client);
      expect((await ai.tagClothing(Uint8List.fromList([1]))).category, 'top');
      client.reply = outfits;
      final request = OutfitRequest(closet: sampleCloset(), occasion: 'class');
      expect(await ai.generateOutfits(request), hasLength(1));
      await expectLater(ai.generateOutfits(request), limitError);
      expect(client.calls, 2);
    },
  );

  test('a malformed reply retry also requires a reservation', () async {
    final client = RecordingClient()..reply = 'invalid JSON';
    await expectLater(
      service(client, limit: 1).tagClothing(Uint8List.fromList([1])),
      limitError,
    );
    expect(client.calls, 1);
  });

  test(
    'both malformed attempts consume allowance before returning an error',
    () async {
      final client = RecordingClient()..reply = 'invalid JSON';
      await expectLater(
        service(client).tagClothing(Uint8List.fromList([1])),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            contains('invalid data'),
          ),
        ),
      );
      expect(client.calls, 2);
      await expectLater(allowance().reserve(), limitError);
    },
  );

  test(
    'provider failures consume a slot and later calls remain blocked',
    () async {
      final client = RecordingClient()..fail = true;
      final ai = service(client, limit: 1);
      await expectLater(
        ai.tagClothing(Uint8List.fromList([1])),
        throwsA(isA<AiServiceException>()),
      );
      await expectLater(ai.tagClothing(Uint8List.fromList([1])), limitError);
      expect(client.calls, 1);
    },
  );

  test('invalid photos and incomplete closets consume no allowance', () async {
    final client = RecordingClient();
    final ai = service(client, limit: 1);
    await expectLater(
      ai.tagClothing(Uint8List(0)),
      throwsA(isA<AiServiceException>()),
    );
    await expectLater(
      ai.generateOutfits(OutfitRequest(closet: [], occasion: 'class')),
      throwsA(isA<AiServiceException>()),
    );
    expect(client.calls, 0);
    await ai.tagClothing(Uint8List.fromList([1]));
    expect(client.calls, 1);
  });

  test(
    'a storage error prevents the model call and reaches the caller',
    () async {
      final file = await File('${directory.path}/blocked').create();
      final client = RecordingClient();
      final ai = FirebaseAiService(
        client: DailyLimitedAiJsonClient(
          client: client,
          allowance: DailyAiAllowance(directory: Directory(file.path)),
        ),
        preparePhoto: (bytes) async => bytes,
      );
      await expectLater(
        ai.tagClothing(Uint8List.fromList([1])),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            contains('device storage'),
          ),
        ),
      );
      expect(client.calls, 0);
    },
  );
}
