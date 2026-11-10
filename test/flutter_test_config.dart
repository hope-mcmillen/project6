import 'dart:async';

import 'package:fitcheck_ai/core/logging/app_log.dart';

/// Keeps the debug log out of test output. Logging tests turn it back on.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppLog.enabled = false;
  await testMain();
}
