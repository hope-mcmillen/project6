import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Debug-only, human-readable log lines for following what the app is doing.
///
/// Every line starts with `[FitCheck]`, so it is easy to spot in the
/// `flutter run` output or to filter with
/// `adb logcat | grep FitCheck`. Lines look like:
///
///     [FitCheck] 14:02:31.415 TAP  "Save to closet" on Review Tags
///     [FitCheck] 14:02:31.420 DATA Closet: saving item 1730... (top)
///
/// Never log photos, App Check tokens, API keys, or other secrets.
abstract final class AppLog {
  /// Logging is on in debug builds only. Tests turn it off.
  static bool enabled = kDebugMode;

  /// Where finished lines go. Tests can swap this to capture them.
  static void Function(String line) sink = _print;

  static void _print(String line) => debugPrint(line);

  /// A button, chip, card, or menu the user tapped.
  static void tap(String control, {required String screen}) =>
      _write('TAP ', '"$control" on $screen');

  /// A page, dialog, or tab change.
  static void nav(String message) => _write('NAV ', message);

  /// Something a screen did in response to the user.
  static void ui(String message) => _write('UI  ', message);

  /// Firestore reads and writes.
  static void data(String message) => _write('DATA', message);

  /// Firebase AI calls.
  static void ai(String message) => _write('AI  ', message);

  /// Firebase startup, sign-in, and App Check.
  static void app(String message) => _write('APP ', message);

  static void _write(String kind, String message) {
    if (!enabled) return;
    sink('[FitCheck] ${_time(DateTime.now())} $kind $message');
  }

  static String _time(DateTime t) {
    String pad(int value, [int width = 2]) =>
        value.toString().padLeft(width, '0');
    return '${pad(t.hour)}:${pad(t.minute)}:${pad(t.second)}'
        '.${pad(t.millisecond, 3)}';
  }
}

/// Logs every page and dialog that opens or closes.
///
/// Name a route with a path, such as `RouteSettings(name: '/review-tags')`,
/// to get a readable label. The navigator parses names as URLs, so plain
/// text with spaces does not work. Unnamed pages and popups are still logged.
class AppNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final from = previousRoute == null
        ? ''
        : ' from ${describeRoute(previousRoute)}';
    AppLog.nav('Opened ${describeRoute(route)}$from');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLog.nav(
      'Closed ${describeRoute(route)}, back on ${describeRoute(previousRoute)}',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLog.nav(
      'Replaced ${describeRoute(oldRoute)} with ${describeRoute(newRoute)}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLog.nav('Removed ${describeRoute(route)}');
  }
}

/// A readable label for a route in the logs.
String describeRoute(Route<dynamic>? route) {
  if (route == null) return 'nothing';
  final name = route.settings.name;
  if (name == '/') return 'the app home (tabs)';
  if (name != null) {
    // '/review-tags' -> 'Review Tags'
    return name
        .replaceAll('/', ' ')
        .replaceAll('-', ' ')
        .trim()
        .split(' ')
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
  if (route is PopupRoute) return 'a popup';
  return 'an unnamed page';
}
