import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/operator_constants.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../services/operators/ussd_generator.dart';

class SettingsProvider extends ChangeNotifier {
  final SettingsRepository repository;

  String _storeName = AppConstants.defaultStoreName;
  String _storeAddress = AppConstants.defaultStoreAddress;
  String _storePhone = AppConstants.defaultStorePhone;
  bool _mockMode = false;
  ThemeMode _themeMode = ThemeMode.light;

  final Map<OperatorType, String> _operatorPins = {
    OperatorType.mobilis: '11111',
    OperatorType.ooredoo: '0000',
    OperatorType.djezzy: '00000',
  };

  SettingsProvider({required this.repository});

  String get storeName => _storeName;
  String get storeAddress => _storeAddress;
  String get storePhone => _storePhone;
  bool get mockMode => _mockMode;
  ThemeMode get themeMode => _themeMode;

  String getOperatorPin(OperatorType op) => _operatorPins[op] ?? UssdGenerator.defaultPins[op] ?? '0000';

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

    // Load operator PINs
    if (settings.containsKey('pin_mobilis')) _operatorPins[OperatorType.mobilis] = settings['pin_mobilis']!;
    if (settings.containsKey('pin_ooredoo')) _operatorPins[OperatorType.ooredoo] = settings['pin_ooredoo']!;
    if (settings.containsKey('pin_djezzy')) _operatorPins[OperatorType.djezzy] = settings['pin_djezzy']!;

    // Load custom USSD templates into UssdGenerator
    UssdGenerator.loadCustomTemplates(settings);

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

  Future<void> setOperatorPin(OperatorType op, String pin) async {
    _operatorPins[op] = pin.trim();
    await repository.setSetting('pin_${op.name}', pin.trim());
    notifyListeners();
  }

  Future<void> saveCustomUssdTemplate(OperatorType op, String serviceKey, String template) async {
    UssdGenerator.setCustomTemplate(op, serviceKey, template);
    await repository.setSetting('ussd_tpl_${op.name}_$serviceKey', template.trim());
    notifyListeners();
  }

  Future<void> resetOperatorUssdTemplates(OperatorType op) async {
    final defs = UssdGenerator.defaultOperatorServices[op] ?? {};
    for (final entry in defs.entries) {
      final customKey = 'ussd_tpl_${op.name}_${entry.key}';
      await repository.deleteSetting(customKey);
      UssdGenerator.setCustomTemplate(op, entry.key, entry.value.defaultTemplate);
    }
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
