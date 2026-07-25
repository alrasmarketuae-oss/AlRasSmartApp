import 'package:alrasmarket/generated/l10n.dart';

/// Packing weight in kg, stored as tinyint (1–255). Null / 0 = none.
class CreateAdPackingOptions {
  CreateAdPackingOptions._();

  static const int maxValue = 255;
  static const String unit = 'kg';

  static int? normalize(int? value) {
    if (value == null || value <= 0) return null;
    if (value > maxValue) return null;
    return value;
  }

  static int? parseInput(String? raw) {
    final text = raw?.trim() ?? '';
    if (text.isEmpty) return null;
    return normalize(int.tryParse(text));
  }

  static String displayText(int? packaging, {S? s}) {
    final kg = normalize(packaging);
    if (kg == null) return '';
    return '$kg kg';
  }
}
