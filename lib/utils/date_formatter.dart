import 'package:intl/intl.dart';

/// Date formatting utilities
class DateFormatter {
  static final _dayMonthYear =
      DateFormat('dd MMM yyyy', 'id_ID');
  static final _dayMonth = DateFormat('dd MMM', 'id_ID');
  static final _fullDay =
      DateFormat('EEEE, dd MMMM yyyy', 'id_ID');
  static final _monthYear = DateFormat('MMMM yyyy', 'id_ID');
  static final _time = DateFormat('HH:mm');

  /// "25 Jan 2025"
  static String short(DateTime date) => _dayMonthYear.format(date);

  /// "25 Jan"
  static String dayMonth(DateTime date) => _dayMonth.format(date);

  /// "Senin, 25 Januari 2025"
  static String full(DateTime date) => _fullDay.format(date);

  /// "Januari 2025"
  static String monthYear(DateTime date) => _monthYear.format(date);

  /// "14:30"
  static String time(DateTime date) => _time.format(date);

  /// Relative: "Hari ini", "Besok", "3 hari lagi", "2 hari lalu"
  static String relative(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Besok';
    if (diff == -1) return 'Kemarin';
    if (diff > 1) return '$diff hari lagi';
    return '${diff.abs()} hari lalu';
  }

  /// Deadline status
  static String deadlineStatus(DateTime? deadline) {
    if (deadline == null) return 'Tanpa deadline';
    final now = DateTime.now();
    if (deadline.isBefore(now)) return 'Overdue';
    return relative(deadline);
  }
}
