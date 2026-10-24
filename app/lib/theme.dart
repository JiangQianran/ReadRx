import 'package:flutter/material.dart';

/// 适老化主题：大字号、大按钮、高对比
ThemeData buildTheme() {
  const seed = Color(0xFF1B7F6B); // 医药绿
  final scheme = ColorScheme.fromSeed(seedColor: seed);
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF6F8F7),
    textTheme: base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 18, height: 1.5),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 17, height: 1.5),
      titleLarge: base.textTheme.titleLarge?.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
      titleMedium: base.textTheme.titleMedium?.copyWith(fontSize: 19, fontWeight: FontWeight.w600),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      centerTitle: true,
      titleTextStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 72,
      labelTextStyle: WidgetStateProperty.all(const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ),
  );
}

/// 相克等级对应的颜色
Color levelColor(String level) {
  switch (level) {
    case '禁止':
      return Colors.red.shade700;
    case '慎用':
      return Colors.orange.shade800;
    case '无明显风险':
      return Colors.green.shade700;
    default:
      return Colors.blueGrey.shade600;
  }
}

IconData levelIcon(String level) {
  switch (level) {
    case '禁止':
      return Icons.block;
    case '慎用':
      return Icons.warning_amber_rounded;
    case '无明显风险':
      return Icons.check_circle_outline;
    default:
      return Icons.help_outline;
  }
}
