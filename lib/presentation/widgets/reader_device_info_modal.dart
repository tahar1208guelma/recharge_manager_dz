import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../services/smart_card/platforms/windows_pcsc_native.dart';
import '../providers/usb_provider.dart';
import '../../services/smart_card/smart_card_state.dart';

class ReaderDeviceInfoModal extends StatefulWidget {
  final UsbProvider usb;

  const ReaderDeviceInfoModal({super.key, required this.usb});

  static void show(BuildContext context, UsbProvider usb) {
    showDialog(
      context: context,
      builder: (context) => ReaderDeviceInfoModal(usb: usb),
    );
  }

  @override
  State<ReaderDeviceInfoModal> createState() => _ReaderDeviceInfoModalState();
}

class _ReaderDeviceInfoModalState extends State<ReaderDeviceInfoModal> {
  bool _isScanning = false;
  String? _selectedReader;

  @override
  void initState() {
    super.initState();
    _selectedReader = widget.usb.readerName;
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _isScanning = true);
    await widget.usb.refreshReaders();
    if (mounted) {
      setState(() {
        if (widget.usb.availableReaders.isNotEmpty) {
          _selectedReader = widget.usb.availableReaders.first.readerName;
        }
        _isScanning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dev = widget.usb.deviceInfo;
    final card = widget.usb.cardInfo;

    Color statusColor;
    Color statusBg;
    String statusTitle;

    switch (widget.usb.status) {
      case SmartCardConnectionStatus.readerConnected:
        statusColor = AppColors.success;
        statusBg = AppColors.successBg;
        statusTitle = '🟢 Reader Connected';
        break;
      case SmartCardConnectionStatus.cardWaiting:
        statusColor = AppColors.warning;
        statusBg = AppColors.warningBg;
        statusTitle = '🟡 Card Waiting (No SIM Inserted)';
        break;
      case SmartCardConnectionStatus.cardDetected:
        statusColor = AppColors.primary;
        statusBg = AppColors.infoBg;
        statusTitle = '🔵 Card Detected (SIM Ready)';
        break;
      case SmartCardConnectionStatus.readerError:
        statusColor = AppColors.danger;
        statusBg = AppColors.dangerBg;
        statusTitle = '🔴 Reader Error';
        break;
      case SmartCardConnectionStatus.disconnected:
        statusColor = AppColors.textMuted;
        statusBg = AppColors.lightCard;
        statusTitle = '⚪ Reader Disconnected';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
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
                          color: statusBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.credit_card, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إعدادات وتشخيص قارئ الشريحة (Hardware Diagnostics)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            statusTitle,
                            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
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

              // Hardware Selector Box
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'اختر القارئ أو المنفذ المتصل (Reader / Port):',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        if (_isScanning)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          InkWell(
                            onTap: _refresh,
                            child: const Row(
                              children: [
                                Icon(Icons.refresh, size: 16, color: AppColors.primary),
                                SizedBox(width: 4),
                                Text('إعادة فحص المنافذ', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (widget.usb.availableReaders.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: widget.usb.availableReaders.any((r) => r.readerName == _selectedReader)
                                ? _selectedReader
                                : widget.usb.availableReaders.first.readerName,
                            items: widget.usb.availableReaders.map((r) {
                              return DropdownMenuItem<String>(
                                value: r.readerName,
                                child: Text(
                                  r.readerName,
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedReader = val);
                                widget.usb.connectReader(val);
                              }
                            },
                          ),
                        ),
                      )
                    else
                      const Text('لا توجد منافذ مكتشفة حالياً.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Device Details
              const Text(
                'بيانات الاتصال الحالية (Hardware Details):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _buildRow('القارئ النشط', dev?.readerName ?? widget.usb.readerName ?? 'USB Smart Card Reader', isBold: true),
                    _buildRow('بروتوكول الاتصال', dev?.protocol ?? 'PC/SC CCID & Direct Serial'),
                    _buildRow('حالة الشريحة', 'متصلة وجاهزة للعمل (Card Ready)', highlightColor: AppColors.success),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // SIM Information Section
              if (card != null) ...[
                const Text(
                  'بيانات الشريحة (SIM Public Data):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      _buildRow(
                        'الشبكة المكتشفة',
                        OperatorConstants.getOperatorName(card.operator, lang: 'ar'),
                        highlightColor: OperatorConstants.getOperatorColor(card.operator),
                      ),
                      if (card.msisdn != null) _buildRow('رقم الهاتف (MSISDN)', card.msisdn!, isMonospace: true, isBold: true),
                      if (card.imsi != null) _buildRow('رقم الهوية (IMSI)', card.imsi!, isMonospace: true),
                      if (card.atr != null) _buildRow('كود ATR', card.atr!, isMonospace: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Windows Troubleshooting Actions
              if (Platform.isWindows) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.build_circle_outlined, color: AppColors.info, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'إذا كان القارئ متصلاً ولا يستجيب، اضغط على زر تشغيل خدمة الويندوز الذكية.',
                          style: TextStyle(fontSize: 11, color: AppColors.info),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await WinSCardNative.ensureSmartCardServiceRunning();
                          await _refresh();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✅ تم تشغيل خدمة Windows Smart Card وتحديث المنافذ بنجاح.')),
                            );
                          }
                        },
                        child: const Text('تشغيل الخدمة', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('تفعيل الشريحة فوراً'),
                    onPressed: () {
                      widget.usb.connectReader(_selectedReader);
                      Navigator.pop(context);
                    },
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('تم (Done)'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isMonospace = false, bool isBold = false, Color? highlightColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: isMonospace ? 'monospace' : null,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                fontSize: 12,
                color: highlightColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
