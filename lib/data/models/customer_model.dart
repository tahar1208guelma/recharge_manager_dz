import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  CustomerModel({
    super.id,
    required super.phoneNumber,
    required super.operator,
    super.name,
    super.notes,
    super.lastRecharge,
    super.totalTransactions = 0,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CustomerModel.fromMap(Map<String, dynamic> map) {
    return CustomerModel(
      id: map['id'] as int?,
      phoneNumber: map['phone_number'] as String,
      operator: map['operator'] as String,
      name: map['name'] as String?,
      notes: map['notes'] as String?,
      lastRecharge: map['last_recharge'] != null
          ? DateTime.tryParse(map['last_recharge'] as String)
          : null,
      totalTransactions: (map['total_transactions'] as int?) ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'phone_number': phoneNumber,
      'operator': operator,
      'name': name,
      'notes': notes,
      'last_recharge': lastRecharge?.toIso8601String(),
      'total_transactions': totalTransactions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CustomerModel.fromEntity(Customer customer) {
    return CustomerModel(
      id: customer.id,
      phoneNumber: customer.phoneNumber,
      operator: customer.operator,
      name: customer.name,
      notes: customer.notes,
      lastRecharge: customer.lastRecharge,
      totalTransactions: customer.totalTransactions,
      createdAt: customer.createdAt,
      updatedAt: customer.updatedAt,
    );
  }
}
