import 'package:flutter/material.dart';

import 'tokens.dart';

/// Light theme — must be rebuilt after `T.applyLight()` is called so the
/// constructor reads the freshest semantic colors.
ThemeData buildLightTheme() {
  T.applyLight();
  final base = ThemeData.light(useMaterial3: true);
  return _buildFrom(base, Brightness.light);
}

ThemeData buildDarkTheme() {
  T.applyDark();
  final base = ThemeData.dark(useMaterial3: true);
  return _buildFrom(base, Brightness.dark);
}

ThemeData _buildFrom(ThemeData base, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  return base.copyWith(
    brightness: brightness,
    scaffoldBackgroundColor: T.cream,
    colorScheme: ColorScheme(
      brightness: brightness,
      primary: T.terracotta,
      onPrimary: Colors.white,
      secondary: T.forest,
      onSecondary: Colors.white,
      surface: T.surface,
      onSurface: T.ink,
      error: T.alert,
      onError: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: T.cream,
      foregroundColor: T.ink,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: T.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(T.rLg)),
        side: BorderSide(color: T.line),
      ),
    ),
    dividerTheme: DividerThemeData(color: T.lineSoft, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: T.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: TextStyle(color: T.inkFaint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: BorderSide(color: T.line),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: BorderSide(color: T.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(T.rMd),
        borderSide: const BorderSide(color: T.terracotta, width: 1.5),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: T.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(color: T.ink, fontWeight: FontWeight.w600, fontSize: 18),
      contentTextStyle: TextStyle(color: T.inkSoft, fontSize: 14),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: T.cream,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: T.cream,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: T.terracotta,
      selectionColor: T.terracotta.withValues(alpha: 0.25),
      selectionHandleColor: T.terracotta,
    ),
    iconTheme: IconThemeData(color: T.inkSoft),
    textTheme: base.textTheme.apply(
      bodyColor: T.ink,
      displayColor: T.ink,
      fontFamily: T.ffSans,
    ),
    // Make Material's elevation surface tint not blow our warm palette.
    canvasColor: T.cream,
    splashColor: T.terracotta.withValues(alpha: 0.08),
    highlightColor: T.terracotta.withValues(alpha: 0.05),
  );
}

class TLText {
  TLText._();
  /// Big serif-style display number (uses Geist with tight tracking)
  static TextStyle display(double size, {Color? color, FontStyle? italic}) => TextStyle(
        fontFamily: T.ffSerif,
        fontSize: size,
        fontWeight: FontWeight.w400,
        letterSpacing: -size * 0.035,
        color: color ?? T.ink,
        fontStyle: italic ?? FontStyle.normal,
      );

  static TextStyle title(double size, {Color? color}) => TextStyle(
        fontFamily: T.ffSans,
        fontSize: size,
        fontWeight: FontWeight.w500,
        letterSpacing: -size * 0.01,
        color: color ?? T.ink,
      );

  static TextStyle label({Color? color}) => TextStyle(
        fontFamily: T.ffSans,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: color ?? T.inkMute,
      );

  static TextStyle body({Color? color, double size = 14, FontWeight? weight}) => TextStyle(
        fontFamily: T.ffSans,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w500,
        color: color ?? T.ink,
      );

  static TextStyle num({double size = 16, Color? color, FontWeight? weight}) => TextStyle(
        fontFamily: T.ffSans,
        fontSize: size,
        fontWeight: weight ?? FontWeight.w600,
        color: color ?? T.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
