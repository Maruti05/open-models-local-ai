import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/screens/chat_screen.dart';
import '../../model_manager/screens/model_manager_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'dashboard_screen.dart';

class _NavConfig {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;

  const _NavConfig({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
  });
}

const _navItems = [
  _NavConfig(icon: Icons.analytics_outlined, activeIcon: Icons.analytics_rounded, label: 'Telemetry', screen: DashboardScreen()),
  _NavConfig(icon: Icons.folder_open_outlined, activeIcon: Icons.folder_special_rounded, label: 'Repository', screen: ModelManagerScreen()),
  _NavConfig(icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded, label: 'Chat', screen: ChatScreen()),
  _NavConfig(icon: Icons.tune_outlined, activeIcon: Icons.tune_rounded, label: 'Hyperparams', screen: SettingsScreen()),
];

class ShellLayout extends ConsumerStatefulWidget {
  const ShellLayout({super.key});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  int _currentIndex = 0;

  Color _navColor(int index) {
    const colors = [
      AppColors.neonCyan,
      AppColors.vibrantIndigo,
      AppColors.success,
      Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: Row(
          children: [
            if (isWideScreen) _buildRail(isDark),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _navItems.map((item) => item.screen).toList(),
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWideScreen ? null : _buildBottomNav(isDark),
      ),
    );
  }

  Widget _buildRail(bool isDark) {
    final railColor = _navColor(_currentIndex);

    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      labelType: NavigationRailLabelType.all,
      backgroundColor: isDark ? AppColors.darkCardBg : Colors.white,
      indicatorColor: Colors.transparent,
      minWidth: 72,
      groupAlignment: -0.3,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Center(
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.neonCyan, AppColors.vibrantIndigo],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Icon(Icons.sensors_rounded, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
      selectedIconTheme: IconThemeData(color: railColor, size: 24),
      unselectedIconTheme: IconThemeData(
        color: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5),
        size: 22,
      ),
      selectedLabelTextStyle: TextStyle(
        color: railColor,
        fontWeight: FontWeight.w700,
        fontSize: 10,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
      destinations: List.generate(_navItems.length, (i) {
        final item = _navItems[i];
        final isActive = i == _currentIndex;
        final color = _navColor(i);

        return NavigationRailDestination(
          icon: _buildRailIcon(item.icon, null, false, color, isDark),
          selectedIcon: _buildRailIcon(item.activeIcon, railColor, true, color, isDark),
          label: isActive
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: railColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: railColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                )
              : Text(
                  item.label,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 10,
                  ),
                ),
        );
      }),
    );
  }

  Widget _buildRailIcon(IconData icon, Color? activeColor, bool isActive, Color color, bool isDark) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isActive)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor?.withValues(alpha: 0.12),
                border: Border.all(
                  color: activeColor?.withValues(alpha: 0.3) ?? Colors.transparent,
                  width: 1,
                ),
              ),
            ),
          Icon(
            icon,
            size: isActive ? 24 : 22,
            color: isActive
                ? activeColor
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5),
          ),
          if (isActive)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: activeColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withValues(alpha: 0.5),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.darkObsidian : Colors.white,
        selectedItemColor: _navColor(_currentIndex),
        unselectedItemColor: (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary).withValues(alpha: 0.5),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 10),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        elevation: 0,
        items: List.generate(_navItems.length, (i) {
          final item = _navItems[i];
          final isActive = i == _currentIndex;
          final color = _navColor(i);

          return BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color.withValues(alpha: 0.1) : Colors.transparent,
              ),
              child: Icon(item.icon, size: 20),
            ),
            activeIcon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
              ),
              child: Icon(item.activeIcon, size: 22, color: color),
            ),
            label: item.label,
          );
        }),
      ),
    );
  }
}
