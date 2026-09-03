import '../../core/constants/operator_constants.dart';

class UssdServiceDef {
  final String key;
  final String title;
  final String template;
  final List<String> requiredParams;

  const UssdServiceDef({
    required this.key,
    required this.title,
    required this.template,
    required this.requiredParams,
  });
}

class UssdGenerator {
  static const Map<OperatorType, Map<String, UssdServiceDef>> operatorServices = {
    OperatorType.mobilis: {
      'transfert_flexy': UssdServiceDef(
        key: 'transfert_flexy',
        title: 'تحويل رصيد Flexy (رصيد عادي)',
        template: '*630*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'arseli_avec_activation': UssdServiceDef(
        key: 'arseli_avec_activation',
        title: 'Arseli مع التفعيل (عروض ومكالمات)',
        template: '*696*1*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'arseli_international': UssdServiceDef(
        key: 'arseli_international',
        title: 'Arseli دولي (المكالمات الدولية)',
        template: '*633*1*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'paiement_facture': UssdServiceDef(
        key: 'paiement_facture',
        title: 'دفع فاتورة Mobilis للمشترك',
        template: '*633*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'transfert_normal': UssdServiceDef(
        key: 'transfert_normal',
        title: 'تحويل رصيد عادي (Transfert)',
        template: '*631*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'solde': UssdServiceDef(
        key: 'solde',
        title: 'معرفة الرصيد المتوفر في الشريحة',
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
      'transfert_flexy': UssdServiceDef(
        key: 'transfert_flexy',
        title: 'تحويل رصيد Flexy (عادي)',
        template: '*580*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'flexy_activation': UssdServiceDef(
        key: 'flexy_activation',
        title: 'Flexy مع التفعيل المباشر للباقة',
        template: '*585*{receiver}#',
        requiredParams: ['receiver'],
      ),
      'solde_avec_pin': UssdServiceDef(
        key: 'solde_avec_pin',
        title: 'معرفة الرصيد (باستخدام رمز PIN)',
        template: '*570*{pin}#',
        requiredParams: ['pin'],
      ),
      'solde_sans_pin': UssdServiceDef(
        key: 'solde_sans_pin',
        title: 'معرفة الرصيد السريع (بدون PIN)',
        template: '*766#',
        requiredParams: [],
      ),
      'liste_flexy_avec_pin': UssdServiceDef(
        key: 'liste_flexy_avec_pin',
        title: 'قائمة أرقام Flexy (باستخدام PIN)',
        template: '*221*{pin}#',
        requiredParams: ['pin'],
      ),
      'liste_flexy_sans_pin': UssdServiceDef(
        key: 'liste_flexy_sans_pin',
        title: 'قائمة أرقام Flexy (بدون PIN)',
        template: '*762#',
        requiredParams: [],
      ),
      'transfert_ou_liste': UssdServiceDef(
        key: 'transfert_ou_liste',
        title: 'تحويل رصيد إضافي / عروض خاصة',
        template: '*660*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'flexy_bonus': UssdServiceDef(
        key: 'flexy_bonus',
        title: 'Flexy مع مكافأة البونص (Bonus)',
        template: '*764*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
    },
    OperatorType.djezzy: {
      'transfert_flexy': UssdServiceDef(
        key: 'transfert_flexy',
        title: 'تحويل رصيد Flexy العادي',
        template: '*770*{receiver}*{amount}*{pin}#',
        requiredParams: ['receiver', 'amount', 'pin'],
      ),
      'solde': UssdServiceDef(
        key: 'solde',
        title: 'معرفة الرصيد المتوفر في الشريحة',
        template: '*777*{pin}#',
        requiredParams: ['pin'],
      ),
      'solde_rapide': UssdServiceDef(
        key: 'solde_rapide',
        title: 'معرفة الرصيد السريع',
        template: '*777#',
        requiredParams: [],
      ),
      'historique': UssdServiceDef(
        key: 'historique',
        title: 'قائمة وسجل آخر المعاملات',
        template: '*770*1#',
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
