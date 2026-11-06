import 'package:flutter/material.dart';

/// Configuración de temas visuales (Material 3) para la aplicación.
abstract final class AppTheme {
  /// Configuración de tema claro.
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
  );

  /// Configuración de tema oscuro.
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.teal,
      brightness: Brightness.dark,
    ),
  );
}
