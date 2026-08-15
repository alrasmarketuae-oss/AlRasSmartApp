import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/utils/status_bar_helper.dart';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'themeMode';

  ThemeMode mode = ThemeMode.light;

  Future<void> load() async {
    final raw = CachHelper.getData(_key)?.toString();
    mode = switch (raw) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    _syncStatusBar();
  }

  bool get isDark {
    if (mode == ThemeMode.dark) return true;
    if (mode == ThemeMode.light) return false;
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }

  Future<void> setDark(bool dark) async {
    mode = dark ? ThemeMode.dark : ThemeMode.light;
    await CachHelper.saveData(key: _key, value: dark ? 'dark' : 'light');
    _syncStatusBar();
    notifyListeners();
  }

  void _syncStatusBar() {
    if (isDark) {
      StatusBarHelper.setDarkStatusBar();
    } else {
      StatusBarHelper.setLightStatusBar();
    }
  }
}
