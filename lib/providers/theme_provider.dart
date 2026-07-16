import 'package:flutter/material.dart';
import '../services/hive_service.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';

  ThemeMode _themeMode;

  ThemeProvider() : _themeMode = ThemeMode.system {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.system) {
      final window = WidgetsBinding.instance.window;
      return window.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  void _loadThemeMode() {
    final savedTheme = HiveService.settingsBox.get(_themeKey) as String?;
    if (savedTheme != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (e) => e.toString() == savedTheme,
        orElse: () => ThemeMode.system,
      );
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await HiveService.settingsBox.put(_themeKey, mode.toString());
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final isCurrentlyDark = isDarkMode;
    await setThemeMode(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }
}
