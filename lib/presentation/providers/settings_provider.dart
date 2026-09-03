import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository repository;

  String _storeName = AppConstants.defaultStoreName;
  String _storeAddress = AppConstants.defaultStoreAddress;
  String _storePhone = AppConstants.defaultStorePhone;
  bool _mockMode = true;
  ThemeMode _themeMode = ThemeMode.light;

  SettingsProvider({required this.repository});

  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  String get storePhone => _storePhone;
  bool get mockMode => _mockMode;
  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    final settings = await repository.getAllSettings();
    if (settings.containsKey('store_name')) _storeName = settings['store_name']!;
    if (settings.containsKey('store_address')) _storeAddress = settings['store_address']!;
    if (settings.containsKey('store_phone')) _storePhone = settings['store_phone']!;
    if (settings.containsKey('mock_mode')) _mockMode = settings['mock_mode'] == 'true';
    if (settings.containsKey('theme_mode')) {
      final mode = settings['theme_mode']!;
      if (mode == 'dark') _themeMode = ThemeMode.dark;
      if (mode == 'light') _themeMode = ThemeMode.light;
      if (mode == 'system') _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> updateStoreInfo({
    required String name,
    required String address,
    required String phone,
  }) async {
    _storeName = name;
    _storeAddress = address;
    _storePhone = phone;
    await repository.setSetting('store_name', name);
    await repository.setSetting('store_address', address);
    await repository.setSetting('store_phone', phone);
    notifyListeners();
  }

  Future<void> setMockMode(bool enabled) async {
    _mockMode = enabled;
    await repository.setSetting('mock_mode', enabled.toString());
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await repository.setSetting('theme_mode', mode.name);
    notifyListeners();
  }
}
