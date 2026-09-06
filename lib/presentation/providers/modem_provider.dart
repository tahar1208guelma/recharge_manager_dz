import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/utils/app_logger.dart';
import '../../debug/debug_logger.dart';
import '../../modem/models/hardware_device_type.dart';
import '../../modem/models/serial_port_info.dart';
import '../../modem/modem_service.dart';
import '../../network/network_info.dart';
import '../../network/network_service.dart';
import '../../operators/default_profiles.dart';
import '../../operators/operator_repository.dart';
import '../../printer/receipt_printer_service.dart';
import '../../sim/sim_card_info.dart';
import '../../sim/sim_service.dart';
import '../../sms/sms_message.dart';
import '../../sms/sms_service.dart';
import '../../transactions/transaction_manager.dart';
import '../../ussd/session_engine.dart';
import '../../ussd/ussd_service.dart';

class ModemProvider extends ChangeNotifier {
  final ModemService modemService;
  late final SimService simService;
  late final NetworkService networkService;
  late final SmsService smsService;
  late final UssdService ussdService;
  final TransactionManager transactionManager = TransactionManager();
  final OperatorRepository operatorRepository;
  final ReceiptPrinterService printerService = ReceiptPrinterService();
  final DebugLogger debugLogger = DebugLogger();

  List<SerialPortInfo> _detectedDevices = [];
  SerialPortInfo? _selectedDevice;
  bool _isScanning = false;
  bool _isConnecting = false;
  String? _statusError;

  StreamSubscription? _simSub;
  StreamSubscription? _netSub;
  StreamSubscription? _ussdSub;
  StreamSubscription? _smsSub;
  Timer? _pollingTimer;

  ModemProvider({
    ModemService? modemService,
    OperatorRepository? operatorRepository,
  })  : modemService = modemService ?? ModemService(),
        operatorRepository = operatorRepository ?? InMemoryOperatorRepository() {
    simService = SimService(modemService: this.modemService);
    networkService = NetworkService(modemService: this.modemService);
    smsService = SmsService(modemService: this.modemService);
    ussdService = UssdService(modemService: this.modemService);

    _simSub = simService.simStateStream.listen((_) => notifyListeners());
    _netSub = networkService.networkStateStream.listen((_) => notifyListeners());
    _ussdSub = ussdService.sessionStateStream.listen((_) => notifyListeners());
    _smsSub = smsService.incomingSmsStream.listen((_) => notifyListeners());

    scanAndAutoConnect();
  }

  // Getters
  List<SerialPortInfo> get detectedDevices => _detectedDevices;
  SerialPortInfo? get selectedDevice => _selectedDevice;
  bool get isConnected => modemService.isConnected;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  String? get statusError => _statusError;

  SimCardInfo get simInfo => simService.currentSim;
  NetworkInfo get networkInfo => networkService.networkInfo;
  UssdSessionData? get activeUssdSession => ussdService.currentSession;
  List<SmsMessage> get smsList => smsService.messages;
  List<PosTransaction> get recentTransactions => transactionManager.transactions;

  /// Scans for attached hardware and automatically connects to the first GSM Modem
  Future<void> scanAndAutoConnect() async {
    _isScanning = true;
    _statusError = null;
    notifyListeners();

    try {
      _detectedDevices = await modemService.scanDevices();
      debugLogger.logSystem('ALL', 'تم فحص العتاد واكتشاف ${_detectedDevices.length} أجهزة');

      if (_detectedDevices.isNotEmpty) {
        // Find best candidate (GSM Modem or Mock Device)
        final candidate = _detectedDevices.firstWhere(
          (d) => d.deviceType == HardwareDeviceType.gsmModem || d.deviceType == HardwareDeviceType.mockDevice,
          orElse: () => _detectedDevices.first,
        );
        await connectToDevice(candidate);
      }
    } catch (e) {
      _statusError = 'خطأ في فحص العتاد: $e';
      AppLogger.error('ModemProvider scan error: $e');
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Connects to a specific serial port or modem device
  Future<bool> connectToDevice(SerialPortInfo device) async {
    _isConnecting = true;
    _statusError = null;
    notifyListeners();

    debugLogger.logSystem(device.portName, 'جاري فتح الاتصال بالمنفذ ${device.portName} (${device.friendlyName})...');

    final ok = await modemService.connect(device);
    _isConnecting = false;

    if (ok) {
      _selectedDevice = device;
      debugLogger.logSystem(device.portName, 'تم الاتصال بالمنفذ بنجاح. جاري فحص الشريحة والشبكة...');

      // Sequence: Check SIM -> Refresh Network -> Fetch SMS
      await simService.checkSimStatus();
      await networkService.refreshNetworkInfo();
      await smsService.fetchAllMessages();

      _startPeriodicStatusPolling();
      notifyListeners();
      return true;
    } else {
      _statusError = 'تعذر فتح الاتصال بالمنفذ ${device.portName}';
      debugLogger.logSystem(device.portName, 'فشل الاتصال بالمنفذ ${device.portName}');
      notifyListeners();
      return false;
    }
  }

  /// Starts polling network registration and signal strength every 15 seconds
  void _startPeriodicStatusPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (modemService.isConnected) {
        await networkService.refreshNetworkInfo();
      }
    });
  }

  /// Initiates an interactive USSD session (e.g. Recharge, Solde, Internet)
  Future<UssdSessionData> startUssdSession({
    required OperatorType operator,
    required String ussdCode,
  }) async {
    debugLogger.logTx(modemService.activePort ?? 'COM', 'AT+CUSD=1,"$ussdCode",15');
    final session = await ussdService.executeSession(operator: operator, ussdCode: ussdCode);
    if (session.currentPrompt != null) {
      debugLogger.logRx(modemService.activePort ?? 'COM', session.currentPrompt!);
    }
    return session;
  }

  /// Sends a reply choice to the active USSD session
  Future<UssdSessionData> sendUssdReply(String replyText) async {
    debugLogger.logTx(modemService.activePort ?? 'COM', 'AT+CUSD=1,"$replyText",15');
    final session = await ussdService.reply(replyText);
    if (session.currentPrompt != null) {
      debugLogger.logRx(modemService.activePort ?? 'COM', session.currentPrompt!);
    }
    return session;
  }

  /// Cancels active USSD session
  void cancelUssdSession() {
    debugLogger.logTx(modemService.activePort ?? 'COM', 'AT+CUSD=2 (Cancel Session)');
    ussdService.cancel();
  }

  /// Executes full Recharge Transaction with duplicate protection and profile templating
  Future<PosTransaction> executeRecharge({
    required OperatorType operator,
    required String phoneNumber,
    required double amount,
    String? pin,
  }) async {
    final profile = await operatorRepository.getProfileByType(operator) ?? DefaultProfiles.mobilis;

    // 1. Guard against duplicate rapid transactions
    final tx = transactionManager.createTransaction(
      operator: operator,
      phoneNumber: phoneNumber,
      amount: amount,
      serviceName: 'تعبئة رصيد (Recharge)',
    );

    // 2. Build live USSD code from operator profile template
    final ussdCode = profile.buildUssd('recharge', params: {
      'phone': phoneNumber,
      'amount': amount.toInt().toString(),
      'pin': pin ?? profile.defaultPin,
    });

    // 3. Start USSD Session
    final session = await startUssdSession(operator: operator, ussdCode: ussdCode);

    if (session.isCompleted) {
      transactionManager.markSuccess(
        tx.transactionId,
        reference: session.transactionRef,
        responseMessage: session.currentPrompt,
      );
    } else if (session.isFailed) {
      transactionManager.markFailed(tx.transactionId, error: session.errorMessage);
    }

    return tx;
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _simSub?.cancel();
    _netSub?.cancel();
    _ussdSub?.cancel();
    _smsSub?.cancel();
    simService.dispose();
    networkService.dispose();
    smsService.dispose();
    ussdService.dispose();
    transactionManager.dispose();
    modemService.dispose();
    super.dispose();
  }
}
