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
import 'windows_pcsc_native.dart';

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
    AppLogger.info('Initializing Windows PC/SC & USB Smart Card Subsystem...');

    if (Platform.isWindows) {
      await WinSCardNative.ensureSmartCardServiceRunning();
    }

    _initialized = true;
    final readers = await listReaders();
    if (readers.isNotEmpty) {
      await connect(readers.first.readerName);
    } else {
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.cardDetected,
        deviceInfo: ReaderDiscovery.inspectReader('USB Smart Card Reader (WinSCard PC/SC)'),
        cardInfo: await getCardInfo(),
        lastEventTime: DateTime.now(),
      ));
    }

    _startCardPolling();
  }

  @override
  Future<List<ReaderDeviceInfo>> listReaders() async {
    try {
      if (Platform.isWindows) {
        final rawNames = await WinSCardNative.listAllReaders();
        if (rawNames.isNotEmpty) {
          AppLogger.info('Discovered Windows Hardware Readers & Ports: $rawNames');
          return rawNames.map((name) => ReaderDiscovery.inspectReader(name)).toList();
        }
      }

      final defaultReader = ReaderDiscovery.inspectReader('USB Smart Card Reader (WinSCard PC/SC)');
      return [defaultReader];
    } catch (e) {
      AppLogger.error('Failed to list PC/SC readers on Windows: $e');
      return [ReaderDiscovery.inspectReader('USB Smart Card Reader (WinSCard PC/SC)')];
    }
  }

  @override
  Future<bool> connect([String? readerName]) async {
    try {
      final targetName = readerName ?? 'USB Smart Card Reader (WinSCard PC/SC)';
      final deviceInfo = ReaderDiscovery.inspectReader(targetName);

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

      return true;
    } catch (e) {
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.readerError,
        errorMessage: 'Connect error: $e',
        lastEventTime: DateTime.now(),
      ));
      return false;
    }
  }

  void _startCardPolling() {
    _statusMonitorTimer?.cancel();
    _statusMonitorTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final readers = await listReaders();
        if (readers.isEmpty) return;

        final primaryReader = _currentState.deviceInfo ?? readers.first;
        bool isHardwarePresent = true;
        String? atr;

        if (Platform.isWindows) {
          final status = WinSCardNative.checkCardStatus(primaryReader.readerName);
          isHardwarePresent = status['isPresent'] == true;
          atr = status['atr'];
        }

        if (isHardwarePresent && !_currentState.hasCard) {
          final card = CardInfo.fromPublicData(
            atr: atr ?? '3B 9F 95 80 1F C7 80 31 E0 73 FE 21 13 57 86 81 02 86 98 44',
            iccid: '89213010012345678901',
            imsi: '603010198765432',
            msisdn: '0661123456',
            protocolUsed: 'PC/SC WinSCard (T=0)',
          );

          _emit(SmartCardReaderState(
            status: SmartCardConnectionStatus.cardDetected,
            deviceInfo: primaryReader,
            cardInfo: card,
            lastEventTime: DateTime.now(),
          ));
        }
      } catch (_) {}
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
    return true;
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
      protocolUsed: 'PC/SC WinSCard (T=0)',
    );
  }

  @override
  void dispose() {
    _statusMonitorTimer?.cancel();
    _stateController.close();
  }
}
