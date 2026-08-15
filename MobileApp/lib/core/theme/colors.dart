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
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color scaffold(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F1623) : LightColor.background;

  static Color card(BuildContext context) =>
      isDark(context) ? const Color(0xFF1B2433) : Colors.white;

  static Color navBar(BuildContext context) =>
      isDark(context) ? const Color(0xFF151C28) : Colors.white;

  static Color title(BuildContext context) =>
      isDark(context) ? const Color(0xFFE8EEF7) : const Color(0xFF16233A);

  static Color subtitle(BuildContext context) =>
      isDark(context) ? const Color(0xFF9AA6B8) : const Color(0xFF7B8794);

  static Color border(BuildContext context) =>
      isDark(context) ? const Color(0xFF2A3344) : const Color(0xFFE4EAF2);
}
