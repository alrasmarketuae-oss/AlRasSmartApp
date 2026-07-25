import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const Color primaryColor = Color(0xffB4EAFA);
  static const Color darkBlue = Color(0xff0B0717);
  static const Color buttonColor = Color(0xFF37C7F3);

  static const Color grey = Colors.grey;
  static const Color grey24 = Color(0xFF242424);
  static const Color grey66 = Color(0xFF666666);
  static const Color grey75 = Color(0xff757575);
  static const Color greyED = Color(0xFFEDEDED);
  static final Color grey100 = Colors.grey.shade100;
  static final Color grey200 = Colors.grey.shade200;
  static final Color grey300 = Colors.grey.shade300;

  static const Color fillRed = Color(0xffFF4C5E);
  static const Color lightGrey = Color(0xffc2c2c2);
  static const Color lighterGrey = Color(0xffededed);
  static const Color moreLightGrey = Color(0xfffdfdff);
  static const Color darkBlue2 = Color(0xff4395ca);

  static const LinearGradient itemBackgroundGradient = LinearGradient(
    colors: [Color(0xff404B4C), Color(0xff85E9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  static const Color backgroundLight = Color(
    0xFFF2F7FF,
  ); // Very light background
  static const Color primaryDarkBlue = Color(0xFF2C2E83); // Strong dark blue
  static const Color pureBlackBlue = Color(0xFF03030A); // Deep black-blue
  static const Color greyMedium = Color(0xFF817E7E); // Medium grey
  static const Color pureWhite = Color(0xFFFFFFFF); // White
  static const Color black25Opacity = Color(
    0x40000000,
  ); // Black with 25% opacity
  static const Color successGreen = Color(
    0xFF249611,
  ); // Green for success or check
  static const Color pureBlack = Color(0xFF000000); // Black
  static const Color secondaryGreen = Color(
    0xFF068241,
  ); // Secondary darker green
  static const Color greyLightest = Color(0xFFEEEEEE); // Light grey for borders
  static const Color textDark = Color(0xFF141414); // Near-black for text
  static const Color errorRed = Color(0xFFEC2028); // Bright red for errors
  static const Color greyDark = Color(0xFF444444); // Dark grey
}
