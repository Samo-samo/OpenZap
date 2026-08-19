import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => build(
    ColorScheme.fromSeed(
      seedColor: Colors.indigo,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => build(
    ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
  );

  /// Builds the app theme from an arbitrary [ColorScheme] — used for the
  /// seeded default as well as the system's Material You dynamic scheme.
  static ThemeData build(ColorScheme colorScheme) {
    // Desktop convention: interactive controls show a pointer cursor on
    // hover instead of Flutter's default arrow (adaptiveClickable).
    const click = WidgetStatePropertyAll<MouseCursor>(SystemMouseCursors.click);
    return ThemeData(
      colorScheme: colorScheme,
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(mouseCursor: click),
      ),
      filledButtonTheme: const FilledButtonThemeData(
        style: ButtonStyle(mouseCursor: click),
      ),
      outlinedButtonTheme: const OutlinedButtonThemeData(
        style: ButtonStyle(mouseCursor: click),
      ),
      textButtonTheme: const TextButtonThemeData(
        style: ButtonStyle(mouseCursor: click),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        mouseCursor: click,
      ),
    );
  }
}
