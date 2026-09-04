import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/operators/ussd_generator.dart';
import '../providers/recharge_provider.dart';
import '../providers/usb_provider.dart';
import '../widgets/operator_card.dart';
import '../widgets/quick_amount_selector.dart';
import '../widgets/sim_pin_modal.dart';
import '../widgets/smart_phone_search_field.dart';
import '../widgets/interactive_ussd_dialog.dart';

enum RechargeMode { flexyService, directCard }

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cardCodeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  RechargeMode _mode = RechargeMode.flexyService;
  String _selectedServiceKey = 'transfert_flexy';
  String _selectedSubOption = '1';

  @override
  void initState() {
    super.initState();
    final recharge = Provider.of<RechargeProvider>(context, listen: false);
    _phoneController.text = recharge.phoneNumber;
    _amountController.text = recharge.amount.toStringAsFixed(0);
    _nameController.text = recharge.customerName ?? '';
    _notesController.text = recharge.notes ?? '';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _cardCodeController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _onOperatorChanged(OperatorType op, RechargeProvider recharge) {
    recharge.setOperator(op);
    setState(() {
      if (op == OperatorType.mobilis) {
        _selectedServiceKey = 'transfert_flexy';
        _selectedSubOption = '1';
      } else if (op == OperatorType.ooredoo) {
        _selectedServiceKey = 'transfert_flexy';
        _selectedSubOption = '1';
      } else if (op == OperatorType.djezzy) {
        _selectedServiceKey = 'transfert_flexy';
        _selectedSubOption = '1';
      }
    });
  }

  String _calculateLiveUssd(RechargeProvider recharge, UsbProvider usb) {
    if (_mode == RechargeMode.directCard) {
      return usb.buildUssdCommand(
        recharge.selectedOperator,
        'recharge_direct',
        cardCode: _cardCodeController.text.trim(),
      );
    }

    return usb.buildUssdCommand(
      recharge.selectedOperator,
      _selectedServiceKey,
      receiver: _phoneController.text.trim(),
      amount: recharge.amount,
      subOption: _selectedSubOption,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recharge = Provider.of<RechargeProvider>(context);
    final usb = Provider.of<UsbProvider>(context);
    final services = UssdGenerator.operatorServices[recharge.selectedOperator] ?? {};
    final currentServiceDef = services[_selectedServiceKey];
    final liveUssdCode = _calculateLiveUssd(recharge, usb);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 850),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('nav_recharge'),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'إدارة وتعبئة الأرصدة عبر شرائح نقاط البيع (USSD POS & Smart Card)',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),

                  // PIN Quick Action Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.key, size: 16),
                    label: Text('PIN الشريحة: ${usb.simPin}'),
                    onPressed: () => SimPinModal.show(context, usb),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Operator Selection Cards (Mobilis, Djezzy, Ooredoo)
              Row(
                children: [
                  OperatorCard(
                    operatorType: OperatorType.mobilis,
                    isSelected: recharge.selectedOperator == OperatorType.mobilis,
                    onTap: () => _onOperatorChanged(OperatorType.mobilis, recharge),
                  ),
                  const SizedBox(width: 12),
                  OperatorCard(
                    operatorType: OperatorType.djezzy,
                    isSelected: recharge.selectedOperator == OperatorType.djezzy,
                    onTap: () => _onOperatorChanged(OperatorType.djezzy, recharge),
                  ),
                  const SizedBox(width: 12),
                  OperatorCard(
                    operatorType: OperatorType.ooredoo,
                    isSelected: recharge.selectedOperator == OperatorType.ooredoo,
                    onTap: () => _onOperatorChanged(OperatorType.ooredoo, recharge),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Mode Tabs: Flexy vs Direct Card Recharge
              Container(
                decoration: BoxDecoration(
                  color: AppColors.lightCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _mode = RechargeMode.flexyService),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _mode == RechargeMode.flexyService ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _mode == RechargeMode.flexyService
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android,
                                size: 18,
                                color: _mode == RechargeMode.flexyService ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تعبئة سريعة / فليكسي (Flexy & Arseli)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _mode == RechargeMode.flexyService ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _mode = RechargeMode.directCard),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _mode == RechargeMode.directCard ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: _mode == RechargeMode.directCard
                                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card,
                                size: 18,
                                color: _mode == RechargeMode.directCard ? AppColors.primary : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'تعبئة مباشرة (بطاقة شحن كرت)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _mode == RechargeMode.directCard ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Main POS Form Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_mode == RechargeMode.flexyService) ...[
                      // Service Selector Dropdown / Chips
                      const Text(
                        'نوع الخدمة المطلوبة:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: services.entries.where((e) => e.key != 'recharge_direct').map((entry) {
                          final isSel = _selectedServiceKey == entry.key;
                          return ChoiceChip(
                            label: Text(entry.value.title),
                            selected: isSel,
                            selectedColor: AppColors.primary.withOpacity(0.15),
                            labelStyle: TextStyle(
                              color: isSel ? AppColors.primary : AppColors.textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (val) {
                              if (val) {
                                setState(() {
                                  _selectedServiceKey = entry.key;
                                  _selectedSubOption = '1';
                                });
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),

                      // Sub-menu Selector if applicable (Arseli / Flexy with activation)
                      if (currentServiceDef != null && currentServiceDef.hasSubMenu) ...[
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
                                children: [
                                  const Icon(Icons.list_alt, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    currentServiceDef.subMenuTitle ?? 'خيارات الخدمة الفرعية:',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: currentServiceDef.subOptions!.map((opt) {
                                  final isOptSel = _selectedSubOption == opt.key;
                                  return ChoiceChip(
                                    label: Text(opt.label),
                                    selected: isOptSel,
                                    selectedColor: AppColors.primary,
                                    labelStyle: TextStyle(
                                      color: isOptSel ? Colors.white : AppColors.textPrimary,
                                      fontWeight: isOptSel ? FontWeight.bold : FontWeight.normal,
                                    ),
                                    onSelected: (val) {
                                      if (val) {
                                        setState(() => _selectedSubOption = opt.key);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Phone Number Smart Search Field
                      SmartPhoneSearchField(
                        controller: _phoneController,
                        focusNode: _phoneFocusNode,
                        onChanged: (val) => recharge.setPhoneNumber(val),
                      ),
                      const SizedBox(height: 20),

                      // Quick Amounts Selector
                      Text(
                        context.tr('quick_amounts'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      QuickAmountSelector(
                        selectedAmount: recharge.amount,
                        onAmountSelected: (val) {
                          _amountController.text = val.toStringAsFixed(0);
                          recharge.setAmount(val);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Custom Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: context.tr('amount'),
                          hintText: context.tr('amount_hint'),
                          suffixText: context.tr('currency'),
                          prefixIcon: const Icon(Icons.attach_money, color: AppColors.primary),
                        ),
                        onChanged: (val) {
                          final parsed = double.tryParse(val);
                          if (parsed != null) {
                            recharge.setAmount(parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Customer Name & Notes
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: context.tr('customer_name'),
                                prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                              ),
                              onChanged: (val) => recharge.setCustomerName(val),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _notesController,
                              decoration: InputDecoration(
                                labelText: context.tr('notes'),
                                prefixIcon: const Icon(Icons.note_alt_outlined, color: AppColors.textSecondary),
                              ),
                              onChanged: (val) => recharge.setNotes(val),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Direct Card Recharge Mode (Scratch card)
                      const Text(
                        'إدخال رمز بطاقة الشحن المباشرة:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 8),

                      TextFormField(
                        controller: _cardCodeController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: 'رمز البطاقة (14 أو 16 رقم)',
                          hintText: 'أدخل الأرقام المطبوعة على بطاقة التعبئة',
                          prefixIcon: const Icon(Icons.credit_card, color: AppColors.primary),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _cardCodeController.clear(),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),

                      if (recharge.selectedOperator == OperatorType.ooredoo) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.info.withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.phone_in_talk, color: AppColors.info, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'تعبئة Ooredoo المباشرة بالكرت: اطلب 222 من الشريحة ثم اختر 1 وأدخل رمز البطاقة.',
                                  style: TextStyle(fontSize: 12, color: AppColors.info),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 24),

                    // Live USSD Code Preview Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.code, color: Colors.greenAccent, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'كود USSD المولد للشريحة (Live Command):',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.white, size: 16),
                                tooltip: 'نسخ الكود',
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: liveUssdCode));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('✅ تم نسخ كود USSD: $liveUssdCode'),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SelectableText(
                            liveUssdCode.isNotEmpty ? liveUssdCode : '*...',
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              icon: const Icon(Icons.phonelink_ring, size: 16, color: Colors.greenAccent),
                              label: const Text(
                                'عرض رسائل الشريحة والخيارات تفاعلياً (Interactive Session)',
                                style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () {
                                InteractiveUssdDialog.show(
                                  context,
                                  operator: recharge.selectedOperator,
                                  initialUssdCode: liveUssdCode,
                                  phoneNumber: _phoneController.text.trim(),
                                  amount: recharge.amount,
                                  customerName: _nameController.text.trim(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Error Banner if present
                    if (recharge.errorMessage != null)
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
                            const Icon(Icons.error_outline, color: AppColors.danger, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                recharge.errorMessage!,
                                style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Execute Recharge Button with Interactive Dialog
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OperatorConstants.getOperatorColor(recharge.selectedOperator),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          await InteractiveUssdDialog.show(
                            context,
                            operator: recharge.selectedOperator,
                            initialUssdCode: liveUssdCode,
                            phoneNumber: _phoneController.text.trim(),
                            amount: recharge.amount,
                            customerName: _nameController.text.trim(),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.flash_on, size: 22),
                            const SizedBox(width: 10),
                            Text(
                              _mode == RechargeMode.directCard
                                  ? 'تأكيد التعبئة بالبطاقة ($liveUssdCode)'
                                  : '${context.tr('btn_recharge_now')} (${CurrencyFormatter.formatCompact(recharge.amount)})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
