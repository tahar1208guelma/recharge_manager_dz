import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/smart_card/smart_card_state.dart';
import '../providers/auth_provider.dart';
import '../providers/license_provider.dart';
import '../providers/recharge_provider.dart';
import '../providers/usb_provider.dart';
import 'reader_device_info_modal.dart';
import 'sim_pin_modal.dart';

class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final usb = Provider.of<UsbProvider>(context);
    final license = Provider.of<LicenseProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final recharge = Provider.of<RechargeProvider>(context, listen: false);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.borderLight, width: 1)),
      ),
      child: Row(
        children: [
          // USB & Smart Card Reader Indicator (with 4 States: 🟢 🟡 🔵 🔴)
          InkWell(
            onTap: () => ReaderDeviceInfoModal.show(context, usb),
            borderRadius: BorderRadius.circular(20),
            child: _buildUsbStatus(context, usb),
          ),
          const SizedBox(width: 10),

          // SIM PIN Quick Action Badge
          InkWell(
            onTap: () => SimPinModal.show(context, usb),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.key, color: AppColors.primary, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'PIN: ${usb.simPin}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // License Status Badge
          _buildLicenseBadge(context, license),

          const Spacer(),

          // Refresh Balances Button (F5)
          IconButton(
            tooltip: '${context.tr('refresh')} (F5)',
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: () {
              recharge.refreshAllBalances();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('available_balance')),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // Language Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderLight),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: localeProvider.languageCode,
                icon: const Icon(Icons.language, size: 18, color: AppColors.textSecondary),
                items: const [
                  DropdownMenuItem(value: 'ar', child: Text('العربية')),
                  DropdownMenuItem(value: 'fr', child: Text('Français')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (code) {
                  if (code != null) {
                    localeProvider.setLanguageCode(code);
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 16),

          // User Info / Cashier
          if (auth.isAuthenticated)
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    auth.currentUser!.fullName.substring(0, 1),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  auth.currentUser!.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildUsbStatus(BuildContext context, UsbProvider usb) {
    Color badgeColor;
    Color bgColor;
    IconData icon;
    String statusText;

    switch (usb.status) {
      case SmartCardConnectionStatus.cardDetected:
        badgeColor = AppColors.primary;
        bgColor = AppColors.infoBg;
        icon = Icons.sim_card;
        final opName = OperatorConstants.getOperatorName(usb.detectedOperator, lang: context.isRtl ? 'ar' : 'en');
        statusText = '🔵 Card Detected ($opName)';
        break;
      case SmartCardConnectionStatus.cardWaiting:
        badgeColor = AppColors.warning;
        bgColor = AppColors.warningBg;
        icon = Icons.hourglass_top;
        statusText = '🟡 Card Waiting';
        break;
      case SmartCardConnectionStatus.readerConnected:
        badgeColor = AppColors.success;
        bgColor = AppColors.successBg;
        icon = Icons.usb;
        statusText = '🟢 Reader Connected';
        break;
      case SmartCardConnectionStatus.readerError:
        badgeColor = AppColors.danger;
        bgColor = AppColors.dangerBg;
        icon = Icons.error_outline;
        statusText = '🔴 Reader Error';
        break;
      case SmartCardConnectionStatus.disconnected:
        badgeColor = AppColors.textMuted;
        bgColor = AppColors.lightCard;
        icon = Icons.usb_off;
        statusText = '🔴 Reader Disconnected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: badgeColor, size: 16),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Icon(Icons.info_outline, color: badgeColor.withOpacity(0.7), size: 14),
        ],
      ),
    );
  }

  Widget _buildLicenseBadge(BuildContext context, LicenseProvider license) {
    if (license.license == null) return const SizedBox.shrink();

    final lic = license.license!;
    final isTrial = license.isTrial;
    final isValid = license.isLicensed;

    Color color = isValid ? (isTrial ? AppColors.info : AppColors.success) : AppColors.danger;
    Color bgColor = isValid ? (isTrial ? AppColors.infoBg : AppColors.successBg) : AppColors.dangerBg;
    String label = isTrial ? context.tr('license_trial') : context.tr('license_active');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isValid ? Icons.check_circle : Icons.warning, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            '$label (${lic.daysRemaining} ${context.tr('days_remaining')})',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
