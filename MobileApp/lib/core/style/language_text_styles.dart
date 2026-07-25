import 'package:alrasmarket/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';

import 'text_styles.dart';

/// A utility class that provides language-aware text styles.
/// This handles the font family difference between Arabic and English.
/// For Arabic, it uses the same style as English but with Cairo font family.
class LanguageTextStyles {
  /// Get the appropriate text style based on the current language
  /// and the requested style type.
  static TextStyle getStyle({
    required String langValue,
    required TextStyleType type,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    TextDecoration? decoration,
    double? height,
    double? letterSpacing,
    FontStyle? fontStyle,
    Color? decorationColor,
  }) {
    // Get the base style based on type
    TextStyle baseStyle = _getBaseStyle(type);

  baseStyle = baseStyle.copyWith(
      fontFamily: AppFonts.familyForLanguageCode(langValue),
    );

    // Apply additional modifications if provided
    return baseStyle.copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      decoration: decoration,
      height: height,
      letterSpacing: letterSpacing,
      fontStyle: fontStyle,
      decorationColor: decorationColor,
    );
  }

  /// Get the base TextStyle based on style type
  static TextStyle _getBaseStyle(TextStyleType type) {
    switch (type) {
      // Poppins styles
      case TextStyleType.poppinsBold13:
        return TextStyles.poppinsBold13;
      case TextStyleType.poppinsLight12:
        return TextStyles.poppinsLight12;
      case TextStyleType.poppinsBold14:
        return TextStyles.poppinsBold14;
      case TextStyleType.poppinsBold23:
        return TextStyles.poppinsBold23;
      case TextStyleType.poppinsSemiBold13:
        return TextStyles.poppinsSemiBold13;
      case TextStyleType.poppinsRegular10:
        return TextStyles.poppinsRegular10;
      case TextStyleType.poppinsRegular13:
        return TextStyles.poppinsRegular13;
      case TextStyleType.poppinsRegular12:
        return TextStyles.poppinsRegular12;
      case TextStyleType.poppinsRegular14:
        return TextStyles.poppinsRegular14;
      case TextStyleType.poppinsRegular15:
        return TextStyles.poppinsRegular15;
      case TextStyleType.poppinsBold16:
        return TextStyles.poppinsBold16;
      case TextStyleType.poppinsBold19:
        return TextStyles.poppinsBold19;
      case TextStyleType.poppinsSemiBold16:
        return TextStyles.poppinsSemiBold16;
      case TextStyleType.poppinsSemiBold18:
        return TextStyles.poppinsSemiBold18;
      case TextStyleType.poppinsBold28:
        return TextStyles.poppinsBold28;
      case TextStyleType.poppinsRegular22:
        return TextStyles.poppinsRegular22;
      case TextStyleType.poppinsSemiBold11:
        return TextStyles.poppinsSemiBold11;
      case TextStyleType.poppinsMedium12:
        return TextStyles.poppinsMedium12;
      case TextStyleType.poppinsMedium14:
        return TextStyles.poppinsMedium14;
      case TextStyleType.poppinsMedium15:
        return TextStyles.poppinsMedium15;
      case TextStyleType.poppinsMedium16:
        return TextStyles.poppinsMedium16;
      case TextStyleType.poppinsMedium20:
        return TextStyles.poppinsMedium20;

      case TextStyleType.poppinsMedium24:
        return TextStyles.poppinsMedium24;
      case TextStyleType.poppinsRegular26:
        return TextStyles.poppinsRegular26;
      case TextStyleType.poppinsRegular16:
        return TextStyles.poppinsRegular16;
      case TextStyleType.poppinsRegular11:
        return TextStyles.poppinsRegular11;
      case TextStyleType.poppinsMedium14_:
        return TextStyles.poppinsMedium14_;
      case TextStyleType.poppinsRegular12_:
        return TextStyles.poppinsRegular12_;
      case TextStyleType.poppinsBold14_:
        return TextStyles.poppinsBold14_;
      case TextStyleType.poppinsSemiBold14:
        return TextStyles.poppinsSemiBold14;
      case TextStyleType.poppinsBold24:
        return TextStyles.poppinsBold24;
      case TextStyleType.poppinsBold36:
        return TextStyles.poppinsBold36;

      // Jakarta styles
      case TextStyleType.jakartaMedium14:
        return TextStyles.jakartaMedium14;
      case TextStyleType.jakartaMedium16:
        return TextStyles.jakartaMedium16;
      case TextStyleType.jakartaMedium32:
        return TextStyles.jakartaMedium32;
      case TextStyleType.jakartaMedium36:
        return TextStyles.jakartaMedium36;
      case TextStyleType.jakartaRegular12:
        return TextStyles.jakartaRegular12;
      case TextStyleType.jakartaSemiBold14:
        return TextStyles.jakartaSemiBold14;
      case TextStyleType.jakartaSemiBold16:
        return TextStyles.jakartaSemiBold16;
      case TextStyleType.jakartaMedium20:
        return TextStyles.jakartaMedium20;
      case TextStyleType.jakartaMedium24:
        return TextStyles.jakartaMedium24;

      // Inter styles
      case TextStyleType.interSemiBold14:
        return TextStyles.interSemiBold14;
      case TextStyleType.interMedium14:
        return TextStyles.interMedium14;
      case TextStyleType.interMedium24:
        return TextStyles.interMedium24;
      case TextStyleType.interBold14:
        return TextStyles.interBold14;
      case TextStyleType.interRegular12:
        return TextStyles.interRegular12;
      case TextStyleType.interSemiBold15:
        return TextStyles.interSemiBold15;
      case TextStyleType.interRegular32:
        return TextStyles.interRegular32;

      // Cairo styles (will be used directly for Arabic)
      case TextStyleType.cairoMedium14:
        return TextStyles.cairoMedium14;
      case TextStyleType.cairoMedium16:
        return TextStyles.cairoMedium16;
      case TextStyleType.cairoMedium32:
        return TextStyles.cairoMedium32;

      // El Messiri styles
      case TextStyleType.elMessiriRegular14:
        return TextStyles.elMessiriRegular14;
      case TextStyleType.elMessiriMedium14:
        return TextStyles.elMessiriMedium14;

      // Roboto styles
      case TextStyleType.robotoRegular12:
        return TextStyles.robotoRegular12;

      // Fallback
      default:
        return TextStyles.jakartaMedium14;
    }
  }
}

/// Enum representing different text style types in the application
/// Matches the variable names from TextStyles class
enum TextStyleType {
  // Poppins styles
  poppinsBold13,
  poppinsLight12,
  poppinsBold14,
  poppinsBold23,
  poppinsSemiBold13,
  poppinsRegular10,
  poppinsRegular13,
  poppinsRegular12,
  poppinsRegular14,
  poppinsRegular15,
  poppinsBold16,
  poppinsBold19,
  poppinsSemiBold16,
  poppinsSemiBold18,
  poppinsBold28,
  poppinsRegular22,
  poppinsSemiBold11,
  poppinsMedium12,
  poppinsMedium14,
  poppinsMedium15,
  poppinsMedium16,
  poppinsMedium20,

  poppinsMedium24,
  poppinsRegular26,
  poppinsRegular16,
  poppinsRegular11,
  poppinsMedium14_,
  poppinsRegular12_,
  poppinsBold14_,
  poppinsSemiBold14,
  poppinsBold24,
  poppinsBold36,

  // Jakarta styles
  jakartaMedium14,
  jakartaMedium16,
  jakartaMedium32,
  jakartaMedium36,
  jakartaRegular12,
  jakartaSemiBold14,
  jakartaSemiBold16,
  jakartaMedium20,
  jakartaMedium24,

  // Inter styles
  interSemiBold14,
  interMedium14,
  interMedium24,
  interBold14,
  interRegular12,
  interSemiBold15,
  interRegular32,

  // Cairo styles
  cairoMedium14,
  cairoMedium16,
  cairoMedium32,

  // El Messiri styles
  elMessiriRegular14,
  elMessiriMedium14,

  // Roboto styles
  robotoRegular12,
}
