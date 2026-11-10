import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:path_provider/path_provider.dart';

import 'ai_service.dart';
import 'firebase_json_client.dart';

/// A durable reservation per provider attempt, shared by all AI features/accounts.
class DailyAiAllowance {
  DailyAiAllowance({
    required this.directory,
    this.limit = defaultLimit,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive.');
    }
  }

  static const defaultLimit = 30;
  final Directory directory;
  final int limit;
  final DateTime Function() _now;

  static Future<DailyAiAllowance> forDevice({int limit = defaultLimit}) async {
    final support = await getApplicationSupportDirectory();
    return DailyAiAllowance(
      directory: Directory('${support.path}/daily-ai-allowance-v1'),
      limit: limit,
    );
  }

  Future<void> reserve() async {
    try {
      await directory.create(recursive: true);
      final now = _now().toLocal();
      var day = now.year * 10000 + now.month * 100 + now.day;
      // Keep the most recent calendar day when the device clock moves backwards.
      await for (final entry in directory.list(followLinks: false)) {
        final savedDay = int.tryParse(
          entry.path.split(Platform.pathSeparator).last,
        );
        if (entry is Directory && savedDay != null && savedDay > day) {
          day = savedDay;
        }
      }
      final today = Directory('${directory.path}/$day');
      await today.create();
      for (var slot = 0; slot < limit; slot++) {
        try {
          // Exclusive creation is atomic across instances, isolates and processes.
          // A crash after reservation consumes a slot without sending a request.
          await File('${today.path}/$slot').create(exclusive: true);
          return;
        } on PathExistsException {
          // Another request already reserved this slot. Try the next one.
        }
      }
      throw AiServiceException(
        'Daily AI limit of $limit requests reached. Try again tomorrow.',
      );
    } on FileSystemException {
      throw const AiServiceException(
        'Could not save the AI allowance. Check device storage and retry.',
      );
    }
  }
}

/// Count retries and failed requests before contacting the model provider.
class DailyLimitedAiJsonClient implements AiJsonClient {
  const DailyLimitedAiJsonClient({
    required this.client,
    required this.allowance,
  });

  final AiJsonClient client;
  final DailyAiAllowance allowance;

  @override
  Future<String> generate({
    required String prompt,
    required Schema schema,
    Uint8List? jpeg,
  }) async {
    await allowance.reserve();
    return client.generate(prompt: prompt, schema: schema, jpeg: jpeg);
  }
}
