import '../../core/constants/operator_constants.dart';

class UssdSubOption {
  final String key;
  final String label;

  const UssdSubOption({required this.key, required this.label});
}

class UssdServiceDef {
  final String key;
  final String title;
  final String template;
  final List<String> requiredParams;
  final String? subMenuTitle;
  final List<UssdSubOption>? subOptions;

  const UssdServiceDef({
    required this.key,
    required this.title,
    required this.template,
    required this.requiredParams,
    this.subMenuTitle,
    this.subOptions,
  });

  bool get hasSubMenu => subOptions != null && subOptions!.isNotEmpty;
}

class UssdGenerator {
  static const Map<OperatorType, Map<String, UssdServiceDef>> operatorServices = {
    OperatorType.mobilis: {
      'recharge_direct': UssdServiceDef(
        key: 'recharge_direct',
        title: 'تعبئة الرصيد (بطاقة شحن)',
        template: '*111*{card_code}#',
        requiredParams: ['card_code'],
      ),
      'arseli_avec_activation': UssdServiceDef(
        key: 'arseli_avec_activation',
        title: '📞 Arseli مع التفعيل',
        template: '*696*{sub_option}*{receiver}*{amount}*{pin}#',
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
        title: '💳 تحويل رصيد Flexy',
        template: '*630*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'solde': UssdServiceDef(
        key: 'solde',
        title: '📊 معرفة الرصيد',
        template: '*632*01*{pin}#',
        requiredParams: ['pin'],
      ),
      'liste_flexy': UssdServiceDef(
        key: 'liste_flexy',
        title: 'قائمة أرقام Flexy المحولة',
        template: '*632*03*{pin}#',
        requiredParams: ['pin'],
      ),
      'liste_transferts': UssdServiceDef(
        key: 'liste_transferts',
        title: 'قائمة آخر عمليات التحويل',
        template: '*631*01*{pin}#',
        requiredParams: ['pin'],
      ),
      'changer_pin': UssdServiceDef(
        key: 'changer_pin',
        title: 'تغيير الرمز السري لشريحة Flexy',
        template: '*632*02*{old_pin}*{new_pin}#',
        requiredParams: ['old_pin', 'new_pin'],
      ),
    },
    OperatorType.ooredoo: {
      'recharge_direct': UssdServiceDef(
        key: 'recharge_direct',
        title: 'تعبئة الرصيد (بطاقة شحن 222)',
        template: '222',
        requiredParams: ['card_code'],
      ),
      'flexy_activation': UssdServiceDef(
        key: 'flexy_activation',
        title: '📞 Flexy مع التفعيل',
        template: '*585*{sub_option}*{receiver}#',
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
        template: '*580*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'solde_avec_pin': UssdServiceDef(
        key: 'solde_avec_pin',
        title: 'معرفة الرصيد (باستخدام رمز PIN)',
        template: '*570*{pin}#',
        requiredParams: ['pin'],
      ),
      'solde_sans_pin': UssdServiceDef(
        key: 'solde_sans_pin',
        title: '📊 معرفة الرصيد السريع',
        template: '*766#',
        requiredParams: [],
      ),
      'flexy_bonus': UssdServiceDef(
        key: 'flexy_bonus',
        title: 'Flexy مع مكافأة البونص (Bonus)',
        template: '*764*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
    },
    OperatorType.djezzy: {
      'recharge_direct': UssdServiceDef(
        key: 'recharge_direct',
        title: 'تعبئة الرصيد (بطاقة شحن)',
        template: '*700*{card_code}#',
        requiredParams: ['card_code'],
      ),
      'flexy_activation': UssdServiceDef(
        key: 'flexy_activation',
        title: '📞 Flexy مع التفعيل',
        template: '*770*{sub_option}*{receiver}*{amount}*00000#',
        requiredParams: ['sub_option', 'receiver', 'amount'],
        subMenuTitle: 'اختر خدمة Flexy:',
        subOptions: [
          UssdSubOption(key: '1', label: '1. تحويل رصيد (إرسال)'),
          UssdSubOption(key: '2', label: '2. تفعيل رقم Flexy جديد'),
          UssdSubOption(key: '3', label: '3. قائمة الأرقام المقيدة'),
        ],
      ),
      'transfert_flexy': UssdServiceDef(
        key: 'transfert_flexy',
        title: '💳 تحويل رصيد Flexy العادي',
        template: '*770*{receiver}*{amount}*00000#',
        requiredParams: ['receiver', 'amount'],
      ),
      'solde': UssdServiceDef(
        key: 'solde',
        title: '📊 معرفة الرصيد',
        template: '*710#',
        requiredParams: [],
      ),
      'changer_pin': UssdServiceDef(
        key: 'changer_pin',
        title: 'تغيير الرمز السري لشريحة Flexy',
        template: '*770*{old_pin}*{new_pin}#',
        requiredParams: ['old_pin', 'new_pin'],
      ),
    },
  };

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
    final services = operatorServices[operator];
    if (services == null) return '';

    final def = services[serviceKey];
    if (def == null) return '';

    String result = def.template;

    const defaultPin = '0000';
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
