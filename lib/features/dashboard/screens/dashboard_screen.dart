import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/hardware_checker.dart';
import '../../../core/services/benchmark_service.dart';
import '../../../core/widgets/styled_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../providers/diagnostics_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isBenchmarking = false;
  BenchmarkResult? _latestResult;
  List<BenchmarkResult> _history = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final hist = await BenchmarkService.instance.getBenchmarkHistory();
    if (mounted) {
      setState(() {
        _history = hist;
        if (hist.isNotEmpty) _latestResult = hist.first;
      });
    }
  }

  Future<void> _runBenchmark() async {
    setState(() => _isBenchmarking = true);
    await Future.delayed(const Duration(milliseconds: 1200));

    final state = ref.read(diagnosticsProvider);
    final modelName = state.modelTier == 1
        ? 'Mistral-7B-Q4'
        : (state.modelTier == 2 ? 'Llama-3-3B-Q4' : 'Qwen-0.5B-Q4');
    final result = await BenchmarkService.instance.runOnDeviceBenchmark(modelName);

    if (mounted) {
      setState(() {
        _latestResult = result;
        _isBenchmarking = false;
      });
      _loadHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(diagnosticsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark),
          if (state.isLoading)
            SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                ),
              ),
            )
          else if (state.error.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 40.h),
                child: _buildErrorCard(state.error),
              ),
            )
          else ...[
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildHealthScore(state, isDark),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildStatsGrid(state, isDark),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildAccelerationBlock(state, isDark),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildTierCard(state, isDark),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildBenchmarkSection(context, isDark),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildBenchmarkResults(context, isDark),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 40.h)),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isDark) {
    return SliverAppBar.large(
      title: Row(
        children: [
          Icon(Icons.sensors_rounded, size: 28.r,
              color: isDark ? AppColors.neonCyan : AppColors.vibrantIndigo),
          SizedBox(width: 12.w),
          Text('Telemetry',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        ],
      ),
      backgroundColor: Colors.transparent,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh_rounded, size: 22.r),
          onPressed: () => ref.read(diagnosticsProvider.notifier).scanHardware(),
        ),
      ],
    );
  }

  Widget _buildHealthScore(DiagnosticsState state, bool isDark) {
    final double freePct = state.totalRamGb > 0
        ? (state.availableRamGb / state.totalRamGb) * 100
        : 0;
    final tierScore = state.modelTier == 1 ? 1.0 : (state.modelTier == 2 ? 0.65 : 0.35);
    final cpuScore = (state.cores / 8).clamp(0, 1);
    final ramScore = (freePct / 100);
    final accelScore = (state.vulkan ? 0.3 : 0) + (state.nnapi ? 0.3 : 0);
    final overall = ((ramScore * 0.35) + (tierScore * 0.30) + (cpuScore * 0.20) + accelScore).clamp(0.0, 1.0);

    Color ringColor;
    String label;
    if (overall >= 0.75) {
      ringColor = AppColors.neonCyan;
      label = 'Excellent';
    } else if (overall >= 0.5) {
      ringColor = AppColors.success;
      label = 'Good';
    } else if (overall >= 0.3) {
      ringColor = AppColors.warning;
      label = 'Fair';
    } else {
      ringColor = AppColors.error;
      label = 'Poor';
    }

    return StyledCard(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 28.h),
      borderRadiusValue: 28,
      boxShadow: [
        BoxShadow(color: ringColor.withValues(alpha: 0.06), blurRadius: 30, spreadRadius: 2),
      ],
      child: Row(
        children: [
          SizedBox(
            width: 80.r,
            height: 80.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80.r, height: 80.r,
                  child: CircularProgressIndicator(
                    value: overall,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${(overall * 100).toInt()}',
                        style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                    Text('%', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600,
                        color: ringColor)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 24.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: ringColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(label.toUpperCase(),
                          style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800,
                              color: ringColor, letterSpacing: 1.2)),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.auto_awesome_rounded, size: 14.r, color: ringColor),
                  ],
                ),
                SizedBox(height: 10.h),
                Text('System Health Score',
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                SizedBox(height: 4.h),
                Text('Derived from RAM, CPU, acceleration & model tier metrics',
                    style: TextStyle(fontSize: 11.sp,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(DiagnosticsState state, bool isDark) {
    final double freePct = state.totalRamGb > 0
        ? (state.availableRamGb / state.totalRamGb) * 100
        : 0;
    final double usedRam = state.totalRamGb - state.availableRamGb;
    final int optimalThreads = HardwareChecker.optimalThreadCount(state.cores);

    final cards = [
      _StatCardData(
        icon: Icons.memory_rounded,
        label: 'RAM Usage',
        value: '${usedRam.toStringAsFixed(1)} / ${state.totalRamGb.toStringAsFixed(0)} GB',
        sub: '${freePct.toStringAsFixed(0)}% free',
        color: const Color(0xFF3B82F6),
        darkColor: const Color(0xFF60A5FA),
      ),
      _StatCardData(
        icon: Icons.developer_board_rounded,
        label: 'CPU',
        value: '${state.cores} Cores',
        sub: '$optimalThreads optimal threads',
        color: const Color(0xFF10B981),
        darkColor: const Color(0xFF34D399),
      ),
      _StatCardData(
        icon: Icons.speed_rounded,
        label: 'Performance',
        value: HardwareChecker.getTierLabel(state.modelTier),
        sub: 'Tier ${state.modelTier} device',
        color: const Color(0xFF8B5CF6),
        darkColor: const Color(0xFFA78BFA),
      ),
      _StatCardData(
        icon: Icons.storage_rounded,
        label: 'Free RAM',
        value: '${state.availableRamGb.toStringAsFixed(1)} GB',
        sub: 'of ${state.totalRamGb.toStringAsFixed(0)} GB total',
        color: freePct >= 50 ? const Color(0xFF00F2FE) : const Color(0xFFF59E0B),
        darkColor: freePct >= 50 ? const Color(0xFF00F2FE) : const Color(0xFFFBBF24),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(cards[0], isDark)),
            SizedBox(width: 12.w),
            Expanded(child: _buildStatCard(cards[1], isDark)),
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildStatCard(cards[2], isDark)),
            SizedBox(width: 12.w),
            Expanded(child: _buildStatCard(cards[3], isDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatCardData c, bool isDark) {
    final col = isDark ? c.darkColor : c.color;
    return StyledCard(
      padding: EdgeInsets.all(16.r),
      borderRadiusValue: 20,
      boxShadow: [
        BoxShadow(color: col.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: col.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(c.icon, color: col, size: 18.r),
          ),
          SizedBox(height: 12.h),
          Text(c.label,
              style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 0.5)),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
            child: Text(c.value, maxLines: 1,
                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: col)),
          ),
          SizedBox(height: 2.h),
          Text(c.sub, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.sp,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildAccelerationBlock(DiagnosticsState state, bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildAccelCard('Vulkan', state.vulkan,
            Icons.auto_awesome_rounded, const Color(0xFF7C3AED), isDark)),
        SizedBox(width: 12.w),
        Expanded(child: _buildAccelCard('NNAPI', state.nnapi,
            Icons.psychology_rounded, const Color(0xFFF59E0B), isDark)),
      ],
    );
  }

  Widget _buildAccelCard(String name, bool active, IconData icon, Color color, bool isDark) {
    return StyledCard(
      padding: EdgeInsets.all(18.r),
      borderRadiusValue: 24,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: (active ? color : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))
                  .withValues(alpha: active ? 0.15 : 0.08),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Icon(
              icon,
              color: active ? color : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                  .withValues(alpha: 0.4),
              size: 28.r,
            ),
          ),
          SizedBox(height: 12.h),
          Text(name,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.sp,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          SizedBox(height: 6.h),
          StatusBadge(active: active),
          SizedBox(height: 4.h),
          if (active)
            Text('Hardware accelerated', style: TextStyle(fontSize: 10.sp,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))
          else
            Text('Software fallback', style: TextStyle(fontSize: 10.sp, color: AppColors.error.withValues(alpha: 0.7))),
        ],
      ),
    );
  }

  Widget _buildTierCard(DiagnosticsState state, bool isDark) {
    final tier = state.modelTier;
    final label = HardwareChecker.getTierLabel(tier);

    Color tierColor;
    String model;
    String desc;
    switch (tier) {
      case 1:
        tierColor = AppColors.neonCyan;
        model = 'Mistral 7B / Llama 3 8B';
        desc = 'Full 4-bit quantized large models with maximum context window. On-device RAG pipeline ready.';
      case 2:
        tierColor = AppColors.vibrantIndigo;
        model = 'Llama 3 3B / Phi-3';
        desc = 'Optimized for mid-size models. Streaming generation with low latency.';
      default:
        tierColor = AppColors.warning;
        model = 'Qwen 0.5B / TinyLlama';
        desc = 'Lightweight models for fundamental tasks. Efficient offline inference.';
    }

    return StyledCard(
      padding: EdgeInsets.all(20.r),
      borderRadiusValue: 24,
      boxShadow: [
        BoxShadow(color: tierColor.withValues(alpha: 0.06), blurRadius: 24, spreadRadius: 1),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [tierColor.withValues(alpha: 0.2), tierColor.withValues(alpha: 0.05)]),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.military_tech_rounded, size: 14.r, color: tierColor),
                    SizedBox(width: 6.w),
                    Text(label.toUpperCase(),
                        style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800,
                            color: tierColor, letterSpacing: 1.2)),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                width: 44.r, height: 44.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: tierColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Center(
                  child: Text('T$tier', style: TextStyle(fontSize: 16.sp,
                      fontWeight: FontWeight.w900, color: tierColor)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(model,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          SizedBox(height: 8.h),
          Text(desc,
              style: TextStyle(fontSize: 12.sp, height: 1.5,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: tier == 1 ? 0.95 : (tier == 2 ? 0.6 : 0.3),
              minHeight: 4,
              backgroundColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
              valueColor: AlwaysStoppedAnimation<Color>(tierColor),
            ),
          ),
          SizedBox(height: 6.h),
          Align(
            alignment: Alignment.centerRight,
            child: Text('${tier == 1 ? 95 : (tier == 2 ? 60 : 30)}% model capacity',
                style: TextStyle(fontSize: 9.sp,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkSection(BuildContext context, bool isDark) {
    return StyledCard(
      padding: EdgeInsets.all(20.r),
      borderRadiusValue: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.speed_rounded, size: 18.r,
                      color: isDark ? AppColors.vibrantIndigo : AppColors.vibrantIndigo),
                  SizedBox(width: 10.w),
                  Text('CHIP BENCHMARK',
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          letterSpacing: 1.2)),
                ],
              ),
              if (_isBenchmarking)
                SizedBox(width: 18.r, height: 18.r,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantIndigo))),
            ],
          ),
          SizedBox(height: 16.h),
          if (_isBenchmarking) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: LinearProgressIndicator(
                minHeight: 6,
                backgroundColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vibrantIndigo),
              ),
            ),
            SizedBox(height: 12.h),
            Center(
              child: Text('Running matrix operations...',
                  style: TextStyle(fontSize: 11.sp, color: AppColors.vibrantIndigo, fontWeight: FontWeight.bold)),
            ),
          ] else if (_latestResult != null) ...[
            Row(
              children: [
                Expanded(child: _buildMetricTile(
                    'Tokens/sec', '${_latestResult!.tokensPerSecond}', AppColors.neonCyan, isDark, Icons.bolt_rounded)),
                SizedBox(width: 12.w),
                Expanded(child: _buildMetricTile(
                    'Prompt Eval', '${_latestResult!.promptEvalLatencyMs}ms', AppColors.vibrantIndigo, isDark, Icons.timer_rounded)),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(child: _buildMetricTile(
                    'Generation', '${_latestResult!.totalGenerationLatencyMs}ms', AppColors.success, isDark, Icons.hourglass_bottom_rounded)),
                SizedBox(width: 12.w),
                Expanded(child: _buildMetricTile(
                    'RAM Used', '${_latestResult!.ramUsedMb.toStringAsFixed(0)} MB', const Color(0xFFF59E0B), isDark, Icons.memory_rounded)),
              ],
            ),
          ] else ...[
            SizedBox(
              width: double.infinity, height: 48.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                  elevation: 0,
                ),
                onPressed: _runBenchmark,
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text('RUN BENCHMARK',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12.sp)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, bool isDark, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: color, size: 14.r),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                Text(value, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkResults(BuildContext context, bool isDark) {
    if (_history.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: StyledCard(
        padding: EdgeInsets.all(16.r),
        borderRadiusValue: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HISTORY',
                style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    letterSpacing: 1.2)),
            SizedBox(height: 12.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length.clamp(0, 4),
              separatorBuilder: (_, _) => Divider(
                height: 1, thickness: 0.5,
                color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
              ),
              itemBuilder: (context, index) {
                final run = _history[index];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(
                          color: AppColors.vibrantIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(Icons.schedule_rounded, size: 12.r, color: AppColors.vibrantIndigo),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(run.modelName, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.sp,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                            Text(
                              '${run.timestamp.day}/${run.timestamp.month}/${run.timestamp.year}',
                              style: TextStyle(fontSize: 10.sp,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text('${run.tokensPerSecond} t/s',
                          style: TextStyle(color: AppColors.neonCyan,
                              fontWeight: FontWeight.bold, fontSize: 12.sp)),
                      SizedBox(width: 8.w),
                      Text('${run.promptEvalLatencyMs}ms',
                          style: TextStyle(fontSize: 11.sp,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Diagnostic Failure',
                    style: TextStyle(fontWeight: FontWeight.bold,
                        fontSize: 15, color: AppColors.error)),
                SizedBox(height: 6.h),
                Text(error,
                    style: const TextStyle(fontSize: 12, color: AppColors.error, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardData {
  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final Color color;
  final Color darkColor;

  const _StatCardData({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.darkColor,
  });
}
