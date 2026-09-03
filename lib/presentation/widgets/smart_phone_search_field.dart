import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/phone_validator.dart';
import '../../domain/entities/customer.dart';
import '../providers/customer_provider.dart';
import '../providers/recharge_provider.dart';

class SmartPhoneSearchField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;

  const SmartPhoneSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onChanged,
  });

  @override
  State<SmartPhoneSearchField> createState() => _SmartPhoneSearchFieldState();
}

class _SmartPhoneSearchFieldState extends State<SmartPhoneSearchField> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    widget.focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final text = widget.controller.text.trim();
    widget.onChanged?.call(text);

    // Trigger instant search for prefix inputs (e.g. 05, 06, 07 or any digits)
    if (text.isNotEmpty) {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      customerProvider.search(text).then((_) {
        if (mounted && widget.focusNode.hasFocus) {
          _showOverlay();
        }
      });
    } else {
      _hideOverlay();
    }
  }

  void _onFocusChanged() {
    if (!widget.focusNode.hasFocus) {
      _hideOverlay();
    } else if (widget.controller.text.trim().isNotEmpty) {
      _showOverlay();
    }
  }

  void _showOverlay() {
    _hideOverlay();
    final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
    if (customerProvider.searchResults.isEmpty) return;

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: size.width,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0, size.height + 6),
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: Container(
                constraints: const BoxConstraints(maxHeight: 280),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Consumer<CustomerProvider>(
                  builder: (context, provider, _) {
                    final results = provider.searchResults;
                    if (results.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      shrinkWrap: true,
                      itemCount: results.length,
                      separatorBuilder: (_, index) => const Divider(height: 1, color: AppColors.borderLight),
                      itemBuilder: (context, index) {
                        final customer = results[index];
                        return _buildSuggestionItem(customer);
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionItem(Customer customer) {
    final operatorType = OperatorConstants.fromString(customer.operator);
    final opColor = OperatorConstants.getOperatorColor(operatorType);
    final opBg = OperatorConstants.getOperatorLightBg(operatorType);

    return InkWell(
      onTap: () {
        widget.controller.text = customer.phoneNumber;
        final recharge = Provider.of<RechargeProvider>(context, listen: false);
        recharge.selectCustomer(customer);
        _hideOverlay();
        widget.focusNode.unfocus();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Operator badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: opBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: opColor.withOpacity(0.3)),
              ),
              child: Text(
                customer.operator.toUpperCase(),
                style: TextStyle(color: opColor, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 12),

            // Phone number & customer details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    PhoneValidator.formatDisplay(customer.phoneNumber),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (customer.name != null && customer.name!.isNotEmpty)
                    Text(
                      customer.name!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),

            // Last recharge timestamp or total count
            if (customer.lastRecharge != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    DateFormatter.formatDate(customer.lastRecharge!),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                  Text(
                    '${customer.totalTransactions} ${context.tr('total_recharges')}',
                    style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    widget.controller.removeListener(_onTextChanged);
    widget.focusNode.removeListener(_onFocusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        decoration: InputDecoration(
          labelText: context.tr('phone_number'),
          hintText: context.tr('phone_hint'),
          prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    widget.controller.clear();
                    _hideOverlay();
                    final recharge = Provider.of<RechargeProvider>(context, listen: false);
                    recharge.clearForm();
                  },
                )
              : null,
        ),
      ),
    );
  }
}
