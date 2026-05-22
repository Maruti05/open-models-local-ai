import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/hardware_checker.dart';
import '../../../core/services/benchmark_service.dart';
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
        if (hist.isNotEmpty) {
          _latestResult = hist.first;
        }
      });
    }
  }

  Future<void> _runBenchmark() async {
    setState(() {
      _isBenchmarking = true;
    });

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
      
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: AppColors.neonCyan),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Benchmark Complete: ${result.tokensPerSecond} tokens/sec on $modelName',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
      );
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
          SliverAppBar.large(
            title: const Text(
              'Telemetry Core',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5),
            ),
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.read(diagnosticsProvider.notifier).scanHardware(),
              ),
            ],
          ),
          if (state.isLoading)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 250,
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.neonCyan),
                  ),
                ),
              ),
            )
          else if (state.error.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                child: _buildErrorCard(state.error),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildTierRecommendationCard(context, state.modelTier, isDark),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildBenchmarkCard(context, isDark),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              sliver: _buildMetricGrid(context, state),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 24.h)),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: _buildHardwareAccelerationPanel(context, state),
              ),
            ),
            SliverToBoxAdapter(child: SizedBox(height: 40.h)),
          ],
        ],
      ),
    );
  }

  Widget _buildTierRecommendationCard(BuildContext context, int tier, bool isDark) {
    final title = HardwareChecker.getTierLabel(tier);
    String subtitle = '';
    Color glowColor = Colors.transparent;

    if (tier == 1) {
      subtitle = 'Mistral 7B & advanced 4-bit quantized layers fully unlocked.';
      glowColor = AppColors.neonCyan;
    } else if (tier == 2) {
      subtitle = 'Optimized for 1.5B to 3B models. Seamless local conversations.';
      glowColor = AppColors.vibrantIndigo;
    } else {
      subtitle = 'Recommended for 0.5B parameters. Secure offline processing.';
      glowColor = AppColors.error;
    }

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: BoxDecoration(
                        color: glowColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'HARDWARE DIAGNOSTIC RANK',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w800,
                        color: glowColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                ),
                SizedBox(height: 6.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          _buildHexagonalDial(tier, glowColor),
        ],
      ),
    );
  }

  Widget _buildHexagonalDial(int tier, Color color) {
    return Container(
      width: 64.r,
      height: 64.r,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
      ),
      child: Center(
        child: FittedBox(
          child: Text(
            'T$tier',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenchmarkCard(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CHIP PERFORMANCE BENCHMARK',
                style: TextStyle(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              if (_isBenchmarking)
                SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.vibrantIndigo),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Runs on-device matrix numeric tests to evaluate real physical token generation throughput (tokens/sec) and prompt processing speed.',
            style: TextStyle(
              fontSize: 12.sp,
              height: 1.4,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          if (_latestResult != null && !_isBenchmarking) ...[
            Row(
              children: [
                Expanded(
                  child: _buildBenchmarkMetricTile(
                    'GENERATION',
                    '${_latestResult!.tokensPerSecond}',
                    't/sec',
                    AppColors.neonCyan,
                    isDark,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildBenchmarkMetricTile(
                    'PROMPT EVAL',
                    '${_latestResult!.promptEvalLatencyMs}',
                    'ms',
                    AppColors.vibrantIndigo,
                    isDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
          ],
          if (_isBenchmarking) ...[
            ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(8.r)),
              child: LinearProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.vibrantIndigo),
                backgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                minHeight: 6,
              ),
            ),
            SizedBox(height: 12.h),
            Center(
              child: Text(
                'Measuring floating-point operation speeds...',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.vibrantIndigo,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ] else
            SizedBox(
              width: double.infinity,
              height: 44.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.vibrantIndigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  elevation: 0,
                ),
                onPressed: _runBenchmark,
                icon: Icon(Icons.speed_rounded, size: 18.r),
                label: Text(
                  'RUN ON-DEVICE CHIP TEST',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0, fontSize: 12.sp),
                ),
              ),
            ),
          if (_history.isNotEmpty) ...[
            SizedBox(height: 20.h),
            Text(
              'HISTORICAL RUN RECORDS',
              style: TextStyle(
                fontSize: 9.sp,
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                letterSpacing: 1.0,
              ),
            ),
            SizedBox(height: 10.h),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length.clamp(0, 3),
              separatorBuilder: (_, _) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final run = _history[index];
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        run.modelName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${run.tokensPerSecond} t/s',
                      style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 12.sp),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${run.promptEvalLatencyMs}ms',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBenchmarkMetricTile(String label, String value, String unit, Color color, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBorder.withValues(alpha: 0.3)
            : AppColors.lightBorder.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          SizedBox(height: 4.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: color),
                ),
                SizedBox(width: 4.w),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context, DiagnosticsState state) {
    final double freePercentage =
        state.totalRamGb > 0 ? (state.availableRamGb / state.totalRamGb) * 100 : 0.0;

    final metrics = [
      _MetricItem('Total Memory', '${state.totalRamGb.toStringAsFixed(1)} GB', 'Physical System RAM', Icons.memory_rounded, AppColors.vibrantIndigo),
      _MetricItem('Available Memory', '${state.availableRamGb.toStringAsFixed(1)} GB', '${freePercentage.toStringAsFixed(0)}% available space', Icons.speed_rounded, AppColors.neonCyan),
      _MetricItem('Compute Cores', '${state.cores} Cores', 'Active CPU workers', Icons.developer_board_rounded, Colors.amber),
      _MetricItem('Latency State', 'Smooth 120Hz', 'Bridge optimization active', Icons.bolt_rounded, AppColors.success),
    ];

    return SliverPadding(
      padding: EdgeInsets.zero,
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.w,
          mainAxisSpacing: 12.h,
          childAspectRatio: 1.6,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildDialCard(context, metrics[index], isDark: Theme.of(context).brightness == Brightness.dark),
          childCount: metrics.length,
        ),
      ),
    );
  }

  Widget _buildDialCard(BuildContext context, _MetricItem item, {required bool isDark}) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              SizedBox(width: 6.w),
              Icon(item.icon, color: item.color, size: 16.r),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              item.value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp, color: item.color),
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            item.footer,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareAccelerationPanel(BuildContext context, DiagnosticsState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : AppColors.lightCardBg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ON-DEVICE ACCELERATION INTERFACES',
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16.h),
          _buildHardwareStatusRow(
            context,
            'Vulkan Graphics Accelerator',
            'Enables massive parallel array compute for matrix multiplications.',
            state.vulkan,
            isDark,
          ),
          SizedBox(height: 20.h),
          _buildHardwareStatusRow(
            context,
            'Android Neural Networks API (NNAPI)',
            'Maps tensor compilation operations directly onto native NPU hardware.',
            state.nnapi,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildHardwareStatusRow(
      BuildContext context, String title, String subtitle, bool active, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 2.h),
          child: Icon(
            active ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: active
                ? AppColors.success
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.4),
            size: 20.r,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                subtitle,
                softWrap: true,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: active
                ? AppColors.success.withValues(alpha: 0.1)
                : (isDark ? Colors.grey : AppColors.lightBorder).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            active ? 'ACTIVE' : 'INACTIVE',
            style: TextStyle(
              fontSize: 8.sp,
              fontWeight: FontWeight.bold,
              color: active
                  ? AppColors.success
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Diagnostic Scan Failure',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                SizedBox(height: 4.h),
                Text(
                  error,
                  style: const TextStyle(fontSize: 12, color: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  final String title;
  final String value;
  final String footer;
  final IconData icon;
  final Color color;

  const _MetricItem(this.title, this.value, this.footer, this.icon, this.color);
}
