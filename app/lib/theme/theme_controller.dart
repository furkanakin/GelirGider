import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'evimiz.theme_mode';

/// Persisted theme preference: system / light / dark.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getString(_kThemeKey);
    state = switch (v) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kThemeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>(
  (_) => ThemeController(),
);
