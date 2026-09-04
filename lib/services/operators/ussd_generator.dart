import '../../core/constants/operator_constants.dart';

class UssdSubOption {
  final String key;
  final String label;

  const UssdSubOption({required this.key, required this.label});
}

class UssdServiceDef {
  final String key;
  final String title;
  final String defaultTemplate;
  final List<String> requiredParams;
  final String? subMenuTitle;
  final List<UssdSubOption>? subOptions;

  const UssdServiceDef({
    required this.key,
    required this.title,
    required this.defaultTemplate,
    required this.requiredParams,
    this.subMenuTitle,
    this.subOptions,
  });

  bool get hasSubMenu => subOptions != null && subOptions!.isNotEmpty;
}

class UssdGenerator {
  /// Default PINs per Algerian Operator
  static const Map<OperatorType, String> defaultPins = {
    OperatorType.mobilis: '11111',
    OperatorType.ooredoo: '0000',
    OperatorType.djezzy: '00000',
    OperatorType.unknown: '0000',
  };

  /// Master list of all operator services with default templates (Mobilis includes 04 account)
  static Map<OperatorType, Map<String, UssdServiceDef>> get operatorServices => defaultOperatorServices;

  static const Map<OperatorType, Map<String, UssdServiceDef>> defaultOperatorServices = {
    OperatorType.mobilis: {
      'recharge_direct': UssdServiceDef(
        key: 'recharge_direct',
        title: 'تعبئة الرصيد (بطاقة شحن)',
        defaultTemplate: '*111*{card_code}#',
        requiredParams: ['card_code'],
      ),
      'arseli_avec_activation': UssdServiceDef(
        key: 'arseli_avec_activation',
        title: '📞 Arseli مع التفعيل',
        defaultTemplate: '*696*1*{receiver}*04*{amount}*{pin}#',
        requiredParams: ['sub_option', 'receiver', 'amount', 'pin'],
        subMenuTitle: 'اختر نوع Arseli:',
        subOptions: [
          UssdSubOption(key: '1', label: '1. محلي (Local)'),
          UssdSubOption(key: '2', label: '2. دولي (International)'),
          UssdSubOption(key: '3', label: '3. استشارة الرصيد'),
        ],
      ),
      'transfert_flexy': UssdServiceDef(
        key: 'transfert_flexy',
        title: '💳 تحويل Flexy',
        defaultTemplate: '*630*{receiver}*04*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'arseli_international': UssdServiceDef(
        key: 'arseli_international',
        title: '🌍 Arseli دولي / دفع الفاتورة',
        defaultTemplate: '*633*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'transfert_normal': UssdServiceDef(
        key: 'transfert_normal',
        title: '💸 تحويل الرصيد (Transfert)',
        defaultTemplate: '*631*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'solde': UssdServiceDef(
        key: 'solde',
        title: '📊 معرفة الرصيد (Solde)',
        defaultTemplate: '*632*01*{pin}#',
        requiredParams: ['pin'],
      ),
      'liste_flexy': UssdServiceDef(
        key: 'liste_flexy',
        title: '📋 قائمة أرقام Flexy',
        defaultTemplate: '*632*03*{pin}#',
        requiredParams: ['pin'],
      ),
      'liste_transferts': UssdServiceDef(
        key: 'liste_transferts',
        title: '📋 قائمة التحويلات',
        defaultTemplate: '*631*01*{pin}#',
        requiredParams: ['pin'],
      ),
      'changer_pin': UssdServiceDef(
        key: 'changer_pin',
        title: '🔑 تغيير الرمز السري (PIN)',
        defaultTemplate: '*632*02*{old_pin}*{new_pin}#',
        requiredParams: ['old_pin', 'new_pin'],
      ),
    },
    OperatorType.ooredoo: {
      'recharge_direct': UssdServiceDef(
        key: 'recharge_direct',
        title: 'تعبئة الرصيد (بطاقة شحن 222)',
        defaultTemplate: '222',
        requiredParams: ['card_code'],
      ),
      'flexy_activation': UssdServiceDef(
        key: 'flexy_activation',
        title: '📞 Flexy مع التفعيل',
        defaultTemplate: '*585*{receiver}#',
        requiredParams: ['sub_option', 'receiver'],
        subMenuTitle: 'اختر نوع تفعيل Flexy:',
        subOptions: [
          UssdSubOption(key: '1', label: '1. تفعيل برقم هاتف'),
          UssdSubOption(key: '2', label: '2. إلغاء التفعيل'),
          UssdSubOption(key: '3', label: '3. قائمة الأرقام المفعلة'),
        ],
      ),
      'transfert_flexy': UssdServiceDef(
        key: 'transfert_flexy',
        title: '💳 تحويل رصيد Flexy',
        defaultTemplate: '*580*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'solde_avec_pin': UssdServiceDef(
        key: 'solde_avec_pin',
        title: '📊 معرفة الرصيد (مع PIN)',
        defaultTemplate: '*570*{pin}#',
        requiredParams: ['pin'],
      ),
      'liste_flexy_avec_pin': UssdServiceDef(
        key: 'liste_flexy_avec_pin',
        title: '📋 قائمة أرقام Flexy (مع PIN)',
        defaultTemplate: '*221*{pin}#',
        requiredParams: ['pin'],
      ),
      'liste_flexy_sans_pin': UssdServiceDef(
        key: 'liste_flexy_sans_pin',
        title: '📋 قائمة أرقام Flexy (بدون PIN)',
        defaultTemplate: '*762#',
        requiredParams: [],
      ),
      'transfert_ou_liste': UssdServiceDef(
        key: 'transfert_ou_liste',
        title: '💳 تحويل Flexy (بديل)',
        defaultTemplate: '*660*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'flexy_bonus': UssdServiceDef(
        key: 'flexy_bonus',
        title: '🎁 Flexy مع مكافأة (Bonus)',
        defaultTemplate: '*764*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
    },
    OperatorType.djezzy: {
      'recharge_direct': UssdServiceDef(
        key: 'recharge_direct',
        title: 'تعبئة الرصيد (بطاقة شحن)',
        defaultTemplate: '*700*{card_code}#',
        requiredParams: ['card_code'],
      ),
      'flexy_activation': UssdServiceDef(
        key: 'flexy_activation',
        title: '📞 Flexy مع التفعيل',
        defaultTemplate: '*770*{sub_option}*{receiver}*{amount}*{pin}#',
        requiredParams: ['sub_option', 'receiver', 'amount', 'pin'],
        subMenuTitle: 'اختر خدمة Flexy:',
        subOptions: [
          UssdSubOption(key: '1', label: '1. تحويل رصيد (إرسال)'),
          UssdSubOption(key: '2', label: '2. تفعيل رقم Flexy جديد'),
          UssdSubOption(key: '3', label: '3. قائمة الأرقام المقيدة'),
        ],
      ),
      'transfert_flexy': UssdServiceDef(
        key: 'transfert_flexy',
        title: '💳 تحويل رصيد عادي',
        defaultTemplate: '*770*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'solde': UssdServiceDef(
        key: 'solde',
        title: '📊 معرفة الرصيد',
        defaultTemplate: '*710#',
        requiredParams: [],
      ),
      'liste_flexy': UssdServiceDef(
        key: 'liste_flexy',
        title: '📋 قائمة أرقام Flexy',
        defaultTemplate: '*777#',
        requiredParams: [],
      ),
      'transfert_alt': UssdServiceDef(
        key: 'transfert_alt',
        title: '💳 تحويل رصيد (بديل 00000)',
        defaultTemplate: '*770*{receiver}*{amount}*00000#',
        requiredParams: ['receiver', 'amount'],
      ),
    },
  };

  /// In-memory custom templates cache (loaded from settings)
  static final Map<String, String> _customTemplates = {};

  static void setCustomTemplate(OperatorType operator, String serviceKey, String template) {
    _customTemplates['${operator.name}_$serviceKey'] = template.trim();
  }

  static String getEffectiveTemplate(OperatorType operator, String serviceKey) {
    final customKey = '${operator.name}_$serviceKey';
    if (_customTemplates.containsKey(customKey) && _customTemplates[customKey]!.isNotEmpty) {
      return _customTemplates[customKey]!;
    }
    final def = defaultOperatorServices[operator]?[serviceKey];
    return def?.defaultTemplate ?? '';
  }

  static void loadCustomTemplates(Map<String, String> settingsMap) {
    _customTemplates.clear();
    for (final entry in settingsMap.entries) {
      if (entry.key.startsWith('ussd_tpl_')) {
        final key = entry.key.replaceFirst('ussd_tpl_', '');
        _customTemplates[key] = entry.value;
      }
    }
  }

  static void resetAllCustomTemplates() {
    _customTemplates.clear();
  }

  /// Generates the final USSD execution string with parameters filled in
  static String generate(
    OperatorType operator,
    String serviceKey, {
    String? receiver,
    double? amount,
    String? pin,
    String? cardCode,
    String? subOption,
    String? oldPin,
    String? newPin,
    Map<String, dynamic>? extraParams,
  }) {
    String result = getEffectiveTemplate(operator, serviceKey);
    if (result.isEmpty) return '';

    final defaultPin = defaultPins[operator] ?? '0000';
    final effectivePin = (pin != null && pin.trim().isNotEmpty) ? pin.trim() : defaultPin;

    if (cardCode != null) {
      result = result.replaceAll('{card_code}', cardCode.trim());
    }

    if (subOption != null && subOption.trim().isNotEmpty) {
      result = result.replaceAll('{sub_option}', subOption.trim());
    } else {
      result = result.replaceAll('{sub_option}', '1');
    }

    if (receiver != null) {
      final cleanReceiver = receiver.replaceAll(RegExp(r'[^0-9]'), '');
      result = result.replaceAll('{receiver}', cleanReceiver);
    }

    if (amount != null) {
      result = result.replaceAll('{amount}', amount.toInt().toString());
    }

    result = result.replaceAll('{pin}', effectivePin);
    if (oldPin != null) result = result.replaceAll('{old_pin}', oldPin);
    if (newPin != null) result = result.replaceAll('{new_pin}', newPin);

    if (extraParams != null) {
      for (final entry in extraParams.entries) {
        result = result.replaceAll('{${entry.key}}', entry.value.toString());
      }
    }

    return result;
  }
}
