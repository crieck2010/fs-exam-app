import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'features/domains/domain_picker_screen.dart';

/// Root widget. Theme mode comes from [ThemeController] (persisted);
/// light/dark schemes from [AppTheme] (Material 3).
class FsExamApp extends StatelessWidget {
  const FsExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeController>().mode;
    return MaterialApp(
      title: 'FS Exam Prep',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const DomainPickerScreen(),
    );
  }
}
