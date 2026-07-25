import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Default app color
const Color _defaultAppColor = Color(0xff3A7DC5);
const MaterialColor _defaultAppSwatch = MaterialColor(0xff3A7DC5, {
  50: Color(0xFFE7F0F9),
  100: Color(0xFFC3DBF0),
  200: Color(0xFF9BC4E7),
  300: Color(0xFF73ADDD),
  400: Color(0xFF559BD6),
  500: Color(0xFF3A7DC5),
  600: Color(0xFF3575BF),
  700: Color(0xFF2D6AB8),
  800: Color(0xFF265FB0),
  900: Color(0xFF194CA3),
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
    scaffoldBackgroundColor: const Color(0xffF2F7FF),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _defaultAppColor,
      circularTrackColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      titleSpacing: 20.0,
      backgroundColor: Colors.white,
      elevation: 0.0,
      titleTextStyle: TextStyle(
        fontFamily: appFontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 25,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Color.fromARGB(0, 133, 16, 16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: _defaultAppColor,
      unselectedItemColor: const Color(0xff999999),
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
