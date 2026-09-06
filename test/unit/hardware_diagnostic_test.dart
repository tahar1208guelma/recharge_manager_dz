import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:recharge_manager_dz/diagnostic/hardware_diagnostic_service.dart';

void main() {
  group('Hardware Diagnostic Tool Unit Tests', () {
    late HardwareDiagnosticService service;

    setUp(() {
      service = HardwareDiagnosticService();
    });

    test('HardwareDiagnosticService should run complete scan and return valid DiagnosticReport', () async {
      final progressStages = <String>[];
      final report = await service.runDiagnostic(
        onProgress: (msg, pct) => progressStages.add(msg),
      );

      expect(report, isNotNull);
      expect(progressStages.isNotEmpty, true);
      expect(report.usbDevices.isNotEmpty, true);
      expect(report.comPorts.isNotEmpty, true);
      expect(report.verdict, isNotNull);

      // Verify required fields in verdict
      final v = report.verdict;
      expect(['PC/SC READER', 'GSM MODEM', 'UNKNOWN'].contains(v.deviceType), true);
      expect(['SUPPORTED', 'NOT SUPPORTED'].contains(v.pcsc), true);
      expect(['SUPPORTED', 'NOT SUPPORTED'].contains(v.atModem), true);
      expect(['SUPPORTED', 'NOT VERIFIED', 'NOT SUPPORTED'].contains(v.ussd), true);
      expect(['SUPPORTED', 'NOT VERIFIED', 'NOT SUPPORTED'].contains(v.sms), true);
      expect(['REGISTERED', 'NOT REGISTERED'].contains(v.network), true);
      expect(['READY', 'PIN REQUIRED', 'NOT PRESENT', 'UNKNOWN'].contains(v.sim), true);
    });

    test('DiagnosticReport should export valid, pretty JSON structure', () async {
      final report = await service.runDiagnostic();
      final jsonStr = report.toPrettyJson();

      expect(jsonStr.isNotEmpty, true);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded.containsKey('diagnostic_report'), true);

      final repMap = decoded['diagnostic_report'] as Map<String, dynamic>;
      expect(repMap.containsKey('verdict'), true);
      expect(repMap.containsKey('usb_devices'), true);
      expect(repMap.containsKey('com_ports'), true);

      final verdict = repMap['verdict'] as Map<String, dynamic>;
      expect(verdict.containsKey('DEVICE_TYPE'), true);
      expect(verdict.containsKey('PCSC'), true);
      expect(verdict.containsKey('AT_MODEM'), true);
      expect(verdict.containsKey('USSD'), true);
      expect(verdict.containsKey('SMS'), true);
      expect(verdict.containsKey('NETWORK'), true);
      expect(verdict.containsKey('SIM'), true);
    });

    test('DiagnosticReport should generate human-readable ASCII text report', () async {
      final report = await service.runDiagnostic();
      final textReport = report.toFormattedTextReport();

      expect(textReport.contains('HARDWARE DIAGNOSTIC REPORT'), true);
      expect(textReport.contains('VAST SOLUTIONS DZ'), true);
      expect(textReport.contains('EXECUTIVE VERDICT'), true);
      expect(textReport.contains('DEVICE TYPE :'), true);
      expect(textReport.contains('PC/SC       :'), true);
      expect(textReport.contains('AT MODEM    :'), true);
      expect(textReport.contains('USSD        :'), true);
      expect(textReport.contains('SMS         :'), true);
      expect(textReport.contains('NETWORK     :'), true);
      expect(textReport.contains('SIM         :'), true);
      expect(textReport.contains('USB DEVICES LIST'), true);
      expect(textReport.contains('VID:'), true);
      expect(textReport.contains('PID:'), true);
      expect(textReport.contains('AT PORT PROBE RESULTS'), true);
      expect(textReport.contains('TX: AT'), true);
      expect(textReport.contains('TX: AT+CPIN?'), true);
      expect(textReport.contains('TX: AT+CSQ'), true);
      expect(textReport.contains('TX: AT+CREG?'), true);
      expect(textReport.contains('TX: AT+COPS?'), true);
    });

    test('HardwareDiagnosticService should export report files to target directory', () async {
      final tempDir = await Directory.systemTemp.createTemp('diag_test_');
      try {
        final report = await service.runDiagnostic();
        final paths = await service.exportReportFiles(report, targetDirectory: tempDir.path);

        expect(paths.containsKey('json'), true);
        expect(paths.containsKey('txt'), true);

        final jsonFile = File(paths['json']!);
        final txtFile = File(paths['txt']!);

        expect(await jsonFile.exists(), true);
        expect(await txtFile.exists(), true);

        final jsonContent = await jsonFile.readAsString();
        expect(jsonContent.contains('diagnostic_report'), true);

        final txtContent = await txtFile.readAsString();
        expect(txtContent.contains('HARDWARE DIAGNOSTIC REPORT'), true);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
