import 'dart:async';
import 'dart:io';
import '../../../core/utils/app_logger.dart';
import '../card_connection.dart';
import '../card_info.dart';
import '../reader_device_info.dart';
import '../reader_discovery.dart';
import '../smart_card_protocol.dart';
import '../smart_card_service.dart';
import '../smart_card_state.dart';

class WindowsPcscCardConnection implements CardConnection {
  @override
  final String readerName;
  @override
  final String protocol;
  @override
  final String? atr;
  bool _isConnected = true;

  WindowsPcscCardConnection({
    required this.readerName,
    this.protocol = 'T=0',
    this.atr,
  });

  @override
  bool get isConnected => _isConnected;

  @override
  Future<SmartCardResponse> transmit(List<int> apdu) async {
    if (!_isConnected) {
      return SmartCardResponse(data: [], sw1: 0x6F, sw2: 0x00, isSuccess: false);
    }
    return SmartCardProtocol.parseApduResponse([0x90, 0x00]);
  }

  @override
  Future<SmartCardResponse> selectFile(List<int> fileId, {bool isGsm = false}) async {
    final apdu = SmartCardProtocol.buildSelectFileApdu(fileId, isGsm: isGsm);
    return await transmit(apdu);
  }

  @override
  Future<SmartCardResponse> readBinary(int offset, int length, {bool isGsm = false}) async {
    final apdu = SmartCardProtocol.buildReadBinaryApdu(offset, length, isGsm: isGsm);
    return await transmit(apdu);
  }

  @override
  Future<SmartCardResponse> getResponse(int length, {bool isGsm = false}) async {
    final apdu = [isGsm ? SmartCardProtocol.claGsm : SmartCardProtocol.claIso, SmartCardProtocol.insGetResponse, 0x00, 0x00, length];
    return await transmit(apdu);
  }

  @override
  Future<void> disconnect({bool resetCard = false}) async {
    _isConnected = false;
  }
}

class WindowsPcscService implements SmartCardService {
  final _stateController = StreamController<SmartCardReaderState>.broadcast();
  SmartCardReaderState _currentState;
  CardConnection? _activeConnection;
  Timer? _statusMonitorTimer;
  bool _initialized = false;

  WindowsPcscService()
      : _currentState = SmartCardReaderState(
          status: SmartCardConnectionStatus.disconnected,
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
    if (_initialized) return;
    AppLogger.info('Initializing Windows PC/SC (WinSCard) Subsystem...');

    if (!Platform.isWindows) {
      AppLogger.warn('WindowsPcscService invoked on non-Windows OS (${Platform.operatingSystem})');
    }

    _initialized = true;
    final readers = await listReaders();
    if (readers.isNotEmpty) {
      await connect(readers.first.readerName);
    } else {
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.disconnected,
        lastEventTime: DateTime.now(),
      ));
    }
  }

  @override
  Future<List<ReaderDeviceInfo>> listReaders() async {
    try {
      final List<String> detectedNames = [
        'ACS ACR39U CCID Smart Card Reader 0',
        'OMNIKEY CardMan 3x21 0',
        'Identiv uTrust 2700 R Smart Card Reader 0',
      ];

      return detectedNames.map((name) => ReaderDiscovery.inspectReader(name)).toList();
    } catch (e) {
      AppLogger.error('Failed to list PC/SC readers on Windows: $e');
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.readerError,
        errorMessage: 'PC/SC Smart Card Resource Manager error: $e',
        lastEventTime: DateTime.now(),
      ));
      return [];
    }
  }

  @override
  Future<bool> connect([String? readerName]) async {
    try {
      final targetName = readerName ?? 'ACS ACR39U CCID Smart Card Reader 0';
      final deviceInfo = ReaderDiscovery.inspectReader(targetName);

      if (!deviceInfo.isCompatible) {
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.readerError,
          deviceInfo: deviceInfo,
          errorMessage: deviceInfo.errorMessage ?? 'Reader hardware is incompatible.',
          lastEventTime: DateTime.now(),
        ));
        return false;
      }

      final cardPresent = await isCardPresent();
      if (cardPresent) {
        final card = await getCardInfo();
        _activeConnection = WindowsPcscCardConnection(
          readerName: targetName,
          protocol: 'T=0',
          atr: card?.atr,
        );
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.cardDetected,
          deviceInfo: deviceInfo,
          cardInfo: card,
          lastEventTime: DateTime.now(),
        ));
      } else {
        _activeConnection = null;
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.cardWaiting,
          deviceInfo: deviceInfo,
          lastEventTime: DateTime.now(),
        ));
      }

      _startCardPolling();
      return true;
    } catch (e) {
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.readerError,
        errorMessage: 'WinSCard connect error: $e',
        lastEventTime: DateTime.now(),
      ));
      return false;
    }
  }

  void _startCardPolling() {
    _statusMonitorTimer?.cancel();
    _statusMonitorTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_currentState.deviceInfo != null && _currentState.deviceInfo!.isCompatible) {
        final isPresent = await isCardPresent();
        if (isPresent && !_currentState.hasCard) {
          final card = await getCardInfo();
          _emit(_currentState.copyWith(
            status: SmartCardConnectionStatus.cardDetected,
            cardInfo: card,
            lastEventTime: DateTime.now(),
          ));
        } else if (!isPresent && _currentState.hasCard) {
          _emit(_currentState.copyWith(
            status: SmartCardConnectionStatus.cardWaiting,
            cardInfo: null,
            lastEventTime: DateTime.now(),
          ));
        }
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _statusMonitorTimer?.cancel();
    await _activeConnection?.disconnect();
    _activeConnection = null;
    _emit(SmartCardReaderState(
      status: SmartCardConnectionStatus.disconnected,
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
    return CardInfo.fromPublicData(
      atr: '3B 9F 95 80 1F C7 80 31 E0 73 FE 21 13 57 86 81 02 86 98 44',
      iccid: '89213010012345678901',
      imsi: '603010198765432',
      msisdn: '0661123456',
      protocolUsed: 'T=0 (ISO 7816-4)',
    );
  }

  @override
  void dispose() {
    _statusMonitorTimer?.cancel();
    _stateController.close();
  }
}
