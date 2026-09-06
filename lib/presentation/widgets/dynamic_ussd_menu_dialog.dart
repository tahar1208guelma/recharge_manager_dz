import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../transactions/transaction_manager.dart';
import '../../transactions/transaction_state.dart';
import '../../ussd/session_engine.dart';
import '../providers/modem_provider.dart';
import 'receipt_preview_modal.dart';

class DynamicUssdMenuDialog extends StatefulWidget {
  final OperatorType operator;
  final String initialUssdCode;
  final String? phoneNumber;
  final double? amount;

  const DynamicUssdMenuDialog({
    super.key,
    required this.operator,
    required this.initialUssdCode,
    this.phoneNumber,
    this.amount,
  });

  static Future<void> show(
    BuildContext context, {
    required OperatorType operator,
    required String initialUssdCode,
    String? phoneNumber,
    double? amount,
  }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DynamicUssdMenuDialog(
        operator: operator,
        initialUssdCode: initialUssdCode,
        phoneNumber: phoneNumber,
        amount: amount,
      ),
    );
  }

  @override
  State<DynamicUssdMenuDialog> createState() => _DynamicUssdMenuDialogState();
}

class _DynamicUssdMenuDialogState extends State<DynamicUssdMenuDialog> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  UssdSessionData? _session;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startSession();
  }

  Future<void> _startSession() async {
    setState(() => _isProcessing = true);
    final modem = Provider.of<ModemProvider>(context, listen: false);
    final s = await modem.startUssdSession(
      operator: widget.operator,
      ussdCode: widget.initialUssdCode,
    );
    if (mounted) {
      setState(() {
        _session = s;
        _isProcessing = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendReply(String input) async {
    if (input.trim().isEmpty || _isProcessing) return;
    _replyController.clear();
    setState(() => _isProcessing = true);

    final modem = Provider.of<ModemProvider>(context, listen: false);
    final s = await modem.sendUssdReply(input.trim());
    if (mounted) {
      setState(() {
        _session = s;
        _isProcessing = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opColor = OperatorConstants.getOperatorColor(widget.operator);
    final opName = OperatorConstants.getOperatorName(widget.operator, lang: 'ar');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 580,
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
                        'جلسة تفاعلية مباشرة مع الشريحة ($opName)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        _getSessionStatusText(),
                        style: TextStyle(
                          color: _getSessionStatusColor(),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    final modem = Provider.of<ModemProvider>(context, listen: false);
                    modem.cancelUssdSession();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            const Divider(height: 20, color: AppColors.borderLight),

            // Live Chat / Terminal Log
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A), // Dark Terminal View
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _session?.history.length ?? 0,
                  itemBuilder: (context, index) {
                    final step = _session!.history[index];
                    return _buildStepBubble(step, opColor);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Dynamic Clickable Buttons for Detected Menu Options
            if (_session != null && _session!.isWaitingUser && _session!.currentOptions.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _session!.currentOptions.map((opt) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opColor.withOpacity(0.15),
                      foregroundColor: opColor,
                      elevation: 0,
                      side: BorderSide(color: opColor, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onPressed: _isProcessing ? null : () => _sendReply(opt.key),
                    child: Text(
                      opt.displayButtonText,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
            ],

            // Input Bar (if waiting for user choice/input)
            if (_session != null && _session!.isWaitingUser) ...[
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
                    icon: _isProcessing
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 16),
                    label: const Text('إرسال للشريحة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: opColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: _isProcessing ? null : () => _sendReply(_replyController.text),
                  ),
                ],
              ),
            ] else if (_session != null && _session!.isCompleted) ...[
              // Action buttons on successful completion
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.print, size: 18),
                    label: const Text('طباعة الوصل الحراري'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      final modem = Provider.of<ModemProvider>(context, listen: false);
                      final receipt = modem.printerService.createReceiptFromTransaction(
                        PosTransaction(
                          transactionId: _session!.transactionRef ?? _session!.sessionId,
                          operator: widget.operator,
                          phoneNumber: widget.phoneNumber ?? '0600000000',
                          amount: widget.amount ?? 0,
                          status: PosTransactionStatus.success,
                          networkReference: _session!.transactionRef,
                          startTime: _session!.startTime,
                        ),
                      );
                      showDialog(
                        context: context,
                        builder: (_) => ReceiptPreviewModal(receipt: receipt),
                      );
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
            ] else if (_isProcessing) ...[
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      SizedBox(width: 10),
                      Text('جاري الاتصال بالشبكة واستلام رد الشريحة...', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepBubble(SessionEngineStep step, Color opColor) {
    final isNet = step.isFromNetwork;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      alignment: isNet ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isNet ? const Color(0xFF1E293B) : opColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isNet ? const Color(0xFF334155) : opColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: isNet ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isNet ? Icons.sim_card_outlined : Icons.person_outline,
                  size: 14,
                  color: isNet ? const Color(0xFF38BDF8) : opColor,
                ),
                const SizedBox(width: 4),
                Text(
                  isNet ? 'رد الشبكة (SIM Response)' : 'الطلب المرسل (Sent)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isNet ? const Color(0xFF38BDF8) : opColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              step.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSessionStatusText() {
    if (_session == null) return 'جاري البدء...';
    switch (_session!.state) {
      case UssdEngineState.starting:
      case UssdEngineState.waitingResponse:
      case UssdEngineState.processing:
        return 'جاري التنفيذ... (Processing)';
      case UssdEngineState.menuPresented:
      case UssdEngineState.userInputRequired:
        return 'بانتظار اختيار البائع (Waiting Choice)';
      case UssdEngineState.completed:
        return 'تمت العملية بنجاح (Completed)';
      case UssdEngineState.error:
        return 'فشلت العملية (Failed)';
      case UssdEngineState.timeout:
        return 'انتهت المهلة (Timeout)';
      case UssdEngineState.cancelled:
        return 'تم إلغاء الجلسة (Cancelled)';
      case UssdEngineState.idle:
        return 'جاهز';
    }
  }

  Color _getSessionStatusColor() {
    if (_session == null) return AppColors.primary;
    switch (_session!.state) {
      case UssdEngineState.completed:
        return AppColors.success;
      case UssdEngineState.menuPresented:
      case UssdEngineState.userInputRequired:
        return AppColors.warning;
      case UssdEngineState.error:
      case UssdEngineState.timeout:
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }
}
