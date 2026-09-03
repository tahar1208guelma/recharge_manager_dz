import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../services/printing/print_service.dart';
import '../../services/printing/receipt_template.dart';

class ReceiptPreviewModal extends StatelessWidget {
  final ReceiptData receipt;

  const ReceiptPreviewModal({super.key, required this.receipt});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Receipt Container Paper Look
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    Text(
                      receipt.storeName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      receipt.storeAddress,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Tel: ${receipt.storePhone}',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                    const Divider(height: 24, thickness: 1),

                    Text(
                      context.tr('receipt_title'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(context.tr('receipt_number'), receipt.receiptNumber),
                    _buildInfoRow(context.tr('transaction_number'), receipt.transactionNumber),
                    _buildInfoRow(context.tr('date'), DateFormatter.formatReceipt(receipt.dateTime)),
                    _buildInfoRow(context.tr('operator'), receipt.operator),
                    _buildInfoRow(context.tr('phone_number'), PhoneValidator.formatDisplay(receipt.phoneNumber)),
                    _buildInfoRow(context.tr('status'), receipt.status),
                    const Divider(height: 20, thickness: 1),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.tr('amount'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          CurrencyFormatter.format(receipt.amount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    if (receipt.rechargeCode != null && receipt.rechargeCode!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.lightCard,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Column(
                          children: [
                            Text(
                              context.tr('recharge_code'),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              receipt.rechargeCode!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // QR Code
                    QrImageView(
                      data: receipt.qrData,
                      version: QrVersions.auto,
                      size: 90,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('scan_qr_to_verify'),
                      style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr('receipt_thank_you'),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.print, size: 18),
                      label: Text(context.tr('btn_print')),
                      onPressed: () async {
                        await PrintService.printReceipt(receipt);
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('close')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
