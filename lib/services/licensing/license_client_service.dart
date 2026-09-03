import '../../core/constants/app_constants.dart';
import '../../core/errors/exceptions.dart';
import '../../core/security/device_identity.dart';
import '../../core/security/encryption_service.dart';
import '../../core/security/secure_storage_service.dart';
import '../../core/utils/app_logger.dart';
import '../../data/datasources/remote/license_remote_datasource.dart';
import '../../domain/entities/license.dart';
import '../../domain/repositories/license_repository.dart';
import 'anti_tamper_validator.dart';

class LicenseClientService {
  final LicenseRepository _repository;
  final LicenseRemoteDataSource _remoteDataSource;
  final AntiTamperValidator _antiTamper;
  final ISecureStorageService _secureStorage;
  LicenseEntity? _cachedLicense;

  LicenseClientService({
    required LicenseRepository repository,
    LicenseRemoteDataSource? remoteDataSource,
    AntiTamperValidator? antiTamper,
    ISecureStorageService? secureStorage,
  })  : _repository = repository,
        _remoteDataSource = remoteDataSource ?? LicenseRemoteDataSourceImpl(),
        _antiTamper = antiTamper ?? AntiTamperValidator(repository: repository),
        _secureStorage = secureStorage ?? SecureStorageService();

  LicenseEntity? get currentLicense => _cachedLicense;
  bool get isLicensed => _cachedLicense?.isValid ?? false;

  Future<LicenseEntity> initialize() async {
    final deviceId = await DeviceIdentity.getDeviceId(secureStorage: _secureStorage);
    AppLogger.info('Initializing License for Device: $deviceId');

    // 1. Try loading cached license
    final cached = await _repository.getCachedLicense();
    if (cached != null) {
      try {
        await _antiTamper.validateLicense(license: cached, currentDeviceId: deviceId);
        _cachedLicense = cached;
        return cached;
      } catch (e) {
        AppLogger.warn('Cached license validation warning: $e');
        _cachedLicense = cached;
      }
    }

    // 2. If no license exists, generate an initial default Trial license
    final now = DateTime.now();
    final trialExpiry = now.add(const Duration(days: AppConstants.trialDurationDays));
    final trialToken = EncryptionService.sign(
      'TRIAL-$deviceId|$deviceId|trial|${trialExpiry.toIso8601String()}',
      AntiTamperValidator.serverSigningSecret,
    );

    final trialLicense = LicenseEntity(
      licenseId: 'TRIAL-${deviceId.substring(3, 9)}',
      customerId: 'TRIAL_USER',
      plan: LicensePlan.trial,
      status: LicenseStatus.trial,
      createdAt: now,
      startDate: now,
      expiryDate: trialExpiry,
      maxDevices: 1,
      deviceId: deviceId,
      lastCheck: now,
      offlineGracePeriod: AppConstants.offlineGracePeriodDays,
      token: trialToken,
    );

    await _repository.saveLicense(trialLicense);
    _cachedLicense = trialLicense;
    return trialLicense;
  }

  Future<LicenseEntity> activate({
    required String licenseKey,
    String? customerName,
    String? serverUrl,
  }) async {
    final deviceId = await DeviceIdentity.getDeviceId(secureStorage: _secureStorage);
    AppLogger.info('Activating license $licenseKey for device $deviceId...');

    try {
      final remoteLicense = await _remoteDataSource.activateLicense(
        licenseKey: licenseKey,
        deviceId: deviceId,
        customerName: customerName,
        serverUrl: serverUrl,
      );

      await _antiTamper.validateLicense(license: remoteLicense, currentDeviceId: deviceId);
      await _repository.saveLicense(remoteLicense);
      _cachedLicense = remoteLicense;
      return remoteLicense;
    } catch (e) {
      if (e is LicenseException || e is ServerException) rethrow;
      throw LicenseException('Failed to activate license: $e');
    }
  }

  Future<LicenseEntity> verifyOnline({String? serverUrl}) async {
    final deviceId = await DeviceIdentity.getDeviceId(secureStorage: _secureStorage);
    if (_cachedLicense == null) {
      return await initialize();
    }

    try {
      final updated = await _remoteDataSource.verifyLicense(
        licenseKey: _cachedLicense!.licenseId,
        deviceId: deviceId,
        token: _cachedLicense!.token,
        serverUrl: serverUrl,
      );

      await _antiTamper.validateLicense(license: updated, currentDeviceId: deviceId);
      await _repository.saveLicense(updated);
      _cachedLicense = updated;
      return updated;
    } catch (e) {
      AppLogger.warn('Online verification failed, falling back to local grace period: $e');
      // Validate offline grace period
      await _antiTamper.validateLicense(license: _cachedLicense!, currentDeviceId: deviceId);
      return _cachedLicense!;
    }
  }
}
