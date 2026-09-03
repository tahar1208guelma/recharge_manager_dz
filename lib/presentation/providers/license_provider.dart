import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/security/device_identity.dart';
import '../../domain/entities/license.dart';
import '../../services/licensing/license_client_service.dart';

class LicenseProvider extends ChangeNotifier {
  final LicenseClientService licenseService;
  LicenseEntity? _license;
  String _deviceId = '';
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  String _serverUrl = AppConstants.defaultLicenseServerUrl;

  LicenseProvider({required this.licenseService});

  LicenseEntity? get license => _license;
  String get deviceId => _deviceId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get serverUrl => _serverUrl;

  bool get isLicensed => _license?.isValid ?? false;
  bool get isTrial => _license?.plan == LicensePlan.trial;
  int get daysRemaining => _license?.daysRemaining ?? 0;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _deviceId = await DeviceIdentity.getDeviceId();
      _license = await licenseService.initialize();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setServerUrl(String url) {
    _serverUrl = url;
    notifyListeners();
  }

  Future<bool> activateLicense(String licenseKey, {String? customerName}) async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await licenseService.activate(
        licenseKey: licenseKey,
        customerName: customerName,
        serverUrl: _serverUrl,
      );
      _license = updated;
      _successMessage = 'License activated successfully for plan: ${updated.plan.name.toUpperCase()}';
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> verifyOnline() async {
    _isLoading = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final updated = await licenseService.verifyOnline(serverUrl: _serverUrl);
      _license = updated;
      _successMessage = 'License verified with server';
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
