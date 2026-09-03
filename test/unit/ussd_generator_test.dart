import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/operators/ussd_generator.dart';

void main() {
  group('Mobilis USSD Code Generation Tests', () {
    test('Should generate Mobilis Flexy USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'transfert_flexy',
        receiver: '0661123456',
        amount: 500,
        pin: '0000',
      );
      expect(code, '*630*0661123456*500*0000#');
    });

    test('Should generate Mobilis Arseli with Activation USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'arseli_avec_activation',
        receiver: '0661123456',
        amount: 1000,
        pin: '1234',
      );
      expect(code, '*696*1*0661123456*1000*1234#');
    });

    test('Should generate Mobilis Solde USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'solde',
        pin: '0000',
      );
      expect(code, '*632*01*0000#');
    });

    test('Should generate Mobilis Change PIN USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'changer_pin',
        oldPin: '0000',
        newPin: '5678',
      );
      expect(code, '*632*02*0000*5678#');
    });
  });

  group('Ooredoo USSD Code Generation Tests', () {
    test('Should generate Ooredoo Flexy USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'transfert_flexy',
        receiver: '0555432100',
        amount: 200,
        pin: '0000',
      );
      expect(code, '*580*0555432100*200*0000#');
    });

    test('Should generate Ooredoo Solde without PIN USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'solde_sans_pin',
      );
      expect(code, '*766#');
    });

    test('Should generate Ooredoo Flexy with Activation USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'flexy_activation',
        receiver: '0555432100',
      );
      expect(code, '*585*0555432100#');
    });

    test('Should generate Ooredoo Bonus USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'flexy_bonus',
        receiver: '0555432100',
        amount: 500,
        pin: '0000',
      );
      expect(code, '*764*0555432100*500*0000#');
    });
  });

  group('Djezzy USSD Code Generation Tests', () {
    test('Should generate Djezzy Flexy USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.djezzy,
        'transfert_flexy',
        receiver: '0770987654',
        amount: 1500,
        pin: '0000',
      );
      expect(code, '*770*0770987654*1500*0000#');
    });

    test('Should generate Djezzy Solde USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.djezzy,
        'solde',
        pin: '0000',
      );
      expect(code, '*777*0000#');
    });
  });
}
