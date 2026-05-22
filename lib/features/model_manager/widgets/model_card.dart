import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/hardware_checker.dart';
import '../../../core/widgets/meta_icon_text.dart';
import '../../dashboard/providers/diagnostics_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/model_provider.dart';
import 'ram_warning.dart';
import 'tier_warning.dart';
import 'error_banner.dart';
import 'progress_bar.dart';

class ModelCard extends StatelessWidget {
  final Map<String, dynamic> model;
  final WidgetRef ref;
  final double availableRamGb;
  final bool isDownloaded;
  final ModelDownloadState? downloadInfo;
  final bool isLoaded;
  final bool isTierMismatched;
  final bool globalLoading;
  final bool isDark;

  const ModelCard({
    super.key,
    required this.model,
    required this.ref,
    required this.availableRamGb,
    required this.isDownloaded,
    this.downloadInfo,
    required this.isLoaded,
    required this.isTierMismatched,
    required this.globalLoading,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final modelId = model['id'] as String;
    final modelName = model['name'] as String;
    final sizeGb = model['sizeGb'] as double;
    final minRam = model['minRamRequired'] as double;
    final params = model['params'] as String;
    final desc = model['description'] as String;
    final dl = downloadInfo;
    final canRun = HardwareChecker.canRunModel(availableRamGb, minRam);

    Color tierColor = AppColors.neonCyan;
    if (model['tier'] == 2) tierColor = AppColors.vibrantIndigo;
    if (model['tier'] == 1) tierColor = Colors.purpleAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isLoaded ? AppColors.neonCyan : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          width: isLoaded ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  modelName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tierColor.withValues(alpha: 0.3)),
                ),
                child: Text(params, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: tierColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              MetaIconText(icon: Icons.save_rounded, text: '${sizeGb.toStringAsFixed(2)} GB Disk'),
              const SizedBox(width: 20),
              MetaIconText(icon: Icons.memory_rounded, text: 'Min. ${minRam.toStringAsFixed(0)}GB RAM'),
            ],
          ),
          const SizedBox(height: 12),
          Text(desc, style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          const SizedBox(height: 20),
          if (isTierMismatched && !isDownloaded) ...[
            const TierWarning(),
            const SizedBox(height: 16),
          ],
          if (!canRun) ...[
            RamWarning(availableRamGb: availableRamGb, minRamRequired: minRam),
            const SizedBox(height: 16),
          ],
          if (dl != null && dl.status == 'DOWNLOADING') ...[
            DownloadProgressBar(download: dl, isDark: isDark),
            const SizedBox(height: 16),
          ],
          if (dl != null && dl.status == 'ERROR') ...[
            ErrorBanner(
              message: dl.error.isNotEmpty ? dl.error : 'Download failed.',
              isDark: isDark,
              onRetry: () => ref.read(modelProvider.notifier).retryDownload(modelId),
              onDismiss: () => ref.read(modelProvider.notifier).clearDownloadError(modelId),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isDownloaded) ...[
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: globalLoading ? null : () => ref.read(modelProvider.notifier).deleteModel(modelId),
                ),
                const SizedBox(width: 8),
                if (isLoaded)
                  ElevatedButton.icon(
                    onPressed: () => ref.read(modelProvider.notifier).unloadModel(),
                    icon: const Icon(Icons.power_settings_new_rounded, size: 18),
                    label: const Text('UNLOAD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error.withValues(alpha: 0.15),
                      foregroundColor: AppColors.error,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: globalLoading || !canRun ? null : () {
                      final settings = ref.read(settingsProvider);
                      final diag = ref.read(diagnosticsProvider);
                      final optimalThreads = HardwareChecker.optimalThreadCount(diag.cores);
                      ref.read(modelProvider.notifier).loadModelToRam(
                        modelId,
                        settings.toMap(),
                        threads: optimalThreads,
                        availableRamGb: diag.availableRamGb,
                      );
                    },
                    icon: globalLoading
                        ? SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(isDark ? Colors.white : AppColors.darkObsidian),
                            ),
                          )
                        : const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(!canRun ? 'INSUFFICIENT RAM' : 'LOAD TO RAM'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !canRun ? AppColors.error.withValues(alpha: 0.15) : AppColors.neonCyan,
                      foregroundColor: !canRun ? AppColors.error : AppColors.darkObsidian,
                    ),
                  )
              ] else if (dl != null && dl.status == 'DOWNLOADING')
                const Expanded(
                  child: Text('Downloading...', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.neonCyan), textAlign: TextAlign.end),
                )
              else if (dl != null && dl.status == 'ERROR')
                const Spacer()
              else
                ElevatedButton.icon(
                  onPressed: canRun ? () => ref.read(modelProvider.notifier).triggerDownload(modelId) : null,
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text(!canRun ? 'INSUFFICIENT RAM' : 'GET MODEL'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !canRun
                        ? AppColors.error.withValues(alpha: 0.15)
                        : (isDark ? AppColors.vibrantIndigo : AppColors.vibrantIndigo).withValues(alpha: 0.15),
                    foregroundColor: !canRun ? AppColors.error : AppColors.vibrantIndigo,
                    elevation: 0,
                  ),
                )
            ],
          )
        ],
      ),
    );
  }
}
