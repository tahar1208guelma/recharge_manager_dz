import 'dart:async';
import '../core/utils/app_logger.dart';
import '../modem/models/at_command.dart';
import '../modem/modem_service.dart';
import 'sim_card_info.dart';
import 'sim_state.dart';

class SimService {
  final ModemService modemService;
  SimCardInfo _currentSim = const SimCardInfo(status: SimCardStatus.unknown);
  final _simStateController = StreamController<SimCardInfo>.broadcast();

  SimService({required this.modemService});

  SimCardInfo get currentSim => _currentSim;
  Stream<SimCardInfo> get simStateStream => _simStateController.stream;

  /// Checks SIM status via AT+CPIN?, then reads IMSI and ICCID if READY
  Future<SimCardInfo> checkSimStatus() async {
    AppLogger.info('SimService: Checking SIM card status...');

    final cpinResp = await modemService.executeCommand(
      AtCommand(command: 'AT+CPIN?', timeout: const Duration(seconds: 4)),
    );

    SimCardStatus status = SimCardStatus.unknown;
    final raw = cpinResp.rawOutput.toUpperCase();

    if (raw.contains('READY')) {
      status = SimCardStatus.ready;
    } else if (raw.contains('SIM PIN')) {
      status = SimCardStatus.pinRequired;
    } else if (raw.contains('SIM PUK')) {
      status = SimCardStatus.pukRequired;
    } else if (raw.contains('NOT INSERTED') || cpinResp.cmeError == 10) {
      status = SimCardStatus.absent;
    } else if (cpinResp.error != null) {
      status = SimCardStatus.error;
    }

    String? imsi;
    String? iccid;
    String? spn;

    if (status == SimCardStatus.ready) {
      // 1. Read IMSI (AT+CIMI)
      final imsiResp = await modemService.sendRaw('AT+CIMI', timeout: const Duration(seconds: 3));
      if (imsiResp.isSuccess) {
        final imsiMatch = RegExp(r'(\d{15})').firstMatch(imsiResp.rawOutput);
        imsi = imsiMatch?.group(1);
      }

      // 2. Read ICCID (AT+CCID or AT+QCCID)
      final ccidResp = await modemService.sendRaw('AT+CCID', timeout: const Duration(seconds: 3));
      if (ccidResp.isSuccess) {
        final iccidMatch = RegExp(r'(\d{18,20})').firstMatch(ccidResp.rawOutput);
        iccid = iccidMatch?.group(1);
      }

      // 3. Read SPN if available (AT+CRSM=176,28486,0,0,17)
      final spnResp = await modemService.sendRaw('AT+CPHS?', timeout: const Duration(seconds: 2));
      if (spnResp.isSuccess) {
        spn = spnResp.resultData;
      }
    }

    _currentSim = SimCardInfo.fromRaw(
      status: status,
      imsi: imsi,
      iccid: iccid,
      spn: spn,
    );

    _simStateController.add(_currentSim);
    AppLogger.info('SimService: Status is ${_currentSim.status.name}, Operator is ${_currentSim.operator.name}, IMSI: $imsi');
    return _currentSim;
  }

  /// Sends SIM PIN to unlock card (AT+CPIN="1234")
  Future<bool> unlockPin(String pin) async {
    final cleanPin = pin.trim();
    if (cleanPin.isEmpty) return false;

    AppLogger.info('SimService: Sending PIN unlock command...');
    final resp = await modemService.sendRaw('AT+CPIN="$cleanPin"', timeout: const Duration(seconds: 5));

    if (resp.isSuccess) {
      await Future.delayed(const Duration(milliseconds: 500));
      await checkSimStatus();
      return _currentSim.status == SimCardStatus.ready;
    }

    return false;
  }

  void dispose() {
    _simStateController.close();
  }
}
