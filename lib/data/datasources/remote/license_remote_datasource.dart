import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../../models/license_model.dart';

abstract class LicenseRemoteDataSource {
  Future<LicenseModel> activateLicense({
    required String licenseKey,
    required String deviceId,
    String? customerName,
    String? serverUrl,
  });

  Future<LicenseModel> verifyLicense({
    required String licenseKey,
    required String deviceId,
    String? token,
    String? serverUrl,
  });

  Future<bool> deactivateLicense({
    required String licenseKey,
    required String deviceId,
    String? serverUrl,
  });
}

class LicenseRemoteDataSourceImpl implements LicenseRemoteDataSource {
  final ApiClient _client;

  LicenseRemoteDataSourceImpl({ApiClient? client}) : _client = client ?? ApiClient();

  @override
  Future<LicenseModel> activateLicense({
    required String licenseKey,
    required String deviceId,
    String? customerName,
    String? serverUrl,
  }) async {
    final base = serverUrl ?? AppConstants.defaultLicenseServerUrl;
    final url = '$base/api/license/activate';

    final body = <String, dynamic>{
      'license_key': licenseKey.trim(),
      'device_id': deviceId.trim(),
    };
    if (customerName != null) {
      body['customer_name'] = customerName.trim();
    }

    final response = await _client.post(url, body: body);

    final data = response['data'] != null ? response['data'] as Map<String, dynamic> : response;
    return LicenseModel.fromMap(data);
  }

  @override
  Future<LicenseModel> verifyLicense({
    required String licenseKey,
    required String deviceId,
    String? token,
    String? serverUrl,
  }) async {
    final base = serverUrl ?? AppConstants.defaultLicenseServerUrl;
    final url = '$base/api/license/verify';

    final body = <String, dynamic>{
      'license_key': licenseKey.trim(),
      'device_id': deviceId.trim(),
    };
    if (token != null) {
      body['token'] = token;
    }

    final response = await _client.post(url, body: body);

    final data = response['data'] != null ? response['data'] as Map<String, dynamic> : response;
    return LicenseModel.fromMap(data);
  }

  @override
  Future<bool> deactivateLicense({
    required String licenseKey,
    required String deviceId,
    String? serverUrl,
  }) async {
    final base = serverUrl ?? AppConstants.defaultLicenseServerUrl;
    final url = '$base/api/license/deactivate';

    final response = await _client.post(
      url,
      body: {
        'license_key': licenseKey.trim(),
        'device_id': deviceId.trim(),
      },
    );

    return response['success'] == true;
  }
}
