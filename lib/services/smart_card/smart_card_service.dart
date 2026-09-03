import 'dart:async';
import 'card_connection.dart';
import 'card_info.dart';
import 'reader_device_info.dart';
import 'smart_card_state.dart';

abstract class SmartCardService {
  Stream<SmartCardReaderState> get stateStream;
  SmartCardReaderState get currentState;
  CardConnection? get activeConnection;

  /// Initializes subsystem (PC/SC WinSCard on Windows, USB Host on Android)
  Future<void> initialize();

  /// Lists all attached smart card reader devices with their hardware descriptors
  Future<List<ReaderDeviceInfo>> listReaders();

  /// Connects to a specific reader by name or connects to the default attached reader
  Future<bool> connect([String? readerName]);

  /// Disconnects from current reader and active card session
  Future<void> disconnect();

  /// Checks if a SIM/Smart Card is physically inserted into the connected reader
  Future<bool> isCardPresent();

  /// Reads standard public EF files (EF_ICCID, EF_IMSI, EF_MSISDN) from the card
  Future<CardInfo?> getCardInfo();

  /// Releases handles and closes streams
  void dispose();
}
