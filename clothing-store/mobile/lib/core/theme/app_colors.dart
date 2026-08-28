import 'package:flutter/material.dart';

/// Centralized boutique palette using the tailored brand colors:
/// - Warm Alabaster: #FFFCF2
/// - Pale Silver / Border: #CCC5B9
/// - Dark Slate / Charcoal: #403D39
/// - Deep Espresso / Jet: #252422
/// - Vibrant Tangerine / Flame: #EB5E28
class AppColors {
  AppColors._();

  // ── Brand palette (Requested Boutique Tones) ───────────────────
  // #edede9: Warm Eggshell Background
  // #d6ccc2: Soft Sand Border / Taupe
  // #f5ebe0: Soft Linen Surface / Card
  // #e3d5ca: Warm Latte Secondary Container
  // #d5bdaf: Warm Clay / Sand Accent
  static const Color surfaceLight = Color(0xFFEDEDE9); // Warm eggshell background
  static const Color dark = Color(0xFF2A2826);         // Deep warm charcoal text/dark mode
  static const Color secondary = Color(0xFF4A4541);    // Deep slate taupe
  static const Color accent = Color(0xFFC7A997);       // Warm clay accent (#d5bdaf tuned for contrast)
  static const Color primary = Color(0xFFB89680);      // Refined warm clay primary
  static const Color sandTaupe = Color(0xFFD6CCC2);    // Pale sand
  static const Color warmLinen = Color(0xFFF5EBE0);    // Soft linen cream
  static const Color warmLatte = Color(0xFFE3D5CA);    // Warm latte container

  // ── Extended palette ────────────────────────────────────────────
  static const Color skyBlue = Color(0xFF4A4541);
  static const Color softBlue = Color(0xFFD6CCC2);

  // ── Semantic surfaces ──────────────────────────────────────────
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF5EBE0);
  static const Color cardDark = Color(0xFF33302D);
  static const Color inputFill = Color(0xFFF5EBE0);
  static const Color inputFillDark = Color(0xFF3A3734);

  // ── Semantic text ──────────────────────────────────────────────
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onDark = Color(0xFFF5EBE0);
  static const Color textMuted = Color(0xFF7D756D);
  static const Color textMutedDark = Color(0xFFD6CCC2);

  // ── Borders & dividers ─────────────────────────────────────────
  static const Color border = Color(0xFFD6CCC2);
  static const Color borderDark = Color(0xFF4A4541);
  static const Color divider = Color(0xFFE3D5CA);
  static const Color dividerDark = Color(0xFF4A4541);

  // ── Functional ─────────────────────────────────────────────────
  static const Color danger = Color(0xFFD94F4F);
  static const Color debtRed = Color(0xFFE63946);
  static const Color warning = Color(0xFFD97706);
  static const Color success = Color(0xFF2A9D8F);

  // ── Aliases ───────────────────────────────────────────────────
  static const Color black = dark;
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray900 = dark;
  static const Color gray800 = Color(0xFF33302D);
  static const Color gray700 = Color(0xFF4A4541);
  static const Color gray600 = Color(0xFF6B635B);
  static const Color gray500 = textMuted;
  static const Color gray400 = Color(0xFF9E958C);
  static const Color gray300 = border;
  static const Color gray200 = divider;
  static const Color gray100 = warmLatte;
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
