import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const _seed = Color(0xFF6366F1);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.light,
    );
    return _baseTheme(scheme);
  }

  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: Brightness.dark,
    );
    return _baseTheme(scheme);
  }

  static ThemeData _baseTheme(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    );
  }

  /// Subtle top accent per kanban column status (ClickUp-style cue).
  static Color columnAccent(String status, ColorScheme scheme) {
    switch (status) {
      case 'backlog':
        return scheme.outline;
      case 'to_do':
        return const Color(0xFF3B82F6);
      case 'in_progress':
        return const Color(0xFFF59E0B);
      case 'blocked':
        return const Color(0xFFEF4444);
      case 'review':
        return const Color(0xFF8B5CF6);
      case 'done':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return scheme.outline;
      default:
        return scheme.primary;
    }
  }

  static Color columnBackground(ColorScheme scheme) {
    return scheme.brightness == Brightness.dark
        ? scheme.surfaceContainerLow
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
  }
}
