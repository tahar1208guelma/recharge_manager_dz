// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import '../../../core/utils/app_logger.dart';

// Win32 Constants for Serial Port (Kernel32)
const int GENERIC_READ = 0x80000000;
const int GENERIC_WRITE = 0x40000000;
const int OPEN_EXISTING = 3;
const int FILE_ATTRIBUTE_NORMAL = 0x00000080;
const int INVALID_HANDLE_VALUE = -1;

const int PURGE_TXABORT = 0x0001;
const int PURGE_RXABORT = 0x0002;
const int PURGE_TXCLEAR = 0x0004;
const int PURGE_RXCLEAR = 0x0008;

// DCB Flags
// bit 0: fBinary = 1
// bit 4-5: fDtrControl = 0x01 (DTR_CONTROL_ENABLE) -> (1 << 4) = 0x10
// bit 12-13: fRtsControl = 0x01 (RTS_CONTROL_ENABLE) -> (1 << 12) = 0x1000
const int DCB_FLAGS_8N1_DTR_RTS = 0x0001 | 0x0010 | 0x1000;

final class DCB extends Struct {
  @Uint32()
  external int DCBlength;
  @Uint32()
  external int BaudRate;
  @Uint32()
  external int fFlags;
  @Uint16()
  external int wReserved;
  @Uint16()
  external int XonLim;
  @Uint16()
  external int XoffLim;
  @Uint8()
  external int ByteSize;
  @Uint8()
  external int Parity;
  @Uint8()
  external int StopBits;
  @Int8()
  external int XonChar;
  @Int8()
  external int XoffChar;
  @Int8()
  external int ErrorChar;
  @Int8()
  external int EofChar;
  @Int8()
  external int EvtChar;
  @Uint16()
  external int wReserved1;
}

final class COMMTIMEOUTS extends Struct {
  @Uint32()
  external int ReadIntervalTimeout;
  @Uint32()
  external int ReadTotalTimeoutMultiplier;
  @Uint32()
  external int ReadTotalTimeoutConstant;
  @Uint32()
  external int WriteTotalTimeoutMultiplier;
  @Uint32()
  external int WriteTotalTimeoutConstant;
}

typedef CreateFileWC = IntPtr Function(
  Pointer<Utf16> lpFileName,
  Uint32 dwDesiredAccess,
  Uint32 dwShareMode,
  Pointer<Void> lpSecurityAttributes,
  Uint32 dwCreationDisposition,
  Uint32 dwFlagsAndAttributes,
  IntPtr hTemplateFile,
);
typedef CreateFileWDart = int Function(
  Pointer<Utf16> lpFileName,
  int dwDesiredAccess,
  int dwShareMode,
  Pointer<Void> lpSecurityAttributes,
  int dwCreationDisposition,
  int dwFlagsAndAttributes,
  int hTemplateFile,
);

typedef CloseHandleC = Int32 Function(IntPtr hObject);
typedef CloseHandleDart = int Function(int hObject);

typedef ReadFileC = Int32 Function(
  IntPtr hFile,
  Pointer<Uint8> lpBuffer,
  Uint32 nNumberOfBytesToRead,
  Pointer<Uint32> lpNumberOfBytesRead,
  Pointer<Void> lpOverlapped,
);
typedef ReadFileDart = int Function(
  int hFile,
  Pointer<Uint8> lpBuffer,
  int nNumberOfBytesToRead,
  Pointer<Uint32> lpNumberOfBytesRead,
  Pointer<Void> lpOverlapped,
);

typedef WriteFileC = Int32 Function(
  IntPtr hFile,
  Pointer<Uint8> lpBuffer,
  Uint32 nNumberOfBytesToWrite,
  Pointer<Uint32> lpNumberOfBytesWritten,
  Pointer<Void> lpOverlapped,
);
typedef WriteFileDart = int Function(
  int hFile,
  Pointer<Uint8> lpBuffer,
  int nNumberOfBytesToWrite,
  Pointer<Uint32> lpNumberOfBytesWritten,
  Pointer<Void> lpOverlapped,
);

typedef SetCommStateC = Int32 Function(IntPtr hFile, Pointer<DCB> lpDCB);
typedef SetCommStateDart = int Function(int hFile, Pointer<DCB> lpDCB);

typedef GetCommStateC = Int32 Function(IntPtr hFile, Pointer<DCB> lpDCB);
typedef GetCommStateDart = int Function(int hFile, Pointer<DCB> lpDCB);

typedef SetCommTimeoutsC = Int32 Function(IntPtr hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts);
typedef SetCommTimeoutsDart = int Function(int hFile, Pointer<COMMTIMEOUTS> lpCommTimeouts);

typedef PurgeCommC = Int32 Function(IntPtr hFile, Uint32 dwFlags);
typedef PurgeCommDart = int Function(int hFile, int dwFlags);

/// Persistent Windows Serial Port Driver communicating via Win32 Kernel32 FFI.
/// Avoids spawning external PowerShell processes for AT commands.
/// Abstract interface for a persistent serial port
abstract interface class ISerialPort {
  bool get isOpen;
  String? get portName;
  int get baudRate;
  bool open(String portName, {int baudRate = 115200});
  void close();
  bool write(String text);
  List<int> readChunk({int maxBytes = 256});
  Future<String> sendCommand(String command, {Duration timeout = const Duration(seconds: 5)});
}

class WindowsSerialPort implements ISerialPort {
  static DynamicLibrary? _kernel32;
  static CreateFileWDart? _createFileW;
  static CloseHandleDart? _closeHandle;
  static ReadFileDart? _readFile;
  static WriteFileDart? _writeFile;
  static SetCommStateDart? _setCommState;
  static GetCommStateDart? _getCommState;
  static SetCommTimeoutsDart? _setCommTimeouts;
  static PurgeCommDart? _purgeComm;

  static bool _init() {
    if (_kernel32 != null) return true;
    if (!Platform.isWindows) return false;
    try {
      _kernel32 = DynamicLibrary.open('kernel32.dll');
      _createFileW = _kernel32!.lookupFunction<CreateFileWC, CreateFileWDart>('CreateFileW');
      _closeHandle = _kernel32!.lookupFunction<CloseHandleC, CloseHandleDart>('CloseHandle');
      _readFile = _kernel32!.lookupFunction<ReadFileC, ReadFileDart>('ReadFile');
      _writeFile = _kernel32!.lookupFunction<WriteFileC, WriteFileDart>('WriteFile');
      _setCommState = _kernel32!.lookupFunction<SetCommStateC, SetCommStateDart>('SetCommState');
      _getCommState = _kernel32!.lookupFunction<GetCommStateC, GetCommStateDart>('GetCommState');
      _setCommTimeouts = _kernel32!.lookupFunction<SetCommTimeoutsC, SetCommTimeoutsDart>('SetCommTimeouts');
      _purgeComm = _kernel32!.lookupFunction<PurgeCommC, PurgeCommDart>('PurgeComm');
      return true;
    } catch (e) {
      AppLogger.error('Failed to load kernel32 serial bindings: $e');
      return false;
    }
  }

  int _handle = 0;
  String? _portName;
  int _baudRate = 115200;
  bool _isOpen = false;

  @override
  bool get isOpen => _isOpen && _handle != 0 && _handle != INVALID_HANDLE_VALUE;
  @override
  String? get portName => _portName;
  @override
  int get baudRate => _baudRate;

  /// Opens the COM port persistently with 8N1, DTR=true, RTS=true, and fast timeouts.
  @override
  bool open(String portName, {int baudRate = 115200}) {
    if (!_init()) return false;
    close();

    final cleanPort = portName.trim().toUpperCase();
    final devicePath = cleanPort.startsWith(r'\\.\') ? cleanPort : r'\\.\' + cleanPort;
    final pPath = devicePath.toNativeUtf16();

    try {
      _handle = _createFileW!(
        pPath,
        GENERIC_READ | GENERIC_WRITE,
        0, // Exclusive access
        nullptr,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0,
      );

      if (_handle == 0 || _handle == INVALID_HANDLE_VALUE) {
        AppLogger.warn('WindowsSerialPort: Failed to open $cleanPort (CreateFileW returned $_handle)');
        _handle = 0;
        return false;
      }

      // Configure DCB (Baud Rate, 8N1, DTR=true, RTS=true)
      final pDcb = calloc<DCB>();
      pDcb.ref.DCBlength = sizeOf<DCB>();
      _getCommState!(_handle, pDcb);

      pDcb.ref.BaudRate = baudRate;
      pDcb.ref.ByteSize = 8;
      pDcb.ref.Parity = 0; // NOPARITY
      pDcb.ref.StopBits = 0; // ONESTOPBIT
      pDcb.ref.fFlags = DCB_FLAGS_8N1_DTR_RTS; // fBinary=1, DTR=1, RTS=1

      final setDcbRes = _setCommState!(_handle, pDcb);
      calloc.free(pDcb);

      if (setDcbRes == 0) {
        AppLogger.warn('WindowsSerialPort: SetCommState failed for $cleanPort');
        close();
        return false;
      }

      // Configure Timeouts for responsive non-blocking line reading
      final pTimeouts = calloc<COMMTIMEOUTS>();
      pTimeouts.ref.ReadIntervalTimeout = 50;
      pTimeouts.ref.ReadTotalTimeoutMultiplier = 0;
      pTimeouts.ref.ReadTotalTimeoutConstant = 100;
      pTimeouts.ref.WriteTotalTimeoutMultiplier = 0;
      pTimeouts.ref.WriteTotalTimeoutConstant = 1000;

      _setCommTimeouts!(_handle, pTimeouts);
      calloc.free(pTimeouts);

      // Purge buffers
      _purgeComm!(_handle, PURGE_RXCLEAR | PURGE_TXCLEAR | PURGE_RXABORT | PURGE_TXABORT);

      _portName = cleanPort;
      _baudRate = baudRate;
      _isOpen = true;
      AppLogger.info('WindowsSerialPort: Successfully opened $cleanPort at $baudRate bps (DTR=true, RTS=true)');
      return true;
    } finally {
      calloc.free(pPath);
    }
  }

  /// Writes raw string data to the serial port
  @override
  bool write(String text) {
    if (!isOpen) return false;
    final bytes = utf8.encode(text);
    final pBuffer = calloc<Uint8>(bytes.length);
    final pWritten = calloc<Uint32>();

    try {
      for (int i = 0; i < bytes.length; i++) {
        pBuffer[i] = bytes[i];
      }
      final res = _writeFile!(_handle, pBuffer, bytes.length, pWritten, nullptr);
      return res != 0 && pWritten.value == bytes.length;
    } finally {
      calloc.free(pBuffer);
      calloc.free(pWritten);
    }
  }

  /// Reads a single chunk of bytes available on the port
  @override
  List<int> readChunk({int maxBytes = 256}) {
    if (!isOpen) return [];
    final pBuffer = calloc<Uint8>(maxBytes);
    final pRead = calloc<Uint32>();

    try {
      final res = _readFile!(_handle, pBuffer, maxBytes, pRead, nullptr);
      if (res != 0 && pRead.value > 0) {
        final count = pRead.value;
        final bytes = <int>[];
        for (int i = 0; i < count; i++) {
          bytes.add(pBuffer[i]);
        }
        return bytes;
      }
      return [];
    } finally {
      calloc.free(pBuffer);
      calloc.free(pRead);
    }
  }

  /// Sends an AT command and collects response lines until a terminal token
  /// (OK, ERROR, +CME ERROR, +CUSD) is encountered or timeout occurs.
  @override
  Future<String> sendCommand(
    String command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isOpen) return 'ERR: Port not open';

    // Clear stale input in receive buffer
    _purgeComm!(_handle, PURGE_RXCLEAR);

    final toSend = command.endsWith('\r') || command.endsWith('\n') ? command : '$command\r\n';
    final writeOk = write(toSend);
    if (!writeOk) {
      return 'ERR: Write failed';
    }

    final stopwatch = Stopwatch()..start();
    final buffer = StringBuffer();

    while (stopwatch.elapsed < timeout) {
      final chunk = readChunk(maxBytes: 512);
      if (chunk.isNotEmpty) {
        final text = utf8.decode(chunk, allowMalformed: true);
        buffer.write(text);
        final current = buffer.toString();

        // Check for terminal responses
        if (current.contains('OK\r') ||
            current.contains('OK\n') ||
            current.contains('ERROR\r') ||
            current.contains('ERROR\n') ||
            current.contains('+CME ERROR') ||
            current.contains('+CMS ERROR')) {
          // If CUSD was requested, make sure we got CUSD or error
          if (command.contains('AT+CUSD')) {
            if (current.contains('+CUSD:') || current.contains('ERROR')) {
              break;
            }
          } else {
            break;
          }
        } else if (current.contains('+CUSD:')) {
          break;
        }
      }
      await Future.delayed(const Duration(milliseconds: 30));
    }

    return buffer.toString().trim();
  }

  /// Closes the serial port handle cleanly
  @override
  void close() {
    if (_handle != 0 && _handle != INVALID_HANDLE_VALUE) {
      try {
        _closeHandle!(_handle);
      } catch (_) {}
      _handle = 0;
    }
    _isOpen = false;
    _portName = null;
  }

  /// Lists available COM ports on Windows
  static Future<List<String>> listComPorts() async {
    if (!Platform.isWindows) return [];
    try {
      final res = await Process.run('powershell', [
        '-NoProfile',
        '-Command',
        r"[System.IO.Ports.SerialPort]::GetPortNames()",
      ]);
      if (res.exitCode == 0 && res.stdout != null) {
        return LineSplitter.split(res.stdout.toString())
            .map((s) => s.trim().toUpperCase())
            .where((s) => s.isNotEmpty && s.startsWith('COM'))
            .toSet()
            .toList();
      }
    } catch (_) {}
    return [];
  }
}
