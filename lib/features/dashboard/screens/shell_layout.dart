import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../chat/screens/chat_screen.dart';
import '../../model_manager/screens/model_manager_screen.dart';
import '../../settings/screens/settings_screen.dart';
import 'dashboard_screen.dart';

class ShellLayout extends ConsumerStatefulWidget {
  const ShellLayout({super.key});

  @override
  ConsumerState<ShellLayout> createState() => _ShellLayoutState();
}

class _ShellLayoutState extends ConsumerState<ShellLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ModelManagerScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        body: Row(
          children: [
            if (isWideScreen) ...[
              NavigationRail(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) => setState(() => _currentIndex = index),
                labelType: NavigationRailLabelType.all,
                backgroundColor: isDark ? AppColors.darkCardBg : Colors.white,
                indicatorColor: AppColors.neonCyan.withValues(alpha: 0.15),
                selectedIconTheme: const IconThemeData(color: AppColors.neonCyan),
                unselectedIconTheme: IconThemeData(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                unselectedLabelTextStyle: TextStyle(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  fontSize: 12,
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics_rounded),
                    label: Text('Telemetry'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.folder_open_outlined),
                    selectedIcon: Icon(Icons.folder_special_rounded),
                    label: Text('Repository'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    selectedIcon: Icon(Icons.chat_bubble_rounded),
                    label: Text('Chat'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune_rounded),
                    label: Text('Hyperparams'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1, thickness: 1),
            ],
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
        bottomNavigationBar: isWideScreen
            ? null
            : BottomNavigationBar(
                currentIndex: _currentIndex,
                onTap: (index) => setState(() => _currentIndex = index),
                type: BottomNavigationBarType.fixed,
                backgroundColor: isDark ? AppColors.darkCardBg : Colors.white,
                selectedItemColor: isDark ? AppColors.neonCyan : AppColors.lightNavy,
                unselectedItemColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                unselectedLabelStyle: const TextStyle(fontSize: 11),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.analytics_outlined),
                    activeIcon: Icon(Icons.analytics_rounded),
                    label: 'Telemetry',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.folder_open_outlined),
                    activeIcon: Icon(Icons.folder_special_rounded),
                    label: 'Repository',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.chat_bubble_outline_rounded),
                    activeIcon: Icon(Icons.chat_bubble_rounded),
                    label: 'Chat',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.tune_outlined),
                    activeIcon: Icon(Icons.tune_rounded),
                    label: 'Hyperparams',
                  ),
                ],
              ),
      ),
    );
  }
}
