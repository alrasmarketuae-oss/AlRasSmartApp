import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Forest green primary (matches Merge home chrome).
const Color _defaultAppColor = Color(0xFF2D5A27);
const MaterialColor _defaultAppSwatch = MaterialColor(0xFF2D5A27, {
  50: Color(0xFFE8F0E6),
  100: Color(0xFFC6DBC2),
  200: Color(0xFFA0C49A),
  300: Color(0xFF7AAD71),
  400: Color(0xFF5C9C53),
  500: Color(0xFF2D5A27),
  600: Color(0xFF285223),
  700: Color(0xFF22481D),
  800: Color(0xFF1C3E18),
  900: Color(0xFF112E0E),
});

ThemeData lightTheme(Locale locale) {
  final appFontFamily = AppFonts.familyFor(locale);
  final base = ThemeData(
    useMaterial3: true,
    primaryColor: _defaultAppColor,
    primarySwatch: _defaultAppSwatch,
    fontFamily: appFontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _defaultAppColor,
      primary: _defaultAppColor,
      secondary: _defaultAppColor,
    ),
    scaffoldBackgroundColor: LightColor.background,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _defaultAppColor,
      circularTrackColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      titleSpacing: 20.0,
      backgroundColor: LightColor.background,
      elevation: 0.0,
      titleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 25,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: _defaultAppColor,
      unselectedItemColor: const Color(0xFF8A7A5C),
      elevation: 20,
      selectedLabelStyle: TextStyle(fontFamily: appFontFamily),
      unselectedLabelStyle: TextStyle(fontFamily: appFontFamily),
    ),
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(fontFamily: appFontFamily),
    primaryTextTheme: base.primaryTextTheme.apply(fontFamily: appFontFamily),
  );
}
