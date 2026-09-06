import 'dart:async';
import '../models/at_command.dart';
import '../models/at_response.dart';
import '../models/unsolicited_response.dart';
import 'modem_driver.dart';

class MockModemDriver implements IModemDriver {
  bool _isConnected = false;
  String? _activePort;
  int _activeBaudRate = 115200;

  String mockOperatorName = 'MOBILIS';
  String mockMsisdn = '0661123456';
  String mockImsi = '603011234567890';
  String mockIccid = '8921301000001234567';
  int mockSignalRssi = 25; // Good signal
  bool mockSimReady = true;

  final _unsolicitedController = StreamController<UnsolicitedResponse>.broadcast();

  @override
  String get driverName => 'Mock GSM Modem Simulator Driver';

  @override
  bool get isConnected => _isConnected;

  @override
  String? get activePort => _activePort;

  @override
  int get activeBaudRate => _activeBaudRate;

  @override
  Stream<UnsolicitedResponse> get unsolicitedEvents => _unsolicitedController.stream;

  @override
  Future<bool> connect(String portName, {int baudRate = 115200}) async {
    _activePort = portName;
    _activeBaudRate = baudRate;
    _isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _activePort = null;
  }

  @override
  Future<int?> probeBaudRate(String portName, {List<int> baudRates = const [115200, 57600, 38400, 19200, 9600]}) async {
    return 115200;
  }

  @override
  Future<AtResponse> sendRaw(String commandString, {Duration timeout = const Duration(seconds: 5)}) {
    return executeCommand(AtCommand(command: commandString, timeout: timeout));
  }

  @override
  Future<AtResponse> executeCommand(AtCommand command) async {
    final cmd = command.command.trim();
    final stopwatch = Stopwatch()..start();
    await Future.delayed(const Duration(milliseconds: 60)); // Simulate realistic bus latency
    stopwatch.stop();

    if (cmd == 'AT' || cmd == 'ATE0' || cmd == 'ATE1') {
      return AtResponse.fromRaw('OK', stopwatch.elapsed);
    }

    if (cmd == 'AT+CPIN?') {
      if (mockSimReady) {
        return AtResponse.fromRaw('+CPIN: READY\r\n\r\nOK', stopwatch.elapsed);
      } else {
        return AtResponse.fromRaw('+CPIN: SIM PIN\r\n\r\nOK', stopwatch.elapsed);
      }
    }

    if (cmd == 'AT+CSQ') {
      return AtResponse.fromRaw('+CSQ: $mockSignalRssi,99\r\n\r\nOK', stopwatch.elapsed);
    }

    if (cmd == 'AT+CREG?' || cmd == 'AT+CGREG?') {
      return AtResponse.fromRaw('+CREG: 0,1\r\n\r\nOK', stopwatch.elapsed); // 1 = Registered home network
    }

    if (cmd == 'AT+COPS?') {
      return AtResponse.fromRaw('+COPS: 0,0,"$mockOperatorName",7\r\n\r\nOK', stopwatch.elapsed);
    }

    if (cmd == 'AT+CIMI') {
      return AtResponse.fromRaw('$mockImsi\r\n\r\nOK', stopwatch.elapsed);
    }

    if (cmd == 'AT+CCID' || cmd == 'AT+QCCID') {
      return AtResponse.fromRaw('+CCID: "$mockIccid"\r\n\r\nOK', stopwatch.elapsed);
    }

    if (cmd == 'AT+CMGF=1' || cmd == 'AT+CMGF=0') {
      return AtResponse.fromRaw('OK', stopwatch.elapsed);
    }

    if (cmd.startsWith('AT+CMGL')) {
      final mockSmsList = [
        '+CMGL: 1,"REC READ","MOBILIS","","2026/09/06 14:30:15+04"\r\nVotre solde Flexy a ete credite de 50000.00 DA.',
        '+CMGL: 2,"REC READ","INFO","","2026/09/06 16:45:00+04"\r\nBienvenue sur le reseau Mobilis.',
      ].join('\r\n');
      return AtResponse.fromRaw('$mockSmsList\r\n\r\nOK', stopwatch.elapsed);
    }

    if (cmd.startsWith('AT+CUSD=1,')) {
      final match = RegExp(r'AT\+CUSD=1,"([^"]+)"').firstMatch(cmd);
      final ussdCode = match?.group(1) ?? '';
      final cusdResp = _generateMockUssdResponse(ussdCode);

      // Trigger unsolicited event asynchronously
      Future.microtask(() {
        _unsolicitedController.add(UnsolicitedResponse.parse(cusdResp));
      });

      return AtResponse.fromRaw('OK\r\n\r\n$cusdResp', stopwatch.elapsed);
    }

    return AtResponse.fromRaw('OK', stopwatch.elapsed);
  }

  String _generateMockUssdResponse(String ussd) {
    final clean = ussd.trim();

    // 1. Mobilis Flexy Transfer Prompt -> Asks for confirmation
    if (clean.startsWith('*630*') || clean.startsWith('*696*')) {
      return '+CUSD: 1, "Voulez-vous transferer le montant vers le destinataire ?\\n1: Confirmer\\n2: Annuler", 15';
    }

    // 2. Mobilis Solde
    if (clean.startsWith('*632*01*') || clean == '*600#') {
      return '+CUSD: 0, "Votre solde Flexy est de 48500.00 DA. Validite: 31/12/2026", 15';
    }

    // 3. Ooredoo Flexy
    if (clean.startsWith('*580*') || clean.startsWith('*585*')) {
      return '+CUSD: 1, "Transfert Ooredoo Flexy:\\n1: Confirmer\\n2: Rejeter", 15';
    }

    // 4. Djezzy Flexy
    if (clean.startsWith('*770*') || clean.startsWith('*710*')) {
      return '+CUSD: 1, "Djezzy Flexy POS:\\n1: Envoyer le credit\\n2: Retour", 15';
    }

    // 5. User replies '1' (Confirmation)
    if (clean == '1') {
      final ref = 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      return '+CUSD: 0, "Operation reussie. Ref: $ref. Nouveau solde disponible.", 15';
    }

    // 6. User replies '2' (Cancel)
    if (clean == '2') {
      return '+CUSD: 0, "Operation annulee par le vendeur.", 15';
    }

    // Default multi-option interactive menu simulation
    return '+CUSD: 1, "Menu POS:\\n1. Recharge Directe\\n2. Consultation Solde\\n3. Forfaits Internet\\n4. Quitter", 15';
  }

  @override
  void dispose() {
    _unsolicitedController.close();
  }
}
