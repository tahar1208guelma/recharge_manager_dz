import '../core/constants/operator_constants.dart';
import 'default_profiles.dart';
import 'operator_profile.dart';

abstract class OperatorRepository {
  Future<List<OperatorProfile>> getAllProfiles();
  Future<OperatorProfile?> getProfileById(String id);
  Future<OperatorProfile?> getProfileByType(OperatorType type);
  Future<OperatorProfile?> detectFromPhone(String phoneNumber);
  Future<void> saveProfile(OperatorProfile profile);
  Future<void> updatePin(String id, String newPin);
  Future<void> updateTemplate(String id, String templateKey, String templateCode);
}

class InMemoryOperatorRepository implements OperatorRepository {
  final Map<String, OperatorProfile> _profiles = {};

  InMemoryOperatorRepository() {
    for (final p in DefaultProfiles.all) {
      _profiles[p.id] = p;
    }
  }

  @override
  Future<List<OperatorProfile>> getAllProfiles() async {
    return _profiles.values.where((p) => p.isEnabled).toList();
  }

  @override
  Future<OperatorProfile?> getProfileById(String id) async {
    return _profiles[id];
  }

  @override
  Future<OperatorProfile?> getProfileByType(OperatorType type) async {
    return _profiles.values.firstWhere((p) => p.operatorType == type, orElse: () => DefaultProfiles.mobilis);
  }

  @override
  Future<OperatorProfile?> detectFromPhone(String phoneNumber) async {
    final clean = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    for (final p in _profiles.values) {
      for (final prefix in p.phonePrefixes) {
        if (clean.startsWith(prefix) || clean.startsWith('213${prefix.substring(1)}') || clean.startsWith('+213${prefix.substring(1)}')) {
          return p;
        }
      }
    }
    return _profiles['mobilis_dz'];
  }

  @override
  Future<void> saveProfile(OperatorProfile profile) async {
    _profiles[profile.id] = profile;
  }

  @override
  Future<void> updatePin(String id, String newPin) async {
    final p = _profiles[id];
    if (p != null) {
      _profiles[id] = OperatorProfile(
        id: p.id,
        name: p.name,
        nameAr: p.nameAr,
        operatorType: p.operatorType,
        country: p.country,
        mcc: p.mcc,
        mnc: p.mnc,
        phonePrefixes: p.phonePrefixes,
        defaultPin: newPin.trim(),
        ussdTemplates: p.ussdTemplates,
        smsCommands: p.smsCommands,
        presetAmounts: p.presetAmounts,
        isEnabled: p.isEnabled,
      );
    }
  }

  @override
  Future<void> updateTemplate(String id, String templateKey, String templateCode) async {
    final p = _profiles[id];
    if (p != null) {
      final updatedTemplates = Map<String, String>.from(p.ussdTemplates);
      updatedTemplates[templateKey] = templateCode.trim();

      _profiles[id] = OperatorProfile(
        id: p.id,
        name: p.name,
        nameAr: p.nameAr,
        operatorType: p.operatorType,
        country: p.country,
        mcc: p.mcc,
        mnc: p.mnc,
        phonePrefixes: p.phonePrefixes,
        defaultPin: p.defaultPin,
        ussdTemplates: updatedTemplates,
        smsCommands: p.smsCommands,
        presetAmounts: p.presetAmounts,
        isEnabled: p.isEnabled,
      );
    }
  }
}
