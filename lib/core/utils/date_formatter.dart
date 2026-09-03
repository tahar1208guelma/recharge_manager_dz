import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm:ss');
  static final DateFormat _receiptFormat = DateFormat('dd/MM/yyyy HH:mm');

  static String formatDateTime(DateTime dateTime) => _dateTimeFormat.format(dateTime);
  static String formatDate(DateTime dateTime) => _dateFormat.format(dateTime);
  static String formatTime(DateTime dateTime) => _timeFormat.format(dateTime);
  static String formatReceipt(DateTime dateTime) => _receiptFormat.format(dateTime);

  static DateTime? parse(String? isoString) {
    if (isoString == null || isoString.isEmpty) return null;
    try {
      return DateTime.parse(isoString);
    } catch (_) {
      return null;
    }
  }
}
