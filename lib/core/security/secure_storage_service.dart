import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/app_logger.dart';

abstract class ISecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<Map<String, String>> readAll();
}

class SecureStorageService implements ISecureStorageService {
  final FlutterSecureStorage _storage;
  final Map<String, String> _memoryCache = {};
  bool _useMemoryFallback = false;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
              mOptions: MacOsOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  @override
  Future<void> write(String key, String value) async {
    _memoryCache[key] = value;
    if (_useMemoryFallback) return;
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      AppLogger.warn('SecureStorage write failed, using memory fallback: $e');
      _useMemoryFallback = true;
    }
  }

  @override
  Future<String?> read(String key) async {
    if (_useMemoryFallback) {
      return _memoryCache[key];
    }
    try {
      final value = await _storage.read(key: key);
      if (value != null) {
        _memoryCache[key] = value;
      }
      return value ?? _memoryCache[key];
    } catch (e) {
      AppLogger.warn('SecureStorage read failed, using memory fallback: $e');
      _useMemoryFallback = true;
      return _memoryCache[key];
    }
  }

  @override
  Future<void> delete(String key) async {
    _memoryCache.remove(key);
    if (_useMemoryFallback) return;
    try {
      await _storage.delete(key: key);
    } catch (e) {
      AppLogger.warn('SecureStorage delete failed: $e');
    }
  }

  @override
  Future<void> deleteAll() async {
    _memoryCache.clear();
    if (_useMemoryFallback) return;
    try {
      await _storage.deleteAll();
    } catch (e) {
      AppLogger.warn('SecureStorage deleteAll failed: $e');
    }
  }

  @override
  Future<Map<String, String>> readAll() async {
    if (_useMemoryFallback) {
      return Map.from(_memoryCache);
    }
    try {
      final all = await _storage.readAll();
      _memoryCache.addAll(all);
      return all;
    } catch (e) {
      AppLogger.warn('SecureStorage readAll failed: $e');
      _useMemoryFallback = true;
      return Map.from(_memoryCache);
    }
  }
}
