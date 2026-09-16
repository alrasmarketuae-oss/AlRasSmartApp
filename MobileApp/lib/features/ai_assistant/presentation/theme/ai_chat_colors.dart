import 'package:alrasmarket/core/theme/colors.dart';
import 'package:flutter/material.dart';

/// Assistant accent ramp, used across the header, avatars, and the send button
/// so the screen reads as an AI surface rather than a normal support chat.
const aiGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [LightColor.defaultColor, LightColor.lightBlue],
);

class AiChatColors {
  const AiChatColors({required this.isDark, this.planMode = false});

  final bool isDark;
  final bool planMode;

  factory AiChatColors.of(BuildContext context) => AiChatColors(
        isDark: Theme.of(context).brightness == Brightness.dark,
      );

  Color get scaffoldBg => planMode
      ? const Color(0xFF2A2208)
      : (isDark ? const Color(0xFF0B1220) : const Color(0xFFF6F8FC));

  Color get assistantBubbleBg => Colors.white;

  Color get assistantBorder =>
      isDark ? const Color(0xFFE6EAF2) : const Color(0xFFE6EAF2);

  Color get primaryText =>
      isDark ? const Color(0xFFE5E7EB) : const Color(0xFF1F2937);

  Color get mutedText =>
      isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  Color get composerBg => isDark ? const Color(0xFF0F172A) : Colors.white;

  Color get composerBorder =>
      isDark ? const Color(0xFF1F2937) : const Color(0xFFE6EAF2);

  Color get thinkingPanelBg =>
      planMode ? const Color(0xFF3A2F10) : Colors.white;

  Color get thinkingPanelBorder => planMode
      ? const Color(0xFFF0D48A)
      : const Color(0xFFE6EAF2);

  Color get thinkingText => planMode
      ? const Color(0xFFF8E7B0)
      : (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF));

  Color get pathCode =>
      planMode ? const Color(0xFFE6A817) : const Color(0xFF2E77CC);
}
