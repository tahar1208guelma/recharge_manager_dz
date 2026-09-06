import 'dart:convert';
import '../core/constants/operator_constants.dart';

class OperatorProfile {
  final String id; // e.g. "mobilis_dz", "djezzy_dz", "ooredoo_dz"
  final String name; // e.g. "Mobilis"
  final String nameAr; // e.g. "موبيليس"
  final OperatorType operatorType;
  final String country; // "DZ"
  final String mcc; // "603"
  final String mnc; // "01", "02", "03"
  final List<String> phonePrefixes; // e.g. ["06", "065", "066", "067", "069"]
  final String defaultPin; // e.g. "11111", "0000", "00000"
  final Map<String, String> ussdTemplates; // e.g. {"recharge": "*630*{phone}*04*{amount}*{pin}#", "balance": "*600#"}
  final Map<String, String> smsCommands; // e.g. {"balance": "SOLDE"}
  final List<double> presetAmounts; // e.g. [100.0, 200.0, 500.0, 1000.0, 2000.0]
  final bool isEnabled;

  const OperatorProfile({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.operatorType,
    this.country = 'DZ',
    required this.mcc,
    required this.mnc,
    required this.phonePrefixes,
    required this.defaultPin,
    required this.ussdTemplates,
    this.smsCommands = const {},
    this.presetAmounts = const [100.0, 200.0, 500.0, 1000.0, 2000.0],
    this.isEnabled = true,
  });

  /// Builds a live USSD command using profile templates without hardcoding
  String buildUssd(String templateKey, {Map<String, String> params = const {}}) {
    final template = ussdTemplates[templateKey];
    if (template == null || template.isEmpty) return '';

    String result = template;
    params.forEach((k, v) {
      result = result.replaceAll('{$k}', v);
    });
    // Replace default PIN if present
    result = result.replaceAll('{pin}', params['pin'] ?? defaultPin);
    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_ar': nameAr,
      'operator_type': operatorType.name,
      'country': country,
      'mcc': mcc,
      'mnc': mnc,
      'phone_prefixes': jsonEncode(phonePrefixes),
      'default_pin': defaultPin,
      'ussd_templates': jsonEncode(ussdTemplates),
      'sms_commands': jsonEncode(smsCommands),
      'preset_amounts': jsonEncode(presetAmounts),
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory OperatorProfile.fromMap(Map<String, dynamic> map) {
    return OperatorProfile(
      id: map['id'] as String,
      name: map['name'] as String,
      nameAr: map['name_ar'] as String,
      operatorType: OperatorType.values.firstWhere(
        (e) => e.name == map['operator_type'],
        orElse: () => OperatorType.mobilis,
      ),
      country: map['country'] as String? ?? 'DZ',
      mcc: map['mcc'] as String? ?? '603',
      mnc: map['mnc'] as String? ?? '01',
      phonePrefixes: List<String>.from(jsonDecode(map['phone_prefixes'] as String? ?? '[]')),
      defaultPin: map['default_pin'] as String? ?? '0000',
      ussdTemplates: Map<String, String>.from(jsonDecode(map['ussd_templates'] as String? ?? '{}')),
      smsCommands: Map<String, String>.from(jsonDecode(map['sms_commands'] as String? ?? '{}')),
      presetAmounts: List<double>.from((jsonDecode(map['preset_amounts'] as String? ?? '[]') as List).map((e) => (e as num).toDouble())),
      isEnabled: (map['is_enabled'] as int? ?? 1) == 1,
    );
  }
}
