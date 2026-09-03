import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../providers/usb_provider.dart';
import '../../services/smart_card/smart_card_state.dart';

class ReaderDeviceInfoModal extends StatelessWidget {
  final UsbProvider usb;

  const ReaderDeviceInfoModal({super.key, required this.usb});

  static void show(BuildContext context, UsbProvider usb) {
    showDialog(
      context: context,
      builder: (context) => ReaderDeviceInfoModal(usb: usb),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dev = usb.deviceInfo;
    final card = usb.cardInfo;

    Color statusColor;
    Color statusBg;
    String statusTitle;

    switch (usb.status) {
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
        statusTitle = '🔵 Card Detected (SIM Present)';
        break;
      case SmartCardConnectionStatus.readerError:
        statusColor = AppColors.danger;
        statusBg = AppColors.dangerBg;
        statusTitle = '🔴 Reader Error / Incompatible';
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
        width: 520,
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
                          'Smart Card Hardware & Device Info',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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

            // Incompatibility warning banner if present
            if (dev != null && !dev.isCompatible) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.danger),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: AppColors.danger, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        dev.errorMessage ?? 'This device is not compatible with ISO 7816-4 SIM smart cards.',
                        style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Device Information Section
            const Text(
              'Hardware Identifiers (PC/SC & USB Host):',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                children: [
                  _buildRow('Reader Name', dev?.readerName ?? usb.readerName ?? 'N/A', isBold: true),
                  _buildRow('Manufacturer', dev?.manufacturer ?? 'Standard PC/SC Device'),
                  _buildRow('Vendor ID (VID)', dev?.formattedVendorId ?? 'N/A', isMonospace: true),
                  _buildRow('Product ID (PID)', dev?.formattedProductId ?? 'N/A', isMonospace: true),
                  _buildRow('Protocol', dev?.protocol ?? 'PC/SC (CCID T=0 / T=1)'),
                  _buildRow('Connection Status', dev?.connectionStatus ?? usb.status.name.toUpperCase()),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Smart Card / SIM Information Section if card detected
            if (card != null) ...[
              const Text(
                'Inserted SIM Card Info (ISO 7816-4 Public Data):',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.lightCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  children: [
                    _buildRow(
                      'Detected Operator',
                      OperatorConstants.getOperatorName(card.operator, lang: 'ar'),
                      highlightColor: OperatorConstants.getOperatorColor(card.operator),
                    ),
                    if (card.msisdn != null) _buildRow('MSISDN (Phone)', card.msisdn!, isMonospace: true, isBold: true),
                    if (card.imsi != null) _buildRow('IMSI (EF_IMSI)', card.imsi!, isMonospace: true),
                    if (card.iccid != null) _buildRow('ICCID (EF_ICCID)', card.iccid!, isMonospace: true),
                    if (card.atr != null) _buildRow('ATR (Answer To Reset)', card.atr!, isMonospace: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Close button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق (Close)'),
              ),
            ),
          ],
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
