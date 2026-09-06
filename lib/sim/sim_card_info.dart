import '../core/constants/operator_constants.dart';
import 'sim_state.dart';

class SimCardInfo {
  final SimCardStatus status;
  final String? imsi;
  final String? iccid;
  final String? msisdn;
  final OperatorType operator;
  final String? spn; // Service Provider Name (e.g. Mobilis)
  final int? pinRetriesLeft;

  const SimCardInfo({
    required this.status,
    this.imsi,
    this.iccid,
    this.msisdn,
    this.operator = OperatorType.mobilis,
    this.spn,
    this.pinRetriesLeft,
  });

  factory SimCardInfo.fromRaw({
    required SimCardStatus status,
    String? imsi,
    String? iccid,
    String? msisdn,
    String? spn,
  }) {
    OperatorType detectedOp = OperatorType.mobilis;
    if (imsi != null) {
      if (imsi.startsWith('60301')) detectedOp = OperatorType.mobilis;
      if (imsi.startsWith('60302')) detectedOp = OperatorType.djezzy;
      if (imsi.startsWith('60303')) detectedOp = OperatorType.ooredoo;
    } else if (spn != null) {
      final s = spn.toLowerCase();
      if (s.contains('mobilis')) detectedOp = OperatorType.mobilis;
      if (s.contains('djezzy')) detectedOp = OperatorType.djezzy;
      if (s.contains('ooredoo') || s.contains('nedjma')) detectedOp = OperatorType.ooredoo;
    }

    return SimCardInfo(
      status: status,
      imsi: imsi,
      iccid: iccid,
      msisdn: msisdn,
      operator: detectedOp,
      spn: spn,
    );
  }
}
