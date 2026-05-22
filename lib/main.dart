import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/dashboard/screens/shell_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: OpenModelsApp(),
    ),
  );
}

class OpenModelsApp extends ConsumerWidget {
  const OpenModelsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'OpenModels Local AI',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          darkTheme: AppTheme.darkTheme,
          theme: AppTheme.lightTheme,
          home: const ShellLayout(),
        );
      },
    );
  }
}
