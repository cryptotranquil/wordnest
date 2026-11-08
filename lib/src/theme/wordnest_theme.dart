import 'package:flutter/material.dart';

class AppColors {
  static const Color ink = Color(0xFF05161A);
  static const Color inkDeep = Color(0xFF020D11);
  static const Color cream = Color(0xFFDDECEB);
  static const Color creamTop = Color(0xFFF3E7CA);
  static const Color creamBottom = Color(0xFFD7E5E7);
  static const Color teal = Color(0xFF6ED5C6);
  static const Color tealLift = Color(0xFF9CE8DA);
  static const Color tealBright = Color(0xFFB9FFF4);
  static const Color tealDeep = Color(0xFF0F7F77);
  static const Color gold = Color(0xFFF0C66B);
  static const Color goldLight = Color(0xFFFFE7A8);
  static const Color goldDeep = Color(0xFFC88A2E);
  static const Color goldInk = Color(0xFF442700);
  static const Color muted = Color(0xFF9AB6BA);
  static const Color glass = Color(0x1A1B3140);
  static const Color glassLine = Color(0xFF2A3A3F);
  static const Color danger = Color(0xFFE96D5A);
  static const Color text = cream;
  static const Color bevel = Color(0xFF183F48);
  static const Color tileInk = Color(0xFF0A1D23);
  static const Color slotFill = Color(0xFF0E2128);
  static const Color slotLine = Color(0xFF34545C);

  static const Color primaryContainer = teal;
  static const Color onPrimaryContainer = cream;
  static const Color primary = teal;
  static const Color onPrimary = ink;
  static const Color secondaryContainer = gold;

  static Color withValues({
    required Color color,
    double? alpha,
  }) {
    if (alpha == null) return color;
    return color.withValues(alpha: alpha);
  }
}

class AppMetrics {
  static const double smallPillHeight = 30.0;
  static const double pillHeight = 40.0;
  static const double panelRadius = 22.0;
  static const double sheetRadius = 22.0;
  static const double wheelSize = 304.0;
  static const double gridGap = 12.0;
  static const double boosterSize = 52.0;
}

class AppText {
  static FontWeight? _resolveWeight(dynamic weight, {FontWeight fallback = FontWeight.w500}) {
    if (weight is FontWeight) return weight;
    if (weight is int) {
      switch (weight) {
        case 100:
          return FontWeight.w100;
        case 200:
          return FontWeight.w200;
        case 300:
          return FontWeight.w300;
        case 400:
          return FontWeight.w400;
        case 500:
          return FontWeight.w500;
        case 600:
          return FontWeight.w600;
        case 700:
          return FontWeight.w700;
        case 800:
          return FontWeight.w800;
        case 900:
          return FontWeight.w900;
      }
    }
    return fallback;
  }

  static TextStyle quicksand(
    double size, {
    Color? color,
    dynamic weight,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Quicksand',
      fontSize: size,
      color: color ?? AppColors.cream,
      fontWeight: _resolveWeight(weight, fallback: FontWeight.w500),
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextStyle label(
    double size, {
    Color? color,
    dynamic weight,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: size,
      color: color ?? AppColors.cream,
      fontWeight: _resolveWeight(weight, fallback: FontWeight.w600),
      letterSpacing: letterSpacing,
      height: height,
    );
  }
}

ThemeData buildWordnestTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.teal,
    brightness: Brightness.dark,
    surface: AppColors.ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.ink,
    fontFamily: 'PlusJakartaSans',
  );
}