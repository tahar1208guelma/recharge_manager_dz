import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/keyboard_shortcuts_handler.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/top_status_bar.dart';
import 'android_usb_check_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'history_screen.dart';
import 'license_activation_screen.dart';
import 'recharge_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);

    return KeyboardShortcutsHandler(
      child: Scaffold(
        body: Row(
          children: [
            // Sidebar Navigation
            const SidebarNavigation(),

            // Main Content Area
            Expanded(
              child: Column(
                children: [
                  // Top Status Bar (USB, License, Language, User, Refresh)
                  const TopStatusBar(),

                  // Active Screen Body
                  Expanded(
                    child: _buildActiveTab(appState.activeTab),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTab(AppTab tab) {
    switch (tab) {
      case AppTab.dashboard:
        return const DashboardScreen();
      case AppTab.recharge:
        return const RechargeScreen();
      case AppTab.customers:
        return const CustomersScreen();
      case AppTab.history:
        return const HistoryScreen();
      case AppTab.reports:
        return const ReportsScreen();
      case AppTab.settings:
        return const SettingsScreen();
      case AppTab.license:
        return const LicenseActivationScreen();
      case AppTab.usbCheck:
        return const AndroidUsbCheckScreen();
    }
  }
}
