import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/native_bridge.dart';
import '../../../core/utils/hardware_checker.dart';
import '../../dashboard/providers/diagnostics_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../providers/model_provider.dart';

class ModelManagerScreen extends ConsumerStatefulWidget {
  const ModelManagerScreen({super.key});

  @override
  ConsumerState<ModelManagerScreen> createState() => _ModelManagerScreenState();
}

class _ModelManagerScreenState extends ConsumerState<ModelManagerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Set<int> _selectedTiers = {};
  String _sizeFilter = 'All';
  String _statusFilter = 'All';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const _sizeOptions = ['All', '<300MB', '300MB-1GB', '1-2GB', '>2GB'];
  static const _statusOptions = ['All', 'Downloaded', 'Not Downloaded'];

  @override
  void initState() {
    super.initState();
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      final isOffline = result.contains(ConnectivityResult.none);
      if (!isOffline) return;

      final modelState = ref.read(modelProvider);
      final hasActiveDownloads = modelState.downloads.values
          .any((d) => d.status == 'DOWNLOADING');

      if (!hasActiveDownloads) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Internet lost. Turn on WiFi or mobile data to continue download.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 8),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          action: SnackBarAction(
            label: 'Settings',
            textColor: Colors.white,
            onPressed: () => NativeBridge.instance.openWifiSettings(),
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredModels(ModelState modelState) {
    final all = ApiEndpoints.localModelsCatalog;
    return all.where((m) {
      final name = (m['name'] as String).toLowerCase();
      final desc = (m['description'] as String).toLowerCase();
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty && !name.contains(q) && !desc.contains(q)) return false;

      if (_selectedTiers.isNotEmpty) {
        final tier = m['tier'] as int;
        if (!_selectedTiers.contains(tier)) return false;
      }

      final sizeGb = m['sizeGb'] as double;
      switch (_sizeFilter) {
        case '<300MB':
          if (sizeGb >= 0.3) return false;
        case '300MB-1GB':
          if (sizeGb < 0.3 || sizeGb >= 1.0) return false;
        case '1-2GB':
          if (sizeGb < 1.0 || sizeGb >= 2.0) return false;
        case '>2GB':
          if (sizeGb < 2.0) return false;
      }

      if (_statusFilter != 'All') {
        final id = m['id'] as String;
        final downloaded = modelState.downloadedModelIds.contains(id);
        if (_statusFilter == 'Downloaded' && !downloaded) return false;
        if (_statusFilter == 'Not Downloaded' && downloaded) return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final modelState = ref.watch(modelProvider);
    final diagnostics = ref.watch(diagnosticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredModels(modelState);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              'Model Repository',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            backgroundColor: Colors.transparent,
          ),

          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Search models by name or description...',
                  hintStyle: TextStyle(
                    color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(Icons.search_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.neonCyan),
                  ),
                  fillColor: isDark ? AppColors.darkCardBg : Colors.white,
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // Filter chips row
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildTierFilter(isDark),
                  const SizedBox(width: 8),
                  _buildDropdownFilter('Size', _sizeFilter, _sizeOptions, (v) {
                    setState(() => _sizeFilter = v);
                  }, isDark),
                  const SizedBox(width: 8),
                  _buildDropdownFilter('Status', _statusFilter, _statusOptions, (v) {
                    setState(() => _statusFilter = v);
                  }, isDark),
                  if (_hasActiveFilters)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: ActionChip(
                        label: const Text('Reset', style: TextStyle(fontSize: 11)),
                        avatar: const Icon(Icons.refresh_rounded, size: 14),
                        onPressed: _resetFilters,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),

          if (modelState.error.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: _buildErrorAlert(modelState.error),
              ),
            ),

          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 48,
                        color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text('No models match your filters.',
                        style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final model = filtered[index];
                    return _ModelCard(
                      model: model,
                      ref: ref,
                      availableRamGb: diagnostics.availableRamGb,
                      isDownloaded: modelState.downloadedModelIds.contains(model['id'] as String),
                      downloadInfo: modelState.downloads[model['id'] as String],
                      isLoaded: modelState.loadedModelId == model['id'] as String,
                      isTierMismatched: model['tier'] < diagnostics.modelTier,
                      globalLoading: modelState.isModelLoading,
                      isDark: isDark,
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _selectedTiers.isNotEmpty || _sizeFilter != 'All' || _statusFilter != 'All';

  void _resetFilters() {
    setState(() {
      _selectedTiers = {};
      _sizeFilter = 'All';
      _statusFilter = 'All';
      _searchController.clear();
      _searchQuery = '';
    });
  }

  void _toggleTier(int tier) {
    setState(() {
      if (_selectedTiers.contains(tier)) {
        _selectedTiers.remove(tier);
      } else {
        _selectedTiers.add(tier);
      }
    });
  }

  Widget _buildTierFilter(bool isDark) {
    return Row(
      children: [1, 2, 3].map((tier) {
        final selected = _selectedTiers.contains(tier);
        final label = tier == 1 ? 'High-end' : (tier == 2 ? 'Mid-range' : 'Entry');
        Color chipColor;
        if (tier == 1) {
          chipColor = Colors.purpleAccent;
        } else if (tier == 2) {
          chipColor = AppColors.vibrantIndigo;
        } else {
          chipColor = AppColors.neonCyan;
        }
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: FilterChip(
            label: Text('T$tier $label', style: TextStyle(fontSize: 11, color: selected ? Colors.white : chipColor)),
            selected: selected,
            selectedColor: chipColor,
            checkmarkColor: Colors.white,
            onSelected: (_) => _toggleTier(tier),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            side: BorderSide(color: selected ? chipColor : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDropdownFilter(String label, String current, List<String> options, ValueChanged<String> onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        color: isDark ? AppColors.darkCardBg : Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: current,
          dropdownColor: isDark ? AppColors.darkCardBg : Colors.white,
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text('$label: $o', style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildErrorAlert(String err) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        'ERROR: $err',
        style: const TextStyle(color: AppColors.error, fontSize: 13),
      ),
    );
  }
}

class _RamWarning extends StatelessWidget {
  const _RamWarning({required this.availableRamGb, required this.minRamRequired});

  final double availableRamGb;
  final double minRamRequired;

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

class _ModelCard extends StatelessWidget {
  const _ModelCard({
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

  final Map<String, dynamic> model;
  final WidgetRef ref;
  final double availableRamGb;
  final bool isDownloaded;
  final ModelDownloadState? downloadInfo;
  final bool isLoaded;
  final bool isTierMismatched;
  final bool globalLoading;
  final bool isDark;

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
          color: isLoaded
              ? AppColors.neonCyan
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
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
                child: Text(
                  params,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _MetaIconText(Icons.save_rounded, '${sizeGb.toStringAsFixed(2)} GB Disk', isDark),
              const SizedBox(width: 20),
              _MetaIconText(Icons.memory_rounded, 'Min. ${minRam.toStringAsFixed(0)}GB RAM', isDark),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 20),
          if (isTierMismatched && !isDownloaded) ...[
            _TierWarning(),
            const SizedBox(height: 16),
          ],
          if (!canRun) ...[
            _RamWarning(availableRamGb: availableRamGb, minRamRequired: minRam),
            const SizedBox(height: 16),
          ],
          if (dl != null && dl.status == 'DOWNLOADING') ...[
            _ProgressBar(download: dl, isDark: isDark),
            const SizedBox(height: 16),
          ],
          if (dl != null && dl.status == 'ERROR') ...[
            _ErrorBanner(
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
                  onPressed: globalLoading
                      ? null
                      : () => ref.read(modelProvider.notifier).deleteModel(modelId),
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
                    onPressed: globalLoading || !canRun
                        ? null
                        : () {
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
                      backgroundColor: !canRun
                          ? AppColors.error.withValues(alpha: 0.15)
                          : AppColors.neonCyan,
                      foregroundColor: !canRun ? AppColors.error : AppColors.darkObsidian,
                    ),
                  )
              ] else if (dl != null && dl.status == 'DOWNLOADING')
                const Expanded(
                  child: Text(
                    'Downloading...',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.neonCyan,
                    ),
                    textAlign: TextAlign.end,
                  ),
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
                        : isDark
                            ? AppColors.vibrantIndigo.withValues(alpha: 0.15)
                            : AppColors.vibrantIndigo.withValues(alpha: 0.1),
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

class _MetaIconText extends StatelessWidget {
  const _MetaIconText(this.icon, this.text, this.isDark);
  final IconData icon;
  final String text;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ],
    );
  }
}

class _TierWarning extends StatelessWidget {
  const _TierWarning();

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
              'OOM WARNING: Your physical RAM specs rank below this model\'s size. Out-Of-Memory closures might occur.',
              style: TextStyle(fontSize: 11, color: AppColors.error.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.isDark,
    required this.onRetry,
    required this.onDismiss,
  });

  final String message;
  final bool isDark;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;

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
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.error.withValues(alpha: 0.9),
                  ),
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
                label: Text(
                  'Dismiss',
                  style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, color: AppColors.neonCyan, size: 16),
                label: const Text(
                  'Retry',
                  style: TextStyle(fontSize: 12, color: AppColors.neonCyan),
                ),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.download, required this.isDark});
  final ModelDownloadState download;
  final bool isDark;

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
