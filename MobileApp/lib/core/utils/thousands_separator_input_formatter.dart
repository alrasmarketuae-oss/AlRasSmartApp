import 'package:flutter/services.dart';

/// Formats large numbers while typing (e.g. `1000000` → `1,000,000`) and
/// provides parse helpers that strip separators before API submission.
class ThousandsNumberInput {
  ThousandsNumberInput._();

  static final RegExp separatorPattern = RegExp(r'[,\s٬\u00A0]');

  /// Removes thousand separators and normalizes Arabic/Persian digits.
  static String strip(String? raw) {
    if (raw == null) return '';
    final buffer = StringBuffer();
    for (final code in raw.trim().runes) {
      final ch = String.fromCharCode(code);
      if (separatorPattern.hasMatch(ch)) continue;
      if (code >= 0x0660 && code <= 0x0669) {
        buffer.write(String.fromCharCode(0x30 + (code - 0x0660)));
        continue;
      }
      if (code >= 0x06F0 && code <= 0x06F9) {
        buffer.write(String.fromCharCode(0x30 + (code - 0x06F0)));
        continue;
      }
      buffer.write(ch);
    }
    return buffer.toString();
  }

  static final RegExp _numberPattern = RegExp(r'-?\d+(?:\.\d+)?');

  /// Parses amounts that may include thousand separators and/or currency text
  /// (e.g. `6,000`, `6,000.50 USD`, `AED 1500`).
  static double? parseDouble(String? raw) {
    final cleaned = strip(raw);
    if (cleaned.isEmpty) return null;
    final direct = double.tryParse(cleaned);
    if (direct != null) return direct;
    final match = _numberPattern.firstMatch(cleaned);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  static int? parseInt(String? raw) {
    final asDouble = parseDouble(raw);
    if (asDouble == null) return null;
    if (asDouble == asDouble.roundToDouble()) return asDouble.round();
    return null;
  }

  /// Safe parse for API/model numeric fields that may arrive as formatted text.
  static double parseDoubleOrZero(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return parseDouble(value.toString()) ?? 0;
  }

  /// Formats a number for display in edit forms / controllers.
  /// Fractional money amounts keep two digits (`.50` not `.5`).
  static String format(num value, {bool allowDecimal = true}) {
    if (!allowDecimal || value == value.roundToDouble()) {
      return groupInteger(value.round().toString());
    }
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');
    final decimals = parts.length > 1 ? parts[1] : '00';
    final grouped = groupInteger(parts.first);
    return '$grouped.$decimals';
  }

  static String formatRaw(String? raw, {bool allowDecimal = true}) {
    final cleaned = strip(raw);
    if (cleaned.isEmpty) return '';
    final value = allowDecimal
        ? double.tryParse(cleaned)
        : int.tryParse(cleaned)?.toDouble();
    if (value == null) return cleaned;
    return format(value, allowDecimal: allowDecimal);
  }

  static String groupInteger(String digits) {
    final negative = digits.startsWith('-');
    var body = negative ? digits.substring(1) : digits;
    body = body.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (body.isEmpty) body = '0';
    final buffer = StringBuffer();
    for (var i = 0; i < body.length; i++) {
      final fromEnd = body.length - i;
      if (i > 0 && fromEnd % 3 == 0) buffer.write(',');
      buffer.write(body[i]);
    }
    return negative ? '-${buffer.toString()}' : buffer.toString();
  }
}

/// Live thousand-separator formatter for create-ad quantity / price fields.
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  ThousandsSeparatorInputFormatter({this.allowDecimal = true});

  final bool allowDecimal;

  static ThousandsSeparatorInputFormatter quantity() =>
      ThousandsSeparatorInputFormatter(allowDecimal: false);

  static ThousandsSeparatorInputFormatter price() =>
      ThousandsSeparatorInputFormatter(allowDecimal: true);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.trim().isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final selectionIndex = newValue.selection.end.clamp(0, raw.length);
    var digitsBeforeCaret = 0;
    var decimalBeforeCaret = false;
    for (var i = 0; i < selectionIndex; i++) {
      final ch = raw[i];
      if (_isDigitRune(ch.codeUnitAt(0)) || _isDigit(ch)) {
        digitsBeforeCaret++;
      } else if (allowDecimal && ch == '.') {
        decimalBeforeCaret = true;
      } else {
        final code = ch.codeUnitAt(0);
        if (code >= 0x0660 && code <= 0x0669 ||
            code >= 0x06F0 && code <= 0x06F9) {
          digitsBeforeCaret++;
        }
      }
    }

    final cleaned = _sanitize(raw);
    if (cleaned.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final formatted = _formatCleaned(cleaned);
    final caret = _caretOffset(
      formatted,
      digitsBeforeCaret,
      afterDecimal: decimalBeforeCaret && cleaned.contains('.'),
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: caret),
    );
  }

  String _sanitize(String input) {
    final buffer = StringBuffer();
    var hasDecimal = false;
    for (final code in input.runes) {
      if (ThousandsNumberInput.separatorPattern
          .hasMatch(String.fromCharCode(code))) {
        continue;
      }

      String? digit;
      if (code >= 0x30 && code <= 0x39) {
        digit = String.fromCharCode(code);
      } else if (code >= 0x0660 && code <= 0x0669) {
        digit = String.fromCharCode(0x30 + (code - 0x0660));
      } else if (code >= 0x06F0 && code <= 0x06F9) {
        digit = String.fromCharCode(0x30 + (code - 0x06F0));
      } else if (allowDecimal && code == 0x2E && !hasDecimal) {
        buffer.write('.');
        hasDecimal = true;
        continue;
      }

      if (digit != null) buffer.write(digit);
    }
    return buffer.toString();
  }

  String _formatCleaned(String cleaned) {
    String integerPart;
    String? decimalPart;
    final endsWithDot = cleaned.endsWith('.');
    if (allowDecimal && cleaned.contains('.')) {
      final parts = cleaned.split('.');
      integerPart = parts.first;
      decimalPart = parts.length > 1 ? parts.sublist(1).join() : '';
    } else {
      integerPart = cleaned;
      decimalPart = null;
    }

    integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    if (integerPart.isEmpty) integerPart = '0';

    final grouped = ThousandsNumberInput.groupInteger(integerPart);
    if (!allowDecimal || decimalPart == null) return grouped;
    if (endsWithDot && decimalPart.isEmpty) return '$grouped.';
    return decimalPart.isEmpty ? grouped : '$grouped.$decimalPart';
  }

  int _caretOffset(
    String formatted,
    int digitCount, {
    required bool afterDecimal,
  }) {
    if (digitCount <= 0 && !afterDecimal) return 0;

    var seenDigits = 0;
    var passedDecimal = false;
    for (var i = 0; i < formatted.length; i++) {
      final ch = formatted[i];
      if (_isDigit(ch)) {
        seenDigits++;
        if (seenDigits == digitCount) {
          if (afterDecimal && !passedDecimal) {
            // Still need to land after the decimal point.
            continue;
          }
          return i + 1;
        }
      } else if (ch == '.') {
        passedDecimal = true;
        if (afterDecimal && seenDigits == digitCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }

  static bool _isDigit(String ch) =>
      ch.compareTo('0') >= 0 && ch.compareTo('9') <= 0;

  static bool _isDigitRune(int code) => code >= 0x30 && code <= 0x39;
}
