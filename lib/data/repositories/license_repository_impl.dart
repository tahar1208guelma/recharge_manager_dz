import '../../domain/entities/license.dart';
import '../../domain/repositories/license_repository.dart';
import '../datasources/local/license_local_datasource.dart';
import '../models/license_model.dart';

class LicenseRepositoryImpl implements LicenseRepository {
  final LicenseLocalDataSource _localDataSource;

  LicenseRepositoryImpl({LicenseLocalDataSource? localDataSource})
      : _localDataSource = localDataSource ?? LicenseLocalDataSourceImpl();

  @override
  Future<LicenseEntity?> getCachedLicense() async {
    return await _localDataSource.getCachedLicense();
  }

  @override
  Future<void> saveLicense(LicenseEntity license) async {
    final model = license is LicenseModel ? license : LicenseModel.fromEntity(license);
    await _localDataSource.saveLicense(model);
  }

  @override
  Future<void> clearLicense() async {
    await _localDataSource.clearLicense();
  }

  @override
  Future<DateTime?> getLastTamperCheckTimestamp() async {
    return await _localDataSource.getLastTamperCheckTimestamp();
  }

  @override
  Future<void> updateLastTamperCheckTimestamp(DateTime timestamp) async {
    await _localDataSource.updateLastTamperCheckTimestamp(timestamp);
  }
}
