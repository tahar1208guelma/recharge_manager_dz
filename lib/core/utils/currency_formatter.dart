import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _formatter = NumberFormat('#,##0.00', 'en_US');
  static final NumberFormat _compactFormatter = NumberFormat('#,##0', 'en_US');

  /// Formats amount with currency: 500.00 د.ج or 500.00 DZD
  static String format(double amount, {String currencySymbol = 'د.ج'}) {
    return '${_formatter.format(amount)} $currencySymbol';
  }

  /// Formats compact without decimals if exact: 500 د.ج
  static String formatCompact(double amount, {String currencySymbol = 'د.ج'}) {
    if (amount == amount.roundToDouble()) {
      return '${_compactFormatter.format(amount.toInt())} $currencySymbol';
    }
    return format(amount, currencySymbol: currencySymbol);
  }

  static double? parse(String input) {
    try {
      final clean = input.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean);
    } catch (_) {
      return null;
    }
  }
}
