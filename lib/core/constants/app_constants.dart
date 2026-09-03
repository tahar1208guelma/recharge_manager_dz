class AppConstants {
  static const String appName = 'Recharge Manager DZ';
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String copyright = '© 2026 Recharge Manager DZ. All Rights Reserved.';

  // Default POS Settings
  static const String defaultCurrency = 'DZD';
  static const String defaultCurrencySymbol = 'د.ج';
  static const String defaultStoreName = 'نقطة بيع وخدمات الاتصالات';
  static const String defaultStoreAddress = 'الجزائر العاصمة - الجزائر';
  static const String defaultStorePhone = '0550000000';

  // License Defaults
  static const int trialDurationDays = 7;
  static const int offlineGracePeriodDays = 7;
  static const String defaultLicenseServerUrl = 'http://127.0.0.1:8088';

  // Quick Recharge Presets in DZD
  static const List<double> quickAmounts = [
    100.0,
    200.0,
    500.0,
    1000.0,
    2000.0,
    5000.0,
  ];

  // Pagination
  static const int defaultPageSize = 25;
}
