import 'package:firebase_app_check/firebase_app_check.dart';

/// Which App Check provider the app registers with Firebase.
enum AppCheckMode {
  /// Firebase's debug provider. The device's debug token must be authorized
  /// in the Firebase console (App Check > Manage debug tokens).
  debug('debug provider'),

  /// Play Integrity. Needs the release signing and Play distribution setup in
  /// docs/FIREBASE_STATUS.md.
  playIntegrity('Play Integrity');

  const AppCheckMode(this.label);

  /// A readable name for logs.
  final String label;
}

/// The provider chosen at build time, for example:
///
///     flutter build apk --release --dart-define=APP_CHECK=debug
///
/// Use `debug` for a release or profile APK that is installed directly on a
/// phone (not from Google Play), such as a demo build. Leave it unset to get
/// the debug provider in debug builds and Play Integrity otherwise.
const appCheckSetting = String.fromEnvironment('APP_CHECK');

/// Works out the provider from the build type and the `APP_CHECK` setting.
///
/// Throws an [ArgumentError] for an unknown setting, so a typo stops startup
/// instead of quietly choosing the wrong provider.
AppCheckMode appCheckModeFor({
  required bool debugBuild,
  String setting = appCheckSetting,
}) {
  return switch (setting.trim().toLowerCase()) {
    '' => debugBuild ? AppCheckMode.debug : AppCheckMode.playIntegrity,
    'debug' => AppCheckMode.debug,
    'play-integrity' || 'playintegrity' => AppCheckMode.playIntegrity,
    _ => throw ArgumentError.value(
      setting,
      'APP_CHECK',
      "Use 'debug' or 'play-integrity'.",
    ),
  };
}

/// The Android provider for [mode]. No debug token is built into the app;
/// each device's token is authorized in the Firebase console instead.
AndroidAppCheckProvider androidAppCheckProvider(AppCheckMode mode) =>
    switch (mode) {
      AppCheckMode.debug => const AndroidDebugProvider(),
      AppCheckMode.playIntegrity => const AndroidPlayIntegrityProvider(),
    };
