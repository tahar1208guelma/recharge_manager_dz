import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import 'receipt_template.dart';

class PdfInvoiceGenerator {
  /// Generates 80mm POS Thermal Receipt Document
  static Future<Uint8List> generateThermalReceipt(ReceiptData receipt) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, 200 * PdfPageFormat.mm, marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                // Store Name & Info
                pw.Text(
                  receipt.storeName,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  receipt.storeAddress,
                  style: const pw.TextStyle(fontSize: 8),
                  textAlign: pw.TextAlign.center,
                ),
                pw.Text(
                  'Tel: ${receipt.storePhone}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.Divider(thickness: 0.8),

                // Receipt Title
                pw.Text(
                  'TELECOM RECHARGE RECEIPT',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
                ),
                pw.SizedBox(height: 4),

                // Details Rows
                _buildRow('Receipt No:', receipt.receiptNumber),
                _buildRow('Tx Ref:', receipt.transactionNumber),
                _buildRow('Date/Time:', DateFormatter.formatReceipt(receipt.dateTime)),
                _buildRow('Operator:', receipt.operator),
                _buildRow('Phone Number:', receipt.phoneNumber),
                _buildRow('Status:', receipt.status),
                if (receipt.cashierName != null) _buildRow('Cashier:', receipt.cashierName!),

                pw.Divider(thickness: 0.8),

                // Amount Highlight
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('AMOUNT PAID:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                    pw.Text(
                      CurrencyFormatter.format(receipt.amount),
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),

                // Recharge PIN / Code if present
                if (receipt.rechargeCode != null && receipt.rechargeCode!.isNotEmpty) ...[
                  pw.SizedBox(height: 6),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border.fromBorderSide(pw.BorderSide(width: 0.8)),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Text('RECHARGE CODE / PIN', style: const pw.TextStyle(fontSize: 7)),
                        pw.Text(
                          receipt.rechargeCode!,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],

                pw.SizedBox(height: 8),

                // QR Code
                pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: receipt.qrData,
                  width: 55,
                  height: 55,
                ),
                pw.SizedBox(height: 4),
                pw.Text('Scan to verify transaction', style: const pw.TextStyle(fontSize: 7)),

                pw.SizedBox(height: 6),
                pw.Text('Thank you for your visit!', style: const pw.TextStyle(fontSize: 8)),
                pw.Text('Powered by VAST SOLUTIONS DZ', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800)),
          pw.Text(value, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }
}
