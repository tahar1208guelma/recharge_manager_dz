import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/currency_formatter.dart';

class QuickAmountSelector extends StatelessWidget {
  final double selectedAmount;
  final ValueChanged<double> onAmountSelected;

  const QuickAmountSelector({
    super.key,
    required this.selectedAmount,
    required this.onAmountSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: AppConstants.quickAmounts.map((amount) {
        final isSelected = selectedAmount == amount;
        return InkWell(
          onTap: () => onAmountSelected(amount),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.borderLight,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxInsets.boxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : null,
            ),
            child: Text(
              CurrencyFormatter.formatCompact(amount),
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class BoxInsets {
  static BoxShadow boxShadow({required Color color, required double blurRadius, required Offset offset}) {
    return BoxShadow(color: color, blurRadius: blurRadius, offset: offset);
  }
}
