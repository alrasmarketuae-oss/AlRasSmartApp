import 'package:alrasmarket/core/utils/utc_date_time.dart';
import 'package:alrasmarket/generated/l10n.dart';

/// Localized relative timestamps: "1 hour ago" / "منذ ساعة", etc.
class RelativeTimeFormatter {
  RelativeTimeFormatter._();

  static String format(S s, String? raw) {
    final utc = UtcDateTime.parseAsUtc(raw);
    if (utc == null) return '';
    return formatFromUtc(s, utc);
  }

  static String formatFromUtc(S s, DateTime utc) {
    final diff = DateTime.now().toUtc().difference(utc.toUtc());
    if (diff.isNegative) return s.justNow;

    final seconds = diff.inSeconds;
    if (seconds < 60) {
      return seconds <= 1 ? s.oneSecondAgo : s.secondsAgo(seconds);
    }

    final minutes = diff.inMinutes;
    if (minutes < 60) {
      return minutes == 1 ? s.oneMinuteAgo : s.minutesAgo(minutes);
    }

    final hours = diff.inHours;
    if (hours < 24) {
      return hours == 1 ? s.oneHourAgo : s.hoursAgoRelative(hours);
    }

    final days = diff.inDays;
    if (days < 7) {
      return days == 1 ? s.oneDayAgo : s.daysAgo(days);
    }

    final weeks = days ~/ 7;
    if (weeks < 4) {
      return weeks == 1 ? s.oneWeekAgo : s.weeksAgo(weeks);
    }

    final months = days ~/ 30;
    if (months < 12) {
      if (months == 1) return s.oneMonthAgo;
      if (months == 2) return s.twoMonthsAgo;
      return s.monthsAgo(months);
    }

    final years = days ~/ 365;
    return years == 1 ? s.oneYearAgo : s.yearsAgo(years);
  }

  static String formatFromLocalMs(S s, int createdAtMs) {
    return formatFromUtc(
      s,
      DateTime.fromMillisecondsSinceEpoch(createdAtMs).toUtc(),
    );
  }
}
