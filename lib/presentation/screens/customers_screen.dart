import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../domain/entities/customer.dart';
import '../providers/app_state_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/recharge_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Provider.of<CustomerProvider>(context, listen: false).loadAllCustomers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final rechargeProvider = Provider.of<RechargeProvider>(context, listen: false);
    final appState = Provider.of<AppStateProvider>(context, listen: false);

    final customers = _searchController.text.trim().isNotEmpty
        ? customerProvider.searchResults
        : customerProvider.allCustomers;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Add Customer Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('nav_customers'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${customers.length} ${context.tr('nav_customers')}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add, size: 18),
                label: Text(context.tr('add_customer')),
                onPressed: () => _showAddEditCustomerDialog(context, null),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: '${context.tr('search')} (05, 06, 07, ...)',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        customerProvider.clearSearch();
                        customerProvider.loadAllCustomers();
                      },
                    )
                  : null,
            ),
            onChanged: (val) => customerProvider.search(val),
          ),
          const SizedBox(height: 16),

          // Customers Data Table / Grid
          Expanded(
            child: customerProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : customers.isEmpty
                    ? Center(
                        child: Text(
                          context.tr('no_customers'),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ListView.separated(
                            itemCount: customers.length,
                            separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.borderLight),
                            itemBuilder: (context, index) {
                              final customer = customers[index];
                              final opType = OperatorConstants.fromString(customer.operator);
                              final opColor = OperatorConstants.getOperatorColor(opType);
                              final opBg = OperatorConstants.getOperatorLightBg(opType);

                              return ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: opBg,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: opColor.withOpacity(0.3)),
                                  ),
                                  child: Text(
                                    customer.operator.toUpperCase(),
                                    style: TextStyle(color: opColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(
                                      PhoneValidator.formatDisplay(customer.phoneNumber),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (customer.name != null && customer.name!.isNotEmpty) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        customer.name!,
                                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  customer.notes != null && customer.notes!.isNotEmpty
                                      ? customer.notes!
                                      : (customer.lastRecharge != null
                                          ? '${context.tr('last_recharged')}: ${DateFormatter.formatDate(customer.lastRecharge!)}'
                                          : ''),
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.lightCard,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${customer.totalTransactions} ${context.tr('total_recharges')}',
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Direct Recharge Button
                                    IconButton(
                                      icon: const Icon(Icons.flash_on, color: AppColors.primary),
                                      tooltip: context.tr('btn_recharge_now'),
                                      onPressed: () {
                                        rechargeProvider.selectCustomer(customer);
                                        appState.setActiveTab(AppTab.recharge);
                                      },
                                    ),
                                    // Edit
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
                                      tooltip: context.tr('edit'),
                                      onPressed: () => _showAddEditCustomerDialog(context, customer),
                                    ),
                                    // Delete
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                                      tooltip: context.tr('delete'),
                                      onPressed: () => _confirmDeleteCustomer(context, customer),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showAddEditCustomerDialog(BuildContext context, Customer? customer) {
    final phoneController = TextEditingController(text: customer?.phoneNumber ?? '');
    final nameController = TextEditingController(text: customer?.name ?? '');
    final notesController = TextEditingController(text: customer?.notes ?? '');
    final isEditing = customer != null;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? context.tr('edit_customer') : context.tr('add_customer')),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: phoneController,
                  enabled: !isEditing,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: context.tr('phone_number'), hintText: '05xxxxxxxx / 06xxxxxxxx / 07xxxxxxxx'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: context.tr('customer_name')),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(labelText: context.tr('notes')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                final phone = PhoneValidator.sanitize(phoneController.text.trim());
                if (!PhoneValidator.isValidAlgerianMobile(phone)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(dialogContext.tr('err_invalid_phone')), backgroundColor: AppColors.danger),
                  );
                  return;
                }

                final detectedOp = PhoneValidator.getOperator(phone);
                final opId = OperatorConstants.getOperatorId(detectedOp);
                final customerProvider = Provider.of<CustomerProvider>(dialogContext, listen: false);

                final toSave = Customer(
                  id: customer?.id,
                  phoneNumber: phone,
                  operator: opId,
                  name: nameController.text.trim(),
                  notes: notesController.text.trim(),
                  totalTransactions: customer?.totalTransactions ?? 0,
                  lastRecharge: customer?.lastRecharge,
                  createdAt: customer?.createdAt ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                );

                await customerProvider.saveCustomer(toSave);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('customer_saved')), backgroundColor: AppColors.success),
                  );
                }
              },
              child: Text(context.tr('save')),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteCustomer(BuildContext context, Customer customer) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('confirm')),
        content: Text(dialogContext.tr('delete_customer_confirm')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(dialogContext.tr('cancel'))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (customer.id != null) {
                final customerProvider = Provider.of<CustomerProvider>(dialogContext, listen: false);
                await customerProvider.deleteCustomer(customer.id!);
              }
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: Text(dialogContext.tr('delete')),
          ),
        ],
      ),
    );
  }
}
