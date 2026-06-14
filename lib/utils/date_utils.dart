import 'package:intl/intl.dart';

/// Centralized date formatting utilities for consistent date display
class AppDateUtils {
  /// Format date as "MMM dd, yyyy" (e.g., "Jan 15, 2024")
  static String formatShortDate(DateTime date) =>
      DateFormat('MMM dd, yyyy').format(date);

  /// Format date as "EEEE, MMMM dd, yyyy" (e.g., "Monday, January 15, 2024")
  static String formatLongDate(DateTime date) =>
      DateFormat('EEEE, MMMM dd, yyyy').format(date);

  /// Format time as "h:mm a" (e.g., "3:45 PM")
  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  /// Format as "MMM yyyy" for month headers (e.g., "Jan 2024")
  static String formatMonthYear(DateTime date) =>
      DateFormat('MMM yyyy').format(date);

  /// Format complete date and time (e.g., "Monday, January 15, 2024 at 3:45 PM")
  static String formatDateTime(DateTime date) =>
      '${formatLongDate(date)} at ${formatTime(date)}';
}
