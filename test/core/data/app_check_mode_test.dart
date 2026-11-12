import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:fitcheck_ai/core/data/app_check_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('with no APP_CHECK setting, the build type decides', () {
    expect(appCheckModeFor(debugBuild: true, setting: ''), AppCheckMode.debug);
    expect(
      appCheckModeFor(debugBuild: false, setting: ''),
      AppCheckMode.playIntegrity,
    );
  });

  test('APP_CHECK=debug lets a sideloaded release build use debug tokens', () {
    expect(
      appCheckModeFor(debugBuild: false, setting: 'debug'),
      AppCheckMode.debug,
    );
    expect(
      appCheckModeFor(debugBuild: false, setting: ' Debug '),
      AppCheckMode.debug,
    );
  });

  test('APP_CHECK=play-integrity forces Play Integrity in any build', () {
    expect(
      appCheckModeFor(debugBuild: true, setting: 'play-integrity'),
      AppCheckMode.playIntegrity,
    );
  });

  test('an unknown APP_CHECK value is rejected, not silently ignored', () {
    expect(
      () => appCheckModeFor(debugBuild: false, setting: 'debgu'),
      throwsArgumentError,
    );
  });

  test('each mode maps to the matching Android provider', () {
    expect(
      androidAppCheckProvider(AppCheckMode.debug),
      isA<AndroidDebugProvider>(),
    );
    expect(
      androidAppCheckProvider(AppCheckMode.playIntegrity),
      isA<AndroidPlayIntegrityProvider>(),
    );
  });

  test('builds without the define keep the old behavior', () {
    // `flutter test` passes no APP_CHECK define, so the default is empty.
    expect(appCheckSetting, isEmpty);
  });
}
