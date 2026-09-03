import 'package:flutter/material.dart';
import 'colors.dart';

enum OperatorType {
  mobilis,
  djezzy,
  ooredoo,
  unknown,
}

class OperatorConstants {
  static const String mobilisId = 'mobilis';
  static const String djezzyId = 'djezzy';
  static const String ooredooId = 'ooredoo';

  // Phone prefixes in Algeria (10 digits starting with 0)
  static const List<String> mobilisPrefixes = ['06', '065', '066', '067', '069'];
  static const List<String> djezzyPrefixes = ['07', '077', '078', '079'];
  static const List<String> ooredooPrefixes = ['05', '054', '055', '056'];

  // MCC / MNC (Mobile Country Code / Mobile Network Code for Algeria: MCC = 603)
  static const String mobilisMnc = '01'; // 60301
  static const String djezzyMnc = '02';  // 60302
  static const String ooredooMnc = '03'; // 60303

  static OperatorType detectFromPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length < 2) return OperatorType.unknown;

    // Convert international prefix +213 to local 0
    String local = clean;
    if (local.startsWith('213') && local.length >= 5) {
      local = '0${local.substring(3)}';
    }

    if (local.startsWith('06')) return OperatorType.mobilis;
    if (local.startsWith('07')) return OperatorType.djezzy;
    if (local.startsWith('05')) return OperatorType.ooredoo;
    return OperatorType.unknown;
  }

  static OperatorType detectFromImsi(String imsi) {
    final clean = imsi.trim();
    if (clean.startsWith('60301') || clean.startsWith('6031')) return OperatorType.mobilis;
    if (clean.startsWith('60302') || clean.startsWith('6032')) return OperatorType.djezzy;
    if (clean.startsWith('60303') || clean.startsWith('6033')) return OperatorType.ooredoo;
    return OperatorType.unknown;
  }

  static String getOperatorName(OperatorType type, {String lang = 'ar'}) {
    switch (type) {
      case OperatorType.mobilis:
        return lang == 'ar' ? 'موبيليس (Mobilis)' : 'Mobilis';
      case OperatorType.djezzy:
        return lang == 'ar' ? 'جيزي (Djezzy)' : 'Djezzy';
      case OperatorType.ooredoo:
        return lang == 'ar' ? 'أوريدو (Ooredoo)' : 'Ooredoo';
      case OperatorType.unknown:
        return lang == 'ar' ? 'غير معروف' : 'Unknown';
    }
  }

  static Color getOperatorColor(OperatorType type) {
    switch (type) {
      case OperatorType.mobilis:
        return AppColors.mobilisGreen;
      case OperatorType.djezzy:
        return AppColors.djezzyRed;
      case OperatorType.ooredoo:
        return AppColors.ooredooRed;
      case OperatorType.unknown:
        return AppColors.textSecondary;
    }
  }

  static Color getOperatorLightBg(OperatorType type) {
    switch (type) {
      case OperatorType.mobilis:
        return AppColors.mobilisGreenLight;
      case OperatorType.djezzy:
        return AppColors.djezzyRedLight;
      case OperatorType.ooredoo:
        return AppColors.ooredooRedLight;
      case OperatorType.unknown:
        return AppColors.lightCard;
    }
  }

  static String getOperatorId(OperatorType type) {
    switch (type) {
      case OperatorType.mobilis:
        return mobilisId;
      case OperatorType.djezzy:
        return djezzyId;
      case OperatorType.ooredoo:
        return ooredooId;
      case OperatorType.unknown:
        return 'unknown';
    }
  }

  static OperatorType fromString(String id) {
    switch (id.toLowerCase()) {
      case mobilisId:
        return OperatorType.mobilis;
      case djezzyId:
        return OperatorType.djezzy;
      case ooredooId:
        return OperatorType.ooredoo;
      default:
        return OperatorType.unknown;
    }
  }
}
