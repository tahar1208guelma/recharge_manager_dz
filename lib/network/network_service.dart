import 'dart:async';
import '../core/utils/app_logger.dart';
import '../modem/models/at_command.dart';
import '../modem/modem_service.dart';
import 'network_info.dart';

class NetworkService {
  final ModemService modemService;
  NetworkInfo _networkInfo = const NetworkInfo();
  final _networkStateController = StreamController<NetworkInfo>.broadcast();

  NetworkService({required this.modemService});

  NetworkInfo get networkInfo => _networkInfo;
  Stream<NetworkInfo> get networkStateStream => _networkStateController.stream;

  /// Refreshes network status, registration (AT+CREG?), signal (AT+CSQ), and operator (AT+COPS?)
  Future<NetworkInfo> refreshNetworkInfo() async {
    AppLogger.info('NetworkService: Refreshing cellular network info...');

    // 1. Check Registration (AT+CREG?)
    NetworkRegistrationState regState = NetworkRegistrationState.unknown;
    final cregResp = await modemService.executeCommand(
      AtCommand(command: 'AT+CREG?', timeout: const Duration(seconds: 3)),
    );

    if (cregResp.isSuccess) {
      final match = RegExp(r'\+CREG:\s*\d+,(\d+)').firstMatch(cregResp.rawOutput);
      if (match != null) {
        final code = int.tryParse(match.group(1) ?? '');
        switch (code) {
          case 0:
            regState = NetworkRegistrationState.notSearching;
            break;
          case 1:
            regState = NetworkRegistrationState.registeredHome;
            break;
          case 2:
            regState = NetworkRegistrationState.searching;
            break;
          case 3:
            regState = NetworkRegistrationState.registrationDenied;
            break;
          case 5:
            regState = NetworkRegistrationState.registeredRoaming;
            break;
        }
      }
    }

    // 2. Read Signal Quality (AT+CSQ)
    int rssi = 99;
    int percent = 0;
    int? dbm;

    final csqResp = await modemService.executeCommand(
      AtCommand(command: 'AT+CSQ', timeout: const Duration(seconds: 3)),
    );

    if (csqResp.isSuccess) {
      final match = RegExp(r'\+CSQ:\s*(\d+),\s*(\d+)').firstMatch(csqResp.rawOutput);
      if (match != null) {
        rssi = int.tryParse(match.group(1) ?? '99') ?? 99;
        if (rssi <= 31) {
          percent = ((rssi / 31) * 100).clamp(0, 100).toInt();
          dbm = -113 + (rssi * 2);
        }
      }
    }

    // 3. Read Operator Name (AT+COPS?)
    String? opName;
    String? mcc;
    String? mnc;
    String? act;

    final copsResp = await modemService.executeCommand(
      AtCommand(command: 'AT+COPS?', timeout: const Duration(seconds: 4)),
    );

    if (copsResp.isSuccess) {
      final match = RegExp(r'\+COPS:\s*\d+,\s*\d+,\s*"([^"]+)"(?:,\s*(\d+))?').firstMatch(copsResp.rawOutput);
      if (match != null) {
        opName = match.group(1);
        final actCode = match.group(2);
        if (actCode != null) {
          switch (actCode) {
            case '0':
              act = '2G (GSM)';
              break;
            case '2':
              act = '3G (UMTS)';
              break;
            case '7':
              act = '4G (LTE)';
              break;
          }
        }
      }

      // Check numeric COPS format for MCC/MNC
      if (opName != null && RegExp(r'^\d{5,6}$').hasMatch(opName)) {
        mcc = opName.substring(0, 3);
        mnc = opName.substring(3);
        if (opName == '60301') opName = 'MOBILIS';
        if (opName == '60302') opName = 'Djezzy';
        if (opName == '60303') opName = 'Ooredoo';
      }
    }

    _networkInfo = NetworkInfo(
      registrationState: regState,
      signalRssi: rssi,
      signalPercent: percent,
      signalDbm: dbm,
      operatorName: opName,
      mcc: mcc,
      mnc: mnc,
      accessTechnology: act,
    );

    _networkStateController.add(_networkInfo);
    AppLogger.info('NetworkService: Registered: ${regState.isRegistered}, Signal: $percent%, Operator: $opName');
    return _networkInfo;
  }

  void dispose() {
    _networkStateController.close();
  }
}
