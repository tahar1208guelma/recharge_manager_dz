enum NetworkRegistrationState {
  notSearching, // 0: Not registered, not searching
  registeredHome, // 1: Registered, home network
  searching, // 2: Not registered, searching
  registrationDenied, // 3: Registration denied
  unknown, // 4: Unknown
  registeredRoaming, // 5: Registered, roaming
}

extension NetworkRegistrationStateExtension on NetworkRegistrationState {
  String get displayNameAr {
    switch (this) {
      case NetworkRegistrationState.registeredHome:
        return 'مسجل في الشبكة المحلية (Registered Home)';
      case NetworkRegistrationState.registeredRoaming:
        return 'مسجل في شبكة تجوال (Registered Roaming)';
      case NetworkRegistrationState.searching:
        return 'جاري البحث عن الشبكة... (Searching)';
      case NetworkRegistrationState.registrationDenied:
        return 'تم رفض التسجيل بالشبكة (Registration Denied)';
      case NetworkRegistrationState.notSearching:
        return 'غير مسجل بالشبكة (Not Registered)';
      case NetworkRegistrationState.unknown:
        return 'حالة الشبكة غير معروفة (Unknown)';
    }
  }

  bool get isRegistered => this == NetworkRegistrationState.registeredHome || this == NetworkRegistrationState.registeredRoaming;
}

class NetworkInfo {
  final NetworkRegistrationState registrationState;
  final int signalRssi; // 0-31 (or 99 for unknown)
  final int signalPercent; // 0-100%
  final int? signalDbm; // e.g. -75 dBm
  final String? operatorName; // e.g. "MOBILIS", "Djezzy", "Ooredoo"
  final String? mcc; // 603
  final String? mnc; // 01, 02, 03
  final String? accessTechnology; // 2G, 3G, 4G, LTE

  const NetworkInfo({
    this.registrationState = NetworkRegistrationState.unknown,
    this.signalRssi = 99,
    this.signalPercent = 0,
    this.signalDbm,
    this.operatorName,
    this.mcc,
    this.mnc,
    this.accessTechnology,
  });

  bool get isRegistered => registrationState.isRegistered;
  bool get isReadyForTransactions => registrationState.isRegistered && signalPercent > 10;
}
