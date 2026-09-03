import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/balance_info.dart';

class BalanceCardWidget extends StatelessWidget {
  final OperatorType operatorType;
  final BalanceInfo? balanceInfo;
  final VoidCallback onRefresh;

  const BalanceCardWidget({
    super.key,
    required this.operatorType,
    required this.balanceInfo,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final opColor = OperatorConstants.getOperatorColor(operatorType);
    final opName = OperatorConstants.getOperatorName(operatorType, lang: context.isRtl ? 'ar' : 'en');
    final balance = balanceInfo?.currentBalance ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: opColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    opName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 16, color: AppColors.textSecondary),
                onPressed: onRefresh,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(balance),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: opColor,
            ),
          ),
          const SizedBox(height: 4),
          if (balanceInfo != null)
            Text(
              '${context.tr('date')}: ${DateFormatter.formatTime(balanceInfo!.lastUpdated)}',
              style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
