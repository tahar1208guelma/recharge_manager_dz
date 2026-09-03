import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/core/localization/app_localizations.dart';

void main() {
  group('Localization Catalog Tests', () {
    test('Arabic translations dictionary should contain required keys and be RTL', () {
      final locAr = AppLocalizations(const Locale('ar'));
      expect(locAr.isRtl, true);
      expect(locAr.translate('app_name'), contains('مدير التعبئة'));
      expect(locAr.translate('operator_mobilis'), contains('موبيليس'));
      expect(locAr.translate('operator_djezzy'), contains('جيزي'));
      expect(locAr.translate('operator_ooredoo'), contains('أوريدو'));
      expect(locAr.translate('btn_recharge_now'), 'تنفيذ التعبئة الآن');
    });

    test('French translations dictionary should translate properly', () {
      final locFr = AppLocalizations(const Locale('fr'));
      expect(locFr.isRtl, false);
      expect(locFr.translate('nav_recharge'), 'Recharge de crédit');
      expect(locFr.translate('operator_mobilis'), 'Mobilis');
    });

    test('English translations dictionary should translate properly', () {
      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.isRtl, false);
      expect(locEn.translate('nav_recharge'), 'Balance Recharge');
      expect(locEn.translate('btn_recharge_now'), 'Execute Recharge Now');
    });
  });
}
