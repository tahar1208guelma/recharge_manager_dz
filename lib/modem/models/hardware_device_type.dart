/// Distinguishes between physical device connection architectures
enum HardwareDeviceType {
  /// USB GSM/3G/4G Modem (Supports AT commands, USSD, SMS, Network registration)
  gsmModem,

  /// ISO 7816 Smart Card Reader (Card detection & public EF files only, no direct cellular network access)
  smartCardReader,

  /// Generic USB to Serial Bridge (CH340, FTDI, Prolific, CP2102)
  usbSerialAdapter,

  /// Mock / Simulated hardware for testing and development
  mockDevice,

  /// Unknown or unclassified hardware
  unknown,
}

extension HardwareDeviceTypeExtension on HardwareDeviceType {
  String get displayNameAr {
    switch (this) {
      case HardwareDeviceType.gsmModem:
        return 'مودم اتصالات (USB GSM Modem)';
      case HardwareDeviceType.smartCardReader:
        return 'قارئ بطاقات ذكية (PC/SC Smart Card Reader)';
      case HardwareDeviceType.usbSerialAdapter:
        return 'محول تسلسلي (USB Serial Adapter)';
      case HardwareDeviceType.mockDevice:
        return 'جهاز افتراضي تجريبي (Mock Device)';
      case HardwareDeviceType.unknown:
        return 'جهاز غير محدد (Unknown Device)';
    }
  }

  bool get supportsCellularNetwork => this == HardwareDeviceType.gsmModem || this == HardwareDeviceType.mockDevice;
  bool get supportsAtCommands => this == HardwareDeviceType.gsmModem || this == HardwareDeviceType.usbSerialAdapter || this == HardwareDeviceType.mockDevice;
}
