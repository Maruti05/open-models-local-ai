import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import '../../../core/constants/app_colors.dart';

class MarkdownMessageWidget extends StatelessWidget {
  final String content;
  final bool selectable;

  const MarkdownMessageWidget({
    super.key,
    required this.content,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MarkdownWidget(
      data: content,
      selectable: selectable,
      config: _buildConfig(isDark),
    );
  }

  MarkdownConfig _buildConfig(bool isDark) {
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final codeBg = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08);
    final preBg = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return MarkdownConfig(configs: [
      H1Config(
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.3,
        ),
      ),
      H2Config(
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.3,
        ),
      ),
      H3Config(
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          height: 1.3,
        ),
      ),
      PConfig(
        textStyle: TextStyle(
          fontSize: 14.5,
          height: 1.5,
          color: textPrimary,
        ),
      ),
      CodeConfig(
        style: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          backgroundColor: codeBg,
          color: isDark ? AppColors.neonCyan : AppColors.lightNavy,
        ),
      ),
      PreConfig(
        textStyle: TextStyle(
          fontSize: 13,
          fontFamily: 'monospace',
          height: 1.5,
          color: textPrimary,
        ),
        decoration: BoxDecoration(
          color: preBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor),
        ),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      BlockquoteConfig(
        sideColor: AppColors.neonCyan.withValues(alpha: 0.5),
        textColor: textSecondary,
        sideWith: 3,
        padding: const EdgeInsets.fromLTRB(14, 2, 0, 2),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),
    ]);
  }
}
