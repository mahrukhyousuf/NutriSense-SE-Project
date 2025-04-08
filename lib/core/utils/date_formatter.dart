import 'package:intl/intl.dart';

class DateFormatter {
  // Format date as "Mon, Jan 1"
  static String formatShortDate(DateTime date) {
    return DateFormat('E, MMM d').format(date);
  }

  // Format date as "Monday, January 1, 2023"
  static String formatLongDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  // Format time as "10:30 AM"
  static String formatTime(DateTime time) {
    return DateFormat('h:mm a').format(time);
  }

  // Format as "Today" or "Yesterday" if applicable, otherwise date
  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return formatShortDate(date);
    }
  }
}
