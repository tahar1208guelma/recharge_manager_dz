import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../sms/sms_message.dart';
import '../providers/modem_provider.dart';

class SmsInboxScreen extends StatefulWidget {
  const SmsInboxScreen({super.key});

  @override
  State<SmsInboxScreen> createState() => _SmsInboxScreenState();
}

class _SmsInboxScreenState extends State<SmsInboxScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _recipientController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _showComposeModal() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.send_outlined, color: AppColors.primary),
            SizedBox(width: 8),
            Text('إرسال رسالة نصية قصيرة (Send SMS)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _recipientController,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف المستلم (05 / 06 / 07)',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'نص الرسالة...',
                alignLabelWithHint: true,
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            icon: _isSending
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send, size: 16),
            label: const Text('إرسال الآن'),
            onPressed: _isSending
                ? null
                : () async {
                    final phone = PhoneValidator.sanitize(_recipientController.text);
                    final text = _messageController.text.trim();
                    if (phone.isEmpty || text.isEmpty) return;

                    setState(() => _isSending = true);
                    final modem = Provider.of<ModemProvider>(context, listen: false);
                    final ok = await modem.smsService.sendSms(phone, text);
                    setState(() => _isSending = false);

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(ok ? '✅ تم إرسال الرسالة بنجاح.' : '❌ فشل إرسال الرسالة.'),
                          backgroundColor: ok ? AppColors.success : AppColors.danger,
                        ),
                      );
                    }
                  },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modem = Provider.of<ModemProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'صندوق الرسائل القصيرة (SIM SMS Manager)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'إدارة وقراءة وإرسال رسائل SMS للشريحة المتصلة بالمودم',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('تحديث الرسائل'),
                      onPressed: () => modem.smsService.fetchAllMessages(),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('رسالة جديدة (Compose)'),
                      onPressed: _showComposeModal,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Messages List
            Expanded(
              child: modem.smsList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.mark_email_unread_outlined, size: 64, color: AppColors.textMuted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          const Text(
                            'لا توجد رسائل SMS مخزنة على الشريحة',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: modem.smsList.length,
                      itemBuilder: (context, index) {
                        final msg = modem.smsList[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: msg.type == SmsType.sent ? AppColors.infoBg : AppColors.primary.withOpacity(0.12),
                              child: Icon(
                                msg.type == SmsType.sent ? Icons.call_made : Icons.call_received,
                                color: msg.type == SmsType.sent ? AppColors.info : AppColors.primary,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  msg.senderOrRecipient,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  DateFormatter.formatDateTime(msg.timestamp),
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                msg.text,
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                              ),
                            ),
                            trailing: msg.indexOnSim != null
                                ? IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                                    onPressed: () async {
                                      await modem.smsService.deleteMessage(msg.indexOnSim!);
                                    },
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
