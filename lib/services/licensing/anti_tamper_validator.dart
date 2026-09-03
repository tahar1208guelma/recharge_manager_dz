import '../../core/errors/exceptions.dart';
import '../../core/security/encryption_service.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/license.dart';
import '../../domain/repositories/license_repository.dart';

class AntiTamperValidator {
  static const String serverSigningSecret = 'DZ_LICENSE_SECRET_KEY_SIGNING_2026';
  final LicenseRepository repository;

  AntiTamperValidator({required this.repository});

  /// Verifies system time against stored monotonic checkpoints
  Future<bool> verifySystemClock() async {
    final now = DateTime.now();
    final lastCheck = await repository.getLastTamperCheckTimestamp();

    if (lastCheck != null) {
      // If current time is earlier than the last recorded checkpoint by more than 1 hour, clock tampering occurred
      if (now.isBefore(lastCheck.subtract(const Duration(hours: 1)))) {
        AppLogger.error('Clock tampering detected: Current time ($now) is earlier than recorded ($lastCheck)');
        throw LicenseException('System clock rollback detected. Please restore correct system time.');
      }
    }

    // Update monotonic timestamp checkpoint
    await repository.updateLastTamperCheckTimestamp(now);
    return true;
  }

  /// Verifies token integrity, device binding, expiry date, and offline grace period
  Future<bool> validateLicense({
    required LicenseEntity license,
    required String currentDeviceId,
  }) async {
    // 1. Check system clock
    await verifySystemClock();

    // 2. Device Binding Check
    if (license.deviceId != currentDeviceId) {
      AppLogger.error('Device mismatch: Licensed to ${license.deviceId}, running on $currentDeviceId');
      throw LicenseException('License is not valid for this device hardware ID');
    }

    // 3. Status check
    if (license.status == LicenseStatus.suspended) {
      throw LicenseException('License is suspended by administrator');
    }
    if (license.status == LicenseStatus.expired) {
      throw LicenseException('License has expired');
    }

    // 4. Expiration date check (except Lifetime)
    if (license.plan != LicensePlan.lifetime && license.expiryDate != null) {
      if (DateTime.now().isAfter(license.expiryDate!)) {
        throw LicenseException('License expired on ${license.expiryDate}');
      }
    }

    // 5. Offline Grace Period check
    final now = DateTime.now();
    final graceLimit = license.lastCheck.add(Duration(days: license.offlineGracePeriod));
    if (now.isAfter(graceLimit)) {
      throw LicenseException(
        'Offline grace period (${license.offlineGracePeriod} days) expired. Please connect to internet to verify license.',
      );
    }

    // 6. Cryptographic token verification (if token exists)
    if (license.token != null && license.token!.isNotEmpty) {
      final payload = '${license.licenseId}|${license.deviceId}|${license.plan.name}|${license.expiryDate?.toIso8601String() ?? 'LIFETIME'}';
      final isValid = EncryptionService.verifySignature(payload, license.token!, serverSigningSecret);
      if (!isValid) {
        AppLogger.warn('Cryptographic token signature mismatch for license ${license.licenseId}');
        throw LicenseException('License cryptographic signature is invalid');
      }
    }

    return true;
  }
}
