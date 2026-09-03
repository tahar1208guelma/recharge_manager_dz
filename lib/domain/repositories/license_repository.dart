import '../entities/license.dart';

abstract class LicenseRepository {
  Future<LicenseEntity?> getCachedLicense();
  Future<void> saveLicense(LicenseEntity license);
  Future<void> clearLicense();
  Future<DateTime?> getLastTamperCheckTimestamp();
  Future<void> updateLastTamperCheckTimestamp(DateTime timestamp);
}
