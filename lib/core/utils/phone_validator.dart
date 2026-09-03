import '../constants/operator_constants.dart';

class PhoneValidator {
  /// Cleans phone input removing spaces, dashes, parentheses
  static String sanitize(String input) {
    String clean = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+213')) {
      clean = '0${clean.substring(4)}';
    } else if (clean.startsWith('213') && clean.length == 11) {
      clean = '0${clean.substring(3)}';
    } else if (clean.startsWith('00213')) {
      clean = '0${clean.substring(5)}';
    }
    return clean;
  }

  /// Checks if the phone number is a valid 10-digit Algerian mobile number
  static bool isValidAlgerianMobile(String input) {
    final clean = sanitize(input);
    if (clean.length != 10) return false;
    final prefix = clean.substring(0, 2);
    return prefix == '05' || prefix == '06' || prefix == '07';
  }

  /// Formats phone number for display: 05 55 12 34 56
  static String formatDisplay(String input) {
    final clean = sanitize(input);
    if (clean.length != 10) return input;
    return '${clean.substring(0, 2)} ${clean.substring(2, 4)} ${clean.substring(4, 6)} ${clean.substring(6, 8)} ${clean.substring(8, 10)}';
  }

  /// Returns the matching OperatorType
  static OperatorType getOperator(String input) {
    return OperatorConstants.detectFromPhoneNumber(sanitize(input));
  }
}
