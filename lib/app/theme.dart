import 'package:flutter/material.dart';

class PaceLensTheme {
  const PaceLensTheme._();

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff26c6da),
      brightness: Brightness.dark,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xff101418),
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
