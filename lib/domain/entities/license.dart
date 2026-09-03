enum LicensePlan {
  trial,
  monthly,
  yearly,
  lifetime,
}

enum LicenseStatus {
  active,
  trial,
  suspended,
  expired,
  unregistered,
}

class LicenseEntity {
  final String licenseId;
  final String customerId;
  final LicensePlan plan;
  final LicenseStatus status;
  final DateTime createdAt;
  final DateTime startDate;
  final DateTime? expiryDate;
  final int maxDevices;
  final String deviceId;
  final List<String> features;
  final DateTime lastCheck;
  final int offlineGracePeriod; // in days
  final String? token; // Cryptographic verification token

  LicenseEntity({
    required this.licenseId,
    required this.customerId,
    required this.plan,
    required this.status,
    required this.createdAt,
    required this.startDate,
    this.expiryDate,
    this.maxDevices = 1,
    required this.deviceId,
    this.features = const ['RECHARGE', 'HISTORY', 'CUSTOMERS', 'PRINT', 'EXPORT'],
    required this.lastCheck,
    this.offlineGracePeriod = 7,
    this.token,
  });

  bool get isExpired {
    if (plan == LicensePlan.lifetime || expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isGracePeriodExpired {
    final now = DateTime.now();
    final graceLimit = lastCheck.add(Duration(days: offlineGracePeriod));
    return now.isAfter(graceLimit);
  }

  bool get isValid {
    if (status != LicenseStatus.active && status != LicenseStatus.trial) return false;
    if (isExpired) return false;
    return true;
  }

  int get daysRemaining {
    if (plan == LicensePlan.lifetime || expiryDate == null) return 9999;
    final diff = expiryDate!.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
