import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/settings_provider.dart';
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
            title: Text(
              'Hyperparameters',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: -0.5, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
            backgroundColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildThemeCard(context, ref, isDark),
                const SizedBox(height: 24),
                _buildSystemPromptCard(context, controller, notifier, isDark),
                const SizedBox(height: 24),
                _buildSettingsCard(
                  context,
                  isDark,
                  children: [
                    _buildSliderRow(
                      context,
                      'Temperature: ${settings.temperature.toStringAsFixed(1)}',
                      'Controls randomness: lower is focused, higher is creative.',
                      settings.temperature,
                      0.1,
                      1.5,
                      (val) => notifier.updateTemperature(val),
                      isDark: isDark,
                    ),
                    Divider(height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _buildSliderRow(
                      context,
                      'Top-P: ${settings.topP.toStringAsFixed(2)}',
                      'Nucleus sampling: filters out low-probability tokens.',
                      settings.topP,
                      0.05,
                      1.0,
                      (val) => notifier.updateTopP(val),
                      isDark: isDark,
                    ),
                    Divider(height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _buildSliderRow(
                      context,
                      'Top-K: ${settings.topK}',
                      'Limits vocabulary sampling to the K most likely tokens.',
                      settings.topK.toDouble(),
                      5.0,
                      100.0,
                      (val) => notifier.updateTopK(val.toInt()),
                      divisions: 19,
                      isDark: isDark,
                    ),
                    Divider(height: 32, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    _buildSliderRow(
                      context,
                      'Max Tokens: ${settings.maxTokens}',
                      'Maximum tokens to generate per inference sequence.',
                      settings.maxTokens.toDouble(),
                      64.0,
                      2048.0,
                      (val) => notifier.updateMaxTokens(val.toInt()),
                      divisions: 31,
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildLegalCard(context, isDark),
                const SizedBox(height: 40),
              ]),
            ),
          )
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

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCardBg : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ABOUT & LEGAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              _legalRow(
                context,
                Icons.info_outline_rounded,
                'About & Legal',
                'Version $version+$buildNumber',
                const LegalScreen(),
                isDark,
              ),
              const Divider(height: 24, color: AppColors.darkBorder),
              _legalRow(
                context,
                Icons.privacy_tip_rounded,
                'Privacy Policy',
                'How your data is handled',
                const PrivacyPolicyScreen(),
                isDark,
              ),
              const Divider(height: 24, color: AppColors.darkBorder),
              _legalRow(
                context,
                Icons.gavel_rounded,
                'Terms & Conditions',
                'Rules and guidelines',
                const TermsConditionsScreen(),
                isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legalRow(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    Widget destination,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.neonCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.neonCyan, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, bool isDark) {
    final themeMode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'APPEARANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _themeOption(
                icon: Icons.dark_mode_rounded,
                label: 'Dark',
                selected: themeMode == ThemeMode.dark,
                onTap: () => notifier.setThemeMode(ThemeMode.dark),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _themeOption(
                icon: Icons.light_mode_rounded,
                label: 'Light',
                selected: themeMode == ThemeMode.light,
                onTap: () => notifier.setThemeMode(ThemeMode.light),
                isDark: isDark,
              ),
              const SizedBox(width: 12),
              _themeOption(
                icon: Icons.settings_brightness_rounded,
                label: 'System',
                selected: themeMode == ThemeMode.system,
                onTap: () => notifier.setThemeMode(ThemeMode.system),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _themeOption({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.neonCyan.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.neonCyan : (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.3),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.neonCyan : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.neonCyan : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemPromptCard(
    BuildContext context,
    TextEditingController controller,
    SettingsNotifier notifier,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SYSTEM INSTRUCTION TARGET',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            maxLines: 4,
            style: TextStyle(fontSize: 14, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            decoration: InputDecoration(
              hintText: 'Specify systemic directives...',
              hintStyle: TextStyle(color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.6)),
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan)),
              fillColor: isDark ? AppColors.darkCardBg : Colors.white,
              filled: true,
            ),
            onChanged: (text) => notifier.updateSystemPrompt(text),
          ),
          const SizedBox(height: 12),
          Text(
            'Injected as the primary context node ahead of each text inference prompt sequence.',
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          )
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    bool isDark, {
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBg : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context,
    String title,
    String description,
    double value,
    double min,
    double max,
    Function(double) onChanged, {
    int? divisions,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.neonCyan,
            inactiveTrackColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            thumbColor: AppColors.neonCyan,
            overlayColor: AppColors.neonCyan.withValues(alpha: 0.12),
            valueIndicatorColor: AppColors.neonCyan,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
