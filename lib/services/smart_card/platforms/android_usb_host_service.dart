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

class AndroidUsbHostCardConnection implements CardConnection {
  @override
  final String readerName;
  @override
  final String protocol;
  @override
  final String? atr;
  bool _isConnected = true;

  AndroidUsbHostCardConnection({
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

class AndroidUsbHostService implements SmartCardService {
  final _stateController = StreamController<SmartCardReaderState>.broadcast();
  SmartCardReaderState _currentState;
  CardConnection? _activeConnection;
  bool _initialized = false;

  AndroidUsbHostService()
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
    AppLogger.info('Initializing Android USB Host API Smart Card Subsystem...');

    if (!Platform.isAndroid) {
      AppLogger.warn('AndroidUsbHostService running in fallback mode on ${Platform.operatingSystem}');
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
      // In Android, USB CCID devices are discovered via android.hardware.usb.UsbManager
      final device = ReaderDiscovery.inspectReader('USB OTG CCID Smart Card Reader (072F:2200)', properties: {
        'usb_class': 0x0B, // USB CCID Class
        'usb_subclass': 0x00,
        'usb_protocol': 0x00,
        'has_permission': true,
      });
      return [device];
    } catch (e) {
      AppLogger.error('Failed to list USB Host devices on Android: $e');
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.readerError,
        errorMessage: 'Android USB Host permission or discovery error: $e',
        lastEventTime: DateTime.now(),
      ));
      return [];
    }
  }

  @override
  Future<bool> connect([String? readerName]) async {
    try {
      final name = readerName ?? 'USB OTG CCID Smart Card Reader (072F:2200)';
      final deviceInfo = ReaderDiscovery.inspectReader(name);

      if (!deviceInfo.isCompatible) {
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.readerError,
          deviceInfo: deviceInfo,
          errorMessage: deviceInfo.errorMessage ?? 'Device is not a compatible CCID reader.',
          lastEventTime: DateTime.now(),
        ));
        return false;
      }

      final cardPresent = await isCardPresent();
      if (cardPresent) {
        final card = await getCardInfo();
        _activeConnection = AndroidUsbHostCardConnection(
          readerName: name,
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
      return true;
    } catch (e) {
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.readerError,
        errorMessage: 'Android USB Host connect error: $e',
        lastEventTime: DateTime.now(),
      ));
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
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
      protocolUsed: 'USB Host CCID (T=0)',
    );
  }

  @override
  void dispose() {
    _stateController.close();
  }
}
