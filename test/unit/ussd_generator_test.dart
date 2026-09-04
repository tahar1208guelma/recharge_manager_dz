import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/operators/ussd_generator.dart';

void main() {
  setUp(() {
    UssdGenerator.resetAllCustomTemplates();
  });

  group('Mobilis Corrected USSD Code Tests (Account 04 & PIN 11111)', () {
    test('Should generate Mobilis Direct Card recharge (*111*)', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'recharge_direct',
        cardCode: '12345678901234',
      );
      expect(code, '*111*12345678901234#');
    });

    test('Should generate Mobilis Flexy with account 04 and default PIN 11111', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'transfert_flexy',
        receiver: '0661123456',
        amount: 500,
      );
      expect(code, '*630*0661123456*04*500*11111#');
    });

    test('Should generate Mobilis Arseli with account 04, sub-option 1, and default PIN 11111', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'arseli_avec_activation',
        receiver: '0661123456',
        amount: 1000,
        subOption: '1',
      );
      expect(code, '*696*1*0661123456*04*1000*11111#');
    });

    test('Should generate Mobilis Arseli International without extra 1*', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'arseli_international',
        receiver: '0661123456',
        amount: 2000,
      );
      expect(code, '*633*0661123456*2000*11111#');
    });

    test('Should generate Mobilis Solde with default PIN 11111', () {
      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'solde',
      );
      expect(code, '*632*01*11111#');
    });
  });

  group('Ooredoo Corrected USSD Code Tests (PIN 0000)', () {
    test('Should generate Ooredoo Direct Card recharge (222)', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'recharge_direct',
        cardCode: '123456',
      );
      expect(code, '222');
    });

    test('Should generate Ooredoo Flexy with default PIN 0000', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'transfert_flexy',
        receiver: '0555432100',
        amount: 200,
      );
      expect(code, '*580*0555432100*200*0000#');
    });

    test('Should generate Ooredoo Flexy activation (*585*)', () {
      final code = UssdGenerator.generate(
        OperatorType.ooredoo,
        'flexy_activation',
        receiver: '0555432100',
      );
      expect(code, '*585*0555432100#');
    });
  });

  group('Djezzy Corrected USSD Code Tests (PIN 00000)', () {
    test('Should generate Djezzy Direct Card recharge (*700*)', () {
      final code = UssdGenerator.generate(
        OperatorType.djezzy,
        'recharge_direct',
        cardCode: '98765432101234',
      );
      expect(code, '*700*98765432101234#');
    });

    test('Should generate Djezzy Flexy with sub-option and default PIN 00000', () {
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

  group('Custom USSD Template Overriding Tests', () {
    test('Should allow overriding USSD templates dynamically', () {
      UssdGenerator.setCustomTemplate(
        OperatorType.mobilis,
        'transfert_flexy',
        '*600*{receiver}*{amount}*{pin}#',
      );

      final code = UssdGenerator.generate(
        OperatorType.mobilis,
        'transfert_flexy',
        receiver: '0661123456',
        amount: 500,
      );
      expect(code, '*600*0661123456*500*11111#');
    });
  });
}
