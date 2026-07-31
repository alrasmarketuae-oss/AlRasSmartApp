import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Status bar follows the page behind it (transparent fill).
/// On iOS, `statusBarColor` is ignored; Scaffold/page background shows through.
class StatusBarHelper {
  static const SystemUiOverlayStyle _transparentLight = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.light,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  static const SystemUiOverlayStyle _transparentDark = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarBrightness: Brightness.dark,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarDividerColor: Colors.transparent,
  );

  /// Set status bar style for light background (dark icons)
  static void setLightStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(_transparentLight);
  }

  /// Set status bar style for dark background (light icons)
  static void setDarkStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(_transparentDark);
  }

  /// Set status bar style with custom color (kept for callers; prefers transparent).
  static void setCustomStatusBar({
    Color? statusBarColor,
    Brightness? statusBarBrightness,
    Brightness? statusBarIconBrightness,
    Color? systemNavigationBarColor,
    Brightness? systemNavigationBarIconBrightness,
  }) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? Colors.transparent,
        statusBarBrightness: statusBarBrightness ?? Brightness.light,
        statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
        systemNavigationBarColor: systemNavigationBarColor ?? Colors.white,
        systemNavigationBarIconBrightness:
            systemNavigationBarIconBrightness ?? Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  /// App default: transparent so each page background fills the status bar area.
  static void setAppDefaultStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(_transparentLight);
  }
}
