import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/date_formatter.dart';
import '../../domain/entities/license.dart';
import '../providers/license_provider.dart';

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() => _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final TextEditingController _licenseKeyController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _serverUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final license = Provider.of<LicenseProvider>(context, listen: false);
    _serverUrlController.text = license.serverUrl;
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    _customerNameController.dispose();
    _serverUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final licenseProvider = Provider.of<LicenseProvider>(context);
    final license = licenseProvider.license;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('license_title'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Current License Status Overview Card
              if (license != null) _buildLicenseSummaryCard(context, license, licenseProvider),
              const SizedBox(height: 24),

              // Activate License Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('btn_activate'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _licenseKeyController,
                      decoration: InputDecoration(
                        labelText: context.tr('license_key'),
                        hintText: 'e.g. DZ-YEARLY-2026-ABCD-1234',
                        prefixIcon: const Icon(Icons.vpn_key, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: context.tr('customer_name'),
                        prefixIcon: const Icon(Icons.business, color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _serverUrlController,
                      decoration: InputDecoration(
                        labelText: context.tr('license_server_url'),
                        prefixIcon: const Icon(Icons.cloud_outlined, color: AppColors.textSecondary),
                      ),
                      onChanged: (val) => licenseProvider.setServerUrl(val),
                    ),
                    const SizedBox(height: 20),

                    if (licenseProvider.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          licenseProvider.errorMessage!,
                          style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                        ),
                      ),

                    if (licenseProvider.successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          licenseProvider.successMessage!,
                          style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold),
                        ),
                      ),

                    Row(
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified, size: 18),
                          label: Text(context.tr('btn_activate')),
                          onPressed: licenseProvider.isLoading
                              ? null
                              : () async {
                                  if (_licenseKeyController.text.trim().isEmpty) return;
                                  await licenseProvider.activateLicense(
                                    _licenseKeyController.text.trim(),
                                    customerName: _customerNameController.text.trim(),
                                  );
                                },
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.cloud_sync, size: 18),
                          label: Text(context.tr('btn_check_online')),
                          onPressed: licenseProvider.isLoading
                              ? null
                              : () => licenseProvider.verifyOnline(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicenseSummaryCard(
    BuildContext context,
    LicenseEntity license,
    LicenseProvider provider,
  ) {
    final isLifetime = license.plan == LicensePlan.lifetime;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: license.isValid ? AppColors.success : AppColors.danger,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    license.isValid ? Icons.check_circle : Icons.cancel,
                    color: license.isValid ? AppColors.success : AppColors.danger,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    license.isValid ? context.tr('license_active') : context.tr('license_expired'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  license.plan.name.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderLight),

          _buildDetailRow(context.tr('device_id'), provider.deviceId, isMonospace: true, canCopy: true, context: context),
          _buildDetailRow(context.tr('license_key'), license.licenseId, isMonospace: true),
          _buildDetailRow(
            context.tr('expiry_date'),
            isLifetime
                ? context.tr('plan_lifetime')
                : (license.expiryDate != null ? DateFormatter.formatDate(license.expiryDate!) : '-'),
          ),
          _buildDetailRow(context.tr('days_remaining'), '${license.daysRemaining} ${context.tr('days_remaining')}'),
          _buildDetailRow(context.tr('offline_grace'), '${license.offlineGracePeriod} Days'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isMonospace = false,
    bool canCopy = false,
    BuildContext? context,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  fontFamily: isMonospace ? 'monospace' : null,
                ),
              ),
              if (canCopy && context != null) ...[
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.copy, size: 16, color: AppColors.primary),
                  tooltip: 'Copy Device ID',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Device ID copied to clipboard')),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
