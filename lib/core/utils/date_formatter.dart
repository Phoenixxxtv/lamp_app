import 'package:intl/intl.dart';

/// Utility class for consistent date formatting across the app
class DateFormatter {
  /// Format a date as dd/MM/yyyy
  /// Example: 25/01/2024
  static String format(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// Parse a date string in dd/MM/yyyy format
  static DateTime parse(String dateStr) {
    return DateFormat('dd/MM/yyyy').parse(dateStr);
  }

  /// Format a date as 'dd MMM yyyy' (e.g. 25 Jan 2024)
  static String formatMedium(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Try to parse a string that might be ISO8601 or other formats
  /// Returns null if parsing fails
  static String? tryFormat(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final date = DateTime.parse(dateStr);
      return format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
