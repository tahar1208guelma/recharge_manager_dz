import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/constants/operator_constants.dart';
import 'package:recharge_manager_dz/core/utils/phone_validator.dart';
import 'package:recharge_manager_dz/modem/drivers/mock_modem_driver.dart';
import 'package:recharge_manager_dz/modem/models/hardware_device_type.dart';
import 'package:recharge_manager_dz/modem/models/serial_port_info.dart';
import 'package:recharge_manager_dz/modem/modem_service.dart';
import 'package:recharge_manager_dz/network/network_service.dart';
import 'package:recharge_manager_dz/operators/operator_repository.dart';
import 'package:recharge_manager_dz/printer/receipt_printer_service.dart';
import 'package:recharge_manager_dz/sim/sim_service.dart';
import 'package:recharge_manager_dz/sim/sim_state.dart';
import 'package:recharge_manager_dz/transactions/transaction_manager.dart';
import 'package:recharge_manager_dz/transactions/transaction_state.dart';
import 'package:recharge_manager_dz/ussd/menu_parser.dart';
import 'package:recharge_manager_dz/ussd/ussd_service.dart';

void main() {
  group('Full POS Recharge Integration Flow Tests', () {
    late MockModemDriver mockDriver;
    late ModemService modemService;
    late SimService simService;
    late NetworkService networkService;
    late UssdService ussdService;
    late TransactionManager transactionManager;
    late OperatorRepository operatorRepo;
    late ReceiptPrinterService printerService;

    setUp(() {
      mockDriver = MockModemDriver();
      modemService = ModemService(driver: mockDriver);
      simService = SimService(modemService: modemService);
      networkService = NetworkService(modemService: modemService);
      ussdService = UssdService(modemService: modemService);
      transactionManager = TransactionManager();
      operatorRepo = InMemoryOperatorRepository();
      printerService = ReceiptPrinterService();
    });

    tearDown(() {
      simService.dispose();
      networkService.dispose();
      ussdService.dispose();
      transactionManager.dispose();
      modemService.dispose();
    });

    test('Complete End-to-End POS Recharge Lifecycle with Dynamic Menu & Receipt', () async {
      // Step 1: Connect to Modem
      const mockPortInfo = SerialPortInfo(
        portName: 'COM4',
        friendlyName: 'Mock GSM Modem',
        deviceType: HardwareDeviceType.mockDevice,
      );
      final connected = await modemService.connect(mockPortInfo);
      expect(connected, true);
      expect(modemService.isConnected, true);

      // Step 2: Read SIM Status
      final sim = await simService.checkSimStatus();
      expect(sim.status, SimCardStatus.ready);
      expect(sim.imsi, '603011234567890');
      expect(sim.iccid, '8921301000001234567');

      // Step 3: Read Network Status
      final net = await networkService.refreshNetworkInfo();
      expect(net.isRegistered, true);
      expect(net.signalRssi, 25);
      expect(net.operatorName, 'MOBILIS');

      // Step 4: Resolve Operator Profile for destination phone number
      const customerPhone = '0661123456';
      const rechargeAmount = 500.0;
      final profile = await operatorRepo.detectFromPhone(customerPhone);
      expect(profile, isNotNull);
      expect(profile!.id, 'mobilis_dz');

      // Step 5: Start POS Transaction with Guard
      final tx = transactionManager.createTransaction(
        operator: OperatorType.mobilis,
        phoneNumber: customerPhone,
        amount: rechargeAmount,
        serviceName: 'تعبئة فليكسي (Mobilis Flexy)',
      );
      expect(tx.status, PosTransactionStatus.pending);

      // Step 6: Generate and Execute USSD Command
      final ussdCode = profile.buildUssd('recharge', params: {
        'phone': customerPhone,
        'amount': rechargeAmount.toStringAsFixed(0),
        'pin': profile.defaultPin,
      });
      expect(ussdCode, '*630*0661123456*04*500*11111#');

      final session = await ussdService.executeSession(
        operator: OperatorType.mobilis,
        ussdCode: ussdCode,
      );
      expect(session, isNotNull);

      // Wait briefly for unsolicited event parsing
      await Future.delayed(const Duration(milliseconds: 100));

      final activeSession = ussdService.currentSession;
      expect(activeSession, isNotNull);
      expect(activeSession!.isWaitingUser, true);

      // Step 7: Parse Network Dynamic Options
      final options = MenuParser.parseMenu(activeSession.currentPrompt ?? '');
      expect(options.isNotEmpty, true);
      expect(options.any((o) => o.key == '1'), true);

      // Step 8: Seller clicks '1' (Confirm)
      await ussdService.reply('1');
      await Future.delayed(const Duration(milliseconds: 100));

      final completedSession = ussdService.currentSession;
      expect(completedSession?.isCompleted, true);
      expect(completedSession?.currentPrompt?.contains('Operation reussie'), true);

      // Step 9: Transaction Marked as SUCCESS
      transactionManager.markSuccess(
        tx.transactionId,
        reference: 'REF-MOBILIS-2026',
        responseMessage: completedSession?.currentPrompt,
      );

      final finalTx = transactionManager.transactions.firstWhere((t) => t.transactionId == tx.transactionId);
      expect(finalTx.status, PosTransactionStatus.success);
      expect(finalTx.networkReference, 'REF-MOBILIS-2026');

      // Step 10: Format Thermal Receipt Text
      final receiptData = printerService.createReceiptFromTransaction(finalTx);
      final receiptText = printerService.formatMonospaceReceipt(receiptData);

      expect(receiptText.contains('VAST SOLUTIONS DZ'), true);
      expect(receiptText.contains(finalTx.transactionId), true);
      expect(receiptText.contains(PhoneValidator.formatDisplay(customerPhone)), true);
      expect(receiptText.contains('500'), true);
    });
  });
}
