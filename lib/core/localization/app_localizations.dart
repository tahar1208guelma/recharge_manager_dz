import 'package:flutter/material.dart';
import 'translations/ar.dart';
import 'translations/fr.dart';
import 'translations/en.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('ar'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'ar': arTranslations,
    'fr': frTranslations,
    'en': enTranslations,
  };

  String translate(String key) {
    final langCode = locale.languageCode;
    final dict = _localizedValues[langCode] ?? _localizedValues['ar']!;
    return dict[key] ?? _localizedValues['en']?[key] ?? key;
  }

  bool get isRtl => locale.languageCode == 'ar';
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['ar', 'fr', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension TranslationExtension on BuildContext {
  String tr(String key) => AppLocalizations.of(this).translate(key);
  bool get isRtl => AppLocalizations.of(this).isRtl;
}
