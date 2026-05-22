import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class RamWarning extends StatelessWidget {
  final double availableRamGb;
  final double minRamRequired;

  const RamWarning({
    super.key,
    required this.availableRamGb,
    required this.minRamRequired,
  });

  @override
  Widget build(BuildContext context) {
    final shortfall = minRamRequired - availableRamGb;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.memory, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'INSUFFICIENT RAM: ${availableRamGb.toStringAsFixed(1)} GB available, '
              '${minRamRequired.toStringAsFixed(1)} GB required. '
              'Need ${shortfall.toStringAsFixed(1)} GB more.',
              style: TextStyle(fontSize: 11, color: AppColors.error.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}
