import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the app's [ThemeMode] and persists it across launches.
///
/// The mode is read from disk before the first frame (see main.dart), so
/// the app never flashes the wrong theme on startup.
class ThemeController extends ChangeNotifier {
  static const String _key = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _mode;

  ThemeController(this._prefs) : _mode = _fromString(_prefs.getString(_key));

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    await _prefs.setString(_key, _toString(mode));
    notifyListeners();
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
