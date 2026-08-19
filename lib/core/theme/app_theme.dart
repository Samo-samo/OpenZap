import 'package:flutter/material.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    // Desktop convention: interactive controls show a pointer cursor on
    // hover instead of Flutter's default arrow (adaptiveClickable).
    const click = WidgetStatePropertyAll<MouseCursor>(SystemMouseCursors.click);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brightness,
      ),
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