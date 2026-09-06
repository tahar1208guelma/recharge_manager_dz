import 'generic_at_modem_driver.dart';

class HuaweiDriver extends GenericAtModemDriver {
  @override
  String get driverName => 'Huawei Mobile Connect USB Modem Driver (E3531 / E173 / E303)';

  /// Checks if Huawei SIM lock is active (AT^CARDLOCK?)
  Future<bool> isSimLocked() async {
    final resp = await sendRaw('AT^CARDLOCK?');
    if (resp.rawOutput.contains('^CARDLOCK: 1') || resp.rawOutput.contains('^CARDLOCK: 2')) {
      return true;
    }
    return false;
  }
}
