import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/updater/app_update_service.dart';

class AppUpdateModal extends StatefulWidget {
  const AppUpdateModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AppUpdateModal(),
    );
  }

  @override
  State<AppUpdateModal> createState() => _AppUpdateModalState();
}

class _AppUpdateModalState extends State<AppUpdateModal> {
  bool _isLoading = true;
  AppUpdateInfo? _updateInfo;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    setState(() => _isLoading = true);
    final info = await AppUpdateService.checkForUpdates();
    if (mounted) {
      setState(() {
        _updateInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.system_update_alt, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مركز تحديثات البرنامج (App Updates)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'فحص الإصدارات الجديدة والتحسينات',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderLight),

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('جاري الاتصال بخادم التحديثات وفحص الإصدارات...'),
                    ],
                  ),
                ),
              )
            else if (_updateInfo != null) ...[
              if (_updateInfo!.hasUpdate) ...[
                // New update available banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.new_releases, color: AppColors.success, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🎉 يتوفر إصدار جديد: v${_updateInfo!.latestVersion}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success, fontSize: 14),
                            ),
                            Text(
                              'إصدارك الحالي: v${_updateInfo!.currentVersion}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'سجل التغييرات والتحسينات في هذا التحديث:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),

                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 140),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _updateInfo!.releaseNotes,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('لاحقاً'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('تنزيل وتثبيت التحديث الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('🚀 جاري توجيهك لرابط تحميل أحدث نسخة من البرنامج...'),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ] else ...[
                // Already up to date banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.lightCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 32),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'برنامجك محدث بالكامل ✅',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'أنت تستخدم أحدث إصدار متاح حالياً (v${_updateInfo!.currentVersion})',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('إعادة الفحص'),
                      onPressed: _check,
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق'),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
