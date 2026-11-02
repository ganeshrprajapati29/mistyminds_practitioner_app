import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Formatting helpers so every screen shows money, dates and durations the
/// same way.
abstract final class Fmt {
  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _inrPrecise = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// ₹8,400 — Indian digit grouping, no paise.
  static String inr(num amount) => _inr.format(amount);

  static String money(num amount) =>
      amount == amount.roundToDouble() ? inr(amount) : _inrPrecise.format(amount);

  /// 6:00 PM
  static String time(DateTime t) => DateFormat('h:mm a').format(t);

  static String timeOfDay(TimeOfDay t) =>
      time(DateTime(2000, 1, 1, t.hour, t.minute));

  /// 21 Sep
  static String shortDate(DateTime d) => DateFormat('d MMM').format(d);

  /// Wed, 24 Sep
  static String dayDate(DateTime d) => DateFormat('EEE, d MMM').format(d);

  /// Friday, 4 September
  static String longDate(DateTime d) => DateFormat('EEEE, d MMMM').format(d);

  /// September 2026
  static String monthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);

  /// 1h 42m / 45m / 2 hours
  static String hm(Duration d) {
    final int h = d.inHours;
    final int m = d.inMinutes.remainder(60);
    if (h == 0) return '${m}m';
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  static String hoursLabel(Duration d) {
    final int minutes = d.inMinutes;
    if (minutes % 60 == 0) {
      final int h = minutes ~/ 60;
      return h == 1 ? '1 hour' : '$h hours';
    }
    return hm(d);
  }

  /// 04:32 or 1:04:32 — a running call timer.
  static String clock(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final int h = d.inHours;
    final String ms =
        '${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}';
    return h > 0 ? '$h:$ms' : ms;
  }

  /// "just now", "5 min ago", "2 h ago", "Yesterday", "21 Sep".
  static String ago(DateTime t, {DateTime? now}) {
    final Duration diff = (now ?? DateTime.now()).difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return shortDate(t);
  }

  static bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
