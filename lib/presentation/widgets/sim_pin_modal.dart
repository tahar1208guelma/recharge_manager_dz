import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../providers/usb_provider.dart';

class SimPinModal extends StatefulWidget {
  final UsbProvider usb;

  const SimPinModal({super.key, required this.usb});

  static void show(BuildContext context, UsbProvider usb) {
    showDialog(
      context: context,
      builder: (context) => SimPinModal(usb: usb),
    );
  }

  @override
  State<SimPinModal> createState() => _SimPinModalState();
}

class _SimPinModalState extends State<SimPinModal> {
  late TextEditingController _pinController;
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _pinController = TextEditingController(text: widget.usb.simPin);
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.pin, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'إعداد الرمز السري للشريحة (SIM PIN)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'يُستخدم تلقائياً في أوامر الـ USSD وعمليات التعبئة',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 24, color: AppColors.borderLight),

            const Text(
              'أدخل رمز الـ PIN الحالي لشريحة التعبئة:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _pinController,
              obscureText: _obscureText,
              keyboardType: TextInputType.number,
              maxLength: 8,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: '0000',
                counterText: '',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'الرمز الافتراضي لمعظم شرائح التعبئة ونقاط البيع هو 0000.',
                      style: TextStyle(fontSize: 11, color: AppColors.info),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final newPin = _pinController.text.trim();
                    if (newPin.isNotEmpty) {
                      widget.usb.setSimPin(newPin);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('✅ تم حفظ رمز PIN للشريحة بنجاح: $newPin'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: const Text('حفظ الرمز'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
