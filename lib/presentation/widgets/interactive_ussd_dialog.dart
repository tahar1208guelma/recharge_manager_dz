import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../domain/entities/ussd_session_state.dart';
import '../../services/printing/receipt_template.dart';
import '../../services/ussd/ussd_session_manager.dart';
import '../providers/recharge_provider.dart';
import 'receipt_preview_modal.dart';

class InteractiveUssdDialog extends StatefulWidget {
  final OperatorType operator;
  final String initialUssdCode;
  final String? phoneNumber;
  final double? amount;
  final String? customerName;

  const InteractiveUssdDialog({
    super.key,
    required this.operator,
    required this.initialUssdCode,
    this.phoneNumber,
    this.amount,
    this.customerName,
  });

  static Future<void> show(
    BuildContext context, {
    required OperatorType operator,
    required String initialUssdCode,
    String? phoneNumber,
    double? amount,
    String? customerName,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => InteractiveUssdDialog(
        operator: operator,
        initialUssdCode: initialUssdCode,
        phoneNumber: phoneNumber,
        amount: amount,
        customerName: customerName,
      ),
    );
  }

  @override
  State<InteractiveUssdDialog> createState() => _InteractiveUssdDialogState();
}

class _InteractiveUssdDialogState extends State<InteractiveUssdDialog> {
  late UssdSessionManager _sessionManager;
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  UssdSessionState? _state;
  bool _isFinalized = false;

  @override
  void initState() {
    super.initState();
    _sessionManager = UssdSessionManager();
    _sessionManager.stateStream.listen((state) {
      if (mounted) {
        setState(() => _state = state);
        _scrollToBottom();
        if (state.isCompleted && !_isFinalized) {
          _isFinalized = true;
          _handleSuccessfulCompletion();
        }
      }
    });

    _start();
  }

  Future<void> _start() async {
    await _sessionManager.startSession(
      operator: widget.operator,
      ussdCode: widget.initialUssdCode,
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendReply(String text) {
    if (text.trim().isEmpty) return;
    _replyController.clear();
    _sessionManager.sendReply(text.trim());
  }

  Future<void> _handleSuccessfulCompletion() async {
    final recharge = Provider.of<RechargeProvider>(context, listen: false);
    if (widget.phoneNumber != null && widget.amount != null) {
      await recharge.executeRecharge();
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    _sessionManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opColor = OperatorConstants.getOperatorColor(widget.operator);
    final opName = OperatorConstants.getOperatorName(widget.operator, lang: 'ar');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 580,
        height: 600,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: opColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.phonelink_ring, color: opColor, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'جلسة USSD تفاعلية - $opName (SIM Live Session)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getStatusColor(),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getStatusTitle(),
                            style: TextStyle(color: _getStatusColor(), fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _sessionManager.cancelSession();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.borderLight),

            // Chat / Terminal Messages Feed
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Dark terminal background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _state?.messages.length ?? 0,
                  itemBuilder: (context, index) {
                    final msg = _state!.messages[index];
                    return _buildMessageBubble(msg, opColor);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Detected Option Buttons (if waiting for user response)
            if (_state != null && _state!.isWaitingUser && _state!.currentOptions.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _state!.currentOptions.map((opt) {
                  final numMatch = RegExp(r'^(\d+)').firstMatch(opt);
                  final numVal = numMatch?.group(1) ?? opt;

                  return ActionChip(
                    backgroundColor: opColor.withOpacity(0.12),
                    side: BorderSide(color: opColor),
                    label: Text(
                      opt,
                      style: TextStyle(color: opColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    onPressed: _state!.isProcessing ? null : () => _sendReply(numVal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Input / Actions Bar
            if (_state != null && _state!.isWaitingUser) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _replyController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'أدخل رقم الخيار أو الرد المطلوب...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: _sendReply,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('إرسال للشريحة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _state!.isProcessing ? null : () => _sendReply(_replyController.text),
                  ),
                ],
              ),
            ] else if (_state != null && _state!.isCompleted) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('طباعة الوصل فوراً'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      final recharge = Provider.of<RechargeProvider>(context, listen: false);
                      if (recharge.lastTransaction != null) {
                        final receipt = ReceiptData.fromTransaction(recharge.lastTransaction!);
                        showDialog(
                          context: context,
                          builder: (_) => ReceiptPreviewModal(receipt: receipt),
                        );
                      }
                    },
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('تم (إغلاق)'),
                  ),
                ],
              ),
            ] else if (_state != null && _state!.isProcessing) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('جاري إرسال الطلب للشريحة واستلام الرد...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ] else if (_state != null && (_state!.isFailed || _state!.status == UssdSessionStatus.cancelled)) ...[
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(UssdSessionMessage msg, Color opColor) {
    if (msg.isFromSim) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.sim_card, color: Colors.greenAccent, size: 14),
                SizedBox(width: 6),
                Text(
                  'رد الشريحة (Incoming SIM Message):',
                  style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              msg.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    } else {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: opColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: opColor.withOpacity(0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_forward, color: Colors.white70, size: 12),
              const SizedBox(width: 6),
              Text(
                msg.content,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace'),
              ),
            ],
          ),
        ),
      );
    }
  }

  Color _getStatusColor() {
    switch (_state?.status) {
      case UssdSessionStatus.sending:
        return AppColors.info;
      case UssdSessionStatus.waitingUserResponse:
        return AppColors.warning;
      case UssdSessionStatus.completed:
        return AppColors.success;
      case UssdSessionStatus.failed:
      case UssdSessionStatus.cancelled:
        return AppColors.danger;
      default:
        return AppColors.textMuted;
    }
  }

  String _getStatusTitle() {
    switch (_state?.status) {
      case UssdSessionStatus.sending:
        return 'جاري إرسال الأمر للشريحة...';
      case UssdSessionStatus.waitingUserResponse:
        return 'الشريحة تنتظر اختيارك وتأكيدك';
      case UssdSessionStatus.completed:
        return 'تمت العملية وتأكيد الشريحة بنجاح ✅';
      case UssdSessionStatus.failed:
        return 'فشلت العملية أو انقطع الاتصال';
      case UssdSessionStatus.cancelled:
        return 'تم إلغاء الجلسة';
      default:
        return 'جاهز للبدء';
    }
  }
}
