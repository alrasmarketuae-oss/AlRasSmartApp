/// UTC-safe date/time helpers for API timestamps.
///
/// Backend stores and sends UTC. Values without a timezone offset are treated
/// as UTC (not device-local) so China/UAE/etc. server OS clocks stay correct.
class UtcDateTime {
  UtcDateTime._();

  /// Parse API datetime as UTC. Accepts ISO with Z, offsets, or naive UTC strings.
  static DateTime? parseAsUtc(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final hasExplicitZone = trimmed.endsWith('Z') ||
        trimmed.endsWith('z') ||
        RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(trimmed);

    var candidate = trimmed;
    if (!hasExplicitZone) {
      // "yyyy-MM-dd HH:mm:ss" or "yyyy-MM-ddTHH:mm:ss" from older API → UTC.
      candidate = trimmed.contains('T')
          ? '${trimmed}Z'
          : '${trimmed.replaceFirst(' ', 'T')}Z';
    }

    final parsed = DateTime.tryParse(candidate);
    return parsed?.toUtc();
  }

  /// Absolute date+time in the device local zone (converted from UTC).
  static String formatDateTimeLocal(String? raw) {
    final utc = parseAsUtc(raw);
    if (utc == null) return '';
    final local = utc.toLocal();
    final dd = local.day.toString().padLeft(2, '0');
    final mm = local.month.toString().padLeft(2, '0');
    final yyyy = local.year.toString();
    final hh = local.hour.toString().padLeft(2, '0');
    final min = local.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$min';
  }

  /// Relative age vs [DateTime.now] in UTC.
  static String formatRelativeUtc(
    String? raw, {
    required String Function(int hours) hoursAgo,
    String justNow = 'Just now',
    String Function(int days)? daysAgo,
    String Function(int minutes)? minutesAgo,
  }) {
    final utc = parseAsUtc(raw);
    if (utc == null) return '';

    final diff = DateTime.now().toUtc().difference(utc);
    if (diff.isNegative || diff.inSeconds < 60) {
      return justNow;
    }
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return minutesAgo?.call(m) ?? '$m min ago';
    }
    if (diff.inHours < 24) {
      return hoursAgo(diff.inHours);
    }
    final d = diff.inDays;
    return daysAgo?.call(d) ?? (d == 1 ? '1 day ago' : '$d days ago');
  }
}
