import 'dart:io';
import 'package:recharge_manager_dz/services/smart_card/platforms/windows_pcsc_native.dart';
import 'package:recharge_manager_dz/services/smart_card/smart_card_protocol.dart';

String hexDump(List<int> bytes) {
  if (bytes.isEmpty) return '(empty)';
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
}

Future<SmartCardResponse> transmitWithT0(
  int hCard,
  int activeProtocol,
  int activeCla,
  List<int> apdu,
  String label,
) async {
  stdout.writeln('\n[APDU] $label:');
  stdout.writeln('  --> ${hexDump(apdu)}');

  final res = WinSCardNative.transmit(
    hCard: hCard,
    activeProtocol: activeProtocol,
    apdu: apdu,
  );

  int sw1 = (res['sw1'] as int?) ?? 0x6F;
  int sw2 = (res['sw2'] as int?) ?? 0x00;
  List<int> data = (res['data'] as List<int>?) ?? [];

  stdout.writeln('  <-- ${hexDump(data)} [${sw1.toRadixString(16).padLeft(2, '0').toUpperCase()} ${sw2.toRadixString(16).padLeft(2, '0').toUpperCase()}]');

  // Handle T=0: SW1 == 0x61 (More data available)
  if (sw1 == 0x61) {
    stdout.writeln('  [T=0] SW1=61 detected ($sw2 bytes available), calling GET RESPONSE...');
    final getRespApdu = SmartCardProtocol.buildGetResponseApdu(
      sw2,
      isGsm: activeCla == SmartCardProtocol.claGsm,
    );
    return await transmitWithT0(hCard, activeProtocol, activeCla, getRespApdu, 'GET RESPONSE (0x$sw2)');
  }

  // Handle T=0: SW1 == 0x6C (Wrong Le length)
  if (sw1 == 0x6C) {
    stdout.writeln('  [T=0] SW1=6C detected (wrong Le), resending with Le=$sw2...');
    List<int> corrected;
    if (apdu.length == 4) {
      corrected = [...apdu, sw2];
    } else {
      corrected = List<int>.from(apdu)..[apdu.length - 1] = sw2;
    }
    return await transmitWithT0(hCard, activeProtocol, activeCla, corrected, '$label (corrected Le=$sw2)');
  }

  final isSuccess = (sw1 == 0x90 && sw2 == 0x00) || sw1 == 0x91;
  return SmartCardResponse(data: data, sw1: sw1, sw2: sw2, isSuccess: isSuccess);
}

void main() async {
  stdout.writeln('======================================================================');
  stdout.writeln('  Recharge Manager DZ - PC/SC Hardware SIM Diagnostic Probe');
  stdout.writeln('======================================================================');

  if (!Platform.isWindows) {
    stdout.writeln('[!] This diagnostic probe runs on Windows via winscard.dll.');
    exit(1);
  }

  stdout.writeln('[1] Initializing winscard.dll...');
  final initOk = WinSCardNative.init();
  if (!initOk) {
    stdout.writeln('[!] FAILED: Could not load winscard.dll from system.');
    exit(1);
  }

  await WinSCardNative.ensureSmartCardServiceRunning();
  var hContext = WinSCardNative.establishContext();
  if (hContext == 0) {
    stdout.writeln('[!] FAILED: SCardEstablishContext returned 0 (Smart Card Service SCardSvr could not be started).');
    stdout.writeln('[-] Try opening PowerShell as Administrator and run: Start-Service SCardSvr');
    exit(1);
  }
  stdout.writeln('[+] SCardContext established: 0x${hContext.toRadixString(16)}');

  stdout.writeln('\n[2] Discovering real PC/SC Smart Card readers...');
  final readers = WinSCardNative.listPcscReaders(hContext: hContext);

  if (readers.isEmpty) {
    stdout.writeln('----------------------------------------------------------------------');
    stdout.writeln('[!] NO PC/SC SMART CARD READERS DETECTED');
    stdout.writeln('----------------------------------------------------------------------');
    stdout.writeln('Please check Windows Device Manager under "Smart card readers":');
    stdout.writeln('  1. Verify the USB Smart Card / SIM reader is securely connected.');
    stdout.writeln('  2. Ensure the device driver (CCID) is installed without yellow "!" errors.');
    stdout.writeln('  3. Ensure Windows Smart Card service is active: "net start SCardSvr"');
    stdout.writeln('----------------------------------------------------------------------');
    WinSCardNative.releaseContext(hContext);
    exit(0);
  }

  stdout.writeln('[+] Found ${readers.length} PC/SC Reader(s):');
  for (int i = 0; i < readers.length; i++) {
    stdout.writeln('    [$i] ${readers[i]}');
  }

  int? connectedHCard;
  int? connectedProtocol;
  String? connectedReader;
  String? atrHex;

  for (final reader in readers) {
    stdout.writeln('\n[3] Probing reader: "$reader"...');
    final conn = WinSCardNative.connectCard(hContext, reader);
    final retCode = conn['returnCode'] as int;

    if (retCode == SCARD_E_NO_SMARTCARD) {
      stdout.writeln('  [-] Reader is connected, but NO SIM CARD is inserted.');
      continue;
    } else if (retCode != SCARD_S_SUCCESS) {
      stdout.writeln('  [!] SCardConnect failed with code 0x${retCode.toRadixString(16)}');
      continue;
    }

    connectedHCard = conn['hCard'] as int;
    connectedProtocol = conn['activeProtocol'] as int;
    connectedReader = reader;

    final status = WinSCardNative.getCardStatus(connectedHCard);
    atrHex = status['atr'] as String?;
    final rawAtr = status['rawAtr'] as List<int>;

    stdout.writeln('  [+] Connected successfully!');
    stdout.writeln('  [+] Active Protocol: ${connectedProtocol == SCARD_PROTOCOL_T1 ? "T=1" : "T=0"}');
    stdout.writeln('  [+] Raw ATR (${rawAtr.length} bytes): ${hexDump(rawAtr)}');
    stdout.writeln('  [+] Formatted ATR: ${atrHex ?? "(none)"}');
    break;
  }

  if (connectedHCard == null || connectedProtocol == null) {
    stdout.writeln('\n[!] Could not establish connection with a SIM card in any reader.');
    stdout.writeln('[-] Please ensure a SIM card is properly inserted into the reader.');
    WinSCardNative.releaseContext(hContext);
    exit(0);
  }

  final hCard = connectedHCard;
  final activeProto = connectedProtocol;
  stdout.writeln('\n======================================================================');
  stdout.writeln('  Starting ISO 7816-4 APDU Diagnostic Session on "$connectedReader"');
  stdout.writeln('======================================================================');

  WinSCardNative.beginTransaction(hCard);

  int activeCla = SmartCardProtocol.claGsm; // 0xA0 (GSM 11.11)

  // Step A: SELECT MF (3F00)
  stdout.writeln('\n--- Step A: Selecting Master File (MF 3F00) ---');
  var selMf = await transmitWithT0(
    hCard,
    activeProto,
    activeCla,
    [0xA0, 0xA4, 0x00, 0x00, 0x02, 0x3F, 0x00],
    'SELECT MF (CLA A0)',
  );

  if (selMf.isClassNotSupported || selMf.isInstructionNotSupported) {
    stdout.writeln('[*] CLA A0 not supported (6E00/6D00) -> Falling back to USIM/UICC CLA 00...');
    activeCla = SmartCardProtocol.claIso; // 0x00
    selMf = await transmitWithT0(
      hCard,
      activeProto,
      activeCla,
      [0x00, 0xA4, 0x00, 0x00, 0x02, 0x3F, 0x00],
      'SELECT MF (CLA 00)',
    );
  }

  stdout.writeln('[*] Active Class (CLA) determined: 0x${activeCla.toRadixString(16).padLeft(2, "0").toUpperCase()}');

  // Step B: SELECT EF_ICCID (2FE2)
  stdout.writeln('\n--- Step B: Reading EF_ICCID (2FE2) ---');
  final selIccid = await transmitWithT0(
    hCard,
    activeProto,
    activeCla,
    [activeCla, 0xA4, 0x00, 0x00, 0x02, 0x2F, 0xE2],
    'SELECT EF_ICCID (2FE2)',
  );

  String? iccid;
  if (selIccid.isPinRequired) {
    stdout.writeln('[!] PIN REQUIRED: EF_ICCID requires CHV1/PIN verification.');
  } else {
    final readIccid = await transmitWithT0(
      hCard,
      activeProto,
      activeCla,
      [activeCla, 0xB0, 0x00, 0x00, 0x0A],
      'READ BINARY EF_ICCID (10 bytes)',
    );

    if (readIccid.data.isNotEmpty) {
      iccid = SmartCardProtocol.decodeBcdIccid(readIccid.data);
      stdout.writeln('[+] Raw ICCID bytes: ${hexDump(readIccid.data)}');
      stdout.writeln('[+] Decoded Serial/ICCID: $iccid');
    }
  }

  // Step C: SELECT DF_GSM (7F20)
  stdout.writeln('\n--- Step C: Selecting DF_GSM (7F20) ---');
  final selDfGsm = await transmitWithT0(
    hCard,
    activeProto,
    activeCla,
    [activeCla, 0xA4, 0x00, 0x00, 0x02, 0x7F, 0x20],
    'SELECT DF_GSM (7F20)',
  );

  // Step D: SELECT EF_IMSI (6F07)
  String? imsi;
  if (selDfGsm.isSuccess || selDfGsm.hasMoreData) {
    stdout.writeln('\n--- Step D: Reading EF_IMSI (6F07) ---');
    final selImsi = await transmitWithT0(
      hCard,
      activeProto,
      activeCla,
      [activeCla, 0xA4, 0x00, 0x00, 0x02, 0x6F, 0x07],
      'SELECT EF_IMSI (6F07)',
    );

    if (selImsi.isPinRequired) {
      stdout.writeln('[!] PIN REQUIRED: EF_IMSI requires CHV1/PIN verification.');
    } else {
      final readImsi = await transmitWithT0(
        hCard,
        activeProto,
        activeCla,
        [activeCla, 0xB0, 0x00, 0x00, 0x09],
        'READ BINARY EF_IMSI (9 bytes)',
      );

      if (readImsi.data.isNotEmpty) {
        imsi = SmartCardProtocol.decodeBcdImsi(readImsi.data);
        stdout.writeln('[+] Raw IMSI bytes: ${hexDump(readImsi.data)}');
        stdout.writeln('[+] Decoded IMSI: $imsi');
      }
    }
  }

  // Step E: Operator Detection
  stdout.writeln('\n--- Step E: Operator Identification ---');
  if (imsi != null && imsi.isNotEmpty) {
    String opName = 'Unknown ($imsi)';
    if (imsi.startsWith('60301')) {
      opName = 'Mobilis (موبيليس)';
    } else if (imsi.startsWith('60302')) {
      opName = 'Djezzy (جيزي)';
    } else if (imsi.startsWith('60303')) {
      opName = 'Ooredoo (أوريدو)';
    }
    stdout.writeln('[+] Network Operator: $opName (Detected from IMSI: $imsi)');
  } else {
    stdout.writeln('[-] Could not read IMSI to detect operator.');
  }

  // Step F: Optional MSISDN
  stdout.writeln('\n--- Step F: Probing EF_MSISDN (6F40) under Telecom (7F10) ---');
  try {
    await transmitWithT0(hCard, activeProto, activeCla, [activeCla, 0xA4, 0x00, 0x00, 0x02, 0x3F, 0x00], 'SELECT MF');
    await transmitWithT0(hCard, activeProto, activeCla, [activeCla, 0xA4, 0x00, 0x00, 0x02, 0x7F, 0x10], 'SELECT DF_TELECOM');
    final selMsisdn = await transmitWithT0(hCard, activeProto, activeCla, [activeCla, 0xA4, 0x00, 0x00, 0x02, 0x6F, 0x40], 'SELECT EF_MSISDN');
    if (selMsisdn.isSuccess || selMsisdn.hasMoreData) {
      final readMsisdn = await transmitWithT0(hCard, activeProto, activeCla, [activeCla, 0xB0, 0x00, 0x00, 0x1C], 'READ BINARY MSISDN (28 bytes)');
      final msisdn = SmartCardProtocol.decodeMsisdn(readMsisdn.data);
      stdout.writeln(msisdn != null ? '[+] Stored MSISDN: $msisdn' : '[-] EF_MSISDN is empty / unconfigured.');
    } else {
      stdout.writeln('[-] EF_MSISDN not present under DF_TELECOM.');
    }
  } catch (e) {
    stdout.writeln('[-] MSISDN probe skipped: $e');
  }

  WinSCardNative.endTransaction(hCard);
  WinSCardNative.disconnectCard(hCard, disposition: SCARD_LEAVE_CARD);
  WinSCardNative.releaseContext(hContext);

  stdout.writeln('\n======================================================================');
  stdout.writeln('  PROBE COMPLETE SUMMARY:');
  stdout.writeln('  Reader   : $connectedReader');
  stdout.writeln('  ATR      : ${atrHex ?? "(none)"}');
  stdout.writeln('  ICCID    : ${iccid ?? "(none / protected)"}');
  stdout.writeln('  IMSI     : ${imsi ?? "(none / protected)"}');
  stdout.writeln('======================================================================');
}
