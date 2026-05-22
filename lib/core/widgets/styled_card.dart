import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class StyledCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final Color? backgroundColor;
  final double borderRadiusValue;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const StyledCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderColor,
    this.backgroundColor,
    this.borderRadiusValue = 24,
    this.boxShadow,
    this.gradient,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveBorderColor = borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final effectiveBgColor = backgroundColor ?? (isDark ? AppColors.darkCardBg : AppColors.lightCardBg);

    final border = Border.all(color: effectiveBorderColor, width: 1);

    Widget card = Container(
      margin: margin ?? EdgeInsets.zero,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: gradient != null ? null : effectiveBgColor,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        border: border,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      card = GestureDetector(onTap: onTap, child: card);
    }

    return card;
  }
}
