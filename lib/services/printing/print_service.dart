import 'dart:typed_data';
import 'package:printing/printing.dart';
import '../../core/utils/app_logger.dart';
import 'pdf_invoice_generator.dart';
import 'receipt_template.dart';

class PrintService {
  /// Sends receipt directly to OS Print Dialog / Thermal POS printer
  static Future<bool> printReceipt(ReceiptData receipt) async {
    try {
      AppLogger.info('Printing receipt #${receipt.receiptNumber}...');
      final pdfBytes = await PdfInvoiceGenerator.generateThermalReceipt(receipt);
      return await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'Receipt_${receipt.receiptNumber}.pdf',
      );
    } catch (e) {
      AppLogger.error('Printing error: $e');
      return false;
    }
  }

  /// Generates raw PDF bytes for preview or local saving
  static Future<Uint8List> getReceiptPdfBytes(ReceiptData receipt) async {
    return await PdfInvoiceGenerator.generateThermalReceipt(receipt);
  }
}
