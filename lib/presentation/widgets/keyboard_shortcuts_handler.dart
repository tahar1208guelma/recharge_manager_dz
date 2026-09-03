import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../services/printing/receipt_template.dart';
import '../providers/app_state_provider.dart';
import '../providers/recharge_provider.dart';
import 'receipt_preview_modal.dart';

class KeyboardShortcutsHandler extends StatelessWidget {
  final Widget child;

  const KeyboardShortcutsHandler({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () {
          Provider.of<AppStateProvider>(context, listen: false).setActiveTab(AppTab.recharge);
        },
        const SingleActivator(LogicalKeyboardKey.f2): () {
          Provider.of<AppStateProvider>(context, listen: false).setActiveTab(AppTab.customers);
        },
        const SingleActivator(LogicalKeyboardKey.f3): () {
          Provider.of<AppStateProvider>(context, listen: false).setActiveTab(AppTab.history);
        },
        const SingleActivator(LogicalKeyboardKey.f4): () {
          final recharge = Provider.of<RechargeProvider>(context, listen: false);
          if (recharge.lastTransaction != null) {
            final receipt = ReceiptData.fromTransaction(recharge.lastTransaction!);
            showDialog(
              context: context,
              builder: (_) => ReceiptPreviewModal(receipt: receipt),
            );
          }
        },
        const SingleActivator(LogicalKeyboardKey.f5): () {
          final recharge = Provider.of<RechargeProvider>(context, listen: false);
          recharge.refreshAllBalances();
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          final recharge = Provider.of<RechargeProvider>(context, listen: false);
          recharge.clearForm();
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
