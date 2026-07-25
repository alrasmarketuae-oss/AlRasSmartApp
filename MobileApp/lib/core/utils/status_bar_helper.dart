import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const Color _statusBarBackgroundColor = const Color.fromRGBO(242, 247, 255, 1);

/// Helper class to customize status bar style
class StatusBarHelper {
  /// Set status bar style for light background (dark icons)
  static void setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: _statusBarBackgroundColor,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _statusBarBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Color.fromARGB(0, 235, 98, 98),
      ),
    );
  }

  /// Set status bar style for dark background (light icons)
  static void setDarkStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: _statusBarBackgroundColor,
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _statusBarBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Color.fromARGB(0, 193, 42, 42),
      ),
    );
  }

  /// Set status bar style with custom color
  static void setCustomStatusBar({
    Color? statusBarColor,
    Brightness? statusBarBrightness,
    Brightness? statusBarIconBrightness,
    Color? systemNavigationBarColor,
    Brightness? systemNavigationBarIconBrightness,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? _statusBarBackgroundColor,
        statusBarBrightness: statusBarBrightness ?? Brightness.light,
        statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
        systemNavigationBarColor:
            systemNavigationBarColor ?? _statusBarBackgroundColor,
        systemNavigationBarIconBrightness:
            systemNavigationBarIconBrightness ?? Brightness.dark,
        systemNavigationBarDividerColor: _statusBarBackgroundColor,
      ),
    );
  }

  /// Set status bar with app default color
  static void setAppDefaultStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: _statusBarBackgroundColor,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: _statusBarBackgroundColor,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Color.fromARGB(0, 235, 98, 98),
      ),
    );
  }
}
