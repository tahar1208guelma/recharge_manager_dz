import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/operators/ussd_generator.dart';

void main() {
  group('Mobilis USSD Code Generation Tests', () {
    test('Should generate Mobilis Direct Card recharge (*111*)', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'recharge_direct',
        cardCode: '12345678901234',
      );
      expect(code, '*111*12345678901234#');
    });

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

    test('Should generate Mobilis Arseli with Sub-menu option 1 (Local)', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'arseli_avec_activation',
        receiver: '0661123456',
        amount: 1000,
        pin: '0000',
        subOption: '1',
      );
      expect(code, '*696*1*0661123456*1000*0000#');
    });

    test('Should generate Mobilis Arseli with Sub-menu option 2 (International)', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'arseli_avec_activation',
        receiver: '0661123456',
        amount: 2000,
        pin: '1234',
        subOption: '2',
      );
      expect(code, '*696*2*0661123456*2000*1234#');
    });

    test('Should generate Mobilis Solde USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'solde',
        pin: '0000',
      );
      expect(code, '*632*01*0000#');
    });
  });

  group('Ooredoo USSD Code Generation Tests', () {
    test('Should generate Ooredoo Direct Card recharge (222)', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'recharge_direct',
        cardCode: '123456',
      );
      expect(code, '222');
    });

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

    test('Should generate Ooredoo Flexy with Sub-menu Activation option 1', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'flexy_activation',
        receiver: '0555432100',
        subOption: '1',
      );
      expect(code, '*585*1*0555432100#');
    });

    test('Should generate Ooredoo Solde without PIN USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'solde_sans_pin',
      );
      expect(code, '*766#');
    });
  });

  group('Djezzy USSD Code Generation Tests', () {
    test('Should generate Djezzy Direct Card recharge (*700*)', () {
      final code = UssdGenerator.generate(
        OperatorType.djezzy,
        'recharge_direct',
        cardCode: '98765432101234',
      );
      expect(code, '*700*98765432101234#');
    });

    test('Should generate Djezzy Flexy with Sub-menu option 1', () {
      final code = UssdGenerator.generate(
        OperatorType.djezzy,
        'flexy_activation',
        receiver: '0770987654',
        amount: 500,
        subOption: '1',
      );
      expect(code, '*770*1*0770987654*500*00000#');
    });

    test('Should generate Djezzy Solde USSD code', () {
      final code = UssdGenerator.generate(
        OperatorType.djezzy,
        'solde',
      );
      expect(code, '*710#');
    });
  });
}
