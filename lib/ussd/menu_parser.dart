import 'menu_option.dart';

class MenuParser {
  /// Multi-stage parser converting raw multi-lingual USSD menu text into structured clickable options
  static List<MenuOption> parseMenu(String text) {
    if (text.trim().isEmpty) return [];

    final cleanText = _normalizeText(text);
    final lines = cleanText.split(RegExp(r'[\r\n]+')).map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final options = <MenuOption>[];
    final seenKeys = <String>{};

    // Stage 1: Line-by-line regex matching
    for (final line in lines) {
      final opt = _parseLineOption(line);
      if (opt != null && !seenKeys.contains(opt.key)) {
        options.add(opt);
        seenKeys.add(opt.key);
      }
    }

    // Stage 2: If no line options found, try inline parsing (e.g. "1: Confirmer 2: Annuler" or "1: Oui, 2: Non")
    if (options.isEmpty) {
      final inlineRegex = RegExp(r'(\d+)\s*[:.\-)]\s*([^\d:\n]+)(?=\s+\d+\s*[:.\-)]|$)');
      final matches = inlineRegex.allMatches(cleanText);
      for (final m in matches) {
        final key = m.group(1)?.trim();
        final label = m.group(2)?.replaceAll(RegExp(r'[,;.]$'), '').trim();
        if (key != null && label != null && label.isNotEmpty && !seenKeys.contains(key)) {
          options.add(MenuOption(
            key: key,
            label: label,
            rawLine: m.group(0) ?? '$key: $label',
          ));
          seenKeys.add(key);
        }
      }
    }

    // Stage 3: Confirmation / Binary prompts fallback
    if (options.isEmpty) {
      final lower = cleanText.toLowerCase();
      if (lower.contains('confirmer') || lower.contains('تأكيد') || lower.contains('valider')) {
        options.add(const MenuOption(key: '1', label: 'تأكيد (Confirmer)', rawLine: '1: Confirmer'));
      }
      if (lower.contains('annuler') || lower.contains('إلغاء') || lower.contains('rejeter')) {
        options.add(const MenuOption(key: '2', label: 'إلغاء (Annuler)', rawLine: '2: Annuler'));
      }
    }

    return options;
  }

  static MenuOption? _parseLineOption(String line) {
    // 1. Patterns like "1. Option", "1- Option", "1) Option", "1: Option", "01. Option"
    final pattern1 = RegExp(r'^(\d+)\s*[\.\-:\)]\s*(.+)$');
    final match1 = pattern1.firstMatch(line);
    if (match1 != null) {
      final key = match1.group(1)!.trim();
      final label = match1.group(2)!.trim();
      if (label.isNotEmpty) {
        return MenuOption(key: key, label: label, rawLine: line);
      }
    }

    // 2. Patterns with space delimiter e.g. "1 Recharge", "2 Balance", "1 تعبئة"
    final pattern2 = RegExp(r'^(\d+)\s+([A-Za-z\u0600-\u06FF].+)$');
    final match2 = pattern2.firstMatch(line);
    if (match2 != null) {
      final key = match2.group(1)!.trim();
      final label = match2.group(2)!.trim();
      // Ensure it's not a price like "500 DA"
      if (!label.toLowerCase().startsWith('da') && !label.toLowerCase().startsWith('dinar')) {
        return MenuOption(key: key, label: label, rawLine: line);
      }
    }

    // 3. Eastern Arabic Numerals (١. تعبئة)
    final arabicNumeralsMap = {'١': '1', '٢': '2', '٣': '3', '٤': '4', '٥': '5', '٦': '6', '٧': '7', '٨': '8', '٩': '9', '٠': '0'};
    final pattern3 = RegExp(r'^([١٢٣٤٥٦٧٨٩٠]+)\s*[\.\-:\)]\s*(.+)$');
    final match3 = pattern3.firstMatch(line);
    if (match3 != null) {
      final rawKey = match3.group(1)!;
      final standardKey = rawKey.split('').map((c) => arabicNumeralsMap[c] ?? c).join();
      final label = match3.group(2)!.trim();
      return MenuOption(key: standardKey, label: label, rawLine: line);
    }

    return null;
  }

  static String _normalizeText(String input) {
    return input.replaceAll('\\n', '\n').replaceAll('\\r', '').trim();
  }
}
