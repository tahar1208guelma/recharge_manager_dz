import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../../diagnostic/hardware_diagnostic_service.dart';
import '../../diagnostic/models/diagnostic_report.dart';

class HardwareDiagnosticScreen extends StatefulWidget {
  const HardwareDiagnosticScreen({super.key});

  @override
  State<HardwareDiagnosticScreen> createState() => _HardwareDiagnosticScreenState();
}

class _HardwareDiagnosticScreenState extends State<HardwareDiagnosticScreen> {
  final HardwareDiagnosticService _diagnosticService = HardwareDiagnosticService();
  DiagnosticReport? _report;
  bool _isRunning = false;
  String _progressMessage = '';
  double _progressPercent = 0.0;

  @override
  void initState() {
    super.initState();
    _runDiagnostic();
  }

  Future<void> _runDiagnostic() async {
    setState(() {
      _isRunning = true;
      _progressMessage = 'جاري تحضير فحص العتاد...';
      _progressPercent = 0.05;
    });

    try {
      final rep = await _diagnosticService.runDiagnostic(
        onProgress: (msg, pct) {
          if (mounted) {
            setState(() {
              _progressMessage = msg;
              _progressPercent = pct;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _report = rep;
          _isRunning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRunning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء الفحص: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  Future<void> _exportReport() async {
    if (_report == null) return;

    try {
      final paths = await _diagnosticService.exportReportFiles(_report!);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success),
                SizedBox(width: 8),
                Text('تم تصدير التقرير بنجاح', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تم حفظ ملفي التقرير (JSON و TXT) في المجلد التالي:', style: TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📄 TXT : ${paths['txt']}', style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace')),
                      const SizedBox(height: 6),
                      Text('📦 JSON: ${paths['json']}', style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 11, fontFamily: 'monospace')),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('يمكنك إرسال هذين الملفين لتحليل توافق العتاد بدقة.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('نسخ مسار الملف'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: paths['txt'] ?? ''));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم نسخ المسار إلى الحافظة')),
                  );
                },
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                child: const Text('حسناً'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل تصدير التقرير: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  void _copyTextReport() {
    if (_report == null) return;
    Clipboard.setData(ClipboardData(text: _report!.toFormattedTextReport()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ التقرير النصي بالكامل إلى الحافظة')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أداة تشخيص وتأكيد العتاد (Hardware Diagnostic Tool)',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'فحص شامل للـ USB ومنافذ COM وقارئات PC/SC واستجابة أوامر AT الآمنة (وضع القراءة فقط)',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('نسخ التقرير'),
                      onPressed: _report != null && !_isRunning ? _copyTextReport : null,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_download, size: 18),
                      label: const Text('Export Diagnostic Report', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _report != null && !_isRunning ? _exportReport : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: _isRunning
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(_isRunning ? 'جاري الفحص...' : 'إعادة الفحص'),
                      onPressed: _isRunning ? null : _runDiagnostic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Progress Bar if running
            if (_isRunning) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_progressMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('${(_progressPercent * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(value: _progressPercent, minHeight: 6, borderRadius: BorderRadius.circular(3)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            if (_report != null) ...[
              // 1. Executive Verdict Card
              _buildVerdictCard(_report!.verdict),
              const SizedBox(height: 20),

              // 2. Cellular & SIM Metrics
              if (_report!.cellular != null) ...[
                _buildCellularCard(_report!.cellular!),
                const SizedBox(height: 20),
              ],

              // 3. USB Devices Table
              _buildUsbDevicesCard(_report!.usbDevices),
              const SizedBox(height: 20),

              // 4. AT Probes & COM Ports
              _buildComPortsCard(_report!.comPorts),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerdictCard(DiagnosticVerdict v) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.assessment_outlined, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'التقييم الفني النهائي (EXECUTIVE VERDICT)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            children: [
              _buildVerdictPill('DEVICE TYPE', v.deviceType, _getDeviceTypeColor(v.deviceType)),
              _buildVerdictPill('PC/SC', v.pcsc, v.pcsc == 'SUPPORTED' ? AppColors.success : Colors.grey),
              _buildVerdictPill('AT MODEM', v.atModem, v.atModem == 'SUPPORTED' ? AppColors.success : AppColors.danger),
              _buildVerdictPill('USSD', v.ussd, v.ussd == 'SUPPORTED' ? AppColors.success : Colors.grey),
              _buildVerdictPill('SMS', v.sms, v.sms == 'SUPPORTED' ? AppColors.success : Colors.grey),
              _buildVerdictPill('NETWORK', v.network, v.network == 'REGISTERED' ? AppColors.success : AppColors.warning),
              _buildVerdictPill('SIM', v.sim, _getSimStatusColor(v.sim)),
            ],
          ),
          if (v.notes.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: v.notes
                    .map((n) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(n, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVerdictPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildCellularCard(CellularDiagnostic cell) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.signal_cellular_alt, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('بيانات الاتصال والشبكة الخلوية (Cellular & SIM)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(child: _buildMetricItem('حالة الشريحة (SIM)', cell.simStatus, Icons.sim_card)),
              Expanded(child: _buildMetricItem('المتعامل (Operator)', cell.operatorName ?? 'N/A', Icons.cell_tower)),
              Expanded(child: _buildMetricItem('تسجيل الشبكة (Registration)', cell.networkRegistration, Icons.verified)),
              Expanded(child: _buildMetricItem('قوة الإشارة (Signal)', '${cell.signalRssi}/31 (${cell.signalPercent}%)', Icons.signal_cellular_4_bar)),
              Expanded(child: _buildMetricItem('الجيل والتقنية', cell.accessTechnology ?? 'N/A', Icons.speed)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String title, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildUsbDevicesCard(List<UsbDeviceInfo> devices) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.usb, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('أجهزة USB المتصلة (Enumerated USB Devices)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: AppColors.bgSurface, borderRadius: BorderRadius.circular(6)),
                child: Text('${devices.length} أجهزة', style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
          const Divider(height: 24),
          if (devices.isEmpty)
            const Text('لم يتم العثور على أجهزة USB.', style: TextStyle(fontSize: 13, color: Colors.grey))
          else
            Table(
              columnWidths: const {
                0: FlexColumnWidth(2.5),
                1: FlexColumnWidth(1.2),
                2: FlexColumnWidth(1.2),
                3: FlexColumnWidth(2.0),
                4: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(
                  decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                  children: [
                    _buildTableHeader('اسم الجهاز (Device Name)'),
                    _buildTableHeader('VID'),
                    _buildTableHeader('PID'),
                    _buildTableHeader('المصنع (Manufacturer)'),
                    _buildTableHeader('فئة الجهاز (Class)'),
                  ],
                ),
                for (final d in devices)
                  TableRow(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(d.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(d.vid ?? 'N/A', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.primary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(d.pid ?? 'N/A', style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppColors.primary)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(d.manufacturer ?? 'N/A', style: const TextStyle(fontSize: 12)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(d.deviceClass ?? 'N/A', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ),
                    ],
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildComPortsCard(List<ComPortDiagnostic> ports) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.terminal, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('نتائج فحص منافذ COM وأوامر AT (Read-Only Probes)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          const Divider(height: 24),
          if (ports.isEmpty)
            const Text('لا توجد منافذ تسلسلية COM متصلة.', style: TextStyle(fontSize: 13, color: Colors.grey))
          else
            Column(
              children: ports.map((port) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.cable, color: Color(0xFF06B6D4), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                '${port.portName} - ${port.friendlyName}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: port.isAtResponsive ? AppColors.success : AppColors.danger,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              port.isAtResponsive ? 'AT RESPONSIVE (${port.probedBaudRate ?? 115200} bps)' : 'NO RESPONSE',
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (port.commandResults.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Divider(color: Color(0xFF334155), height: 1),
                        const SizedBox(height: 10),
                        for (final cmd in port.commandResults)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: Text('TX: ${cmd.command}', style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: cmd.isSuccess ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(cmd.isSuccess ? 'OK' : 'ERR', style: TextStyle(color: cmd.isSuccess ? Colors.greenAccent : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cmd.rawOutput.replaceAll('\r\n', ' | ').replaceAll('\n', ' | ').trim(),
                                    style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, fontFamily: 'monospace'),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text('${cmd.durationMs}ms', style: const TextStyle(color: Colors.grey, fontSize: 10)),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
    );
  }

  Color _getDeviceTypeColor(String dev) {
    if (dev == 'GSM MODEM') return AppColors.success;
    if (dev == 'PC/SC READER') return const Color(0xFF0891B2);
    return Colors.grey;
  }

  Color _getSimStatusColor(String sim) {
    if (sim == 'READY') return AppColors.success;
    if (sim == 'PIN REQUIRED') return AppColors.warning;
    return AppColors.danger;
  }
}
