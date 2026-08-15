import 'package:alrasmarket/core/helper/cach_helper.dart';
import 'package:alrasmarket/core/utils/status_bar_helper.dart';
import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._();
  static final ThemeController instance = ThemeController._();

  static const _key = 'themeMode';

  ThemeMode mode = ThemeMode.light;

  Future<void> load() async {
    mode = ThemeMode.light;
    await CachHelper.saveData(key: _key, value: 'light');
    _syncStatusBar();
  }

  bool get isDark => false;

  void _syncStatusBar() {
    StatusBarHelper.setLightStatusBar();
  }
}
