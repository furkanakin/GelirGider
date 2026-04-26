import 'package:flutter/material.dart';

/// Design tokens — sıcak, ev odaklı palet.
/// Kaynak: design/tokens.js
///
/// Bu sınıf `static` field'larla çalışır (const değil) ki uygulama açıkken
/// `T.applyDark()` veya `T.applyLight()` çağrıldığında tüm semantic renkler
/// runtime'da güncellenir. Brand renkler (terracotta, forest, butter, alert)
/// her iki tema için de aynı kalır.
class T {
  T._();

  // ---- Surfaces (mode-dependent) ----
  static Color cream = _LightPalette.cream;
  static Color paper = _LightPalette.paper;
  static Color paperDeep = _LightPalette.paperDeep;
  static Color surface = _LightPalette.surface;

  // ---- Ink (mode-dependent) ----
  static Color ink = _LightPalette.ink;
  static Color inkSoft = _LightPalette.inkSoft;
  static Color inkMute = _LightPalette.inkMute;
  static Color inkFaint = _LightPalette.inkFaint;

  // ---- Lines (mode-dependent) ----
  static Color line = _LightPalette.line;
  static Color lineSoft = _LightPalette.lineSoft;

  // ---- Brand (constant across modes) ----
  static const terracotta = Color(0xFFC4593C);
  static const terraDeep = Color(0xFFA4452C);
  static const terraSoft = Color(0xFFE8B5A0);
  static Color terraTint = _LightPalette.terraTint;

  static const forest = Color(0xFF3D5A4A);
  static const forestDeep = Color(0xFF2A4234);
  static const forestSoft = Color(0xFF9BB3A4);
  static Color forestTint = _LightPalette.forestTint;

  static const butter = Color(0xFFE8C77A);
  static Color butterTint = _LightPalette.butterTint;

  static const alert = Color(0xFFA4452C);
  static const ok = Color(0xFF3D5A4A);

  // ---- Shape ----
  static const rSm = 8.0;
  static const rMd = 14.0;
  static const rLg = 20.0;
  static const rXl = 28.0;
  static const rPill = 999.0;

  // ---- Shadows ----
  static List<BoxShadow> shadowSm = const [
    BoxShadow(color: Color(0x0F3C2814), blurRadius: 6, offset: Offset(0, 2)),
  ];
  static List<BoxShadow> shadowMd = const [
    BoxShadow(color: Color(0x143C2814), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static List<BoxShadow> shadowLg = const [
    BoxShadow(color: Color(0x1F3C2814), blurRadius: 60, offset: Offset(0, 24)),
  ];

  // ---- Type ----
  static const ffSerif = '-apple-system';
  static const ffSans = '-apple-system';
  static const ffMono = 'monospace';

  static bool _isDark = false;
  static bool get isDark => _isDark;

  static void applyLight() {
    _isDark = false;
    cream = _LightPalette.cream;
    paper = _LightPalette.paper;
    paperDeep = _LightPalette.paperDeep;
    surface = _LightPalette.surface;
    ink = _LightPalette.ink;
    inkSoft = _LightPalette.inkSoft;
    inkMute = _LightPalette.inkMute;
    inkFaint = _LightPalette.inkFaint;
    line = _LightPalette.line;
    lineSoft = _LightPalette.lineSoft;
    terraTint = _LightPalette.terraTint;
    forestTint = _LightPalette.forestTint;
    butterTint = _LightPalette.butterTint;
  }

  static void applyDark() {
    _isDark = true;
    cream = _DarkPalette.cream;
    paper = _DarkPalette.paper;
    paperDeep = _DarkPalette.paperDeep;
    surface = _DarkPalette.surface;
    ink = _DarkPalette.ink;
    inkSoft = _DarkPalette.inkSoft;
    inkMute = _DarkPalette.inkMute;
    inkFaint = _DarkPalette.inkFaint;
    line = _DarkPalette.line;
    lineSoft = _DarkPalette.lineSoft;
    terraTint = _DarkPalette.terraTint;
    forestTint = _DarkPalette.forestTint;
    butterTint = _DarkPalette.butterTint;
  }
}

class _LightPalette {
  static const cream = Color(0xFFFAF7F2);
  static const paper = Color(0xFFF2EDE3);
  static const paperDeep = Color(0xFFE8E0D0);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1A1A);
  static const inkSoft = Color(0xFF2B2622);
  static const inkMute = Color(0xFF7A6F65);
  static const inkFaint = Color(0xFFB5A99B);
  static const line = Color(0xFFE5DCC9);
  static const lineSoft = Color(0xFFEFE8DA);
  static const terraTint = Color(0xFFF6E4D8);
  static const forestTint = Color(0xFFDCE7DF);
  static const butterTint = Color(0xFFF6E9C0);
}

/// Warm-dark palette: kept earthy (not black) so the terracotta brand color
/// still feels at home and contrast stays comfortable for evening use.
class _DarkPalette {
  static const cream = Color(0xFF14110E);        // page background
  static const paper = Color(0xFF1F1A15);        // section header bg / inactive chip
  static const paperDeep = Color(0xFF2A231C);
  static const surface = Color(0xFF211C17);      // cards / sheet bg
  static const ink = Color(0xFFF2EDE3);          // primary text
  static const inkSoft = Color(0xFFD9CFB8);
  static const inkMute = Color(0xFF9C9180);
  static const inkFaint = Color(0xFF6E6557);
  static const line = Color(0xFF362E26);
  static const lineSoft = Color(0xFF2A231C);
  // Tints stay readable on dark surfaces — slightly desaturated.
  static const terraTint = Color(0xFF3A1F18);
  static const forestTint = Color(0xFF1F2A24);
  static const butterTint = Color(0xFF2D2516);
}
