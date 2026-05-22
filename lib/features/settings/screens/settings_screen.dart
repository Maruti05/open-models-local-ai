import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/styled_card.dart';
import '../../../core/widgets/theme_option.dart';
import '../providers/settings_provider.dart';
import '../widgets/parameter_curve.dart';
import 'legal_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_conditions_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: settings.systemPrompt);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Row(
              children: [
                Icon(Icons.tune_rounded, size: 28.r,
                    color: isDark ? AppColors.vibrantIndigo : AppColors.vibrantIndigo),
                SizedBox(width: 12.w),
                Text('Hyperparameters',
                    style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
              ],
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildHeaderChart(settings, isDark, context),
                SizedBox(height: 20.h),
                _buildPresetRow(context, ref, settings, isDark),
                SizedBox(height: 24.h),
                _buildThemeCard(context, ref, isDark),
                SizedBox(height: 24.h),
                _buildParamCard(context, settings.temperature, 0.1, 1.5,
                    'Temperature', 'Controls randomness: lower is focused, higher is creative.',
                    Icons.whatshot_rounded, AppColors.neonCyan, isDark,
                        (v) => notifier.updateTemperature(v), CurveType.temperature),
                SizedBox(height: 16.h),
                _buildParamCard(context, settings.topP, 0.05, 1.0,
                    'Top-P', 'Nucleus sampling: filters out low-probability tokens.',
                    Icons.filter_alt_rounded, AppColors.vibrantIndigo, isDark,
                        (v) => notifier.updateTopP(v), CurveType.topP),
                SizedBox(height: 16.h),
                _buildParamCard(context, settings.topK.toDouble(), 5, 100,
                    'Top-K', 'Limits vocabulary sampling to the K most likely tokens.',
                    Icons.format_list_numbered_rounded, AppColors.success, isDark,
                        (v) => notifier.updateTopK(v.toInt()), CurveType.topK),
                SizedBox(height: 16.h),
                _buildParamCard(context, settings.maxTokens.toDouble(), 64, 2048,
                    'Max Tokens', 'Maximum tokens to generate per inference sequence.',
                    Icons.text_fields_rounded, const Color(0xFF8B5CF6), isDark,
                        (v) => notifier.updateMaxTokens(v.toInt()), CurveType.maxTokens),
                SizedBox(height: 24.h),
                _buildSystemPromptCard(context, controller, notifier, isDark),
                SizedBox(height: 24.h),
                _buildLegalCard(context, isDark),
                SizedBox(height: 40.h),
              ]),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeaderChart(SettingsState settings, bool isDark, BuildContext context) {
    return StyledCard(
      padding: EdgeInsets.all(20.r),
      borderRadiusValue: 24,
      boxShadow: [
        BoxShadow(color: AppColors.vibrantIndigo.withValues(alpha: 0.06), blurRadius: 24, spreadRadius: 1),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.vibrantIndigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_graph_rounded, size: 12.r, color: AppColors.vibrantIndigo),
                    SizedBox(width: 4.w),
                    Text('INFERENCE PROFILE',
                        style: TextStyle(fontSize: 9.sp, fontWeight: FontWeight.w800,
                            color: AppColors.vibrantIndigo, letterSpacing: 1.0)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text('Generation Parameter Distribution',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
          SizedBox(height: 4.h),
          Text('Modify sliders to shape how the model responds. Changes apply immediately.',
              style: TextStyle(fontSize: 11.sp, height: 1.4,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildPresetRow(BuildContext context, WidgetRef ref, SettingsState settings, bool isDark) {
    final notifier = ref.read(settingsProvider.notifier);

    return StyledCard(
      padding: EdgeInsets.all(16.r),
      borderRadiusValue: 20,
      child: Row(
        children: [
          _buildPresetChip(context, 'Precise', Icons.psychology_rounded,
              const Color(0xFF3B82F6), () { notifier.updateTemperature(0.1); notifier.updateTopP(0.1); notifier.updateTopK(5); notifier.updateMaxTokens(256); }, isDark),
          SizedBox(width: 8.w),
          _buildPresetChip(context, 'Balanced', Icons.account_balance_rounded,
              const Color(0xFF10B981), () { notifier.updateTemperature(0.7); notifier.updateTopP(0.9); notifier.updateTopK(40); notifier.updateMaxTokens(512); }, isDark),
          SizedBox(width: 8.w),
          _buildPresetChip(context, 'Creative', Icons.auto_awesome_rounded,
              const Color(0xFF8B5CF6), () { notifier.updateTemperature(1.2); notifier.updateTopP(0.95); notifier.updateTopK(80); notifier.updateMaxTokens(1024); }, isDark),
        ],
      ),
    );
  }

  Widget _buildPresetChip(BuildContext context, String label, IconData icon,
      Color color, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20.r),
              SizedBox(height: 4.h),
              Text(label,
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.sp, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return StyledCard(
      padding: EdgeInsets.all(20.r),
      borderRadiusValue: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.palette_rounded, size: 16.r, color: const Color(0xFFF59E0B)),
              ),
              SizedBox(width: 10.w),
              Text('APPEARANCE',
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.5)),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              ThemeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                selected: themeMode == ThemeMode.dark,
                onTap: () => notifier.setThemeMode(ThemeMode.dark),
              ),
              SizedBox(width: 12.w),
              ThemeOption(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                selected: themeMode == ThemeMode.light,
                onTap: () => notifier.setThemeMode(ThemeMode.light),
              ),
              SizedBox(width: 12.w),
              ThemeOption(
                icon: Icons.settings_brightness_rounded,
                label: 'System',
                selected: themeMode == ThemeMode.system,
                onTap: () => notifier.setThemeMode(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildParamCard(
    BuildContext context, double value, double min, double max,
    String title, String description, IconData icon, Color color, bool isDark,
    ValueChanged<double> onChanged, CurveType curveType,
  ) {
    final displayValue = curveType == CurveType.topK || curveType == CurveType.maxTokens
        ? value.toInt().toString()
        : value.toStringAsFixed(2);

    return StyledCard(
      padding: EdgeInsets.all(20.r),
      borderRadiusValue: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 16.r, color: color),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                        const Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(displayValue,
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.sp, color: color)),
                        ),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(description,
                        style: TextStyle(fontSize: 11.sp,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ParameterCurve(type: curveType, value: value, height: 56.h),
          SizedBox(height: 12.h),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.12),
              valueIndicatorColor: color,
              valueIndicatorTextStyle: TextStyle(color: Colors.white, fontSize: 11.sp, fontWeight: FontWeight.bold),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: curveType == CurveType.topK ? 19
                  : curveType == CurveType.maxTokens ? 31
                  : null,
              label: displayValue,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemPromptCard(BuildContext context, TextEditingController controller, SettingsNotifier notifier, bool isDark) {
    return StyledCard(
      padding: EdgeInsets.all(20.r),
      borderRadiusValue: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(Icons.terminal_rounded, size: 16.r, color: const Color(0xFF3B82F6)),
              ),
              SizedBox(width: 10.w),
              Text('SYSTEM INSTRUCTION TARGET',
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.5)),
            ],
          ),
          SizedBox(height: 16.h),
          TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(fontSize: 13.sp, height: 1.4,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            decoration: InputDecoration(
              hintText: 'Specify systemic directives...',
              hintStyle: TextStyle(fontSize: 13.sp,
                  color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.neonCyan, width: 1.5),
              ),
              fillColor: (isDark ? AppColors.darkObsidian : AppColors.lightPorcelain).withValues(alpha: 0.5),
              filled: true,
              contentPadding: EdgeInsets.all(14.r),
            ),
            onChanged: (text) => notifier.updateSystemPrompt(text),
          ),
          SizedBox(height: 12.h),
          Text('Injected as the primary context node ahead of each text inference prompt sequence.',
              style: TextStyle(fontSize: 10.sp, height: 1.4,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        ],
      ),
    );
  }

  Widget _buildLegalCard(BuildContext context, bool isDark) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snapshot) {
        final version = snapshot.data?.version ?? '--';
        final buildNumber = snapshot.data?.buildNumber ?? '--';
        return StyledCard(
          padding: EdgeInsets.all(20.r),
          borderRadiusValue: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: AppColors.neonCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.info_outline_rounded, size: 16.r, color: AppColors.neonCyan),
                  ),
                  SizedBox(width: 10.w),
                  Text('ABOUT & LEGAL',
                      style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, letterSpacing: 1.5)),
                ],
              ),
              SizedBox(height: 16.h),
              _legalRow(context, Icons.info_outline_rounded, 'About & Legal', 'Version $version+$buildNumber', const LegalScreen(), isDark),
              Divider(height: 24.h, color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)),
              _legalRow(context, Icons.privacy_tip_rounded, 'Privacy Policy', 'How your data is handled', const PrivacyPolicyScreen(), isDark),
              Divider(height: 24.h, color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5)),
              _legalRow(context, Icons.gavel_rounded, 'Terms & Conditions', 'Rules and guidelines', const TermsConditionsScreen(), isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _legalRow(BuildContext context, IconData icon, String title, String subtitle, Widget destination, bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => destination)),
      child: Row(
        children: [
          Container(
            width: 36.r, height: 36.r,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: AppColors.neonCyan, size: 18.r),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 11.sp,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, size: 20.r),
        ],
      ),
    );
  }
}
