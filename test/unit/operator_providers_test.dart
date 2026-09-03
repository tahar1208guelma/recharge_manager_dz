import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/services/operators/mock_operator_provider.dart';
import 'package:recharge_manager_dz/services/operators/operator_factory.dart';

void main() {
  group('Operator Constants & Prefix Detection Tests', () {
    test('Should detect Mobilis from 06 prefixes and IMSI 60301', () {
      expect(OperatorConstants.detectFromPhoneNumber('0661123456'), OperatorType.mobilis);
      expect(OperatorConstants.detectFromPhoneNumber('0655123456'), OperatorType.mobilis);
      expect(OperatorConstants.detectFromPhoneNumber('+213661123456'), OperatorType.mobilis);
      expect(OperatorConstants.detectFromImsi('603010198765432'), OperatorType.mobilis);
    });

    test('Should detect Djezzy from 07 prefixes and IMSI 60302', () {
      expect(OperatorConstants.detectFromPhoneNumber('0770987654'), OperatorType.djezzy);
      expect(OperatorConstants.detectFromPhoneNumber('0790112233'), OperatorType.djezzy);
      expect(OperatorConstants.detectFromPhoneNumber('+213770987654'), OperatorType.djezzy);
      expect(OperatorConstants.detectFromImsi('603020987654321'), OperatorType.djezzy);
    });

    test('Should detect Ooredoo from 05 prefixes and IMSI 60303', () {
      expect(OperatorConstants.detectFromPhoneNumber('0555432100'), OperatorType.ooredoo);
      expect(OperatorConstants.detectFromPhoneNumber('0540112233'), OperatorType.ooredoo);
      expect(OperatorConstants.detectFromPhoneNumber('+213555432100'), OperatorType.ooredoo);
      expect(OperatorConstants.detectFromImsi('603030555432100'), OperatorType.ooredoo);
    });
  });

  group('MockOperatorProvider Execution Tests', () {
    late MockOperatorProvider mobilisMock;

    setUp(() {
      mobilisMock = MockOperatorProvider(
        operatorType: OperatorType.mobilis,
        initialBalance: 5000.0,
      );
    });

    test('Should connect and fetch balance successfully', () async {
      final connected = await mobilisMock.connect();
      expect(connected, true);

      final balanceInfo = await mobilisMock.getBalance();
      expect(balanceInfo.currentBalance, 5000.0);
      expect(balanceInfo.operatorId, 'mobilis');
    });

    test('Should execute recharge and deduct balance properly', () async {
      final result = await mobilisMock.recharge(
        phoneNumber: '0661123456',
        amount: 500.0,
        transactionId: 'TX12345',
      );

      expect(result.isSuccess, true);
      expect(result.transactionId, 'TX12345');
      expect(result.newBalance, 4500.0);
      expect(result.rechargeCode, isNotNull);

      final balanceInfo = await mobilisMock.getBalance();
      expect(balanceInfo.currentBalance, 4500.0);
    });

    test('Should fail recharge when amount exceeds balance', () async {
      final result = await mobilisMock.recharge(
        phoneNumber: '0661123456',
        amount: 10000.0,
      );

      expect(result.isSuccess, false);
      expect(result.message, contains('Insufficient'));
    });

    test('OperatorFactory returns proper instances', () {
      final factory = OperatorFactory();
      final mobilis = factory.getProvider(OperatorType.mobilis);
      final djezzy = factory.getProvider(OperatorType.djezzy);
      final ooredoo = factory.getProvider(OperatorType.ooredoo);

      expect(mobilis.operatorId, 'mobilis');
      expect(djezzy.operatorId, 'djezzy');
      expect(ooredoo.operatorId, 'ooredoo');
    });
  });
}
