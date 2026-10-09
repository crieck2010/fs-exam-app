import 'package:flutter/material.dart';

/// Material 3 themes. One seed color (surveyor green) generates both
/// schemes, so light and dark mode always stay visually consistent.
abstract final class AppTheme {
  static const Color _seed = Color(0xFF1B5C3F);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: _seed),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    ),
    appBarTheme: const AppBarTheme(centerTitle: true),
  );
}
