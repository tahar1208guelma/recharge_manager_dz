import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/app_state_provider.dart';

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final isCollapsed = appState.isSidebarCollapsed;

    return Container(
      width: isCollapsed ? 70 : 250,
      decoration: BoxDecoration(
        color: AppColors.bgDark,
        border: Border(
          right: context.isRtl
              ? BorderSide.none
              : const BorderSide(color: AppColors.borderDark, width: 1),
          left: context.isRtl
              ? const BorderSide(color: AppColors.borderDark, width: 1)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          // Logo & Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.white, size: 24),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recharge DZ',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'POS Edition',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(color: AppColors.borderDark, height: 1),

          // Menu Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              children: [
                _buildNavItem(
                  context,
                  tab: AppTab.dashboard,
                  title: context.tr('nav_dashboard'),
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  isSelected: appState.activeTab == AppTab.dashboard,
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.recharge,
                  title: context.tr('nav_recharge'),
                  icon: Icons.phone_android_outlined,
                  activeIcon: Icons.phone_android,
                  isSelected: appState.activeTab == AppTab.recharge,
                  isCollapsed: isCollapsed,
                  badgeText: 'F1',
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.customers,
                  title: context.tr('nav_customers'),
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  isSelected: appState.activeTab == AppTab.customers,
                  isCollapsed: isCollapsed,
                  badgeText: 'F2',
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.history,
                  title: context.tr('nav_history'),
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  isSelected: appState.activeTab == AppTab.history,
                  isCollapsed: isCollapsed,
                  badgeText: 'F3',
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.reports,
                  title: context.tr('nav_reports'),
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  isSelected: appState.activeTab == AppTab.reports,
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.settings,
                  title: context.tr('nav_settings'),
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  isSelected: appState.activeTab == AppTab.settings,
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.license,
                  title: context.tr('nav_license'),
                  icon: Icons.verified_user_outlined,
                  activeIcon: Icons.verified_user,
                  isSelected: appState.activeTab == AppTab.license,
                  isCollapsed: isCollapsed,
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.usbCheck,
                  title: context.tr('nav_usb_check'),
                  icon: Icons.usb,
                  activeIcon: Icons.usb,
                  isSelected: appState.activeTab == AppTab.usbCheck,
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),

          // Collapse Toggle Button
          const Divider(color: AppColors.borderDark, height: 1),
          ListTile(
            onTap: () => appState.toggleSidebar(),
            leading: Icon(
              isCollapsed
                  ? (context.isRtl ? Icons.chevron_left : Icons.chevron_right)
                  : (context.isRtl ? Icons.chevron_right : Icons.chevron_left),
              color: AppColors.textMuted,
            ),
            title: isCollapsed
                ? null
                : Text(
                    isCollapsed ? '' : 'Collapse',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required AppTab tab,
    required String title,
    required IconData icon,
    required IconData activeIcon,
    required bool isSelected,
    required bool isCollapsed,
    String? badgeText,
  }) {
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => appState.setActiveTab(tab),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 12 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment:
                isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? Colors.white : AppColors.textMuted,
                size: 20,
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black26 : AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
