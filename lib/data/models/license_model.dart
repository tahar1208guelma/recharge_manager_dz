import 'dart:convert';
import '../../domain/entities/license.dart';

class LicenseModel extends LicenseEntity {
  LicenseModel({
    required super.licenseId,
    required super.customerId,
    required super.plan,
    required super.status,
    required super.createdAt,
    required super.startDate,
    super.expiryDate,
    super.maxDevices = 1,
    required super.deviceId,
    super.features = const ['RECHARGE', 'HISTORY', 'CUSTOMERS', 'PRINT', 'EXPORT'],
    required super.lastCheck,
    super.offlineGracePeriod = 7,
    super.token,
  });

  factory LicenseModel.fromMap(Map<String, dynamic> map) {
    List<String> parsedFeatures = ['RECHARGE', 'HISTORY', 'CUSTOMERS', 'PRINT', 'EXPORT'];
    if (map['features'] != null) {
      if (map['features'] is List) {
        parsedFeatures = List<String>.from(map['features'] as List);
      } else if (map['features'] is String) {
        try {
          final decoded = jsonDecode(map['features'] as String);
          if (decoded is List) {
            parsedFeatures = List<String>.from(decoded);
          }
        } catch (_) {
          parsedFeatures = (map['features'] as String).split(',');
        }
      }
    }

    return LicenseModel(
      licenseId: map['license_id'] as String,
      customerId: map['customer_id'] as String,
      plan: _parsePlan(map['plan'] as String),
      status: _parseStatus(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      startDate: DateTime.parse(map['start_date'] as String),
      expiryDate: map['expiry_date'] != null && (map['expiry_date'] as String).isNotEmpty
          ? DateTime.tryParse(map['expiry_date'] as String)
          : null,
      maxDevices: (map['max_devices'] as int?) ?? 1,
      deviceId: map['device_id'] as String,
      features: parsedFeatures,
      lastCheck: DateTime.parse(map['last_check'] as String),
      offlineGracePeriod: (map['offline_grace_period'] as int?) ?? 7,
      token: map['token'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'license_id': licenseId,
      'customer_id': customerId,
      'plan': plan.name.toUpperCase(),
      'status': status.name.toUpperCase(),
      'created_at': createdAt.toIso8601String(),
      'start_date': startDate.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'max_devices': maxDevices,
      'device_id': deviceId,
      'features': jsonEncode(features),
      'last_check': lastCheck.toIso8601String(),
      'offline_grace_period': offlineGracePeriod,
      'token': token,
    };
  }

  factory LicenseModel.fromEntity(LicenseEntity entity) {
    return LicenseModel(
      licenseId: entity.licenseId,
      customerId: entity.customerId,
      plan: entity.plan,
      status: entity.status,
      createdAt: entity.createdAt,
      startDate: entity.startDate,
      expiryDate: entity.expiryDate,
      maxDevices: entity.maxDevices,
      deviceId: entity.deviceId,
      features: entity.features,
      lastCheck: entity.lastCheck,
      offlineGracePeriod: entity.offlineGracePeriod,
      token: entity.token,
    );
  }

  static LicensePlan _parsePlan(String str) {
    switch (str.toUpperCase()) {
      case 'TRIAL':
        return LicensePlan.trial;
      case 'MONTHLY':
        return LicensePlan.monthly;
      case 'YEARLY':
        return LicensePlan.yearly;
      case 'LIFETIME':
        return LicensePlan.lifetime;
      default:
        return LicensePlan.trial;
    }
  }

  static LicenseStatus _parseStatus(String str) {
    switch (str.toUpperCase()) {
      case 'ACTIVE':
        return LicenseStatus.active;
      case 'TRIAL':
        return LicenseStatus.trial;
      case 'SUSPENDED':
        return LicenseStatus.suspended;
      case 'EXPIRED':
        return LicenseStatus.expired;
      default:
        return LicenseStatus.unregistered;
    }
  }
}
