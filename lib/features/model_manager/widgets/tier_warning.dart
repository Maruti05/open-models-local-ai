import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class TierWarning extends StatelessWidget {
  const TierWarning({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'OOM WARNING: Your physical RAM specs rank below this model\'s size. '
              'Out-Of-Memory closures might occur.',
              style: TextStyle(fontSize: 11, color: AppColors.error.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
