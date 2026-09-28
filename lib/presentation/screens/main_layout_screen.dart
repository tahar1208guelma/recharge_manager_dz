import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/usb_provider.dart';
import '../widgets/keyboard_shortcuts_handler.dart';
import '../widgets/sidebar_navigation.dart';
import '../widgets/top_status_bar.dart';
import 'android_usb_check_screen.dart';
import 'customers_screen.dart';
import 'dashboard_screen.dart';
import 'debug_console_screen.dart';
import 'hardware_diagnostic_screen.dart';
import 'history_screen.dart';
import 'license_activation_screen.dart';
import 'recharge_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'sms_inbox_screen.dart';

class MainLayoutScreen extends StatelessWidget {
  const MainLayoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);
    final usb = Provider.of<UsbProvider>(context);
    final isSimulationActive = settings.mockMode || usb.isSimulationMode;

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

                  // Visible Simulation Mode Banner (Mandatory Rule)
                  if (isSimulationActive)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '⚠️ وضع المحاكاة مفعّل: يتم استخدام عتاد افتراضي وبيانات وهمية لأغراض الاختبار | Simulation Mode Active: Using mock hardware data',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              settings.setMockMode(false);
                              usb.setSimulationMode(false);
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            ),
                            child: const Text(
                              'تعطيل المحاكاة (Hardware Mode)',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

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
      case AppTab.smsInbox:
        return const SmsInboxScreen();
      case AppTab.debugConsole:
        return const DebugConsoleScreen();
      case AppTab.hardwareDiagnostic:
        return const HardwareDiagnosticScreen();
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
