import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/native_bridge.dart';
import '../../dashboard/providers/diagnostics_provider.dart';
import '../providers/model_provider.dart';
import '../widgets/model_card.dart';

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
  Set<String> _selectedInputTypes = {};
  String _contextFilter = 'All';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  static const _sizeOptions = ['All', '<300MB', '300MB-1GB', '1-2GB', '>2GB'];
  static const _statusOptions = ['All', 'Downloaded', 'Not Downloaded'];
  static const _contextOptions = ['All', '<4K', '4K-8K', '8K-32K', '>32K'];

  @override
  void initState() {
    super.initState();
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      if (!mounted) return;
      if (!result.contains(ConnectivityResult.none)) return;

      final modelState = ref.read(modelProvider);
      if (!modelState.downloads.values.any((d) => d.status == 'DOWNLOADING')) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(child: Text('Internet lost. Turn on WiFi or mobile data to continue download.', style: TextStyle(fontSize: 13))),
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
    return ApiEndpoints.localModelsCatalog.where((m) {
      final name = (m['name'] as String).toLowerCase();
      final desc = (m['description'] as String).toLowerCase();
      final q = _searchQuery.trim().toLowerCase();
      if (q.isNotEmpty && !name.contains(q) && !desc.contains(q)) return false;
      if (_selectedTiers.isNotEmpty && !_selectedTiers.contains(m['tier'] as int)) return false;

      final sizeGb = m['sizeGb'] as double;
      switch (_sizeFilter) {
        case '<300MB': if (sizeGb >= 0.3) return false;
        case '300MB-1GB': if (sizeGb < 0.3 || sizeGb >= 1.0) return false;
        case '1-2GB': if (sizeGb < 1.0 || sizeGb >= 2.0) return false;
        case '>2GB': if (sizeGb < 2.0) return false;
      }

      if (_statusFilter != 'All') {
        final id = m['id'] as String;
        final downloaded = modelState.downloadedModelIds.contains(id);
        if (_statusFilter == 'Downloaded' && !downloaded) return false;
        if (_statusFilter == 'Not Downloaded' && downloaded) return false;
      }

      if (_selectedInputTypes.isNotEmpty) {
        final inputTypes = (m['inputTypes'] as List<dynamic>?)?.cast<String>() ?? ['text'];
        if (!_selectedInputTypes.any((t) => inputTypes.contains(t.toLowerCase()))) return false;
      }

      if (_contextFilter != 'All') {
        final ctx = m['contextWindow'] as int? ?? 2048;
        switch (_contextFilter) {
          case '<4K': if (ctx >= 4000) return false;
          case '4K-8K': if (ctx < 4000 || ctx >= 8000) return false;
          case '8K-32K': if (ctx < 8000 || ctx >= 32000) return false;
          case '>32K': if (ctx < 32000) return false;
        }
      }
      return true;
    }).toList();
  }

  Color _tierColor(int tier) {
    return tier == 1 ? const Color(0xFF7C3AED) : (tier == 2 ? AppColors.vibrantIndigo : AppColors.neonCyan);
  }

  @override
  Widget build(BuildContext context) {
    final modelState = ref.watch(modelProvider);
    final diagnostics = ref.watch(diagnosticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredModels(modelState);
    final totalModels = ApiEndpoints.localModelsCatalog.length;
    final userTier = diagnostics.modelTier;
    final downloadedCount = modelState.downloadedModelIds.length;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Row(
              children: [
                Icon(Icons.folder_special_rounded, size: 28,
                    color: isDark ? AppColors.vibrantIndigo : AppColors.vibrantIndigo),
                const SizedBox(width: 12),
                Text('Model Repository',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              ],
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Search models by name...',
                  hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5)),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.search_rounded, size: 20,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: 18,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); })
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
                  ),
                  fillColor: (isDark ? AppColors.darkCardBg : Colors.white).withValues(alpha: 0.8),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTierFilter(isDark),
                    const SizedBox(width: 8),
                    _buildChipFilter(_sizeFilter, _sizeOptions, (v) => setState(() => _sizeFilter = v), isDark),
                    const SizedBox(width: 8),
                    _buildChipFilter(_statusFilter, _statusOptions, (v) => setState(() => _statusFilter = v), isDark),
                    const SizedBox(width: 8),
                    _buildChipFilter(_contextFilter, _contextOptions, (v) => setState(() => _contextFilter = v), isDark),
                    const SizedBox(width: 8),
                    _buildInputTypeFilter(isDark),
                    if (_hasActiveFilters)
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: GestureDetector(
                          onTap: _resetFilters,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tierColor(userTier).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _tierColor(userTier).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.military_tech_rounded, size: 12, color: _tierColor(userTier)),
                        const SizedBox(width: 4),
                        Text('Tier $userTier',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _tierColor(userTier))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$totalModels available',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$downloadedCount downloaded',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                            color: AppColors.success)),
                  ),
                ],
              ),
            ),
          ),
          if (modelState.error.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _buildErrorAlert(modelState.error),
              ),
            ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.search_off_rounded, size: 36,
                        color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 16),
                  Text('No models match',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  const SizedBox(height: 6),
                  Text('Try adjusting your filters or search query.',
                      style: TextStyle(fontSize: 12,
                          color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.6))),
                ],
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final model = filtered[index];
                    return ModelCard(
                      model: model,
                      ref: ref,
                      availableRamGb: diagnostics.availableRamGb,
                      isDownloaded: modelState.downloadedModelIds.contains(model['id'] as String),
                      downloadInfo: modelState.downloads[model['id'] as String],
                      isLoaded: modelState.loadedModelId == model['id'] as String,
                      isTierMismatched: model['tier'] < diagnostics.modelTier,
                      loadingModelId: modelState.loadingModelId,
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

  bool get _hasActiveFilters => _selectedTiers.isNotEmpty ||
      _sizeFilter != 'All' ||
      _statusFilter != 'All' ||
      _selectedInputTypes.isNotEmpty ||
      _contextFilter != 'All';

  void _resetFilters() {
    setState(() {
      _selectedTiers = {};
      _sizeFilter = 'All';
      _statusFilter = 'All';
      _selectedInputTypes = {};
      _contextFilter = 'All';
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
      mainAxisSize: MainAxisSize.min,
      children: [1, 2, 3].map((tier) {
        final selected = _selectedTiers.contains(tier);
        final color = _tierColor(tier);
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: GestureDetector(
            onTap: () => _toggleTier(tier),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? color : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  width: selected ? 1 : 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.check_rounded, size: 12, color: Colors.white),
                    ),
                  Text('T$tier',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: selected ? Colors.white : color)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChipFilter(String current, List<String> options, ValueChanged<String> onChanged, bool isDark) {
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
          style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 11)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
          isDense: true,
          icon: Icon(Icons.expand_more_rounded, size: 16,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
      ),
    );
  }

  Widget _buildInputTypeFilter(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _inputTypeChip('Text', Icons.text_fields_rounded, isDark),
        const SizedBox(width: 4),
        _inputTypeChip('Image', Icons.image_rounded, isDark),
        const SizedBox(width: 4),
        _inputTypeChip('Audio', Icons.audiotrack_rounded, isDark),
        const SizedBox(width: 4),
        _inputTypeChip('Video', Icons.videocam_rounded, isDark),
      ],
    );
  }

  Widget _inputTypeChip(String label, IconData icon, bool isDark) {
    final selected = _selectedInputTypes.contains(label);
    final color = AppColors.vibrantIndigo;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedInputTypes.remove(label);
          } else {
            _selectedInputTypes.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: selected ? Colors.white : color),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : color)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorAlert(String err) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(err, style: const TextStyle(color: AppColors.error, fontSize: 12))),
        ],
      ),
    );
  }
}
