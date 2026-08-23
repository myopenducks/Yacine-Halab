import 'package:flutter/material.dart';

/// Centralized boutique palette using the tailored brand colors:
/// - Warm Alabaster: #FFFCF2
/// - Pale Silver / Border: #CCC5B9
/// - Dark Slate / Charcoal: #403D39
/// - Deep Espresso / Jet: #252422
/// - Vibrant Tangerine / Flame: #EB5E28
class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFFFFCF2); // Warm alabaster
  static const Color dark = Color(0xFF252422);         // Deep espresso/jet
  static const Color secondary = Color(0xFF403D39);    // Dark slate charcoal
  static const Color accent = Color(0xFFEB5E28);       // Flame tangerine
  static const Color primary = Color(0xFFEB5E28);      // Primary brand accent
  static const Color sandTaupe = Color(0xFFCCC5B9);    // Pale silver taupe
  static const Color terracotta = Color(0xFFEB5E28);   // Flame accent

  // ── Extended palette ────────────────────────────────────────────
  static const Color skyBlue = Color(0xFF403D39);
  static const Color softBlue = Color(0xFFCCC5B9);
  static const Color warmLinen = Color(0xFFFFFCF2);

  // ── Semantic surfaces ──────────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF2E2C2A);
  static const Color inputFill = Color(0xFFF9F7F0);
  static const Color inputFillDark = Color(0xFF33312F);

  // ── Semantic text ──────────────────────────────────────────────
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onDark = Color(0xFFFFFCF2);
  static const Color textMuted = Color(0xFF7D7871);
  static const Color textMutedDark = Color(0xFFCCC5B9);

  // ── Borders & dividers ─────────────────────────────────────────
  static const Color border = Color(0xFFCCC5B9);
  static const Color borderDark = Color(0xFF403D39);
  static const Color divider = Color(0xFFE6DFD5);
  static const Color dividerDark = Color(0xFF403D39);

  // ── Functional ─────────────────────────────────────────────────
  static const Color danger = Color(0xFFD94F4F);
  static const Color debtRed = Color(0xFFE63946);
  static const Color warning = Color(0xFFE76F51);
  static const Color success = Color(0xFF2A9D8F);

  // ── Aliases ───────────────────────────────────────────────────
  static const Color black = dark;
  static const Color white = card;
  static const Color gray900 = dark;
  static const Color gray800 = Color(0xFF33312F);
  static const Color gray700 = Color(0xFF403D39);
  static const Color gray600 = Color(0xFF6B655E);
  static const Color gray500 = textMuted;
  static const Color gray400 = Color(0xFF9E978E);
  static const Color gray300 = border;
  static const Color gray200 = divider;
  static const Color gray100 = Color(0xFFF2ECE1);
  static const Color gray050 = surfaceLight;
  static const Color star = warning;

  /// Selected filter chips, quick-action tiles, chart bars.
  static Color chipSelectedBg(Brightness brightness) =>
      brightness == Brightness.light ? primary : accent;

  static Color chipSelectedFg(Brightness brightness) =>
      brightness == Brightness.light ? onPrimary : onDark;

  static Color chipUnselectedBg(Brightness brightness) =>
      brightness == Brightness.light ? card : cardDark;

  static Color chipUnselectedFg(Brightness brightness) =>
      brightness == Brightness.light ? secondary : onDark;

  static Color chipBorder(Brightness brightness) =>
      brightness == Brightness.light ? border : borderDark;

  static Color iconOnSurface(Brightness brightness) =>
      brightness == Brightness.light ? dark : onDark;

  static Color iconMuted(Brightness brightness) =>
      brightness == Brightness.light ? textMuted : textMutedDark;
}
