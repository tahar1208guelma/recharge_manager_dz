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
    final res = WinSCardNative.transmitApdu(readerName, apdu);
    return SmartCardResponse(
      data: (res['data'] as List<int>?) ?? [],
      sw1: (res['sw1'] as int?) ?? 0x6F,
      sw2: (res['sw2'] as int?) ?? 0x00,
      isSuccess: res['isSuccess'] == true,
    );
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
    final apdu = [
      isGsm ? SmartCardProtocol.claGsm : SmartCardProtocol.claIso,
      SmartCardProtocol.insGetResponse,
      0x00,
      0x00,
      length
    ];
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
          errorCode: SmartCardErrorCode.none,
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
        status: SmartCardConnectionStatus.disconnected,
        errorCode: SmartCardErrorCode.noReader,
        errorMessage: 'لم يتم العثور على أي قارئ بطاقات ذكية متصل (noReader)',
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
          AppLogger.info('Discovered Windows Hardware Readers: $rawNames');
          return rawNames.map((name) => ReaderDiscovery.inspectReader(name)).toList();
        }
      }
      return [];
    } catch (e) {
      AppLogger.error('Failed to list PC/SC readers on Windows: $e');
      return [];
    }
  }

  @override
  Future<bool> connect([String? readerName]) async {
    try {
      final readers = await listReaders();
      if (readers.isEmpty) {
        _activeConnection = null;
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.disconnected,
          errorCode: SmartCardErrorCode.noReader,
          errorMessage: 'لا يوجد قارئ بطاقات متصل (noReader)',
          lastEventTime: DateTime.now(),
        ));
        return false;
      }

      final targetName = readerName ?? readers.first.readerName;
      final deviceInfo = ReaderDiscovery.inspectReader(targetName);

      if (!deviceInfo.isCompatible) {
        _activeConnection = null;
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.readerError,
          errorCode: SmartCardErrorCode.protocolError,
          deviceInfo: deviceInfo,
          errorMessage: deviceInfo.errorMessage ?? 'قارئ البطاقات غير متوافق مع نظام CCID',
          lastEventTime: DateTime.now(),
        ));
        return false;
      }

      final status = WinSCardNative.checkCardStatus(targetName);
      final isHardwarePresent = status['isPresent'] == true;
      final atr = status['atr'] as String?;
      final SmartCardErrorCode err = (status['errorCode'] as SmartCardErrorCode?) ?? SmartCardErrorCode.none;

      if (!isHardwarePresent) {
        _activeConnection = null;
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.cardWaiting,
          errorCode: SmartCardErrorCode.noCard,
          deviceInfo: deviceInfo,
          errorMessage: 'القارئ جاهز ولكن لا توجد شريحة مدرجة (noCard)',
          lastEventTime: DateTime.now(),
        ));
        return true;
      }

      _activeConnection = WindowsPcscCardConnection(
        readerName: targetName,
        protocol: 'T=0',
        atr: atr,
      );

      final card = await _readRealCardFromConnection(_activeConnection!, atr);

      _emit(SmartCardReaderState(
        status: card != null ? SmartCardConnectionStatus.cardDetected : SmartCardConnectionStatus.cardWaiting,
        errorCode: card != null ? SmartCardErrorCode.none : err,
        deviceInfo: deviceInfo,
        cardInfo: card,
        lastEventTime: DateTime.now(),
      ));

      return true;
    } catch (e) {
      _emit(SmartCardReaderState(
        status: SmartCardConnectionStatus.readerError,
        errorCode: SmartCardErrorCode.protocolError,
        errorMessage: 'Connect error: $e',
        lastEventTime: DateTime.now(),
      ));
      return false;
    }
  }

  Future<CardInfo?> _readRealCardFromConnection(CardConnection conn, String? atr) async {
    try {
      // 1. Select MF
      final selMf = await conn.selectFile(SmartCardProtocol.mfMaster);
      if (!selMf.isSuccess && selMf.sw1 != 0x9F && selMf.sw1 != 0x61) {
        return null;
      }

      // 2. Select EF_ICCID
      final selIccid = await conn.selectFile(SmartCardProtocol.efIccid);
      String? iccid;
      if (selIccid.isSuccess || selIccid.sw1 == 0x9F || selIccid.sw1 == 0x61) {
        final len = selIccid.sw2 > 0 ? selIccid.sw2 : 10;
        final readIccid = await conn.readBinary(0, len);
        if (readIccid.isSuccess && readIccid.data.isNotEmpty) {
          iccid = SmartCardProtocol.decodeBcdIccid(readIccid.data);
        }
      }

      // 3. Select DF_GSM and EF_IMSI
      await conn.selectFile(SmartCardProtocol.dfGsm, isGsm: true);
      final selImsi = await conn.selectFile(SmartCardProtocol.efImsi, isGsm: true);
      String? imsi;
      if (selImsi.isSuccess || selImsi.sw1 == 0x9F || selImsi.sw1 == 0x61) {
        final len = selImsi.sw2 > 0 ? selImsi.sw2 : 9;
        final readImsi = await conn.readBinary(0, len, isGsm: true);
        if (readImsi.isSuccess && readImsi.data.isNotEmpty) {
          imsi = SmartCardProtocol.decodeBcdImsi(readImsi.data);
        }
      }

      if (iccid != null || imsi != null || atr != null) {
        return CardInfo.fromPublicData(
          atr: atr ?? '',
          iccid: iccid ?? '',
          imsi: imsi,
          msisdn: null,
          protocolUsed: 'PC/SC WinSCard (${conn.protocol})',
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  void _startCardPolling() {
    _statusMonitorTimer?.cancel();
    _statusMonitorTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final readers = await listReaders();
        if (readers.isEmpty) {
          if (_currentState.status != SmartCardConnectionStatus.disconnected ||
              _currentState.errorCode != SmartCardErrorCode.noReader) {
            _emit(SmartCardReaderState(
              status: SmartCardConnectionStatus.disconnected,
              errorCode: SmartCardErrorCode.noReader,
              errorMessage: 'لم يتم العثور على أي قارئ بطاقات ذكية متصل (noReader)',
              lastEventTime: DateTime.now(),
            ));
          }
          return;
        }

        final primaryReader = _currentState.deviceInfo ?? readers.first;
        final status = WinSCardNative.checkCardStatus(primaryReader.readerName);
        final bool isHardwarePresent = status['isPresent'] == true;
        final String? atr = status['atr'];
        final SmartCardErrorCode err = (status['errorCode'] as SmartCardErrorCode?) ?? SmartCardErrorCode.none;

        if (isHardwarePresent) {
          if (!_currentState.hasCard) {
            _activeConnection = WindowsPcscCardConnection(
              readerName: primaryReader.readerName,
              protocol: 'T=0',
              atr: atr,
            );
            final card = await _readRealCardFromConnection(_activeConnection!, atr);
            _emit(SmartCardReaderState(
              status: card != null ? SmartCardConnectionStatus.cardDetected : SmartCardConnectionStatus.cardWaiting,
              errorCode: card != null ? SmartCardErrorCode.none : err,
              deviceInfo: primaryReader,
              cardInfo: card,
              lastEventTime: DateTime.now(),
            ));
          }
        } else {
          if (_currentState.hasCard || _currentState.status == SmartCardConnectionStatus.disconnected) {
            _activeConnection = null;
            _emit(SmartCardReaderState(
              status: SmartCardConnectionStatus.cardWaiting,
              errorCode: SmartCardErrorCode.noCard,
              deviceInfo: primaryReader,
              errorMessage: 'لا توجد شريحة مدرجة في القارئ (noCard)',
              lastEventTime: DateTime.now(),
            ));
          }
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
      errorCode: SmartCardErrorCode.none,
      lastEventTime: DateTime.now(),
    ));
  }

  @override
  Future<bool> isCardPresent() async {
    if (!Platform.isWindows) return false;
    final readers = await listReaders();
    if (readers.isEmpty) return false;
    final primary = _currentState.deviceInfo?.readerName ?? readers.first.readerName;
    final status = WinSCardNative.checkCardStatus(primary);
    return status['isPresent'] == true;
  }

  @override
  Future<CardInfo?> getCardInfo() async {
    return _currentState.cardInfo;
  }

  @override
  void dispose() {
    _statusMonitorTimer?.cancel();
    _stateController.close();
  }
}
