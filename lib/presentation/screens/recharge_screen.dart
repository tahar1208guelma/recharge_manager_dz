import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/currency_formatter.dart';
import '../../services/printing/receipt_template.dart';
import '../providers/recharge_provider.dart';
import '../providers/usb_provider.dart';
import '../widgets/operator_card.dart';
import '../widgets/quick_amount_selector.dart';
import '../widgets/receipt_preview_modal.dart';
import '../widgets/smart_phone_search_field.dart';

class RechargeScreen extends StatefulWidget {
  const RechargeScreen({super.key});

  @override
  State<RechargeScreen> createState() => _RechargeScreenState();
}

class _RechargeScreenState extends State<RechargeScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

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
    _nameController.dispose();
    _notesController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recharge = Provider.of<RechargeProvider>(context);
    final usb = Provider.of<UsbProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
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
                      Text(
                        context.tr('select_operator'),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),

                  // Smart Card SIM Read Button
                  OutlinedButton.icon(
                    icon: const Icon(Icons.sim_card, size: 18),
                    label: Text(context.tr('btn_read_card')),
                    onPressed: () async {
                      final cardInfo = await usb.readCard();
                      if (cardInfo != null && mounted) {
                        if (cardInfo.operator != OperatorType.unknown) {
                          recharge.setOperator(cardInfo.operator);
                        }
                        if (cardInfo.msisdn != null && cardInfo.msisdn!.isNotEmpty) {
                          _phoneController.text = cardInfo.msisdn!;
                          recharge.setPhoneNumber(cardInfo.msisdn!);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text(
                              '${context.tr('card_detected')}: ${OperatorConstants.getOperatorName(cardInfo.operator, lang: context.isRtl ? 'ar' : 'en')}',
                            ),
                          ),
                        );
                      }
                    },
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
                    onTap: () => recharge.setOperator(OperatorType.mobilis),
                  ),
                  const SizedBox(width: 12),
                  OperatorCard(
                    operatorType: OperatorType.djezzy,
                    isSelected: recharge.selectedOperator == OperatorType.djezzy,
                    onTap: () => recharge.setOperator(OperatorType.djezzy),
                  ),
                  const SizedBox(width: 12),
                  OperatorCard(
                    operatorType: OperatorType.ooredoo,
                    isSelected: recharge.selectedOperator == OperatorType.ooredoo,
                    onTap: () => recharge.setOperator(OperatorType.ooredoo),
                  ),
                ],
              ),
              const SizedBox(height: 24),

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

                    // Optional Customer Details (Name & Notes)
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
                    const SizedBox(height: 24),

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

                    // Success Banner if present
                    if (recharge.successMessage != null && recharge.lastTransaction != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.success),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    recharge.successMessage!,
                                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  if (recharge.lastTransaction!.rechargeCode != null)
                                    Text(
                                      '${context.tr('recharge_code')}: ${recharge.lastTransaction!.rechargeCode!}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.print, size: 16),
                              label: Text(context.tr('btn_print')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              ),
                              onPressed: () {
                                final receipt = ReceiptData.fromTransaction(recharge.lastTransaction!);
                                showDialog(
                                  context: context,
                                  builder: (_) => ReceiptPreviewModal(receipt: receipt),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                    // Execute Recharge Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: OperatorConstants.getOperatorColor(recharge.selectedOperator),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: recharge.isProcessing
                            ? null
                            : () async {
                                final ok = await recharge.executeRecharge();
                                if (ok && recharge.lastTransaction != null && mounted) {
                                  final receipt = ReceiptData.fromTransaction(recharge.lastTransaction!);
                                  showDialog(
                                    context: context,
                                    builder: (_) => ReceiptPreviewModal(receipt: receipt),
                                  );
                                }
                              },
                        child: recharge.isProcessing
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.flash_on, size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${context.tr('btn_recharge_now')} (${CurrencyFormatter.formatCompact(recharge.amount)})',
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
