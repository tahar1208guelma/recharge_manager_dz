import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/utils/phone_validator.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';

void main() {
  group('Phone Validator & Sanitizer Tests', () {
    test('Should sanitize Algerian phone numbers with various formats', () {
      expect(PhoneValidator.sanitize('05 55 12 34 56'), '0555123456');
      expect(PhoneValidator.sanitize('05-55-12-34-56'), '0555123456');
      expect(PhoneValidator.sanitize('+213 555 12 34 56'), '0555123456');
      expect(PhoneValidator.sanitize('00213 661 12 34 56'), '0661123456');
    });

    test('Should validate genuine 10-digit Algerian numbers', () {
      expect(PhoneValidator.isValidAlgerianMobile('0555123456'), true);
      expect(PhoneValidator.isValidAlgerianMobile('0661123456'), true);
      expect(PhoneValidator.isValidAlgerianMobile('0770987654'), true);
      expect(PhoneValidator.isValidAlgerianMobile('021123456'), false); // Landline / 9 digits
      expect(PhoneValidator.isValidAlgerianMobile('0812345678'), false); // Invalid prefix 08
      expect(PhoneValidator.isValidAlgerianMobile('12345'), false);
    });

    test('Should format phone numbers for display', () {
      expect(PhoneValidator.formatDisplay('0555123456'), '05 55 12 34 56');
      expect(PhoneValidator.formatDisplay('0661123456'), '06 61 12 34 56');
    });

    test('Should detect operator correctly from phone string', () {
      expect(PhoneValidator.getOperator('05 55 12 34 56'), OperatorType.ooredoo);
      expect(PhoneValidator.getOperator('06 61 12 34 56'), OperatorType.mobilis);
      expect(PhoneValidator.getOperator('07 70 98 76 54'), OperatorType.djezzy);
    });
  });
}
