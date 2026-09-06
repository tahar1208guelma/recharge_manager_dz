import 'dart:async';
import '../models/at_command.dart';
import '../models/at_response.dart';
import '../models/unsolicited_response.dart';

abstract class IModemDriver {
  String get driverName;
  bool get isConnected;
  String? get activePort;
  int get activeBaudRate;

  /// Stream of unsolicited responses from network (+CUSD, +CMTI, etc.)
  Stream<UnsolicitedResponse> get unsolicitedEvents;

  /// Opens serial connection to the specified port
  Future<bool> connect(String portName, {int baudRate = 115200});

  /// Closes the active serial connection
  Future<void> disconnect();

  /// Executes an AT command and waits for response within timeout
  Future<AtResponse> executeCommand(AtCommand command);

  /// Helper to send raw string command
  Future<AtResponse> sendRaw(String commandString, {Duration timeout = const Duration(seconds: 5)}) {
    return executeCommand(AtCommand(command: commandString, timeout: timeout));
  }

  /// Probes multiple standard baud rates to find the working baud rate
  Future<int?> probeBaudRate(String portName, {List<int> baudRates = const [115200, 57600, 38400, 19200, 9600]});

  /// Releases resources
  void dispose();
}
