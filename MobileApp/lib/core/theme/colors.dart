import 'package:alrasmarket/core/theme/theme_controller.dart';
import 'package:flutter/material.dart';

class LightColor {
  static const Color defaultColor = Color(0xff3A7DC5);
  static const Color background = Color(0xFFF2F7FF);
  static Color hintColor = Color(0xff333333).withOpacity(0.5);
  static Color greyTextColor = Color(0xff333333).withOpacity(0.8);
  static Color greyTextColor60 = Color(0xff333333).withOpacity(0.6);
  static Color defultRed = Color(0xffC83D30);

  static const Color titleTextColor = Colors.black;

  static const Color subTitleTextColor = Color(0xff797878);

  static const Color skyBlue = Color(0xff2890c8);
  static const Color lightBlue = Color(0xff5c3dff);

  static const Color orange = Color(0xffE65829);

  static const Color lightGrey = Color(0xffE1E2E4);
  static const Color grey = Color(0xffA1A3A6);
  static const Color darkgrey = Color(0xff747F8F);

  static const Color iconColor = Color(0xffa8a09b);
  static const Color yellowColor = Color(0xfffbba01);

  static const Color black = Color(0xff20262C);
  static const Color lightblack = Color(0xff5F5F60);
  //
  static const Color surface = Colors.white; // Card background
  static const Color background2 = Color(0xFFFCFCFD); // Screen background
  static const Color success = Color(0xFFB7F2BD); // Light green background
  static const Color successDark = Color(0xFF389E0F); // Darker green text/icon
  static const Color iconColor2 = Color(0xFF5A5A5A);
}

class AppColors {
  static const Color _scaffoldDark = Color(0xFF0F1623);
  static const Color _cardDark = Color(0xFF1B2433);
  static const Color _navDark = Color(0xFF151C28);
  static const Color _titleDark = Color(0xFFE8EEF7);
  static const Color _subtitleDark = Color(0xFF9AA6B8);
  static const Color _borderDark = Color(0xFF2A3344);
  static const Color _iconSoftDark = Color(0xFF243044);
  static const Color _inputBorderDark = Color(0xFF3A4458);
  static const Color _inputBorderLight = Color(0xFFD5D9D9);
  static const Color _titleLight = Color(0xFF16233A);
  static const Color _subtitleLight = Color(0xFF7B8794);
  static const Color _borderLight = Color(0xFFE4EAF2);
  static const Color _iconSoftLight = Color(0xFFEAF3FB);

  static bool get dark => ThemeController.instance.isDark;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color get scaffoldColor =>
      dark ? _scaffoldDark : LightColor.background;

  static Color get cardColor => dark ? _cardDark : Colors.white;

  static Color get navBarColor => dark ? _navDark : Colors.white;

  static Color get titleColor => dark ? _titleDark : _titleLight;

  static Color get subtitleColor => dark ? _subtitleDark : _subtitleLight;

  static Color get borderColor => dark ? _borderDark : _borderLight;

  static Color get inputFillColor => dark ? _cardDark : Colors.white;

  static Color get inputBorderColor =>
      dark ? _inputBorderDark : _inputBorderLight;

  static Color get iconSoftColor => dark ? _iconSoftDark : _iconSoftLight;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? _scaffoldDark : LightColor.background;

  static Color card(BuildContext context) =>
      isDark(context) ? _cardDark : Colors.white;

  static Color navBar(BuildContext context) =>
      isDark(context) ? _navDark : Colors.white;

  static Color title(BuildContext context) =>
      isDark(context) ? _titleDark : _titleLight;

  static Color subtitle(BuildContext context) =>
      isDark(context) ? _subtitleDark : _subtitleLight;

  static Color border(BuildContext context) =>
      isDark(context) ? _borderDark : _borderLight;

  static Color inputFill(BuildContext context) =>
      isDark(context) ? _cardDark : Colors.white;

  static Color inputBorder(BuildContext context) =>
      isDark(context) ? _inputBorderDark : _inputBorderLight;

  static Color iconSoft(BuildContext context) =>
      isDark(context) ? _iconSoftDark : _iconSoftLight;
}
