import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../debug/debug_log_entry.dart';
import '../providers/modem_provider.dart';

class DebugConsoleScreen extends StatefulWidget {
  const DebugConsoleScreen({super.key});

  @override
  State<DebugConsoleScreen> createState() => _DebugConsoleScreenState();
}

class _DebugConsoleScreenState extends State<DebugConsoleScreen> {
  final TextEditingController _cmdController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void dispose() {
    _cmdController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendCommand() async {
    final cmd = _cmdController.text.trim();
    if (cmd.isEmpty || _isSending) return;

    _cmdController.clear();
    setState(() => _isSending = true);

    final modem = Provider.of<ModemProvider>(context, listen: false);
    final port = modem.modemService.activePort ?? 'COM';

    modem.debugLogger.logTx(port, cmd);
    final resp = await modem.modemService.sendRaw(cmd, timeout: const Duration(seconds: 8));
    modem.debugLogger.logRx(port, resp.rawOutput);

    setState(() => _isSending = false);
    _scrollToBottom();
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
  Widget build(BuildContext context) {
    final modem = Provider.of<ModemProvider>(context);
    final logs = modem.debugLogger.logs;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1120), // Dark Engineering Theme
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                      child: const Icon(Icons.terminal, color: Color(0xFF38BDF8), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'سجل المطور وأوامر AT المباشرة (Developer & AT Console)',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'المنفذ النشط: ${modem.modemService.activePort ?? "غير متصل"} • سرعة الباود: ${modem.modemService.activeBaudRate} bps',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFF87171), size: 18),
                      label: const Text('مسح السجل', style: TextStyle(color: Color(0xFFF87171))),
                      onPressed: () {
                        setState(() => modem.debugLogger.clearLogs());
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Quick Diagnostic Command Chips
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildQuickCmdChip('AT (Ping)', 'AT'),
                _buildQuickCmdChip('AT+CPIN? (SIM Status)', 'AT+CPIN?'),
                _buildQuickCmdChip('AT+CSQ (Signal)', 'AT+CSQ'),
                _buildQuickCmdChip('AT+CREG? (Registration)', 'AT+CREG?'),
                _buildQuickCmdChip('AT+COPS? (Operator)', 'AT+COPS?'),
                _buildQuickCmdChip('AT+CIMI (IMSI)', 'AT+CIMI'),
                _buildQuickCmdChip('AT+CCID (ICCID)', 'AT+CCID'),
                _buildQuickCmdChip('ATI (Modem Info)', 'ATI'),
              ],
            ),
            const SizedBox(height: 12),

            // Live Terminal Feed
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: logs.isEmpty
                    ? const Center(
                        child: Text(
                          'بانتظار إرسال أو استقبال الأوامر...',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontFamily: 'monospace'),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final entry = logs[index];
                          return _buildLogItem(entry);
                        },
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Manual Command Input Line
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: TextField(
                      controller: _cmdController,
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: 'أدخل أمر AT (مثل: AT, AT+CSQ, AT+CUSD=1,"*600#",15)...',
                        hintStyle: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _sendCommand(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: _isSending
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send, size: 16),
                  label: const Text('إرسال للأمر'),
                  onPressed: _isSending ? null : _sendCommand,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCmdChip(String label, String command) {
    return ActionChip(
      label: Text(label, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontFamily: 'monospace')),
      backgroundColor: const Color(0xFF1E293B),
      side: const BorderSide(color: Color(0xFF334155), width: 0.8),
      onPressed: () {
        _cmdController.text = command;
        _sendCommand();
      },
    );
  }

  Widget _buildLogItem(DebugLogEntry entry) {
    Color dirColor = const Color(0xFF38BDF8); // Cyan for TX
    if (entry.direction == DebugDirection.rx) dirColor = const Color(0xFF4ADE80); // Green for RX
    if (entry.direction == DebugDirection.system) dirColor = const Color(0xFFFACC15); // Yellow for System

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: SelectableText.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '[${entry.formattedTime}] ',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 11, fontFamily: 'monospace'),
            ),
            TextSpan(
              text: '[${entry.port}] ',
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: '${entry.directionSymbol} ',
              style: TextStyle(color: dirColor, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: entry.content,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
      ),
    );
  }
}
