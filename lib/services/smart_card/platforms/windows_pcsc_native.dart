// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../../core/utils/app_logger.dart';
import '../smart_card_error_code.dart';

// ==========================================
// Windows PC/SC WinSCard Native Definitions
// ==========================================

// PC/SC Scope
const int SCARD_SCOPE_USER = 0;
const int SCARD_SCOPE_TERMINAL = 1;
const int SCARD_SCOPE_SYSTEM = 2;

// PC/SC Share Mode
const int SCARD_SHARE_EXCLUSIVE = 1;
const int SCARD_SHARE_SHARED = 2;
const int SCARD_SHARE_DIRECT = 3;

// PC/SC Protocol
const int SCARD_PROTOCOL_UNDEFINED = 0x00000000;
const int SCARD_PROTOCOL_T0 = 0x00000001;
const int SCARD_PROTOCOL_T1 = 0x00000002;
const int SCARD_PROTOCOL_RAW = 0x00000004;
const int SCARD_PROTOCOL_ANY = 0x00000003; // T=0 | T=1

// PC/SC Disposition on Disconnect / EndTransaction
const int SCARD_LEAVE_CARD = 0;
const int SCARD_RESET_CARD = 1;
const int SCARD_UNPOWER_CARD = 2;
const int SCARD_EJECT_CARD = 3;

// PC/SC Error / Warning Codes
const int SCARD_S_SUCCESS = 0x00000000;
const int SCARD_E_CANCELLED = 0x80100002;
const int SCARD_E_INVALID_HANDLE = 0x80100003;
const int SCARD_E_INVALID_PARAMETER = 0x80100004;
const int SCARD_E_INVALID_TARGET = 0x80100005;
const int SCARD_E_NO_MEMORY = 0x80100006;
const int SCARD_E_UNKNOWN_READER = 0x80100009;
const int SCARD_E_TIMEOUT = 0x8010000A;
const int SCARD_E_SHARING_VIOLATION = 0x8010000B;
const int SCARD_E_NO_SMARTCARD = 0x8010000C;
const int SCARD_E_UNKNOWN_CARD = 0x8010000D;
const int SCARD_E_CANT_DISPOSE = 0x8010000E;
const int SCARD_E_PROTO_MISMATCH = 0x8010000F;
const int SCARD_E_NOT_READY = 0x80100010;
const int SCARD_E_INVALID_VALUE = 0x80100011;
const int SCARD_E_SYSTEM_CANCELLED = 0x80100012;
const int SCARD_F_COMM_ERROR = 0x80100013;
const int SCARD_F_UNKNOWN_ERROR = 0x80100014;
const int SCARD_E_INVALID_ATR = 0x80100015;
const int SCARD_E_NOT_TRANSACTED = 0x80100016;
const int SCARD_E_READER_UNAVAILABLE = 0x80100017;
const int SCARD_P_SHUTDOWN = 0x80100018;
const int SCARD_E_PCI_TOO_SMALL = 0x80100019;
const int SCARD_E_READER_UNSUPPORTED = 0x8010001A;
const int SCARD_E_DUPLICATE_READER = 0x8010001B;
const int SCARD_E_CARD_UNSUPPORTED = 0x8010001C;
const int SCARD_E_NO_SERVICE = 0x8010001D;
const int SCARD_E_SERVICE_STOPPED = 0x8010001E;
const int SCARD_E_UNEXPECTED = 0x8010001F;
const int SCARD_E_NO_READERS_AVAILABLE = 0x8010002E;
const int SCARD_W_UNSUPPORTED_CARD = 0x80100065;
const int SCARD_W_UNRESPONSIVE_CARD = 0x80100066;
const int SCARD_W_UNPOWERED_CARD = 0x80100067;
const int SCARD_W_RESET_CARD = 0x80100068;
const int SCARD_W_REMOVED_CARD = 0x80100069;
const int SCARD_W_SECURITY_VIOLATION = 0x8010006A;
const int SCARD_W_WRONG_CHV = 0x8010006B;
const int SCARD_W_CHV_BLOCKED = 0x8010006C;
const int SCARD_W_EOF = 0x8010006D;
const int SCARD_W_CANCELLED_BY_USER = 0x8010006E;
const int SCARD_W_CARD_NOT_AUTHENTICATED = 0x8010006F;

// PC/SC Reader / Card States for SCardStatus / SCardGetStatusChange
const int SCARD_UNKNOWN = 0x00000000;
const int SCARD_ABSENT = 0x00000001;
const int SCARD_PRESENT = 0x00000002;
const int SCARD_SWALLOWED = 0x00000003;
const int SCARD_POWERED = 0x00000004;
const int SCARD_NEGOTIABLE = 0x00000005;
const int SCARD_SPECIFIC = 0x00000006;

// SCardGetStatusChange Flags
const int SCARD_STATE_UNAWARE = 0x00000000;
const int SCARD_STATE_IGNORE = 0x00000001;
const int SCARD_STATE_CHANGED = 0x00000002;
const int SCARD_STATE_UNKNOWN = 0x00000004;
const int SCARD_STATE_UNAVAILABLE = 0x00000008;
const int SCARD_STATE_EMPTY = 0x00000010;
const int SCARD_STATE_PRESENT = 0x00000020;
const int SCARD_STATE_ATRMATCH = 0x00000040;
const int SCARD_STATE_EXCLUSIVE = 0x00000080;
const int SCARD_STATE_INUSE = 0x00000100;
const int SCARD_STATE_MUTE = 0x00000200;
const int SCARD_STATE_UNPOWERED = 0x00000400;

// Timeout Constants
const int INFINITE = 0xFFFFFFFF;

// Special Windows PnP reader name for reader arrival/removal notification
const String PNP_NOTIFICATION_READER = r'\\?PnP?\Notification';

// ==========================================
// Native Structs
// ==========================================

final class ScardIoRequest extends Struct {
  @Uint32()
  external int dwProtocol;
  @Uint32()
  external int cbPciLength;
}

final class ScardReaderStateA extends Struct {
  external Pointer<Utf8> szReader;
  external Pointer<Void> pvUserData;
  @Uint32()
  external int dwCurrentState;
  @Uint32()
  external int dwEventState;
  @Uint32()
  external int cbAtr;
  @Array(36)
  external Array<Uint8> rgbAtr;
}

// ==========================================
// Function Typedefs
// ==========================================

typedef SCardEstablishContextC = Int32 Function(
  Uint32 dwScope,
  Pointer<Void> pvReserved1,
  Pointer<Void> pvReserved2,
  Pointer<IntPtr> phContext,
);
typedef SCardEstablishContextDart = int Function(
  int dwScope,
  Pointer<Void> pvReserved1,
  Pointer<Void> pvReserved2,
  Pointer<IntPtr> phContext,
);

typedef SCardReleaseContextC = Int32 Function(IntPtr hContext);
typedef SCardReleaseContextDart = int Function(int hContext);

typedef SCardCancelC = Int32 Function(IntPtr hContext);
typedef SCardCancelDart = int Function(int hContext);

typedef SCardListReadersAC = Int32 Function(
  IntPtr hContext,
  Pointer<Utf8> mszGroups,
  Pointer<Utf8> mszReaders,
  Pointer<Uint32> pcchReaders,
);
typedef SCardListReadersADart = int Function(
  int hContext,
  Pointer<Utf8> mszGroups,
  Pointer<Utf8> mszReaders,
  Pointer<Uint32> pcchReaders,
);

typedef SCardConnectAC = Int32 Function(
  IntPtr hContext,
  Pointer<Utf8> szReader,
  Uint32 dwShareMode,
  Uint32 dwPreferredProtocols,
  Pointer<IntPtr> phCard,
  Pointer<Uint32> pdwActiveProtocol,
);
typedef SCardConnectADart = int Function(
  int hContext,
  Pointer<Utf8> szReader,
  int dwShareMode,
  int dwPreferredProtocols,
  Pointer<IntPtr> phCard,
  Pointer<Uint32> pdwActiveProtocol,
);

typedef SCardReconnectC = Int32 Function(
  IntPtr hCard,
  Uint32 dwShareMode,
  Uint32 dwPreferredProtocols,
  Uint32 dwInitialization,
  Pointer<Uint32> pdwActiveProtocol,
);
typedef SCardReconnectDart = int Function(
  int hCard,
  int dwShareMode,
  int dwPreferredProtocols,
  int dwInitialization,
  Pointer<Uint32> pdwActiveProtocol,
);

typedef SCardDisconnectC = Int32 Function(IntPtr hCard, Uint32 dwDisposition);
typedef SCardDisconnectDart = int Function(int hCard, int dwDisposition);

typedef SCardStatusAC = Int32 Function(
  IntPtr hCard,
  Pointer<Utf8> szReaderName,
  Pointer<Uint32> pcchReaderLen,
  Pointer<Uint32> pdwState,
  Pointer<Uint32> pdwProtocol,
  Pointer<Uint8> pbAtr,
  Pointer<Uint32> pcbAtrLen,
);
typedef SCardStatusADart = int Function(
  int hCard,
  Pointer<Utf8> szReaderName,
  Pointer<Uint32> pcchReaderLen,
  Pointer<Uint32> pdwState,
  Pointer<Uint32> pdwProtocol,
  Pointer<Uint8> pbAtr,
  Pointer<Uint32> pcbAtrLen,
);

typedef SCardBeginTransactionC = Int32 Function(IntPtr hCard);
typedef SCardBeginTransactionDart = int Function(int hCard);

typedef SCardEndTransactionC = Int32 Function(IntPtr hCard, Uint32 dwDisposition);
typedef SCardEndTransactionDart = int Function(int hCard, int dwDisposition);

typedef SCardTransmitC = Int32 Function(
  IntPtr hCard,
  Pointer<ScardIoRequest> pioSendPci,
  Pointer<Uint8> pbSendBuffer,
  Uint32 cbSendLength,
  Pointer<ScardIoRequest> pioRecvPci,
  Pointer<Uint8> pbRecvBuffer,
  Pointer<Uint32> pcbRecvLength,
);
typedef SCardTransmitDart = int Function(
  int hCard,
  Pointer<ScardIoRequest> pioSendPci,
  Pointer<Uint8> pbSendBuffer,
  int cbSendLength,
  Pointer<ScardIoRequest> pioRecvPci,
  Pointer<Uint8> pbRecvBuffer,
  Pointer<Uint32> pcbRecvLength,
);

typedef SCardGetStatusChangeAC = Int32 Function(
  IntPtr hContext,
  Uint32 dwTimeout,
  Pointer<ScardReaderStateA> rgReaderStates,
  Uint32 cReaders,
);
typedef SCardGetStatusChangeADart = int Function(
  int hContext,
  int dwTimeout,
  Pointer<ScardReaderStateA> rgReaderStates,
  int cReaders,
);

// ==========================================
// WinSCard Native Class
// ==========================================

class WinSCardNative {
  static DynamicLibrary? _winscardLib;
  static SCardEstablishContextDart? _establishContext;
  static SCardReleaseContextDart? _releaseContext;
  static SCardCancelDart? _cancel;
  static SCardListReadersADart? _listReadersA;
  static SCardConnectADart? _connectA;
  static SCardReconnectDart? _reconnect;
  static SCardDisconnectDart? _disconnect;
  static SCardStatusADart? _statusA;
  static SCardBeginTransactionDart? _beginTransaction;
  static SCardEndTransactionDart? _endTransaction;
  static SCardTransmitDart? _transmit;
  static SCardGetStatusChangeADart? _getStatusChangeA;

  // Global PCI pointers exported by winscard.dll
  static Pointer<ScardIoRequest>? _pciT0;
  static Pointer<ScardIoRequest>? _pciT1;

  static bool _isInitialized = false;

  /// Initializes the winscard.dll dynamic library and resolves C symbols
  static bool init() {
    if (_isInitialized) return _winscardLib != null;
    _isInitialized = true;

    if (!Platform.isWindows) {
      return false;
    }

    try {
      _winscardLib = DynamicLibrary.open('winscard.dll');
      _establishContext = _winscardLib!.lookupFunction<SCardEstablishContextC, SCardEstablishContextDart>('SCardEstablishContext');
      _releaseContext = _winscardLib!.lookupFunction<SCardReleaseContextC, SCardReleaseContextDart>('SCardReleaseContext');
      _cancel = _winscardLib!.lookupFunction<SCardCancelC, SCardCancelDart>('SCardCancel');
      _listReadersA = _winscardLib!.lookupFunction<SCardListReadersAC, SCardListReadersADart>('SCardListReadersA');
      _connectA = _winscardLib!.lookupFunction<SCardConnectAC, SCardConnectADart>('SCardConnectA');
      _reconnect = _winscardLib!.lookupFunction<SCardReconnectC, SCardReconnectDart>('SCardReconnect');
      _disconnect = _winscardLib!.lookupFunction<SCardDisconnectC, SCardDisconnectDart>('SCardDisconnect');
      _statusA = _winscardLib!.lookupFunction<SCardStatusAC, SCardStatusADart>('SCardStatusA');
      _beginTransaction = _winscardLib!.lookupFunction<SCardBeginTransactionC, SCardBeginTransactionDart>('SCardBeginTransaction');
      _endTransaction = _winscardLib!.lookupFunction<SCardEndTransactionC, SCardEndTransactionDart>('SCardEndTransaction');
      _transmit = _winscardLib!.lookupFunction<SCardTransmitC, SCardTransmitDart>('SCardTransmit');
      _getStatusChangeA = _winscardLib!.lookupFunction<SCardGetStatusChangeAC, SCardGetStatusChangeADart>('SCardGetStatusChangeA');

      // Lookup standard exported PCI structures
      try {
        _pciT0 = _winscardLib!.lookup<ScardIoRequest>('g_rgSCardT0Pci');
      } catch (_) {
        _pciT0 = null;
      }

      try {
        _pciT1 = _winscardLib!.lookup<ScardIoRequest>('g_rgSCardT1Pci');
      } catch (_) {
        _pciT1 = null;
      }

      AppLogger.info('WinSCardNative: winscard.dll loaded successfully with full PC/SC bindings.');
      return true;
    } catch (e) {
      AppLogger.error('WinSCardNative: Failed to load winscard.dll: $e');
      _winscardLib = null;
      return false;
    }
  }

  /// Establishes a PC/SC context. Returns hContext (IntPtr) or 0 on failure.
  static int establishContext({int scope = SCARD_SCOPE_USER}) {
    if (!init() || _establishContext == null) return 0;
    final pContext = calloc<IntPtr>();
    try {
      int res = _establishContext!(scope, nullptr, nullptr, pContext);
      if (res != 0 && scope == SCARD_SCOPE_USER) {
        // Fallback to SYSTEM scope if USER scope failed
        res = _establishContext!(SCARD_SCOPE_SYSTEM, nullptr, nullptr, pContext);
      }
      if (res == SCARD_S_SUCCESS) {
        return pContext.value;
      }
      AppLogger.warn('SCardEstablishContext error: 0x${res.toRadixString(16)}');
      return 0;
    } finally {
      calloc.free(pContext);
    }
  }

  /// Releases a previously established PC/SC context
  static void releaseContext(int hContext) {
    if (hContext == 0 || !init() || _releaseContext == null) return;
    try {
      _releaseContext!(hContext);
    } catch (e) {
      AppLogger.warn('SCardReleaseContext error: $e');
    }
  }

  /// Cancels any pending blocking SCardGetStatusChange call on the context
  static void cancelContext(int hContext) {
    if (hContext == 0 || !init() || _cancel == null) return;
    try {
      _cancel!(hContext);
    } catch (_) {}
  }

  /// Monitors status changes across multiple readers using SCardGetStatusChangeA
  static int getStatusChange(
    int hContext,
    int dwTimeout,
    Pointer<ScardReaderStateA> rgReaderStates,
    int cReaders,
  ) {
    if (!init() || _getStatusChangeA == null) return -1;
    return _getStatusChangeA!(hContext, dwTimeout, rgReaderStates, cReaders);
  }

  /// Lists all real smart card readers currently attached to Windows via SCardListReadersA.
  /// If [hContext] is not supplied, a temporary context is created and released.
  static List<String> listPcscReaders({int? hContext}) {
    if (!init() || _listReadersA == null) return [];

    final bool ownContext = hContext == null || hContext == 0;
    final ctx = ownContext ? establishContext() : hContext;
    if (ctx == 0) return [];

    final pLen = calloc<Uint32>();

    try {
      // 1. Determine required buffer size
      final resLen = _listReadersA!(ctx, nullptr, nullptr, pLen);
      if (resLen != SCARD_S_SUCCESS || pLen.value <= 1) {
        return [];
      }

      // 2. Read multi-string buffer
      final buffer = calloc<Uint8>(pLen.value);
      final pUtf8 = buffer.cast<Utf8>();
      final resList = _listReadersA!(ctx, nullptr, pUtf8, pLen);
      final readers = <String>[];

      if (resList == SCARD_S_SUCCESS) {
        int offset = 0;
        final totalBytes = pLen.value;
        while (offset < totalBytes) {
          final strPtr = buffer.elementAt(offset).cast<Utf8>();
          final name = strPtr.toDartString();
          if (name.trim().isEmpty) break;
          readers.add(name);
          offset += name.length + 1;
        }
      }

      calloc.free(buffer);
      return readers;
    } catch (e) {
      AppLogger.error('WinSCardNative listPcscReaders exception: $e');
      return [];
    } finally {
      calloc.free(pLen);
      if (ownContext) {
        releaseContext(ctx);
      }
    }
  }

  /// Master list of real PC/SC Smart Card readers.
  /// Never returns fake readers.
  static Future<List<String>> listAllReaders({int? hContext}) async {
    return listPcscReaders(hContext: hContext);
  }

  /// Connects to a card in the specified reader using an existing context.
  /// Returns a map containing:
  /// - 'hCard': int handle
  /// - 'activeProtocol': int (SCARD_PROTOCOL_T0 / T1)
  /// - 'returnCode': int Windows error code
  static Map<String, dynamic> connectCard(
    int hContext,
    String readerName, {
    int shareMode = SCARD_SHARE_SHARED,
    int preferredProtocols = SCARD_PROTOCOL_ANY,
  }) {
    if (hContext == 0 || !init() || _connectA == null) {
      return {'hCard': 0, 'activeProtocol': 0, 'returnCode': SCARD_E_INVALID_HANDLE};
    }

    final pCard = calloc<IntPtr>();
    final pActiveProto = calloc<Uint32>();
    final szReader = readerName.toNativeUtf8();

    try {
      final res = _connectA!(
        hContext,
        szReader,
        shareMode,
        preferredProtocols,
        pCard,
        pActiveProto,
      );

      return {
        'hCard': pCard.value,
        'activeProtocol': pActiveProto.value,
        'returnCode': res,
      };
    } finally {
      calloc.free(szReader);
      calloc.free(pCard);
      calloc.free(pActiveProto);
    }
  }

  /// Reconnects to an active card handle (e.g. after SCARD_W_RESET_CARD)
  static int reconnectCard(
    int hCard, {
    int shareMode = SCARD_SHARE_SHARED,
    int preferredProtocols = SCARD_PROTOCOL_ANY,
    int initialization = SCARD_RESET_CARD,
    Pointer<Uint32>? outActiveProto,
  }) {
    if (hCard == 0 || !init() || _reconnect == null) return SCARD_E_INVALID_HANDLE;

    final pProto = outActiveProto ?? calloc<Uint32>();
    try {
      final res = _reconnect!(
        hCard,
        shareMode,
        preferredProtocols,
        initialization,
        pProto,
      );
      return res;
    } finally {
      if (outActiveProto == null) {
        calloc.free(pProto);
      }
    }
  }

  /// Disconnects from an active card handle
  static void disconnectCard(int hCard, {int disposition = SCARD_LEAVE_CARD}) {
    if (hCard == 0 || !init() || _disconnect == null) return;
    try {
      _disconnect!(hCard, disposition);
    } catch (_) {}
  }

  /// Begins an exclusive transaction on the card
  static int beginTransaction(int hCard) {
    if (hCard == 0 || !init() || _beginTransaction == null) return SCARD_E_INVALID_HANDLE;
    try {
      return _beginTransaction!(hCard);
    } catch (e) {
      return SCARD_F_UNKNOWN_ERROR;
    }
  }

  /// Ends an exclusive transaction on the card
  static int endTransaction(int hCard, {int disposition = SCARD_LEAVE_CARD}) {
    if (hCard == 0 || !init() || _endTransaction == null) return SCARD_E_INVALID_HANDLE;
    try {
      return _endTransaction!(hCard, disposition);
    } catch (_) {
      return SCARD_F_UNKNOWN_ERROR;
    }
  }

  /// Gets the real card status and ATR from an active card handle (SCardStatusA)
  static Map<String, dynamic> getCardStatus(int hCard) {
    if (hCard == 0 || !init() || _statusA == null) {
      return {'isPresent': false, 'atr': null, 'rawAtr': <int>[], 'state': SCARD_UNKNOWN, 'returnCode': SCARD_E_INVALID_HANDLE};
    }

    final pReaderLen = calloc<Uint32>();
    final pState = calloc<Uint32>();
    final pProtocol = calloc<Uint32>();
    final pAtrLen = calloc<Uint32>()..value = 36;
    final pAtr = calloc<Uint8>(36);

    try {
      final res = _statusA!(
        hCard,
        nullptr,
        pReaderLen,
        pState,
        pProtocol,
        pAtr,
        pAtrLen,
      );

      if (res != SCARD_S_SUCCESS) {
        return {
          'isPresent': false,
          'atr': null,
          'rawAtr': <int>[],
          'state': pState.value,
          'protocol': pProtocol.value,
          'returnCode': res,
        };
      }

      final rawAtr = <int>[];
      for (int i = 0; i < pAtrLen.value; i++) {
        rawAtr.add(pAtr[i]);
      }

      final atrHex = rawAtr.isNotEmpty
          ? rawAtr.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ')
          : null;

      final isPresent = pState.value >= SCARD_PRESENT;

      return {
        'isPresent': isPresent,
        'atr': atrHex,
        'rawAtr': rawAtr,
        'state': pState.value,
        'protocol': pProtocol.value,
        'returnCode': res,
      };
    } finally {
      calloc.free(pReaderLen);
      calloc.free(pState);
      calloc.free(pProtocol);
      calloc.free(pAtrLen);
      calloc.free(pAtr);
    }
  }

  /// Checks if a card is present in reader by name (using temporary connection) and returns ATR
  static Map<String, dynamic> checkCardStatus(String readerName) {
    final ctx = establishContext();
    if (ctx == 0) {
      return {'isPresent': false, 'atr': null, 'errorCode': SmartCardErrorCode.noReader};
    }

    try {
      final conn = connectCard(ctx, readerName);
      final retCode = conn['returnCode'] as int;

      if (retCode == SCARD_E_NO_SMARTCARD) {
        return {'isPresent': false, 'atr': null, 'errorCode': SmartCardErrorCode.noCard};
      } else if (retCode != SCARD_S_SUCCESS) {
        return {'isPresent': false, 'atr': null, 'errorCode': SmartCardErrorCode.noReader};
      }

      final hCard = conn['hCard'] as int;
      final status = getCardStatus(hCard);
      disconnectCard(hCard, disposition: SCARD_LEAVE_CARD);

      final isPresent = status['isPresent'] == true;
      final atr = status['atr'] as String?;

      return {
        'isPresent': isPresent,
        'atr': atr,
        'errorCode': isPresent ? SmartCardErrorCode.none : SmartCardErrorCode.noCard,
      };
    } finally {
      releaseContext(ctx);
    }
  }

  /// Transmits a raw APDU byte array over an active card handle via SCardTransmit
  static Map<String, dynamic> transmit({
    required int hCard,
    required int activeProtocol,
    required List<int> apdu,
  }) {
    if (hCard == 0 || !init() || _transmit == null) {
      return {
        'isSuccess': false,
        'sw1': 0x6F,
        'sw2': 0x00,
        'data': <int>[],
        'returnCode': SCARD_E_INVALID_HANDLE,
      };
    }

    // Select standard exported PCI structure or allocate fallback
    Pointer<ScardIoRequest> pSendPci;
    bool allocatedPci = false;

    if (activeProtocol == SCARD_PROTOCOL_T1 && _pciT1 != null) {
      pSendPci = _pciT1!;
    } else if (_pciT0 != null) {
      pSendPci = _pciT0!;
    } else {
      pSendPci = calloc<ScardIoRequest>();
      pSendPci.ref.dwProtocol = activeProtocol;
      pSendPci.ref.cbPciLength = sizeOf<ScardIoRequest>();
      allocatedPci = true;
    }

    final pSendBuffer = calloc<Uint8>(apdu.length);
    for (int i = 0; i < apdu.length; i++) {
      pSendBuffer[i] = apdu[i];
    }

    // Standard ISO 7816-4 maximum Le response buffer (256 data + 2 SW = 258)
    const maxRecv = 258;
    final pRecvBuffer = calloc<Uint8>(maxRecv);
    final pRecvLen = calloc<Uint32>()..value = maxRecv;

    try {
      int transmitRes = _transmit!(
        hCard,
        pSendPci,
        pSendBuffer,
        apdu.length,
        nullptr,
        pRecvBuffer,
        pRecvLen,
      );

      // Handle card reset or removal warning by reconnecting once
      if (transmitRes == SCARD_W_RESET_CARD || transmitRes == SCARD_W_REMOVED_CARD) {
        final reconnected = reconnectCard(hCard);
        if (reconnected == SCARD_S_SUCCESS) {
          pRecvLen.value = maxRecv;
          transmitRes = _transmit!(
            hCard,
            pSendPci,
            pSendBuffer,
            apdu.length,
            nullptr,
            pRecvBuffer,
            pRecvLen,
          );
        }
      }

      int sw1 = 0x6F;
      int sw2 = 0x00;
      final data = <int>[];
      bool isSuccess = false;

      if (transmitRes == SCARD_S_SUCCESS && pRecvLen.value >= 2) {
        final totalRecv = pRecvLen.value;
        sw1 = pRecvBuffer[totalRecv - 2];
        sw2 = pRecvBuffer[totalRecv - 1];
        for (int i = 0; i < totalRecv - 2; i++) {
          data.add(pRecvBuffer[i]);
        }
        isSuccess = (sw1 == 0x90 && sw2 == 0x00) || sw1 == 0x91 || sw1 == 0x61;
      }

      return {
        'isSuccess': isSuccess,
        'sw1': sw1,
        'sw2': sw2,
        'data': data,
        'returnCode': transmitRes,
      };
    } finally {
      if (allocatedPci) calloc.free(pSendPci);
      calloc.free(pSendBuffer);
      calloc.free(pRecvBuffer);
      calloc.free(pRecvLen);
    }
  }

  /// Diagnostic hint: Scans Windows PNP Devices via PowerShell WMI to report devices
  /// seen by the OS but not exposed as CCID Smart Card Readers in winscard.dll.
  static Future<List<String>> pnpDiagnosticScan() async {
    if (!Platform.isWindows) return [];
    final found = <String>[];
    try {
      const script = "Get-CimInstance Win32_PnPEntity | Where-Object { \$_.PNPClass -in @('SmartCardReader') -or \$_.Name -match 'Smart.*Card|ACR|Omnikey|Gemalto' } | Select-Object -ExpandProperty Name";
      final result = await Process.run('powershell', ['-NoProfile', '-Command', script]);
      if (result.exitCode == 0 && result.stdout != null) {
        final lines = LineSplitter.split(result.stdout.toString());
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isNotEmpty && !found.contains(trimmed)) {
            found.add(trimmed);
          }
        }
      }
    } catch (_) {}
    return found;
  }

  /// Ensures that the Windows Smart Card service (SCardSvr) is started.
  static Future<bool> ensureSmartCardServiceRunning() async {
    if (!Platform.isWindows) return false;
    try {
      final res = await Process.run('sc.exe', ['start', 'SCardSvr']);
      return res.exitCode == 0 || (res.stdout?.toString().contains('already') ?? false);
    } catch (_) {
      return false;
    }
  }
}
