import 'dart:async';
import '../../../core/constants/operator_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../card_connection.dart';
import '../card_info.dart';
import '../reader_device_info.dart';
import '../reader_discovery.dart';
import '../smart_card_protocol.dart';
import '../smart_card_service.dart';
import '../smart_card_state.dart';

class MockCardConnection implements CardConnection {
  @override
  final String readerName;
  @override
  final String protocol;
  @override
  final String? atr;
  final CardInfo? cardInfo;
  bool _isConnected = true;

  MockCardConnection({
    required this.readerName,
    this.protocol = 'T=0',
    this.atr,
    this.cardInfo,
  });

  @override
  bool get isConnected => _isConnected;

  @override
  Future<SmartCardResponse> transmit(List<int> apdu) async {
    if (!_isConnected) {
      return SmartCardResponse(data: [], sw1: 0x6F, sw2: 0x00, isSuccess: false);
    }
    await Future.delayed(const Duration(milliseconds: 20));
    return SmartCardProtocol.parseApduResponse([0x90, 0x00]);
  }

  @override
  Future<SmartCardResponse> selectFile(List<int> fileId, {bool isGsm = false}) async {
    return await transmit(SmartCardProtocol.buildSelectFileApdu(fileId, isGsm: isGsm));
  }

  @override
  Future<SmartCardResponse> readBinary(int offset, int length, {bool isGsm = false}) async {
    return await transmit(SmartCardProtocol.buildReadBinaryApdu(offset, length, isGsm: isGsm));
  }

  @override
  Future<SmartCardResponse> getResponse(int length, {bool isGsm = false}) async {
    return SmartCardResponse(data: List.filled(length, 0xFF), sw1: 0x90, sw2: 0x00, isSuccess: true);
  }

  @override
  Future<void> disconnect({bool resetCard = false}) async {
    _isConnected = false;
  }
}

class MockSmartCardService implements SmartCardService {
  final _stateController = StreamController<SmartCardReaderState>.broadcast();
  SmartCardReaderState _currentState;
  CardConnection? _activeConnection;

  MockSmartCardService({
    SmartCardConnectionStatus initialStatus = SmartCardConnectionStatus.cardWaiting,
    String initialReaderName = 'HID Global OMNIKEY 3x21 Smart Card Reader (076B:3021)',
  }) : _currentState = SmartCardReaderState(
          status: initialStatus,
          deviceInfo: ReaderDiscovery.inspectReader(initialReaderName),
          lastEventTime: DateTime.now(),
        );

  @override
  Stream<SmartCardReaderState> get stateStream => _stateController.stream;

  @override
  SmartCardReaderState get currentState => _currentState;

  @override
  CardConnection? get activeConnection => _activeConnection;

  void _emit(SmartCardReaderState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> initialize() async {
    AppLogger.info('Initializing Mock Smart Card Reader subsystem...');
    await Future.delayed(const Duration(milliseconds: 30));
    final readers = await listReaders();
    if (readers.isNotEmpty) {
      await connect(readers.first.readerName);
    }
  }

  @override
  Future<List<ReaderDeviceInfo>> listReaders() async {
    return [
      ReaderDiscovery.inspectReader('HID Global OMNIKEY 3x21 Smart Card Reader (076B:3021)'),
      ReaderDiscovery.inspectReader('ACS ACR39U CCID Smart Card Reader (072F:2200)'),
      ReaderDiscovery.inspectReader('Identiv uTrust 2700 R Smart Card Reader (04E6:5116)'),
    ];
  }

  @override
  Future<bool> connect([String? readerName]) async {
    final name = readerName ?? 'HID Global OMNIKEY 3x21 Smart Card Reader (076B:3021)';
    final info = ReaderDiscovery.inspectReader(name);

    if (!info.isCompatible) {
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.readerError,
        deviceInfo: info,
        errorMessage: info.errorMessage ?? 'Reader is incompatible.',
        lastEventTime: DateTime.now(),
      ));
      return false;
    }

    _activeConnection = MockCardConnection(
      readerName: name,
      protocol: 'T=0',
      atr: _currentState.cardInfo?.atr,
      cardInfo: _currentState.cardInfo,
    );

    _emit(SmartCardReaderState(
      status: _currentState.hasCard ? SmartCardConnectionStatus.cardDetected : SmartCardConnectionStatus.cardWaiting,
      deviceInfo: info,
      cardInfo: _currentState.cardInfo,
      lastEventTime: DateTime.now(),
    ));
    return true;
  }

  @override
  Future<void> disconnect() async {
    await _activeConnection?.disconnect();
    _activeConnection = null;
    _emit(SmartCardReaderState(
      status: SmartCardConnectionStatus.disconnected,
      deviceInfo: null,
      cardInfo: null,
      lastEventTime: DateTime.now(),
    ));
  }

  @override
  Future<bool> isCardPresent() async {
    return _currentState.hasCard || _currentState.status == SmartCardConnectionStatus.cardDetected;
  }

  @override
  Future<CardInfo?> getCardInfo() async {
    if (_currentState.cardInfo != null) {
      return _currentState.cardInfo;
    }
    // Default to Mobilis SIM if no card is currently inserted
    await insertSimCard(OperatorType.mobilis);
    return _currentState.cardInfo;
  }

  /// Simulation helper: Insert a realistic Algerian SIM card profile (Mobilis, Djezzy, Ooredoo)
  Future<void> insertSimCard(OperatorType operator) async {
    String imsi;
    String iccid;
    String msisdn;
    String atr;

    switch (operator) {
      case OperatorType.mobilis:
        imsi = '603010198765432';
        iccid = '89213010012345678901';
        msisdn = '0661123456';
        atr = '3B 9F 95 80 1F C7 80 31 E0 73 FE 21 13 57 86 81 02 86 98 44';
        break;
      case OperatorType.djezzy:
        imsi = '603020987654321';
        iccid = '89213020098765432100';
        msisdn = '0770987654';
        atr = '3B 7F 96 00 00 80 31 80 65 B0 83 11 00 C8 83 00 90 00';
        break;
      case OperatorType.ooredoo:
        imsi = '603030555432100';
        iccid = '89213030055543210099';
        msisdn = '0555432100';
        atr = '3B 9F 96 80 3F 87 80 31 E0 73 FE 21 1B 67 4A 4C 75 01 00 E8';
        break;
      default:
        imsi = '603010000000000';
        iccid = '89213010000000000000';
        msisdn = '0600000000';
        atr = '3B 9F 95 80 1F C7 80 31 E0 73 FE 21 13 57 86 81 02 86 98 44';
    }

    final card = CardInfo.fromPublicData(
      atr: atr,
      iccid: iccid,
      imsi: imsi,
      msisdn: msisdn,
      protocolUsed: 'PC/SC (T=0)',
    );

    final device = _currentState.deviceInfo ?? ReaderDiscovery.inspectReader('HID Global OMNIKEY 3x21 Smart Card Reader (076B:3021)');

    _activeConnection = MockCardConnection(
      readerName: device.readerName,
      protocol: 'T=0',
      atr: atr,
      cardInfo: card,
    );

    _emit(SmartCardReaderState(
      status: SmartCardConnectionStatus.cardDetected, // 🔵 Card Detected
      deviceInfo: device,
      cardInfo: card,
      lastEventTime: DateTime.now(),
    ));
  }

  /// Simulation helper: Eject SIM card -> Transitions to 🟡 Card Waiting
  Future<void> removeSimCard() async {
    final device = _currentState.deviceInfo ?? ReaderDiscovery.inspectReader('HID Global OMNIKEY 3x21 Smart Card Reader (076B:3021)');
    await _activeConnection?.disconnect();
    _activeConnection = null;

    _emit(SmartCardReaderState(
      status: SmartCardConnectionStatus.cardWaiting, // 🟡 Card Waiting
      deviceInfo: device,
      cardInfo: null,
      lastEventTime: DateTime.now(),
    ));
  }

  /// Simulation helper: Trigger error state -> Transitions to 🔴 Reader Error
  void simulateError(String errorMessage) {
    _emit(SmartCardReaderState(
      status: SmartCardConnectionStatus.readerError, // 🔴 Reader Error
      deviceInfo: _currentState.deviceInfo,
      errorMessage: errorMessage,
      lastEventTime: DateTime.now(),
    ));
  }

  /// Simulation helper: Trigger incompatible reader
  void simulateIncompatibleReader() {
    final badDevice = ReaderDiscovery.inspectReader('Generic USB Mass Storage Flash Drive');
    _emit(SmartCardReaderState(
      status: SmartCardConnectionStatus.readerError,
      deviceInfo: badDevice,
      errorMessage: badDevice.errorMessage ?? 'Incompatible USB device.',
      lastEventTime: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _stateController.close();
  }
}
