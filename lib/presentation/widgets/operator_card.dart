import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/operator_constants.dart';
import '../../core/localization/app_localizations.dart';

class OperatorCard extends StatelessWidget {
  final OperatorType operatorType;
  final bool isSelected;
  final VoidCallback onTap;

  const OperatorCard({
    super.key,
    required this.operatorType,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final opColor = OperatorConstants.getOperatorColor(operatorType);
    final opLightBg = OperatorConstants.getOperatorLightBg(operatorType);
    final name = OperatorConstants.getOperatorName(operatorType, lang: context.isRtl ? 'ar' : 'en');

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? opLightBg : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? opColor : AppColors.borderLight,
              width: isSelected ? 2.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: opColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? opColor : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
