import 'dart:io';
import 'package:flutter/foundation.dart';
import 'encryption_service.dart';
import 'secure_storage_service.dart';

class DeviceIdentity {
  static const String _storageKey = 'DZ_RECHARGE_DEVICE_ID_V1';
  static String? _cachedDeviceId;

  /// Retrieves or generates a unique, hardware-bound device ID
  static Future<String> getDeviceId({ISecureStorageService? secureStorage}) async {
    if (_cachedDeviceId != null) {
      return _cachedDeviceId!;
    }

    final storage = secureStorage ?? SecureStorageService();
    final stored = await storage.read(_storageKey);
    if (stored != null && stored.trim().isNotEmpty) {
      _cachedDeviceId = stored;
      return stored;
    }

    // Generate deterministic hardware fingerprint
    final fingerprint = await _generateHardwareFingerprint();
    final generatedId = 'DZ-${fingerprint.substring(0, 16).toUpperCase()}';

    await storage.write(_storageKey, generatedId);
    _cachedDeviceId = generatedId;
    return generatedId;
  }

  static Future<String> _generateHardwareFingerprint() async {
    final components = <String>[];

    if (kIsWeb) {
      components.add('WEB_CLIENT');
      components.add('CHROME_PREVIEW_DEVICE');
    } else {
      try {
        components.add(Platform.operatingSystem);
        components.add(Platform.operatingSystemVersion);
        components.add(Platform.localHostname);
        components.add(Platform.numberOfProcessors.toString());

        final env = Platform.environment;
        if (env.containsKey('COMPUTERNAME')) components.add(env['COMPUTERNAME']!);
        if (env.containsKey('USER')) components.add(env['USER']!);
        if (env.containsKey('USERNAME')) components.add(env['USERNAME']!);
        if (env.containsKey('PROCESSOR_IDENTIFIER')) components.add(env['PROCESSOR_IDENTIFIER']!);
      } catch (_) {
        components.add('GENERIC_CLIENT');
        components.add(DateTime.now().millisecondsSinceEpoch.toString());
      }
    }

    final combined = components.join('|');
    return EncryptionService.hash(combined, salt: 'DZ_HW_SALT_2026');
  }

  static void resetCacheForTesting() {
    _cachedDeviceId = null;
  }
}
