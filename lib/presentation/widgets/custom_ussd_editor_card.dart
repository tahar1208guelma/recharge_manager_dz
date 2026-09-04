import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../services/operators/ussd_generator.dart';
import '../providers/settings_provider.dart';

class CustomUssdEditorCard extends StatefulWidget {
  final SettingsProvider settings;

  const CustomUssdEditorCard({super.key, required this.settings});

  @override
  State<CustomUssdEditorCard> createState() => _CustomUssdEditorCardState();
}

class _CustomUssdEditorCardState extends State<CustomUssdEditorCard> {
  OperatorType _selectedOp = OperatorType.mobilis;
  final Map<String, TextEditingController> _controllers = {};
  late TextEditingController _pinController;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _pinController = TextEditingController(text: widget.settings.getOperatorPin(_selectedOp));
    _controllers.clear();
    final services = UssdGenerator.defaultOperatorServices[_selectedOp] ?? {};
    for (final entry in services.entries) {
      final effective = UssdGenerator.getEffectiveTemplate(_selectedOp, entry.key);
      _controllers[entry.key] = TextEditingController(text: effective);
    }
  }

  void _switchOperator(OperatorType op) {
    setState(() {
      _selectedOp = op;
      _initControllers();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final services = UssdGenerator.defaultOperatorServices[_selectedOp] ?? {};

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(Icons.tune, color: AppColors.primary, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'تخصيص وتعديل صيغ أكواد الـ USSD (Custom Code Templates)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('استعادة الأكواد الافتراضية'),
                onPressed: () async {
                  await widget.settings.resetOperatorUssdTemplates(_selectedOp);
                  _initControllers();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.info,
                        content: Text('✅ تمت استعادة الأكواد الافتراضية لـ ${OperatorConstants.getOperatorName(_selectedOp, lang: 'ar')}'),
                      ),
                    );
                    setState(() {});
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'يمكنك تعديل أي صيغة كود بحرية عند قيام مشغلي الخدمة بتغيير الأكواد، وسيتم تطبيقها فوراً في البرنامج.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const Divider(height: 24, color: AppColors.borderLight),

          // Operator Switcher Tabs
          Row(
            children: [
              _buildOpTab(OperatorType.mobilis, 'Mobilis (موبيليس)', OperatorConstants.getOperatorColor(OperatorType.mobilis)),
              const SizedBox(width: 8),
              _buildOpTab(OperatorType.djezzy, 'Djezzy (جيزي)', OperatorConstants.getOperatorColor(OperatorType.djezzy)),
              const SizedBox(width: 8),
              _buildOpTab(OperatorType.ooredoo, 'Ooredoo (أوريدو)', OperatorConstants.getOperatorColor(OperatorType.ooredoo)),
            ],
          ),
          const SizedBox(height: 16),

          // Operator Default PIN Row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightCard,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Row(
              children: [
                const Icon(Icons.key, color: AppColors.primary, size: 20),
                const SizedBox(width: 10),
                Text(
                  'الرمز السري الافتراضي (PIN) لـ ${OperatorConstants.getOperatorName(_selectedOp, lang: 'ar')}:',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  height: 38,
                  child: TextField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    onChanged: (val) {
                      if (val.trim().isNotEmpty) {
                        widget.settings.setOperatorPin(_selectedOp, val.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '(الافتراضي الرسمي: ${UssdGenerator.defaultPins[_selectedOp]})',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Available Dynamic Tags Information
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.infoBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withOpacity(0.3)),
            ),
            child: const Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('📌 المتغيرات المتاحة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.info)),
                Chip(label: Text('{receiver} رقم المستلم', style: TextStyle(fontSize: 10))),
                Chip(label: Text('{amount} المبلغ', style: TextStyle(fontSize: 10))),
                Chip(label: Text('{pin} الرمز السري', style: TextStyle(fontSize: 10))),
                Chip(label: Text('{sub_option} الخيار الفرعي', style: TextStyle(fontSize: 10))),
                Chip(label: Text('{card_code} كرت الشحن', style: TextStyle(fontSize: 10))),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Services Table / List
          ...services.entries.map((entry) {
            final def = entry.value;
            final controller = _controllers[entry.key] ?? TextEditingController(text: def.defaultTemplate);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          def.title,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'الافتراضي: ${def.defaultTemplate}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: TextFormField(
                      controller: controller,
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        widget.settings.saveCustomUssdTemplate(_selectedOp, entry.key, val);
                      },
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildOpTab(OperatorType op, String label, Color color) {
    final isSelected = _selectedOp == op;
    return Expanded(
      child: InkWell(
        onTap: () => _switchOperator(op),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : AppColors.lightCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : AppColors.borderLight, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isSelected ? color : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
