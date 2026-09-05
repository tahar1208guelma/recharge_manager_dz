import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../services/smart_card/platforms/windows_pcsc_native.dart';
import '../../services/ussd/gsm_modem_service.dart';
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

class _ReaderDeviceInfoModalState extends State<ReaderDeviceInfoModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isScanning = false;
  String? _selectedReader;

  // Terminal & Diagnostics State
  List<HardwarePortInfo> _comPorts = [];
  String? _selectedComPort;
  int _selectedBaudRate = 115200;
  final TextEditingController _customAtController = TextEditingController();
  final ScrollController _terminalScrollController = ScrollController();
  final List<String> _terminalLogs = [];
  bool _isExecutingAt = false;

  // Multi-SIM Port Mapping
  String? _mobilisPort;
  String? _ooredooPort;
  String? _djezzyPort;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedReader = widget.usb.readerName;
    _selectedComPort = widget.usb.activeComPort;
    _selectedBaudRate = widget.usb.activeBaudRate;
    _mobilisPort = widget.usb.getPortForOperator(OperatorType.mobilis);
    _ooredooPort = widget.usb.getPortForOperator(OperatorType.ooredoo);
    _djezzyPort = widget.usb.getPortForOperator(OperatorType.djezzy);

    _log('⚡ نظام فحص وتشخيص العتاد جاهز (Hardware Diagnostics Ready).');
    _refresh();
  }

  void _log(String message) {
    if (mounted) {
      final time = DateTime.now().toIso8601String().substring(11, 19);
      setState(() {
        _terminalLogs.add('[$time] $message');
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_terminalScrollController.hasClients) {
          _terminalScrollController.animateTo(
            _terminalScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isScanning = true);
    await widget.usb.refreshReaders();

    // Scan COM ports
    final ports = await widget.usb.modemService.listDetailedPorts();

    if (mounted) {
      setState(() {
        _comPorts = ports;
        if (_comPorts.isNotEmpty) {
          if (_selectedComPort == null || !_comPorts.any((p) => p.portName == _selectedComPort)) {
            _selectedComPort = _comPorts.first.portName;
          }
        }
        if (widget.usb.availableReaders.isNotEmpty) {
          _selectedReader = widget.usb.availableReaders.first.readerName;
        }
        _isScanning = false;
      });
      _log('🔍 تم اكتشاف ${_comPorts.length} منفذ تسلسلي و ${widget.usb.availableReaders.length} قارئ بطاقات.');
    }
  }

  Future<void> _runAtTest(String name, Future<String> Function() action) async {
    if (_isExecutingAt) return;
    setState(() => _isExecutingAt = true);
    _log('➡️ جاري تنفيذ: $name على المنفذ ($_selectedComPort)...');

    try {
      final result = await action();
      _log('⬅️ الرد: $result');
    } catch (e) {
      _log('❌ خطأ في التنفيذ: $e');
    } finally {
      if (mounted) {
        setState(() => _isExecutingAt = false);
      }
    }
  }

  Future<void> _sendCustomAt(String cmd) async {
    if (cmd.trim().isEmpty) return;
    final clean = cmd.trim();
    _customAtController.clear();
    await _runAtTest('أمر مخصص ($clean)', () async {
      final res = await widget.usb.modemService.executeRawCommand(
        clean,
        portName: _selectedComPort,
        baudRate: _selectedBaudRate,
        timeoutMs: 6000,
      );
      return GsmModemService.decodeUcs2Hex(res);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customAtController.dispose();
    _terminalScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    String statusTitle;

    switch (widget.usb.status) {
      case SmartCardConnectionStatus.readerConnected:
        statusColor = AppColors.success;
        statusBg = AppColors.successBg;
        statusTitle = '🟢 القارئ متصل (Reader Connected)';
        break;
      case SmartCardConnectionStatus.cardWaiting:
        statusColor = AppColors.warning;
        statusBg = AppColors.warningBg;
        statusTitle = '🟡 بانتظار الشريحة (Card Waiting)';
        break;
      case SmartCardConnectionStatus.cardDetected:
        statusColor = AppColors.primary;
        statusBg = AppColors.infoBg;
        statusTitle = '🔵 الشريحة جاهزة (SIM Ready)';
        break;
      case SmartCardConnectionStatus.readerError:
        statusColor = AppColors.danger;
        statusBg = AppColors.dangerBg;
        statusTitle = '🔴 خطأ في القارئ (Reader Error)';
        break;
      case SmartCardConnectionStatus.disconnected:
        statusColor = AppColors.textMuted;
        statusBg = AppColors.lightCard;
        statusTitle = '⚪ القارئ غير متصل (Disconnected)';
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        height: 640,
        padding: const EdgeInsets.all(20),
        child: Column(
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
                      child: Icon(Icons.developer_board, color: statusColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'تشخيص واختبار العتاد والمنافذ (Hardware & COM Diagnostics)',
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
            const SizedBox(height: 12),

            // Tabs Header
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(
                  icon: Icon(Icons.credit_card, size: 18),
                  text: 'معلومات الشريحة والقارئ (SIM Info)',
                ),
                Tab(
                  icon: Icon(Icons.terminal, size: 18),
                  text: 'محطة فحص المنفذ المباشر (AT Terminal)',
                ),
              ],
            ),
            const Divider(height: 16, color: AppColors.borderLight),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSimInfoTab(),
                  _buildAtTerminalTab(),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.borderLight),
            const SizedBox(height: 12),

            // Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.save, size: 16),
                  label: const Text('حفظ الإعدادات وتفعيل المنفذ'),
                  onPressed: () {
                    if (_selectedComPort != null) {
                      widget.usb.setActiveComPort(_selectedComPort, baudRate: _selectedBaudRate);
                    }
                    if (_mobilisPort != null) widget.usb.setOperatorComPort(OperatorType.mobilis, _mobilisPort!);
                    if (_ooredooPort != null) widget.usb.setOperatorComPort(OperatorType.ooredoo, _ooredooPort!);
                    if (_djezzyPort != null) widget.usb.setOperatorComPort(OperatorType.djezzy, _djezzyPort!);

                    widget.usb.connectReader(_selectedReader);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('✅ تم حفظ إعدادات المنافذ وتفعيل القارئ بنجاح.')),
                    );
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق (Close)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // TAB 1: SIM & READER INFORMATION
  Widget _buildSimInfoTab() {
    final dev = widget.usb.deviceInfo;
    final card = widget.usb.cardInfo;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hardware Selector Box
          Container(
            padding: const EdgeInsets.all(12),
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
                      'اختر قارئ البطاقة الذكية (Smart Card Reader):',
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
                            Text('إعادة الفحص', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

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
                  const Text('لا توجد قارئات مكتشفة حالياً.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Device Details
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
          const SizedBox(height: 12),

          // SIM Information
          if (card != null) ...[
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
            const SizedBox(height: 12),
          ],

          // Windows SCardSvr service helper
          if (Platform.isWindows) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.infoBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build_circle_outlined, color: AppColors.info, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'إذا لم يستجب قارئ البطاقات الذكية، اضغط لتشغيل خدمة Windows Smart Card.',
                      style: TextStyle(fontSize: 11, color: AppColors.info),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await WinSCardNative.ensureSmartCardServiceRunning();
                      await _refresh();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✅ تم تشغيل خدمة Windows Smart Card بنجاح.')),
                        );
                      }
                    },
                    child: const Text('تشغيل الخدمة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 2: HARDWARE AT TERMINAL & DIAGNOSTICS
  Widget _buildAtTerminalTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Port and Baud Selector Bar
        Row(
          children: [
            // COM Port
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _comPorts.any((p) => p.portName == _selectedComPort) ? _selectedComPort : (_comPorts.isNotEmpty ? _comPorts.first.portName : null),
                    hint: const Text('اختر منفذ المودم (COM Port)', style: TextStyle(fontSize: 11)),
                    items: _comPorts.map((p) {
                      return DropdownMenuItem<String>(
                        value: p.portName,
                        child: Text(
                          p.friendlyName,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedComPort = val),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Baud Rate
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedBaudRate,
                    items: const [
                      DropdownMenuItem(value: 115200, child: Text('115200 (Default)', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 9600, child: Text('9600 bps', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 57600, child: Text('57600 bps', style: TextStyle(fontSize: 11))),
                      DropdownMenuItem(value: 19200, child: Text('19200 bps', style: TextStyle(fontSize: 11))),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedBaudRate = val);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Quick Diagnostic Action Buttons
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _buildQuickAtChip('⚡ فحص المودم (AT)', () async {
              final ok = await widget.usb.modemService.testAtPing(portName: _selectedComPort, baudRate: _selectedBaudRate);
              return ok ? '✅ استجابة المودم سليمة (OK)' : '❌ لم يستجب المودم';
            }),
            _buildQuickAtChip('💳 حالة الشريحة (AT+CPIN?)', () async {
              return await widget.usb.modemService.checkSimStatus(portName: _selectedComPort, baudRate: _selectedBaudRate);
            }),
            _buildQuickAtChip('📶 قوة الإشارة (AT+CSQ)', () async {
              return await widget.usb.modemService.getSignalStrength(portName: _selectedComPort, baudRate: _selectedBaudRate);
            }),
            _buildQuickAtChip('🌐 اسم المشغل (AT+COPS?)', () async {
              return await widget.usb.modemService.getNetworkOperator(portName: _selectedComPort, baudRate: _selectedBaudRate);
            }),
            _buildQuickAtChip('🧪 كود USSD تجريبي (*100#)', () async {
              final res = await widget.usb.modemService.sendUssd('*100#', portName: _selectedComPort, baudRate: _selectedBaudRate);
              return res.cleanMessage;
            }),
          ],
        ),
        const SizedBox(height: 8),

        // Terminal Log Area
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A), // Dark console background
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF1E293B)),
            ),
            child: ListView.builder(
              controller: _terminalScrollController,
              itemCount: _terminalLogs.length,
              itemBuilder: (context, index) {
                final line = _terminalLogs[index];
                Color textColor = Colors.white70;
                if (line.contains('➡️')) textColor = const Color(0xFF38BDF8); // Cyan
                if (line.contains('⬅️')) textColor = const Color(0xFF4ADE80); // Green
                if (line.contains('❌') || line.contains('ERR:')) textColor = const Color(0xFFF87171); // Red
                if (line.contains('⚡') || line.contains('🔍')) textColor = const Color(0xFFFACC15); // Yellow

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: SelectableText(
                    line,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Custom AT Command Input Line
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _customAtController,
                decoration: InputDecoration(
                  hintText: 'أدخل أمر AT مخصص (مثل: AT, AT+CUSD=1,"*600#",15, ATI)...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onSubmitted: _sendCustomAt,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: _isExecutingAt
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, size: 14),
              label: const Text('إرسال'),
              onPressed: _isExecutingAt ? null : () => _sendCustomAt(_customAtController.text),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: 'مسح سجل الأوامر',
              icon: const Icon(Icons.delete_outline, size: 18),
              onPressed: () => setState(() => _terminalLogs.clear()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAtChip(String label, Future<String> Function() action) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      backgroundColor: AppColors.primary.withOpacity(0.08),
      side: const BorderSide(color: AppColors.primary, width: 0.8),
      onPressed: _isExecutingAt ? null : () => _runAtTest(label, action),
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

