import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ErrorBanner extends StatelessWidget {
  final String message;
  final bool isDark;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    required this.isDark,
    required this.onRetry,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_off_rounded, color: AppColors.error, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(fontSize: 12, color: AppColors.error.withValues(alpha: 0.9)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                label: Text('Dismiss', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.neonCyan, size: 16),
                label: const Text('Retry', style: TextStyle(fontSize: 12, color: AppColors.neonCyan)),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
