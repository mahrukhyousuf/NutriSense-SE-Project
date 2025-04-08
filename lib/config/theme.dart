import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: Colors.green,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primaryColor: Colors.green,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.green,
        brightness: Brightness.dark,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
      ),
      useMaterial3: true,
    );
  }
}
