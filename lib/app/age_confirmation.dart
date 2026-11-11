import 'package:shared_preferences/shared_preferences.dart';

/// Remembers on this phone that the user confirmed they are 18 or older, so
/// the welcome screen appears only on first launch.
class AgeConfirmation {
  const AgeConfirmation();

  static const key = 'age_confirmed_18_v1';

  Future<bool> isConfirmed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? false;
  }

  Future<void> confirm() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  /// Used by Delete all my data, so the welcome screen shows again.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
