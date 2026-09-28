import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/operator_constants.dart';
import '../../services/operators/ussd_generator.dart';
import '../../services/smart_card/card_info.dart';
import '../../services/smart_card/platforms/mock_smart_card_service.dart';
import '../../services/smart_card/reader_device_info.dart';
import '../../services/smart_card/smart_card_service.dart';
import '../../services/smart_card/smart_card_service_factory.dart';
import '../../services/smart_card/smart_card_state.dart';
import '../../services/ussd/gsm_modem_service.dart';

class UsbProvider extends ChangeNotifier {
  SmartCardService _service;
  final GsmModemService modemService = GsmModemService();
  StreamSubscription<SmartCardReaderState>? _subscription;
  SmartCardReaderState _state;
  List<ReaderDeviceInfo> _availableReaders = [];
  String _simPin = '0000';
  String? _lastExecutedUssd;
  String? _activeComPort;
  int _activeBaudRate = 115200;
  final Map<OperatorType, String> _operatorComPorts = {};
  bool _isSimulationMode = false;

  UsbProvider({SmartCardService? service, bool isSimulationMode = false})
      : _isSimulationMode = isSimulationMode,
        _service = service ?? SmartCardServiceFactory.create(forceMock: isSimulationMode),
        _state = (service ?? SmartCardServiceFactory.create(forceMock: isSimulationMode)).currentState {
    modemService.isSimulationMode = _isSimulationMode;
    _subscription = _service.stateStream.listen((newState) {
      _state = newState;
      notifyListeners();
    });
    refreshReaders();
  }

  bool get isSimulationMode => _isSimulationMode;
  SmartCardReaderState get state => _state;
  SmartCardConnectionStatus get status => _state.status;
  SmartCardErrorCode get errorCode => _state.errorCode;
  bool get isNoReader => _state.isNoReader;
  bool get isNoCard => _state.isNoCard;
  bool get isCardMuted => _state.isCardMuted;
  bool get isPinLocked => _state.isPinLocked;
  bool get isProtocolError => _state.isProtocolError;

  bool get isReaderConnected => _state.isReaderConnected;
  bool get isWaitingForCard => _state.isWaitingForCard;
  bool get hasCard => _state.hasCard;
  bool get hasError => _state.hasError;
  CardInfo? get cardInfo => _state.cardInfo;
  ReaderDeviceInfo? get deviceInfo => _state.deviceInfo;
  String? get readerName => _state.readerName ?? deviceInfo?.readerName;
  OperatorType get detectedOperator => _state.detectedOperator;
  String? get errorMessage => _state.errorMessage ?? _state.formattedErrorMessage;
  List<ReaderDeviceInfo> get availableReaders => _availableReaders;
  String get simPin => _simPin;
  String? get lastExecutedUssd => _lastExecutedUssd;
  String? get activeComPort => _activeComPort;
  int get activeBaudRate => _activeBaudRate;
  Map<OperatorType, String> get operatorComPorts => Map.unmodifiable(_operatorComPorts);

  void setSimulationMode(bool enabled) {
    if (_isSimulationMode == enabled) return;
    _isSimulationMode = enabled;
    modemService.isSimulationMode = enabled;

    _subscription?.cancel();
    _service.dispose();

    _service = SmartCardServiceFactory.create(forceMock: enabled);
    _state = _service.currentState;
    _subscription = _service.stateStream.listen((newState) {
      _state = newState;
      notifyListeners();
    });
    _service.initialize();
    refreshReaders();
    notifyListeners();
  }

  void setActiveComPort(String? port, {int baudRate = 115200}) {
    _activeComPort = port;
    _activeBaudRate = baudRate;
    modemService.setActivePort(port, baudRate: baudRate);
    notifyListeners();
  }

  void setOperatorComPort(OperatorType operator, String port) {
    if (port.trim().isNotEmpty) {
      _operatorComPorts[operator] = port.trim();
      notifyListeners();
    }
  }

  String? getPortForOperator(OperatorType operator) {
    return _operatorComPorts[operator] ?? _activeComPort;
  }

  void setSimPin(String pin) {
    if (pin.trim().isNotEmpty) {
      _simPin = pin.trim();
      notifyListeners();
    }
  }

  Future<void> initialize() async {
    await _service.initialize();
    await refreshReaders();
  }

  Future<void> refreshReaders() async {
    try {
      _availableReaders = await _service.listReaders();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> connectReader([String? readerName]) async {
    await _service.connect(readerName);
    await refreshReaders();
  }

  Future<void> disconnectReader() async {
    await _service.disconnect();
  }

  Future<bool> isCardPresent() async {
    return await _service.isCardPresent();
  }

  Future<CardInfo?> readCard() async {
    final info = await _service.getCardInfo();
    notifyListeners();
    return info;
  }

  String buildUssdCommand(
    OperatorType operator,
    String serviceKey, {
    String? receiver,
    double? amount,
    String? cardCode,
    String? subOption,
  }) {
    final code = UssdGenerator.generate(
      operator,
      serviceKey,
      receiver: receiver,
      amount: amount,
      pin: _simPin,
      cardCode: cardCode,
      subOption: subOption,
    );
    _lastExecutedUssd = code;
    notifyListeners();
    return code;
  }

  // ================= SIMULATION HELPERS =================
  // Allowed ONLY inside MockSmartCardService under explicit Simulation Mode

  Future<void> simulateInsertSimCard(OperatorType operator) async {
    final s = _service;
    if (s is MockSmartCardService) {
      await s.insertSimCard(operator);
    }
  }

  Future<void> simulateRemoveSimCard() async {
    final s = _service;
    if (s is MockSmartCardService) {
      await s.removeSimCard();
    }
  }

  void simulateNoReader() {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateNoReader();
    }
  }

  void simulateNoCard() {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateNoCard();
    }
  }

  void simulateCardMuted() {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateCardMuted();
    }
  }

  void simulatePinLocked() {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulatePinLocked();
    }
  }

  void simulateProtocolError() {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateProtocolError();
    }
  }

  void simulateError(String errorMsg, [SmartCardErrorCode errorCode = SmartCardErrorCode.protocolError]) {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateError(errorMsg, errorCode);
    }
  }

  void simulateIncompatibleReader() {
    final s = _service;
    if (s is MockSmartCardService) {
      s.simulateIncompatibleReader();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
