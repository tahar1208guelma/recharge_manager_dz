import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/history_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<HistoryProvider>(context, listen: false).filterTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<HistoryProvider>(context);
    final stats = history.statistics;

    final totalVolume = (stats['total_volume_dzd'] as num?)?.toDouble() ?? 0.0;
    final totalCount = (stats['total_transactions'] as int?) ?? 0;
    final successCount = (stats['success_count'] as int?) ?? 0;
    final failedCount = (stats['failed_count'] as int?) ?? 0;
    final breakdown = (stats['operator_breakdown'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('nav_reports'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // High-level KPI Cards
          Row(
            children: [
              _buildMetricCard('إجمالي المبيعات', CurrencyFormatter.format(totalVolume), Icons.monetization_on, AppColors.primary),
              const SizedBox(width: 16),
              _buildMetricCard('إجمالي العمليات', '$totalCount', Icons.receipt_long, AppColors.accent),
              const SizedBox(width: 16),
              _buildMetricCard('العمليات الناجحة', '$successCount', Icons.check_circle, AppColors.success),
              const SizedBox(width: 16),
              _buildMetricCard('العمليات الفاشلة', '$failedCount', Icons.cancel, AppColors.danger),
            ],
          ),
          const SizedBox(height: 24),

          // Operator Breakdown Cards
          const Text(
            'توزيع المبيعات حسب المتعامل (Operator Distribution)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              _buildOperatorBreakdownCard(OperatorType.mobilis, breakdown, totalVolume),
              const SizedBox(width: 16),
              _buildOperatorBreakdownCard(OperatorType.djezzy, breakdown, totalVolume),
              const SizedBox(width: 16),
              _buildOperatorBreakdownCard(OperatorType.ooredoo, breakdown, totalVolume),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOperatorBreakdownCard(OperatorType op, List<dynamic> breakdown, double totalVolume) {
    final opId = OperatorConstants.getOperatorId(op);
    final opName = OperatorConstants.getOperatorName(op, lang: 'ar');
    final opColor = OperatorConstants.getOperatorColor(op);

    final row = breakdown.firstWhere((r) => (r['operator'] as String?).toString().toLowerCase() == opId, orElse: () => null);
    final count = row != null ? (row['count'] as int? ?? 0) : 0;
    final total = row != null ? ((row['total'] as num?)?.toDouble() ?? 0.0) : 0.0;
    final percentage = totalVolume > 0 ? ((total / totalVolume) * 100).toStringAsFixed(1) : '0';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
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
                Text(opName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: opColor)),
                Text('$percentage%', style: TextStyle(fontWeight: FontWeight.bold, color: opColor)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: totalVolume > 0 ? total / totalVolume : 0,
                backgroundColor: AppColors.lightCard,
                valueColor: AlwaysStoppedAnimation<Color>(opColor),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('$count عمليات', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                Text(CurrencyFormatter.format(total), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
