import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:fitcheck_ai/core/ai/ai_service.dart';
import 'package:fitcheck_ai/core/ai/daily_ai_allowance.dart';
import 'package:fitcheck_ai/core/ai/firebase_ai_service.dart';
import 'package:fitcheck_ai/core/ai/firebase_json_client.dart';
import 'package:fitcheck_ai/core/data/backend_services.dart';
import 'package:fitcheck_ai/firebase_options.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';

/// Opt-in development-project checks. Uses the already-approved emulator.
/// Run with --no-uninstall to preserve its authorized App Check credential.
/// Two real provider attempts consume two normal daily allowance reservations.
class AppCheckProbeClient extends http.BaseClient {
  AppCheckProbeClient({this.omitAppCheck = false});

  final bool omitAppCheck;
  final http.Client _inner = http.Client();
  bool hadAppCheck = false;
  int? statusCode;
  bool rejectedAppCheck = false;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    hadAppCheck = request.headers.entries.any(
      (entry) =>
          entry.key.toLowerCase() == 'x-firebase-appcheck' &&
          entry.value.isNotEmpty,
    );
    if (omitAppCheck) {
      request.headers.removeWhere(
        (name, _) => name.toLowerCase() == 'x-firebase-appcheck',
      );
    }
    final response = await http.Response.fromStream(await _inner.send(request));
    statusCode = response.statusCode;
    final body = utf8.decode(response.bodyBytes).toLowerCase();
    rejectedAppCheck =
        (statusCode == 401 || statusCode == 403) &&
        (body.contains('app check') || body.contains('appcheck'));
    // Return the response to the SDK. Never print headers, tokens or raw bodies.
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
    );
  }

  @override
  void close() => _inner.close();
}

class CountingJsonClient implements AiJsonClient {
  int calls = 0;

  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) async {
    calls++;
    return '{"category":"top","color":"blue","pattern":"solid",'
        '"formality":"casual","season":"summer"}';
  }
}

Future<GenerateContentResponse> probe(AppCheckProbeClient client) async {
  await (await DailyAiAllowance.forDevice()).reserve();
  final model = FirebaseAI.googleAI().generativeModel(
    model: 'gemini-3.5-flash-lite',
    httpClient: client,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      responseSchema: Schema.object(properties: {'ready': Schema.boolean()}),
      thinkingConfig: ThinkingConfig.withThinkingLevel(ThinkingLevel.low),
      maxOutputTokens: 256,
    ),
  );
  return model
      .generateContent([Content.text('Return ready as true.')])
      .timeout(const Duration(seconds: 20));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await BackendServices.connect(options: DefaultFirebaseOptions.android);
    final token = await FirebaseAppCheck.instance
        .getToken(true)
        .timeout(const Duration(seconds: 30));
    expect(
      token,
      isNotEmpty,
      reason: 'Use the already-authorized development emulator.',
    );
  });

  testWidgets('approved App Check client can use the live AI endpoint', (
    tester,
  ) async {
    final client = AppCheckProbeClient();
    addTearDown(client.close);
    final response = await probe(client);
    expect(client.hadAppCheck, isTrue);
    expect(client.statusCode, 200);
    expect(jsonDecode(response.text!)['ready'], isTrue);
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets('live AI endpoint rejects the same request without App Check', (
    tester,
  ) async {
    final client = AppCheckProbeClient(omitAppCheck: true);
    addTearDown(client.close);
    await expectLater(probe(client), throwsA(isA<FirebaseAIException>()));
    expect(
      client.hadAppCheck,
      isTrue,
      reason: 'The SDK originally attached attestation.',
    );
    expect(
      client.rejectedAppCheck,
      isTrue,
      reason: 'Require an App Check-specific 401/403 response.',
    );
  }, timeout: const Timeout(Duration(minutes: 1)));

  testWidgets(
    'Android allowance blocks the provider after the limit and recreation',
    (tester) async {
      final directory = await Directory.systemTemp.createTemp(
        'ai-allowance-probe-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final provider = CountingJsonClient();
      final now = DateTime.now();
      FirebaseAiService service() => FirebaseAiService(
        client: DailyLimitedAiJsonClient(
          client: provider,
          allowance: DailyAiAllowance(
            directory: directory,
            limit: 1,
            now: () => now,
          ),
        ),
        preparePhoto: (bytes) async => bytes,
      );
      await service().tagClothing(Uint8List.fromList([1]));
      await expectLater(
        service().tagClothing(Uint8List.fromList([1])),
        throwsA(
          isA<AiServiceException>().having(
            (error) => error.message,
            'message',
            contains('Daily AI limit'),
          ),
        ),
      );
      expect(provider.calls, 1);
    },
  );
}
