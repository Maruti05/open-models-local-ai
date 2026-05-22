import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MetaIconText extends StatelessWidget {
  final IconData icon;
  final String text;
  final double iconSize;
  final double fontSize;

  const MetaIconText({
    super.key,
    required this.icon,
    required this.text,
    this.iconSize = 16,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: iconSize, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: fontSize,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
      ],
    );
  }
}
