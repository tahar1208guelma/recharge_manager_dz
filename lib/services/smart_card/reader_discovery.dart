import 'reader_device_info.dart';

class ReaderDiscovery {
  // Known Smart Card Reader Vendor IDs (VID)
  static const Map<String, String> knownVendors = {
    '072F': 'Advanced Card Systems Ltd. (ACS)',
    '076B': 'HID Global / OMNIKEY',
    '04E6': 'Identiv / SCM Microsystems',
    '1A44': 'Identiv Inc.',
    '08E6': 'Gemalto / Thales',
    '0BDA': 'Realtek Semiconductor Corp.',
    '058F': 'Alcor Micro Corp.',
    '2CE3': 'Feitian Technologies',
    '0483': 'STMicroelectronics',
    '10C4': 'Silicon Laboratories',
  };

  /// Parses a raw reader name or USB descriptor string and builds a rich [ReaderDeviceInfo]
  static ReaderDeviceInfo inspectReader(String rawName, {Map<String, dynamic>? properties}) {
    final cleanName = rawName.trim();
    String? vid;
    String? pid;
    String? manufacturer;
    bool isCompatible = true;
    String? errorMessage;

    // Check for incompatible or non-smartcard hardware names
    final lower = cleanName.toLowerCase();
    if (lower.contains('storage') || lower.contains('mass_storage') || lower.contains('flash_drive')) {
      isCompatible = false;
      errorMessage = 'Device is a USB Mass Storage drive, not a Smart Card Reader.';
    } else if (lower.contains('printer') || lower.contains('scanner')) {
      isCompatible = false;
      errorMessage = 'Device is a printer/scanner, not a Smart Card Reader.';
    } else if (lower.contains('magnetic') && !lower.contains('smart') && !lower.contains('ccid')) {
      isCompatible = false;
      errorMessage = 'Magnetic stripe reader detected. Contact Smart Card / SIM reader is required.';
    }

    // Pattern 1: (072F:2200) or 072F:2200 or VID_072F&PID_2200
    final pairRegex = RegExp(r'(?:\(?|VID[_:\s]?)([0-9A-Fa-f]{4})[:&_](?:PID[_:\s]?)?([0-9A-Fa-f]{4})\)?');
    final match = pairRegex.firstMatch(cleanName);
    if (match != null) {
      vid = match.group(1)?.toUpperCase();
      pid = match.group(2)?.toUpperCase();
    }

    // Look up known vendor name if VID is present
    if (vid != null && knownVendors.containsKey(vid)) {
      manufacturer = knownVendors[vid];
    }

    // Fallback detection from device name keywords
    if (vid == null || manufacturer == null) {
      if (lower.contains('acs') || lower.contains('acr39') || lower.contains('acr38')) {
        vid ??= '072F';
        pid ??= '2200';
        manufacturer ??= 'Advanced Card Systems Ltd. (ACS)';
      } else if (lower.contains('omnikey') || lower.contains('hid')) {
        vid ??= '076B';
        pid ??= '3021';
        manufacturer ??= 'HID Global / OMNIKEY';
      } else if (lower.contains('identiv') || lower.contains('utrust') || lower.contains('scr3310')) {
        vid ??= '04E6';
        pid ??= '5116';
        manufacturer ??= 'Identiv / SCM Microsystems';
      } else if (lower.contains('gemalto') || lower.contains('idbridge')) {
        vid ??= '08E6';
        pid ??= '3437';
        manufacturer ??= 'Gemalto / Thales';
      } else {
        vid ??= '0000';
        pid ??= '0000';
        manufacturer ??= 'Generic PC/SC CCID Smart Card Reader';
      }
    }

    return ReaderDeviceInfo(
      vendorId: vid,
      productId: pid,
      manufacturer: manufacturer,
      readerName: cleanName,
      protocol: 'PC/SC (CCID)',
      connectionStatus: isCompatible ? 'CONNECTED' : 'INCOMPATIBLE',
      isCompatible: isCompatible,
      errorMessage: errorMessage,
      rawProperties: properties ?? {},
    );
  }
}
