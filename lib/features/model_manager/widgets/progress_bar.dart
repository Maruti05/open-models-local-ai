import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/model_provider.dart';

class DownloadProgressBar extends StatelessWidget {
  final ModelDownloadState download;
  final bool isDark;

  const DownloadProgressBar({
    super.key,
    required this.download,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Downloading: ${download.progressPercentage.toStringAsFixed(1)}%',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.neonCyan),
            ),
            Text(
              '${download.downloadSpeedMbps.toStringAsFixed(1)} Mbps',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: download.progressPercentage / 100.0,
            minHeight: 6,
            backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
          ),
        ),
      ],
    );
  }
}
