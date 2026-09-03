import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../services/smart_card/smart_card_state.dart';
import '../providers/app_state_provider.dart';
import '../providers/history_provider.dart';
import '../providers/recharge_provider.dart';
import '../providers/usb_provider.dart';
import '../widgets/balance_card_widget.dart';
import '../widgets/reader_device_info_modal.dart';
import '../widgets/recent_transactions_table.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<RechargeProvider>(context, listen: false).refreshAllBalances();
        Provider.of<HistoryProvider>(context, listen: false).loadRecentTransactions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final recharge = Provider.of<RechargeProvider>(context);
    final history = Provider.of<HistoryProvider>(context);
    final usb = Provider.of<UsbProvider>(context);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Quick Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('app_name'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('app_tagline'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.flash_on, size: 20),
                label: Text('${context.tr('btn_recharge_now')} (F1)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: () => appState.setActiveTab(AppTab.recharge),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Balance Cards Row (Mobilis, Djezzy, Ooredoo)
          Row(
            children: [
              Expanded(
                child: BalanceCardWidget(
                  operatorType: OperatorType.mobilis,
                  balanceInfo: recharge.balances[OperatorType.mobilis],
                  onRefresh: () => recharge.refreshBalance(OperatorType.mobilis),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BalanceCardWidget(
                  operatorType: OperatorType.djezzy,
                  balanceInfo: recharge.balances[OperatorType.djezzy],
                  onRefresh: () => recharge.refreshBalance(OperatorType.djezzy),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: BalanceCardWidget(
                  operatorType: OperatorType.ooredoo,
                  balanceInfo: recharge.balances[OperatorType.ooredoo],
                  onRefresh: () => recharge.refreshBalance(OperatorType.ooredoo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Smart Card Hardware Status Banner (PC/SC & USB Host)
          _buildHardwareStatusBanner(context, usb),
          const SizedBox(height: 24),

          // Recent Transactions Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.history, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('nav_history'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => appState.setActiveTab(AppTab.history),
                child: Text(context.tr('details')),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recent Transactions Table
          RecentTransactionsTable(
            transactions: history.recentTransactions,
            onRefresh: () => history.loadRecentTransactions(),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareStatusBanner(BuildContext context, UsbProvider usb) {
    Color badgeColor;
    Color bgColor;
    IconData icon;
    String statusLabel;

    switch (usb.status) {
      case SmartCardConnectionStatus.cardDetected:
        badgeColor = AppColors.primary;
        bgColor = AppColors.infoBg;
        icon = Icons.sim_card;
        statusLabel = '🔵 Card Detected (SIM Present & Decoded)';
        break;
      case SmartCardConnectionStatus.cardWaiting:
        badgeColor = AppColors.warning;
        bgColor = AppColors.warningBg;
        icon = Icons.hourglass_top;
        statusLabel = '🟡 Card Waiting (Insert SIM to start)';
        break;
      case SmartCardConnectionStatus.readerConnected:
        badgeColor = AppColors.success;
        bgColor = AppColors.successBg;
        icon = Icons.usb;
        statusLabel = '🟢 Reader Connected';
        break;
      case SmartCardConnectionStatus.readerError:
        badgeColor = AppColors.danger;
        bgColor = AppColors.dangerBg;
        icon = Icons.error_outline;
        statusLabel = '🔴 Reader Error / Incompatible Hardware';
        break;
      case SmartCardConnectionStatus.disconnected:
        badgeColor = AppColors.textMuted;
        bgColor = AppColors.lightCard;
        icon = Icons.usb_off;
        statusLabel = '⚪ Reader Disconnected';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: badgeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      usb.readerName ?? 'USB Smart Card Reader',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.lightCard,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Text(
                        usb.deviceInfo?.protocol ?? 'PC/SC CCID',
                        style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  statusLabel,
                  style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Hardware Info Button
          OutlinedButton.icon(
            icon: const Icon(Icons.info_outline, size: 16),
            label: const Text('Device Info', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            onPressed: () => ReaderDeviceInfoModal.show(context, usb),
          ),
          const SizedBox(width: 8),

          // Simulation trigger menu for hardware testing
          PopupMenuButton<String>(
            tooltip: 'Hardware Simulator Actions',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.lightCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sim_card, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    usb.hasCard ? 'SIM Inserted' : 'Simulate SIM',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            onSelected: (action) {
              if (action == 'mobilis') usb.simulateInsertSimCard(OperatorType.mobilis);
              if (action == 'djezzy') usb.simulateInsertSimCard(OperatorType.djezzy);
              if (action == 'ooredoo') usb.simulateInsertSimCard(OperatorType.ooredoo);
              if (action == 'eject') usb.simulateRemoveSimCard();
              if (action == 'error') usb.simulateError('PC/SC card communication timeout');
              if (action == 'bad_device') usb.simulateIncompatibleReader();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mobilis',
                child: Text('🟢 Insert Mobilis SIM (0661123456)'),
              ),
              const PopupMenuItem(
                value: 'djezzy',
                child: Text('🟢 Insert Djezzy SIM (0770987654)'),
              ),
              const PopupMenuItem(
                value: 'ooredoo',
                child: Text('🟢 Insert Ooredoo SIM (0555432100)'),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'eject',
                child: Text('🟡 Eject SIM (Card Waiting)'),
              ),
              const PopupMenuItem(
                value: 'bad_device',
                child: Text('🔴 Simulate Incompatible USB Device'),
              ),
              const PopupMenuItem(
                value: 'error',
                child: Text('🔴 Simulate Hardware Error'),
              ),
            ],
          ),
          if (usb.hasCard) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.eject, color: AppColors.danger, size: 20),
              tooltip: 'Eject SIM Card',
              onPressed: () => usb.simulateRemoveSimCard(),
            ),
          ],
        ],
      ),
    );
  }
}
