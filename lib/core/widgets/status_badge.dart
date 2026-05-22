import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final bool active;
  final String activeLabel;
  final String inactiveLabel;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.active,
    this.activeLabel = 'ACTIVE',
    this.inactiveLabel = 'INACTIVE',
    this.fontSize = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: active
            ? AppColors.success.withValues(alpha: 0.1)
            : (isDark ? Colors.grey : AppColors.lightBorder).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? activeLabel : inactiveLabel,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: active
              ? AppColors.success
              : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ),
    );
  }
}
