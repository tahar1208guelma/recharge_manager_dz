import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import '../../../core/utils/app_logger.dart';
import '../card_connection.dart';
import '../card_info.dart';
import '../reader_device_info.dart';
import '../reader_discovery.dart';
import '../smart_card_protocol.dart';
import '../smart_card_service.dart';
import '../smart_card_state.dart';
import 'windows_pcsc_native.dart';

/// Real PC/SC Card Connection holding a single persistent hContext and hCard.
class WindowsPcscCardConnection implements CardConnection {
  @override
  final String readerName;
  @override
  final String protocol;
  @override
  final String? atr;

  final int hContext;
  final int hCard;
  int activeProtocol;
  int activeCla;
  bool _isConnected;
  final Map<String, dynamic> Function({
    required int hCard,
    required int activeProtocol,
    required List<int> apdu,
  }) _rawTransmit;

  WindowsPcscCardConnection({
    required this.readerName,
    required this.hContext,
    required this.hCard,
    required this.activeProtocol,
    this.protocol = 'T=0',
    this.atr,
    this.activeCla = SmartCardProtocol.claGsm,
    Map<String, dynamic> Function({
      required int hCard,
      required int activeProtocol,
      required List<int> apdu,
    })? rawTransmit,
  })  : _rawTransmit = rawTransmit ?? WinSCardNative.transmit,
        _isConnected = hCard != 0;

  @override
  bool get isConnected => _isConnected && hCard != 0;

  @override
  Future<SmartCardResponse> transmit(List<int> apdu) async {
    if (!_isConnected || hCard == 0) {
      return SmartCardResponse(data: [], sw1: 0x6F, sw2: 0x00, isSuccess: false);
    }

    final res = _rawTransmit(
      hCard: hCard,
      activeProtocol: activeProtocol,
      apdu: apdu,
    );

    int sw1 = (res['sw1'] as int?) ?? 0x6F;
    int sw2 = (res['sw2'] as int?) ?? 0x00;
    List<int> data = (res['data'] as List<int>?) ?? [];

    // T=0: SW1 == 0x61 means sw2 bytes are available to be fetched via GET RESPONSE
    if (sw1 == 0x61) {
      final getRespApdu = SmartCardProtocol.buildGetResponseApdu(
        sw2,
        isGsm: activeCla == SmartCardProtocol.claGsm,
      );
      final getResp = await transmit(getRespApdu);
      return getResp;
    }

    // T=0: SW1 == 0x6C means wrong Le length, resend with Le = sw2
    if (sw1 == 0x6C) {
      List<int> correctedApdu;
      if (apdu.length == 4) {
        correctedApdu = [...apdu, sw2];
      } else {
        correctedApdu = List<int>.from(apdu)..[apdu.length - 1] = sw2;
      }
      return await transmit(correctedApdu);
    }

    return SmartCardResponse(
      data: data,
      sw1: sw1,
      sw2: sw2,
      isSuccess: (sw1 == 0x90 && sw2 == 0x00) || sw1 == 0x91,
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
    final apdu = SmartCardProtocol.buildGetResponseApdu(length, isGsm: isGsm);
    return await transmit(apdu);
  }

  /// Verifies PIN / CHV1 explicitly upon user command. Never retries automatically.
  Future<SmartCardResponse> verifyPin(String pin, {bool isGsm = false}) async {
    final apdu = SmartCardProtocol.buildVerifyPinApdu(pin, isGsm: isGsm);
    return await transmit(apdu);
  }

  @override
  Future<void> disconnect({bool resetCard = false}) async {
    if (!_isConnected) return;
    _isConnected = false;
    WinSCardNative.endTransaction(hCard, disposition: SCARD_LEAVE_CARD);
    WinSCardNative.disconnectCard(
      hCard,
      disposition: resetCard ? SCARD_RESET_CARD : SCARD_LEAVE_CARD,
    );
    WinSCardNative.releaseContext(hContext);
  }
}

/// Real Windows PC/SC Smart Card Service talking to winscard.dll.
/// Maintains a persistent context and uses SCardGetStatusChange in an isolate.
class WindowsPcscService implements SmartCardService {
  final _stateController = StreamController<SmartCardReaderState>.broadcast();
  SmartCardReaderState _currentState;
  WindowsPcscCardConnection? _activeConnection;

  int _persistentContext = 0;
  bool _initialized = false;

  // Background Isolate for SCardGetStatusChange
  Isolate? _monitorIsolate;
  ReceivePort? _monitorReceivePort;
  SendPort? _isolateCommandPort;

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
    AppLogger.info('Initializing Windows PC/SC Subsystem via winscard.dll...');

    if (Platform.isWindows) {
      WinSCardNative.init();
      _persistentContext = WinSCardNative.establishContext();
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

    _startStatusMonitoringIsolate();
  }

  @override
  Future<List<ReaderDeviceInfo>> listReaders() async {
    try {
      if (Platform.isWindows) {
        final rawNames = WinSCardNative.listPcscReaders(hContext: _persistentContext);
        if (rawNames.isNotEmpty) {
          AppLogger.info('Discovered Windows PC/SC Hardware Readers: $rawNames');
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
        await _activeConnection?.disconnect();
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
        await _activeConnection?.disconnect();
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

      // Establish dedicated persistent context for this card connection
      final connContext = WinSCardNative.establishContext();
      if (connContext == 0) {
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.disconnected,
          errorCode: SmartCardErrorCode.noReader,
          errorMessage: 'فشل تهيئة سياق PC/SC (SCardEstablishContext)',
          lastEventTime: DateTime.now(),
        ));
        return false;
      }

      final connRes = WinSCardNative.connectCard(connContext, targetName);
      final returnCode = connRes['returnCode'] as int;

      if (returnCode == SCARD_E_NO_SMARTCARD) {
        WinSCardNative.releaseContext(connContext);
        await _activeConnection?.disconnect();
        _activeConnection = null;
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.cardWaiting,
          errorCode: SmartCardErrorCode.noCard,
          deviceInfo: deviceInfo,
          errorMessage: 'القارئ جاهز ولكن لا توجد شريحة مدرجة (noCard)',
          lastEventTime: DateTime.now(),
        ));
        return true;
      } else if (returnCode != SCARD_S_SUCCESS) {
        WinSCardNative.releaseContext(connContext);
        await _activeConnection?.disconnect();
        _activeConnection = null;
        _emit(SmartCardReaderState(
          status: SmartCardConnectionStatus.readerError,
          errorCode: SmartCardErrorCode.protocolError,
          deviceInfo: deviceInfo,
          errorMessage: 'تعذر الاتصال بالبطاقة الذكية: 0x${returnCode.toRadixString(16)}',
          lastEventTime: DateTime.now(),
        ));
        return false;
      }

      final hCard = connRes['hCard'] as int;
      final activeProto = connRes['activeProtocol'] as int;
      final protoStr = activeProto == SCARD_PROTOCOL_T1 ? 'T=1' : 'T=0';

      final statusInfo = WinSCardNative.getCardStatus(hCard);
      final atr = statusInfo['atr'] as String?;

      await _activeConnection?.disconnect();
      _activeConnection = WindowsPcscCardConnection(
        readerName: targetName,
        hContext: connContext,
        hCard: hCard,
        activeProtocol: activeProto,
        protocol: protoStr,
        atr: atr,
      );

      final card = await _readCardData(_activeConnection!);

      _emit(SmartCardReaderState(
        status: card != null ? SmartCardConnectionStatus.cardDetected : SmartCardConnectionStatus.cardWaiting,
        errorCode: card != null ? SmartCardErrorCode.none : (_currentState.errorCode != SmartCardErrorCode.none ? _currentState.errorCode : SmartCardErrorCode.none),
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

  /// Real SIM card data extraction obeying ISO 7816-4 and GSM 11.11 / 3GPP TS 51.011 standards.
  /// Tries CLA A0 first, falls back to CLA 00 on 6E00/6D00.
  Future<CardInfo?> _readCardData(WindowsPcscCardConnection conn) async {
    try {
      WinSCardNative.beginTransaction(conn.hCard);

      // 1. SELECT MF (3F00) - Try CLA A0 (GSM) first
      conn.activeCla = SmartCardProtocol.claGsm;
      var selMf = await conn.selectFile(SmartCardProtocol.mfMaster, isGsm: true);

      // If class or instruction not supported, fallback to CLA 00 (USIM/UICC)
      if (selMf.isClassNotSupported || selMf.isInstructionNotSupported) {
        conn.activeCla = SmartCardProtocol.claIso;
        selMf = await conn.selectFile(SmartCardProtocol.mfMaster, isGsm: false);
      }

      if (!selMf.isSuccess && !selMf.hasMoreData) {
        WinSCardNative.endTransaction(conn.hCard);
        return null;
      }

      final isGsm = conn.activeCla == SmartCardProtocol.claGsm;

      // 2. Read EF_ICCID (2FE2)
      String? iccid;
      final selIccid = await conn.selectFile(SmartCardProtocol.efIccid, isGsm: isGsm);
      if (selIccid.isPinRequired) {
        _emit(_currentState.copyWith(
          errorCode: SmartCardErrorCode.pinLocked,
          errorMessage: 'الشريحة مقفلة برمز PIN / PUK (pinLocked)',
        ));
      } else if (selIccid.isSuccess || selIccid.hasMoreData) {
        final readIccid = await conn.readBinary(0, 10, isGsm: isGsm);
        if (readIccid.isPinRequired) {
          _emit(_currentState.copyWith(
            errorCode: SmartCardErrorCode.pinLocked,
            errorMessage: 'الشريحة مقفلة برمز PIN / PUK (pinLocked)',
          ));
        } else if (readIccid.isSuccess && readIccid.data.isNotEmpty) {
          iccid = SmartCardProtocol.decodeBcdIccid(readIccid.data);
        }
      }

      // 3. SELECT DF_GSM (7F20) then EF_IMSI (6F07)
      String? imsi;
      final selDfGsm = await conn.selectFile(SmartCardProtocol.dfGsm, isGsm: isGsm);
      if (selDfGsm.isSuccess || selDfGsm.hasMoreData) {
        final selImsi = await conn.selectFile(SmartCardProtocol.efImsi, isGsm: isGsm);
        if (selImsi.isPinRequired) {
          _emit(_currentState.copyWith(
            errorCode: SmartCardErrorCode.pinLocked,
            errorMessage: 'قراءة IMSI تتطلب إدخال رمز PIN (pinLocked)',
          ));
        } else if (selImsi.isSuccess || selImsi.hasMoreData) {
          final readImsi = await conn.readBinary(0, 9, isGsm: isGsm);
          if (readImsi.isPinRequired) {
            _emit(_currentState.copyWith(
              errorCode: SmartCardErrorCode.pinLocked,
              errorMessage: 'قراءة IMSI تتطلب إدخال رمز PIN (pinLocked)',
            ));
          } else if (readImsi.isSuccess && readImsi.data.isNotEmpty) {
            imsi = SmartCardProtocol.decodeBcdImsi(readImsi.data);
          }
        }
      }

      // 4. Optional: Read EF_MSISDN (6F40) under DF_TELECOM (7F10)
      String? msisdn;
      try {
        await conn.selectFile(SmartCardProtocol.mfMaster, isGsm: isGsm);
        final selTelecom = await conn.selectFile(SmartCardProtocol.dfTelecom, isGsm: isGsm);
        if (selTelecom.isSuccess || selTelecom.hasMoreData) {
          final selMsisdn = await conn.selectFile(SmartCardProtocol.efMsisdn, isGsm: isGsm);
          if (selMsisdn.isSuccess || selMsisdn.hasMoreData) {
            final readMsisdn = await conn.readBinary(0, 14, isGsm: isGsm);
            if (readMsisdn.isSuccess && readMsisdn.data.isNotEmpty) {
              msisdn = SmartCardProtocol.decodeMsisdn(readMsisdn.data);
            }
          }
        }
      } catch (_) {}

      WinSCardNative.endTransaction(conn.hCard);

      if (iccid != null || imsi != null || conn.atr != null) {
        return CardInfo.fromPublicData(
          atr: conn.atr ?? '',
          iccid: iccid ?? '',
          imsi: imsi,
          msisdn: msisdn,
          protocolUsed: 'PC/SC ${conn.protocol} (CLA: 0x${conn.activeCla.toRadixString(16).toUpperCase()})',
        );
      }

      return null;
    } catch (_) {
      WinSCardNative.endTransaction(conn.hCard);
      return null;
    }
  }

  /// Explicitly verifies SIM PIN1 upon user request. Never retries automatically.
  Future<bool> verifyPin(String pin) async {
    if (_activeConnection == null || !_activeConnection!.isConnected) return false;
    final conn = _activeConnection!;
    final resp = await conn.verifyPin(pin, isGsm: conn.activeCla == SmartCardProtocol.claGsm);

    if (resp.isOk) {
      // PIN verified successfully, re-read card information
      final card = await _readCardData(conn);
      _emit(_currentState.copyWith(
        errorCode: SmartCardErrorCode.none,
        errorMessage: null,
        cardInfo: card,
      ));
      return true;
    } else if (resp.isPinFailed) {
      final rem = resp.remainingPinAttempts;
      _emit(_currentState.copyWith(
        errorCode: SmartCardErrorCode.pinLocked,
        errorMessage: 'رمز PIN غير صحيح. المحاولات المتبقية: ${rem ?? "?"}',
      ));
      return false;
    } else {
      _emit(_currentState.copyWith(
        errorCode: SmartCardErrorCode.protocolError,
        errorMessage: 'فشل التحقق من رمز PIN: ${resp.statusWordHex}',
      ));
      return false;
    }
  }

  /// Spawns a background isolate that executes SCardGetStatusChange to detect
  /// hardware reader arrival/removal and SIM card insertion/ejection without polling.
  void _startStatusMonitoringIsolate() {
    if (!Platform.isWindows) return;

    try {
      _monitorReceivePort = ReceivePort();
      Isolate.spawn(_statusMonitorWorker, _monitorReceivePort!.sendPort).then((iso) {
        _monitorIsolate = iso;
      });

      _monitorReceivePort!.listen((message) async {
        if (message is SendPort) {
          _isolateCommandPort = message;
          return;
        }

        if (message is Map<String, dynamic>) {
          final type = message['type'] as String?;

          if (type == 'readers_changed') {
            final readers = (message['readers'] as List<dynamic>?)?.cast<String>() ?? [];
            if (readers.isEmpty) {
              await _activeConnection?.disconnect();
              _activeConnection = null;
              _emit(SmartCardReaderState(
                status: SmartCardConnectionStatus.disconnected,
                errorCode: SmartCardErrorCode.noReader,
                errorMessage: 'تم فصل قارئ البطاقات الذكية (noReader)',
                lastEventTime: DateTime.now(),
              ));
            } else if (_activeConnection == null) {
              await connect(readers.first);
            }
          } else if (type == 'card_state_changed') {
            final isPresent = message['isPresent'] == true;
            final isEmpty = message['isEmpty'] == true;
            final reader = message['reader'] as String?;

            if (isEmpty) {
              await _activeConnection?.disconnect();
              _activeConnection = null;
              _emit(SmartCardReaderState(
                status: SmartCardConnectionStatus.cardWaiting,
                errorCode: SmartCardErrorCode.noCard,
                deviceInfo: reader != null ? ReaderDiscovery.inspectReader(reader) : _currentState.deviceInfo,
                errorMessage: 'تمت إزالة الشريحة من القارئ (noCard)',
                lastEventTime: DateTime.now(),
              ));
            } else if (isPresent && !_currentState.hasCard) {
              if (reader != null) {
                await connect(reader);
              }
            }
          }
        }
      });
    } catch (e) {
      AppLogger.warn('Could not spawn PC/SC status monitor isolate: $e');
    }
  }

  /// Background isolate worker monitoring SCardGetStatusChange
  static void _statusMonitorWorker(SendPort sendPort) {
    final cmdPort = ReceivePort();
    sendPort.send(cmdPort.sendPort);

    if (!Platform.isWindows || !WinSCardNative.init()) return;

    final hContext = WinSCardNative.establishContext();
    if (hContext == 0) return;

    bool isRunning = true;
    cmdPort.listen((msg) {
      if (msg == 'stop') {
        isRunning = false;
        WinSCardNative.cancelContext(hContext);
      }
    });

    List<String> lastKnownReaders = [];

    while (isRunning) {
      try {
        final currentReaders = WinSCardNative.listPcscReaders(hContext: hContext);

        if (currentReaders.length != lastKnownReaders.length ||
            !currentReaders.every((r) => lastKnownReaders.contains(r))) {
          lastKnownReaders = List<String>.from(currentReaders);
          sendPort.send({'type': 'readers_changed', 'readers': currentReaders});
        }

        if (currentReaders.isEmpty) {
          sleep(const Duration(milliseconds: 1000));
          continue;
        }

        final count = currentReaders.length;
        final pStates = calloc<ScardReaderStateA>(count);
        final stringPointers = <Pointer<Utf8>>[];

        for (int i = 0; i < count; i++) {
          final pStr = currentReaders[i].toNativeUtf8();
          stringPointers.add(pStr);
          pStates[i].szReader = pStr;
          pStates[i].pvUserData = nullptr;
          pStates[i].dwCurrentState = SCARD_STATE_UNAWARE;
          pStates[i].dwEventState = 0;
          pStates[i].cbAtr = 0;
        }

        // Get initial baseline
        int res = WinSCardNative.getStatusChange(hContext, 0, pStates, count);
        if (res == SCARD_S_SUCCESS) {
          for (int i = 0; i < count; i++) {
            pStates[i].dwCurrentState = pStates[i].dwEventState;
          }

          // Wait for state changes up to 1000ms
          res = WinSCardNative.getStatusChange(hContext, 1000, pStates, count);
          if (res == SCARD_S_SUCCESS) {
            for (int i = 0; i < count; i++) {
              final ev = pStates[i].dwEventState;
              if ((ev & SCARD_STATE_CHANGED) != 0) {
                final isPresent = (ev & SCARD_STATE_PRESENT) != 0;
                final isEmpty = (ev & SCARD_STATE_EMPTY) != 0;
                sendPort.send({
                  'type': 'card_state_changed',
                  'reader': currentReaders[i],
                  'isPresent': isPresent,
                  'isEmpty': isEmpty,
                });
              }
            }
          }
        }

        for (final p in stringPointers) {
          calloc.free(p);
        }
        calloc.free(pStates);
      } catch (_) {
        sleep(const Duration(milliseconds: 1000));
      }
    }

    WinSCardNative.releaseContext(hContext);
    cmdPort.close();
  }

  @override
  Future<void> disconnect() async {
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
    if (_activeConnection != null && _activeConnection!.isConnected) {
      final status = WinSCardNative.getCardStatus(_activeConnection!.hCard);
      return status['isPresent'] == true;
    }
    final readers = await listReaders();
    if (readers.isEmpty) return false;
    final status = WinSCardNative.checkCardStatus(readers.first.readerName);
    return status['isPresent'] == true;
  }

  @override
  Future<CardInfo?> getCardInfo() async {
    if (_activeConnection == null || !_activeConnection!.isConnected) return null;
    return await _readCardData(_activeConnection!);
  }

  @override
  void dispose() {
    _isolateCommandPort?.send('stop');
    _monitorReceivePort?.close();
    _monitorIsolate?.kill(priority: Isolate.immediate);

    _activeConnection?.disconnect();
    _activeConnection = null;

    if (_persistentContext != 0) {
      WinSCardNative.releaseContext(_persistentContext);
      _persistentContext = 0;
    }

    _stateController.close();
  }
}
