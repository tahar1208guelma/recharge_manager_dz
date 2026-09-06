class MenuOption {
  final String key; // e.g. "1", "2", "3", "00"
  final String label; // e.g. "Recharge Directe", "تعبئة الرصيد"
  final String rawLine; // e.g. "1. Recharge Directe"

  const MenuOption({
    required this.key,
    required this.label,
    required this.rawLine,
  });

  String get displayButtonText => '$key - $label';

  @override
  String toString() => 'MenuOption($key: $label)';
}
