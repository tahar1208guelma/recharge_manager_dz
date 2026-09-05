import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../providers/app_state_provider.dart';
import '../providers/auth_provider.dart';

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppStateProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
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
          // Logo & Header with VAST solutions branding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              mainAxisAlignment:
                  isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0891B2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.4), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/developer_logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => const Icon(Icons.flash_on, color: AppColors.primary, size: 22),
                    ),
                  ),
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
                            fontSize: 15,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'by VAST solutions',
                          style: TextStyle(
                            color: Color(0xFF06B6D4),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
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
                  onTap: () => appState.setActiveTab(AppTab.dashboard),
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.recharge,
                  title: context.tr('nav_recharge'),
                  icon: Icons.phone_android_outlined,
                  activeIcon: Icons.phone_android,
                  isSelected: appState.activeTab == AppTab.recharge,
                  isCollapsed: isCollapsed,
                  onTap: () => appState.setActiveTab(AppTab.recharge),
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.history,
                  title: context.tr('nav_history'),
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  isSelected: appState.activeTab == AppTab.history,
                  isCollapsed: isCollapsed,
                  onTap: () => appState.setActiveTab(AppTab.history),
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.customers,
                  title: context.tr('nav_customers'),
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  isSelected: appState.activeTab == AppTab.customers,
                  isCollapsed: isCollapsed,
                  onTap: () => appState.setActiveTab(AppTab.customers),
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.reports,
                  title: context.tr('nav_reports'),
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  isSelected: appState.activeTab == AppTab.reports,
                  isCollapsed: isCollapsed,
                  onTap: () => appState.setActiveTab(AppTab.reports),
                ),
                _buildNavItem(
                  context,
                  tab: AppTab.settings,
                  title: context.tr('nav_settings'),
                  icon: Icons.settings_outlined,
                  activeIcon: Icons.settings,
                  isSelected: appState.activeTab == AppTab.settings,
                  isCollapsed: isCollapsed,
                  onTap: () => appState.setActiveTab(AppTab.settings),
                ),
                if (auth.isAdmin)
                  _buildNavItem(
                    context,
                    tab: AppTab.license,
                    title: context.tr('nav_license'),
                    icon: Icons.verified_user_outlined,
                    activeIcon: Icons.verified_user,
                    isSelected: appState.activeTab == AppTab.license,
                    isCollapsed: isCollapsed,
                    onTap: () => appState.setActiveTab(AppTab.license),
                  ),
              ],
            ),
          ),

          // Developer Footer Badge
          if (!isCollapsed) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF06B6D4), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Image.asset(
                      'assets/images/developer_logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, __, ___) => const Icon(Icons.code, color: Color(0xFF06B6D4), size: 18),
                    ),
                  ),
                ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VAST solutions',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Telecom Software',
                          style: TextStyle(
                            color: Color(0xFF06B6D4),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(color: AppColors.borderDark, height: 1),

          // Collapse Toggle Button
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: Icon(
                isCollapsed
                    ? (context.isRtl ? Icons.chevron_left : Icons.chevron_right)
                    : (context.isRtl ? Icons.chevron_right : Icons.chevron_left),
                color: AppColors.textMuted,
              ),
              onPressed: () => appState.toggleSidebar(),
            ),
          ),
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
    required VoidCallback onTap,
    String? badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: isCollapsed ? title : '',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? 12 : 16,
              vertical: 11,
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
                        fontSize: 13,
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
      ),
    );
  }
}
