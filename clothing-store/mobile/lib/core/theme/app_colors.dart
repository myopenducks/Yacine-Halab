import 'package:flutter/material.dart';

/// Centralized boutique palette — use these tokens instead of raw hex in widgets.
class AppColors {
  AppColors._();

  // ── Brand palette ──────────────────────────────────────────────
  static const Color surfaceLight = Color(0xFFF3E3D0); // warm linen
  static const Color accent = Color(0xFFAACDDC);       // soft blue-grey
  static const Color primary = Color(0xFF4C956C);      // boutique green
  static const Color secondary = Color(0xFF2C6E49);    // deep forest green
  static const Color terracotta = Color(0xFFD68C45);   // warm amber

  // ── Extended palette ────────────────────────────────────────────
  static const Color skyBlue = Color(0xFF81A6C6);      // muted sky blue
  static const Color softBlue = Color(0xFFAACDDC);     // pale blue
  static const Color warmLinen = Color(0xFFF3E3D0);    // warm linen/background
  static const Color sandTaupe = Color(0xFFD2C4B4);    // soft taupe/muted sand

  /// Primary dark text / dark UI surfaces.
  static const Color dark = secondary;

  // ── Semantic surfaces ──────────────────────────────────────────
  static const Color card = Color(0xFFFAF6F0);
  static const Color cardDark = Color(0xFF2C6E49);
  static const Color inputFill = Color(0xFFFDF9F5);
  static const Color inputFillDark = Color(0xFF245A3C);

  // ── Semantic text ──────────────────────────────────────────────
  static const Color onPrimary = Color(0xFFF3E3D0);
  static const Color onDark = Color(0xFFF3E3D0);
  static const Color textMuted = Color(0xFF7A8C84);
  static const Color textMutedDark = Color(0xFFAACDDC);

  // ── Borders & dividers ─────────────────────────────────────────
  static const Color border = Color(0xFFD2C4B4);
  static const Color borderDark = Color(0xFF4C956C);
  static const Color divider = Color(0xFFE0D4C8);
  static const Color dividerDark = Color(0xFF3A8058);

  // ── Functional ─────────────────────────────────────────────────
  static const Color danger = Color(0xFFC45C4C);
  static const Color debtRed = Color(0xFFD94F4F);
  static const Color warning = terracotta;
  static const Color success = primary;

  // ── Legacy aliases (keeps existing widgets on-theme) ───────────
  static const Color black = dark;
  static const Color white = card;
  static const Color gray900 = dark;
  static const Color gray800 = Color(0xFF245A3C);
  static const Color gray700 = Color(0xFF3A7060);
  static const Color gray600 = Color(0xFF5A7A6C);
  static const Color gray500 = textMuted;
  static const Color gray400 = Color(0xFF9AADA4);
  static const Color gray300 = border;
  static const Color gray200 = divider;
  static const Color gray100 = Color(0xFFEDE5DC);
  static const Color gray050 = surfaceLight;
  static const Color star = warning;

  /// Selected filter chips, quick-action tiles, chart bars.
  static Color chipSelectedBg(Brightness brightness) =>
      brightness == Brightness.light ? primary : accent;

  static Color chipSelectedFg(Brightness brightness) =>
      brightness == Brightness.light ? onPrimary : dark;

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
