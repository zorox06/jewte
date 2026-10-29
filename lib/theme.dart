import 'package:flutter/material.dart';

class JewteColors {
  static const paper = Color(0xFFF6F5EF), ink = Color(0xFF202D25);
  static const forest = Color(0xFF294C3D), lime = Color(0xFFD4EC85);
  static const rust = Color(0xFF975039), muted = Color(0xFF667267);
  static const dark = Color(0xFF171E19), darkSurface = Color(0xFF222C24);
}

ThemeData jewteTheme(bool dark) {
  final scheme = ColorScheme.fromSeed(
    seedColor: JewteColors.forest,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: dark ? JewteColors.lime : JewteColors.forest,
    surface: dark ? JewteColors.darkSurface : Colors.white,
    onSurface: dark ? const Color(0xFFE9EDE3) : JewteColors.ink,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: dark ? JewteColors.dark : JewteColors.paper,
    fontFamily: 'Manrope',
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontSize: 36,
        height: 1.15,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.6,
        color: scheme.onSurface,
      ),
      headlineMedium: TextStyle(
        fontSize: 28,
        height: 1.18,
        fontWeight: FontWeight.w700,
        letterSpacing: -1,
        color: scheme.onSurface,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -.55,
        color: scheme.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: scheme.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 15, height: 1.6, color: scheme.onSurface),
      bodyMedium: TextStyle(fontSize: 13, height: 1.6, color: scheme.onSurface),
      labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      labelSmall: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
    dividerColor: dark ? const Color(0xFF39443A) : const Color(0xFFE4E7DD),
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: const AppBarTheme(surfaceTintColor: Colors.transparent),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? JewteColors.lime : JewteColors.ink,
      contentTextStyle: TextStyle(
        fontFamily: 'Manrope',
        color: dark ? JewteColors.ink : Colors.white,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      hintStyle: TextStyle(
        fontSize: 13,
        color: dark ? const Color(0xFFABB6A9) : JewteColors.muted,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(
          color: dark ? const Color(0xFF39443A) : const Color(0xFFE4E7DD),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(17),
        borderSide: BorderSide(color: scheme.primary, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 52),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
  );
}

extension JewteContext on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get muted => isDark ? const Color(0xFFB0BAAD) : JewteColors.muted;
  Color get soft => isDark ? const Color(0xFF2B372E) : const Color(0xFFEEF0E6);
  Color get line => Theme.of(this).dividerColor;
}
