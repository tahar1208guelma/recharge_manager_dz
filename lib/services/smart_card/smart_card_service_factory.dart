import 'dart:io';
import 'package:flutter/foundation.dart';
import 'platforms/android_usb_host_service.dart';
import 'platforms/mock_smart_card_service.dart';
import 'platforms/windows_pcsc_service.dart';
import 'smart_card_service.dart';

class SmartCardServiceFactory {
  static SmartCardService create({bool forceMock = false}) {
    if (forceMock || kIsWeb) {
      return MockSmartCardService();
    }

    if (Platform.isWindows) {
      return WindowsPcscService();
    } else if (Platform.isAndroid) {
      return AndroidUsbHostService();
    } else {
      // macOS, Linux, or other environments default to MockSmartCardService
      return MockSmartCardService();
    }
  }
}
