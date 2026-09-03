import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/errors/exceptions.dart';
import 'package:recharge_manager_dz/core/security/encryption_service.dart';
import 'package:recharge_manager_dz/domain/entities/license.dart';
import 'package:recharge_manager_dz/domain/repositories/license_repository.dart';
import 'package:recharge_manager_dz/services/licensing/anti_tamper_validator.dart';

class FakeLicenseRepository implements LicenseRepository {
  DateTime? _tamperTime;
  LicenseEntity? _license;

  @override
  Future<void> clearLicense() async => _license = null;

  @override
  Future<LicenseEntity?> getCachedLicense() async => _license;

  @override
  Future<DateTime?> getLastTamperCheckTimestamp() async => _tamperTime;

  @override
  Future<void> saveLicense(LicenseEntity license) async => _license = license;

  @override
  Future<void> updateLastTamperCheckTimestamp(DateTime timestamp) async => _tamperTime = timestamp;
}

void main() {
  group('License Validator & Anti-Tampering Tests', () {
    late FakeLicenseRepository fakeRepo;
    late AntiTamperValidator validator;

    setUp(() {
      fakeRepo = FakeLicenseRepository();
      validator = AntiTamperValidator(repository: fakeRepo);
    });

    test('Should pass validation for valid active license matching device', () async {
      final now = DateTime.now();
      const deviceId = 'DZ-TEST-DEVICE-001';
      final expiry = now.add(const Duration(days: 30));

      final token = EncryptionService.sign(
        'LIC-001|$deviceId|monthly|${expiry.toIso8601String()}',
        AntiTamperValidator.serverSigningSecret,
      );

      final license = LicenseEntity(
        licenseId: 'LIC-001',
        customerId: 'CUST-01',
        plan: LicensePlan.monthly,
        status: LicenseStatus.active,
        createdAt: now,
        startDate: now,
        expiryDate: expiry,
        deviceId: deviceId,
        lastCheck: now,
        offlineGracePeriod: 7,
        token: token,
      );

      final isValid = await validator.validateLicense(license: license, currentDeviceId: deviceId);
      expect(isValid, true);
    });

    test('Should throw LicenseException if device ID does not match', () async {
      final now = DateTime.now();
      final license = LicenseEntity(
        licenseId: 'LIC-001',
        customerId: 'CUST-01',
        plan: LicensePlan.yearly,
        status: LicenseStatus.active,
        createdAt: now,
        startDate: now,
        expiryDate: now.add(const Duration(days: 365)),
        deviceId: 'DZ-BOUND-DEVICE-A',
        lastCheck: now,
      );

      expect(
        () => validator.validateLicense(license: license, currentDeviceId: 'DZ-DIFFERENT-DEVICE-B'),
        throwsA(isA<LicenseException>()),
      );
    });

    test('Should throw LicenseException if offline grace period is exceeded', () async {
      final oldDate = DateTime.now().subtract(const Duration(days: 15));
      final license = LicenseEntity(
        licenseId: 'LIC-001',
        customerId: 'CUST-01',
        plan: LicensePlan.yearly,
        status: LicenseStatus.active,
        createdAt: oldDate,
        startDate: oldDate,
        expiryDate: DateTime.now().add(const Duration(days: 300)),
        deviceId: 'DZ-DEVICE-1',
        lastCheck: oldDate, // 15 days ago
        offlineGracePeriod: 7, // 7 days grace limit
      );

      expect(
        () => validator.validateLicense(license: license, currentDeviceId: 'DZ-DEVICE-1'),
        throwsA(isA<LicenseException>()),
      );
    });
  });
}
