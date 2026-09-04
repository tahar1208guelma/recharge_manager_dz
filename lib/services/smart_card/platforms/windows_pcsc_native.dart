// ignore_for_file: constant_identifier_names

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../../core/utils/app_logger.dart';

// PC/SC Constants
const int SCARD_SCOPE_USER = 0;
const int SCARD_SCOPE_SYSTEM = 2;
const int SCARD_SHARE_SHARED = 2;
const int SCARD_SHARE_DIRECT = 3;
const int SCARD_PROTOCOL_T0 = 1;
const int SCARD_PROTOCOL_T1 = 2;
const int SCARD_PROTOCOL_RAW = 4;
const int SCARD_PROTOCOL_ANY = 3;
const int SCARD_LEAVE_CARD = 0;
const int SCARD_UNPOWER_CARD = 2;
const int SCARD_RESET_CARD = 1;

// PC/SC State Flags
const int SCARD_UNKNOWN = 0x00000000;
const int SCARD_ABSENT = 0x00000001;
const int SCARD_PRESENT = 0x00000002;
const int SCARD_SWALLOWED = 0x00000003;
const int SCARD_POWERED = 0x00000004;
const int SCARD_NEGOTIABLE = 0x00000005;
const int SCARD_SPECIFIC = 0x00000006;

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

typedef SCardDisconnectC = Int32 Function(
  IntPtr hCard,
  Uint32 dwDisposition,
);
typedef SCardDisconnectDart = int Function(
  int hCard,
  int dwDisposition,
);

typedef SCardReleaseContextC = Int32 Function(
  IntPtr hContext,
);
typedef SCardReleaseContextDart = int Function(
  int hContext,
);

class WinSCardNative {
  static DynamicLibrary? _winscardLib;
  static SCardEstablishContextDart? _establishContext;
  static SCardListReadersADart? _listReaders;
  static SCardConnectADart? _connect;
  static SCardStatusADart? _status;
  static SCardDisconnectDart? _disconnect;
  static SCardReleaseContextDart? _releaseContext;
  static bool _isInitialized = false;

  static bool init() {
    if (_isInitialized) return _winscardLib != null;
    _isInitialized = true;

    if (!Platform.isWindows) {
      AppLogger.warn('WinSCardNative: Not on Windows platform.');
      return false;
    }

    try {
      _winscardLib = DynamicLibrary.open('winscard.dll');
      _establishContext = _winscardLib!.lookupFunction<SCardEstablishContextC, SCardEstablishContextDart>('SCardEstablishContext');
      _listReaders = _winscardLib!.lookupFunction<SCardListReadersAC, SCardListReadersADart>('SCardListReadersA');
      _connect = _winscardLib!.lookupFunction<SCardConnectAC, SCardConnectADart>('SCardConnectA');
      _status = _winscardLib!.lookupFunction<SCardStatusAC, SCardStatusADart>('SCardStatusA');
      _disconnect = _winscardLib!.lookupFunction<SCardDisconnectC, SCardDisconnectDart>('SCardDisconnect');
      _releaseContext = _winscardLib!.lookupFunction<SCardReleaseContextC, SCardReleaseContextDart>('SCardReleaseContext');

      AppLogger.info('WinSCardNative: winscard.dll loaded successfully.');
      return true;
    } catch (e) {
      AppLogger.error('WinSCardNative: Failed to load winscard.dll: $e');
      _winscardLib = null;
      return false;
    }
  }

  /// Lists all smart card readers currently attached to Windows
  static List<String> listReaders() {
    if (!init()) return [];

    final pContext = calloc<IntPtr>();
    final pLen = calloc<Uint32>();

    try {
      final res = _establishContext!(SCARD_SCOPE_USER, nullptr, nullptr, pContext);
      if (res != 0) {
        AppLogger.warn('SCardEstablishContext failed with code: 0x${res.toRadixString(16)}');
        return [];
      }

      final hContext = pContext.value;

      final resLen = _listReaders!(hContext, nullptr, nullptr, pLen);
      if (resLen != 0 || pLen.value <= 1) {
        return [];
      }

      final buffer = calloc<Uint8>(pLen.value);
      final pUtf8 = buffer.cast<Utf8>();

      final resList = _listReaders!(hContext, nullptr, pUtf8, pLen);
      final readers = <String>[];

      if (resList == 0) {
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
      _releaseContext!(hContext);
      return readers;
    } catch (e) {
      AppLogger.error('WinSCardNative listReaders exception: $e');
      return [];
    } finally {
      calloc.free(pContext);
      calloc.free(pLen);
    }
  }

  /// Checks if a card is present in the specified reader and returns ATR hex string
  static Map<String, dynamic> checkCardStatus(String readerName) {
    if (!init()) return {'isPresent': false, 'atr': null};

    final pContext = calloc<IntPtr>();
    final pCard = calloc<IntPtr>();
    final pActiveProtocol = calloc<Uint32>();
    final pState = calloc<Uint32>();
    final pProtocol = calloc<Uint32>();
    final pReaderLen = calloc<Uint32>();
    final pAtrLen = calloc<Uint32>();
    final pAtr = calloc<Uint8>(36);

    try {
      final res = _establishContext!(SCARD_SCOPE_USER, nullptr, nullptr, pContext);
      if (res != 0) return {'isPresent': false, 'atr': null};

      final hContext = pContext.value;
      final szReader = readerName.toNativeUtf8();

      final connectRes = _connect!(
        hContext,
        szReader,
        SCARD_SHARE_SHARED,
        SCARD_PROTOCOL_ANY,
        pCard,
        pActiveProtocol,
      );

      calloc.free(szReader);

      if (connectRes != 0) {
        _releaseContext!(hContext);
        return {'isPresent': false, 'atr': null};
      }

      final hCard = pCard.value;
      pAtrLen.value = 36;
      pReaderLen.value = 0;

      final statusRes = _status!(
        hCard,
        nullptr,
        pReaderLen,
        pState,
        pProtocol,
        pAtr,
        pAtrLen,
      );

      bool isPresent = false;
      String? atrHex;

      if (statusRes == 0) {
        final state = pState.value;
        if (state >= SCARD_PRESENT) {
          isPresent = true;
          final atrBytes = <int>[];
          for (int i = 0; i < pAtrLen.value; i++) {
            atrBytes.add(pAtr[i]);
          }
          atrHex = atrBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
        }
      }

      _disconnect!(hCard, SCARD_LEAVE_CARD);
      _releaseContext!(hContext);

      return {
        'isPresent': isPresent,
        'atr': atrHex,
      };
    } catch (e) {
      AppLogger.error('WinSCard checkCardStatus error: $e');
      return {'isPresent': false, 'atr': null};
    } finally {
      calloc.free(pContext);
      calloc.free(pCard);
      calloc.free(pActiveProtocol);
      calloc.free(pState);
      calloc.free(pProtocol);
      calloc.free(pReaderLen);
      calloc.free(pAtrLen);
      calloc.free(pAtr);
    }
  }
}
