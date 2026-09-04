import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/localization/locale_provider.dart';
import '../../services/updater/app_update_service.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_update_modal.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _storeNameController.text = settings.storeName;
    _storeAddressController.text = settings.storeAddress;
    _storePhoneController.text = settings.storePhone;
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _storePhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('settings_title'),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // Store / POS Receipt Information
              _buildSectionCard(
                title: context.tr('store_info'),
                icon: Icons.storefront,
                children: [
                  TextFormField(
                    controller: _storeNameController,
                    decoration: InputDecoration(
                      labelText: context.tr('store_name'),
                      prefixIcon: const Icon(Icons.store, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _storeAddressController,
                    decoration: InputDecoration(
                      labelText: context.tr('store_address'),
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _storePhoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: context.tr('store_phone'),
                      prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save, size: 18),
                      label: Text(context.tr('btn_save')),
                      onPressed: () async {
                        await settings.updateStoreInfo(
                          name: _storeNameController.text,
                          address: _storeAddressController.text,
                          phone: _storePhoneController.text,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.success,
                              content: Text(context.tr('saved_successfully')),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Software Updates Center (مركز التحديثات)
              _buildSectionCard(
                title: 'تحديثات البرنامج (App Updates & Maintenance)',
                icon: Icons.system_update_alt,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'الإصدار الحالي المثبت:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.lightCard,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: const Text(
                              'v${AppUpdateService.currentAppVersion} (Stable Release)',
                              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('فحص التحديثات الآن'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => AppUpdateModal.show(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Language & Localization Settings
              _buildSectionCard(
                title: context.tr('language'),
                icon: Icons.language,
                children: [
                  _buildLanguageOption(
                    title: 'العربية (Arabic - Default RTL)',
                    code: 'ar',
                    currentCode: localeProvider.languageCode,
                    onSelect: () => localeProvider.setLanguageCode('ar'),
                  ),
                  _buildLanguageOption(
                    title: 'Français (French)',
                    code: 'fr',
                    currentCode: localeProvider.languageCode,
                    onSelect: () => localeProvider.setLanguageCode('fr'),
                  ),
                  _buildLanguageOption(
                    title: 'English',
                    code: 'en',
                    currentCode: localeProvider.languageCode,
                    onSelect: () => localeProvider.setLanguageCode('en'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mock Mode & Simulation
              _buildSectionCard(
                title: context.tr('mock_mode'),
                icon: Icons.developer_mode,
                children: [
                  SwitchListTile(
                    title: Text(context.tr('mock_mode')),
                    subtitle: Text(context.tr('mock_mode_desc')),
                    value: settings.mockMode,
                    activeThumbColor: AppColors.primary,
                    onChanged: (val) => settings.setMockMode(val),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required String code,
    required String currentCode,
    required VoidCallback onSelect,
  }) {
    final isSelected = code == currentCode;
    return InkWell(
      onTap: onSelect,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24, color: AppColors.borderLight),
          ...children,
        ],
      ),
    );
  }
}
