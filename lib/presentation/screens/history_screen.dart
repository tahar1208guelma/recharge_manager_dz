import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../providers/history_provider.dart';
import '../widgets/recent_transactions_table.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<HistoryProvider>(context);

    final stats = history.statistics;
    final totalCount = (stats['total_transactions'] as int?) ?? 0;
    final totalVolume = (stats['total_volume_dzd'] as num?)?.toDouble() ?? 0.0;
    final successCount = (stats['success_count'] as int?) ?? 0;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & CSV Export
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('nav_history'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalCount ${context.tr('nav_history')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download, size: 18),
                label: Text(context.tr('export_csv')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                ),
                onPressed: () async {
                  final csvData = await history.exportCsv();
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('CSV Exported (${csvData.split('\n').length - 1} rows)'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini KPI Stats Row
          Row(
            children: [
              _buildStatCard(context.tr('nav_history'), '$totalCount', AppColors.primary),
              const SizedBox(width: 12),
              _buildStatCard('إجمالي المبالغ', CurrencyFormatter.format(totalVolume), AppColors.accent),
              const SizedBox(width: 12),
              _buildStatCard(context.tr('status_success'), '$successCount', AppColors.success),
            ],
          ),
          const SizedBox(height: 16),

          // Filter Controls Bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                // Search Input
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.tr('search'),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      prefixIcon: const Icon(Icons.search, size: 20),
                    ),
                    onChanged: (val) => history.setQuery(val),
                  ),
                ),
                const SizedBox(width: 10),

                // Operator Filter Dropdown
                DropdownButton<String>(
                  value: history.selectedOperator ?? 'all',
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(context.tr('all_operators'))),
                    DropdownMenuItem(value: 'mobilis', child: Text(context.tr('operator_mobilis'))),
                    DropdownMenuItem(value: 'djezzy', child: Text(context.tr('operator_djezzy'))),
                    DropdownMenuItem(value: 'ooredoo', child: Text(context.tr('operator_ooredoo'))),
                  ],
                  onChanged: (val) => history.setOperatorFilter(val),
                ),
                const SizedBox(width: 10),

                // Status Filter Dropdown
                DropdownButton<String>(
                  value: history.selectedStatus ?? 'all',
                  underline: const SizedBox.shrink(),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(context.tr('all_statuses'))),
                    DropdownMenuItem(value: 'SUCCESS', child: Text(context.tr('status_success'))),
                    DropdownMenuItem(value: 'FAILED', child: Text(context.tr('status_failed'))),
                    DropdownMenuItem(value: 'PENDING', child: Text(context.tr('status_pending'))),
                  ],
                  onChanged: (val) => history.setStatusFilter(val),
                ),
                const SizedBox(width: 10),

                // Reset Filters Button
                IconButton(
                  icon: const Icon(Icons.filter_alt_off, color: AppColors.textSecondary),
                  tooltip: 'Reset Filters',
                  onPressed: () {
                    _searchController.clear();
                    history.resetFilters();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Transactions Table
          Expanded(
            child: history.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RecentTransactionsTable(
                    transactions: history.transactions,
                    onRefresh: () => history.filterTransactions(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
