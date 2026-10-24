import 'package:flutter/material.dart';

enum ExpiryStatus { unknown, expired, soon, ok }

/// 有效期状态：已过期 / 90 天内到期 / 正常 / 未知
class Expiry {
  static const soonDays = 90;

  static ExpiryStatus status(DateTime? date, {DateTime? now}) {
    if (date == null) return ExpiryStatus.unknown;
    final today = DateUtils.dateOnly(now ?? DateTime.now());
    final d = DateUtils.dateOnly(date);
    if (d.isBefore(today)) return ExpiryStatus.expired;
    if (d.difference(today).inDays <= soonDays) return ExpiryStatus.soon;
    return ExpiryStatus.ok;
  }

  static int daysLeft(DateTime date, {DateTime? now}) =>
      DateUtils.dateOnly(date).difference(DateUtils.dateOnly(now ?? DateTime.now())).inDays;

  static String label(DateTime? date) {
    switch (status(date)) {
      case ExpiryStatus.unknown:
        return '有效期未识别';
      case ExpiryStatus.expired:
        return '已过期，请勿服用';
      case ExpiryStatus.soon:
        final n = daysLeft(date!);
        return n == 0 ? '今天到期' : '还有 $n 天到期';
      case ExpiryStatus.ok:
        return '在有效期内';
    }
  }

  static Color color(DateTime? date) {
    switch (status(date)) {
      case ExpiryStatus.unknown:
        return Colors.grey.shade700;
      case ExpiryStatus.expired:
        return Colors.red.shade700;
      case ExpiryStatus.soon:
        return Colors.orange.shade800;
      case ExpiryStatus.ok:
        return Colors.green.shade700;
    }
  }

  static IconData icon(DateTime? date) {
    switch (status(date)) {
      case ExpiryStatus.unknown:
        return Icons.help_outline;
      case ExpiryStatus.expired:
        return Icons.dangerous_outlined;
      case ExpiryStatus.soon:
        return Icons.warning_amber_rounded;
      case ExpiryStatus.ok:
        return Icons.check_circle_outline;
    }
  }

  static String format(DateTime? date) =>
      date == null ? '未识别' : '${date.year}年${date.month}月${date.day}日';
}
