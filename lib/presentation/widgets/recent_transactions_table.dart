import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../domain/entities/transaction.dart';
import '../../services/printing/print_service.dart';
import '../../services/printing/receipt_template.dart';
import 'receipt_preview_modal.dart';

class RecentTransactionsTable extends StatelessWidget {
  final List<TransactionEntity> transactions;
  final VoidCallback? onRefresh;

  const RecentTransactionsTable({
    super.key,
    required this.transactions,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.textMuted),
              const SizedBox(height: 12),
              Text(
                context.tr('no_transactions'),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(AppColors.lightCard),
            columns: [
              DataColumn(label: Text(context.tr('transaction_number'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.tr('date'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.tr('operator'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.tr('phone_number'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.tr('amount'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.tr('status'), style: const TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text(context.tr('actions'), style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: transactions.map((tx) {
              final opType = OperatorConstants.fromString(tx.operator);
              final opColor = OperatorConstants.getOperatorColor(opType);
              final opBg = OperatorConstants.getOperatorLightBg(opType);

              Color statusColor = AppColors.danger;
              Color statusBg = AppColors.dangerBg;
              String statusLabel = context.tr('status_failed');

              if (tx.isSuccess) {
                statusColor = AppColors.success;
                statusBg = AppColors.successBg;
                statusLabel = context.tr('status_success');
              } else if (tx.isPending) {
                statusColor = AppColors.warning;
                statusBg = AppColors.warningBg;
                statusLabel = context.tr('status_pending');
              }

              return DataRow(
                cells: [
                  DataCell(Text(tx.transactionNumber, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                  DataCell(Text(DateFormatter.formatDateTime(tx.createdAt), style: const TextStyle(fontSize: 12))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: opBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        tx.operator.toUpperCase(),
                        style: TextStyle(color: opColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                  DataCell(Text(PhoneValidator.formatDisplay(tx.phoneNumber), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(Text(CurrencyFormatter.format(tx.amount), style: const TextStyle(fontWeight: FontWeight.bold))),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.print, size: 18, color: AppColors.primary),
                          tooltip: context.tr('btn_print'),
                          onPressed: () {
                            final receipt = ReceiptData.fromTransaction(tx);
                            showDialog(
                              context: context,
                              builder: (_) => ReceiptPreviewModal(receipt: receipt),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.picture_as_pdf, size: 18, color: AppColors.accent),
                          tooltip: context.tr('btn_save_pdf'),
                          onPressed: () async {
                            final receipt = ReceiptData.fromTransaction(tx);
                            await PrintService.printReceipt(receipt);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
