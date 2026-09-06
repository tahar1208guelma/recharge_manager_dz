import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/ussd/menu_parser.dart';

void main() {
  group('USSD MenuParser Unit Tests', () {
    test('Should parse Arabic numbered menu with dot delimiter', () {
      const prompt = '''
1. شحن رصيد فليكسي
2. تحويل رصيد
3. كشف الرصيد التجاري
4. الإعدادات
''';
      final options = MenuParser.parseMenu(prompt);
      expect(options.length, 4);
      expect(options[0].key, '1');
      expect(options[0].label, 'شحن رصيد فليكسي');
      expect(options[1].key, '2');
      expect(options[1].label, 'تحويل رصيد');
      expect(options[2].key, '3');
      expect(options[3].key, '4');
    });

    test('Should parse French numbered menu with hyphen and colon delimiters', () {
      const prompt = '''
1- Flexy Mobilis
2- Solde du compte
3: Facture Postpaye
''';
      final options = MenuParser.parseMenu(prompt);
      expect(options.length, 3);
      expect(options[0].key, '1');
      expect(options[0].label, 'Flexy Mobilis');
      expect(options[1].key, '2');
      expect(options[1].label, 'Solde du compte');
      expect(options[2].key, '3');
      expect(options[2].label, 'Facture Postpaye');
    });

    test('Should parse Eastern Arabic Numerals (١, ٢, ٣)', () {
      const prompt = '''
١. تأكيد عملية التعبئة
٢. إلغاء والعودة
''';
      final options = MenuParser.parseMenu(prompt);
      expect(options.length, 2);
      expect(options[0].key, '1');
      expect(options[0].label, 'تأكيد عملية التعبئة');
      expect(options[1].key, '2');
      expect(options[1].label, 'إلغاء والعودة');
    });

    test('Should parse inline menu with multiple options on same line', () {
      const prompt = 'Confirmer le transfert de 500 DA? 1: Confirmer 2: Annuler';
      final options = MenuParser.parseMenu(prompt);
      expect(options.length, 2);
      expect(options[0].key, '1');
      expect(options[0].label, 'Confirmer');
      expect(options[1].key, '2');
      expect(options[1].label, 'Annuler');
    });

    test('Should fallback to semantic confirmation buttons for unstructured prompt', () {
      const prompt = 'هل تريد تأكيد إرسال 1000 دج إلى الرقم 0770123456 ؟';
      final options = MenuParser.parseMenu(prompt);
      expect(options.isNotEmpty, true);
      expect(options.any((o) => o.key == '1'), true);
    });

    test('Should return empty list for empty or whitespace text', () {
      expect(MenuParser.parseMenu(''), isEmpty);
      expect(MenuParser.parseMenu('   \n  \t '), isEmpty);
    });
  });
}
