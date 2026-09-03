import 'package:flutter/material.dart';
import '../security/secure_storage_service.dart';

class LocaleProvider extends ChangeNotifier {
  static const String _prefKey = 'app_language_code';
  final ISecureStorageService _storage;
  Locale _locale = const Locale('ar');

  LocaleProvider({ISecureStorageService? storage})
      : _storage = storage ?? SecureStorageService();

  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isRtl => _locale.languageCode == 'ar';

  Future<void> initialize() async {
    final savedCode = await _storage.read(_prefKey);
    if (savedCode != null && ['ar', 'fr', 'en'].contains(savedCode)) {
      _locale = Locale(savedCode);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale newLocale) async {
    if (!['ar', 'fr', 'en'].contains(newLocale.languageCode)) return;
    _locale = newLocale;
    await _storage.write(_prefKey, newLocale.languageCode);
    notifyListeners();
  }

  Future<void> setLanguageCode(String code) async {
    await setLocale(Locale(code));
  }
}
