class Customer {
  final int? id;
  final String phoneNumber;
  final String operator;
  final String? name;
  final String? notes;
  final DateTime? lastRecharge;
  final int totalTransactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    this.id,
    required this.phoneNumber,
    required this.operator,
    this.name,
    this.notes,
    this.lastRecharge,
    this.totalTransactions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  Customer copyWith({
    int? id,
    String? phoneNumber,
    String? operator,
    String? name,
    String? notes,
    DateTime? lastRecharge,
    int? totalTransactions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      operator: operator ?? this.operator,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      lastRecharge: lastRecharge ?? this.lastRecharge,
      totalTransactions: totalTransactions ?? this.totalTransactions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
