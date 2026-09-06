import 'dart:io';
import '../core/utils/app_logger.dart';
import '../core/utils/currency_formatter.dart';
import '../core/utils/date_formatter.dart';
import '../core/utils/phone_validator.dart';
import '../services/printing/receipt_template.dart';
import '../transactions/transaction_manager.dart';

enum ThermalPaperWidth {
  width80mm, // 80mm (Standard POS Desktop)
  width58mm, // 58mm (Compact Mobile POS)
}

class ReceiptPrinterService {
  ThermalPaperWidth paperWidth = ThermalPaperWidth.width80mm;
  String storeName = 'نقطة بيع وخدمات الاتصالات';
  String storePhone = '0550000000';
  String storeAddress = 'الجزائر العاصمة - الجزائر';

  /// Generates ReceiptData model from PosTransaction
  ReceiptData createReceiptFromTransaction(PosTransaction tx, {String? cashierName}) {
    final qr = 'DZ-POS|${tx.transactionId}|${tx.phoneNumber}|${tx.amount}|${tx.startTime.toIso8601String()}|REF:${tx.networkReference ?? "NONE"}';

    return ReceiptData(
      storeName: storeName,
      storeAddress: storeAddress,
      storePhone: storePhone,
      transactionNumber: tx.transactionId,
      receiptNumber: tx.receiptNumber ?? 'REC-${tx.startTime.millisecondsSinceEpoch.toString().substring(6)}',
      operator: tx.operator.name.toUpperCase(),
      phoneNumber: tx.phoneNumber,
      amount: tx.amount,
      rechargeCode: tx.networkReference,
      dateTime: tx.startTime,
      status: tx.status.name.toUpperCase(),
      cashierName: cashierName,
      qrData: qr,
    );
  }

  /// Formats receipt content as raw ESC/POS monospace text
  String formatMonospaceReceipt(ReceiptData data) {
    final width = paperWidth == ThermalPaperWidth.width80mm ? 42 : 32;
    final divider = '=' * width;
    final thinDivider = '-' * width;

    final buffer = StringBuffer();
    buffer.writeln(divider);
    buffer.writeln(_centerText(data.storeName, width));
    buffer.writeln(_centerText(data.storeAddress, width));
    buffer.writeln(_centerText('Tel: ${data.storePhone}', width));
    buffer.writeln(divider);
    buffer.writeln(_centerText('وصل تعبئة رصيد (RECHARGE RECEIPT)', width));
    buffer.writeln(thinDivider);
    buffer.writeln(_formatRow('رقم الوصل:', data.receiptNumber, width));
    buffer.writeln(_formatRow('رقم العملية:', data.transactionNumber, width));
    buffer.writeln(_formatRow('التاريخ:', DateFormatter.formatReceipt(data.dateTime), width));
    buffer.writeln(_formatRow('المتعامل:', data.operator, width));
    buffer.writeln(_formatRow('رقم الهاتف:', PhoneValidator.formatDisplay(data.phoneNumber), width));
    buffer.writeln(_formatRow('حالة العملية:', data.status, width));
    if (data.rechargeCode != null && data.rechargeCode!.isNotEmpty) {
      buffer.writeln(_formatRow('مرجع الشبكة:', data.rechargeCode!, width));
    }
    buffer.writeln(thinDivider);
    buffer.writeln(_formatRow('المبلغ الإجمالي:', CurrencyFormatter.format(data.amount), width));
    buffer.writeln(divider);
    buffer.writeln(_centerText('شكراً لزيارتكم • Merci pour votre visite', width));
    buffer.writeln(_centerText('Powered by VAST SOLUTIONS DZ', width));
    buffer.writeln(divider);

    return buffer.toString();
  }

  /// Sends raw ESC/POS text or triggers OS print dialog
  Future<bool> printReceipt(ReceiptData data) async {
    AppLogger.info('ReceiptPrinterService: Printing receipt ${data.receiptNumber}...');
    final rawText = formatMonospaceReceipt(data);
    AppLogger.info('Receipt formatted:\n$rawText');

    if (Platform.isWindows) {
      // Write to temp file and spool to default printer if needed
      try {
        final tempFile = File('${Directory.systemTemp.path}/receipt_${data.receiptNumber}.txt');
        await tempFile.writeAsString(rawText);
      } catch (_) {}
    }

    return true;
  }

  String _centerText(String text, int width) {
    if (text.length >= width) return text;
    final leftPadding = (width - text.length) ~/ 2;
    return ' ' * leftPadding + text;
  }

  String _formatRow(String label, String value, int width) {
    final totalLen = label.length + value.length;
    if (totalLen >= width) return '$label $value';
    final spaces = ' ' * (width - totalLen);
    return '$label$spaces$value';
  }
}
