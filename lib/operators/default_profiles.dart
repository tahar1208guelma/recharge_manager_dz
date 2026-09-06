import '../core/constants/operator_constants.dart';
import 'operator_profile.dart';

class DefaultProfiles {
  static const mobilis = OperatorProfile(
    id: 'mobilis_dz',
    name: 'Mobilis',
    nameAr: 'موبيليس',
    operatorType: OperatorType.mobilis,
    country: 'DZ',
    mcc: '603',
    mnc: '01',
    phonePrefixes: ['06', '065', '066', '067', '069'],
    defaultPin: '11111',
    ussdTemplates: {
      'recharge': '*630*{phone}*04*{amount}*{pin}#',
      'arseli': '*696*{phone}*{amount}*{pin}#',
      'balance': '*632*01*{pin}#',
      'menu': '*600#',
    },
    smsCommands: {
      'balance': 'SOLDE',
    },
    presetAmounts: [100.0, 200.0, 500.0, 1000.0, 2000.0],
  );

  static const djezzy = OperatorProfile(
    id: 'djezzy_dz',
    name: 'Djezzy',
    nameAr: 'جيزي',
    operatorType: OperatorType.djezzy,
    country: 'DZ',
    mcc: '603',
    mnc: '02',
    phonePrefixes: ['07', '077', '078', '079'],
    defaultPin: '00000',
    ussdTemplates: {
      'recharge': '*770*{phone}*{amount}*{pin}#',
      'balance': '*710#',
      'menu': '*700#',
    },
    presetAmounts: [100.0, 200.0, 500.0, 1000.0, 2000.0],
  );

  static const ooredoo = OperatorProfile(
    id: 'ooredoo_dz',
    name: 'Ooredoo',
    nameAr: 'أوريدو',
    operatorType: OperatorType.ooredoo,
    country: 'DZ',
    mcc: '603',
    mnc: '03',
    phonePrefixes: ['05', '054', '055', '056'],
    defaultPin: '0000',
    ussdTemplates: {
      'recharge': '*580*{phone}*{amount}*{pin}#',
      'balance': '*585#',
      'menu': '*100#',
    },
    presetAmounts: [100.0, 200.0, 500.0, 1000.0, 2000.0],
  );

  static List<OperatorProfile> get all => [mobilis, djezzy, ooredoo];
}
