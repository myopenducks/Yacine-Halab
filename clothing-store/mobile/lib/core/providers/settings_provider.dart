import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeMode = 'settings.theme_mode';
const _kDisplayName = 'settings.display_name';
const _kAvatarPath = 'settings.avatar_path';
const _kLanguageCode = 'settings.language_code';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.displayName,
    this.avatarPath,
    this.locale = const Locale('fr'),
  });

  final ThemeMode themeMode;
  final String? displayName;
  final String? avatarPath;
  final Locale locale;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? displayName,
    bool clearDisplayName = false,
    String? avatarPath,
    bool clearAvatarPath = false,
    Locale? locale,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  SharedPreferences? _prefs;

  @override
  Future<AppSettings> build() async {
    _prefs = await SharedPreferences.getInstance();
    final modeRaw = _prefs!.getString(_kThemeMode);
    final displayName = _prefs!.getString(_kDisplayName);
    final avatarPath = _prefs!.getString(_kAvatarPath);
    final langRaw = _prefs!.getString(_kLanguageCode) ?? 'fr';
    return AppSettings(
      themeMode: _parseThemeMode(modeRaw),
      displayName: displayName?.trim().isEmpty == true ? null : displayName,
      avatarPath: avatarPath?.trim().isEmpty == true ? null : avatarPath,
      locale: Locale(langRaw),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.value ?? const AppSettings();
    state = AsyncData(current.copyWith(themeMode: mode));
    await _prefs?.setString(_kThemeMode, mode.name);
  }

  Future<void> setLocale(Locale loc) async {
    final current = state.value ?? const AppSettings();
    state = AsyncData(current.copyWith(locale: loc));
    await _prefs?.setString(_kLanguageCode, loc.languageCode);
  }

  Future<void> setDisplayName(String? name) async {
    final trimmed = name?.trim();
    final current = state.value ?? const AppSettings();
    if (trimmed == null || trimmed.isEmpty) {
      state = AsyncData(current.copyWith(clearDisplayName: true));
      await _prefs?.remove(_kDisplayName);
      return;
    }
    state = AsyncData(current.copyWith(displayName: trimmed));
    await _prefs?.setString(_kDisplayName, trimmed);
  }

  Future<void> setAvatarPath(String? filePath) async {
    final trimmed = filePath?.trim();
    final current = state.value ?? const AppSettings();
    if (trimmed == null || trimmed.isEmpty) {
      state = AsyncData(current.copyWith(clearAvatarPath: true));
      await _prefs?.remove(_kAvatarPath);
      return;
    }
    state = AsyncData(current.copyWith(avatarPath: trimmed));
    await _prefs?.setString(_kAvatarPath, trimmed);
  }

  ThemeMode _parseThemeMode(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Resolved theme mode for [MaterialApp]; falls back to system while loading.
final themeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
});

/// Resolved language locale (default: French).
final localeProvider = Provider<Locale>((ref) {
  return ref.watch(settingsProvider).value?.locale ?? const Locale('fr');
});

/// Shop-owner display name shown in profile / dashboard greeting.
final displayNameProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).value?.displayName;
});

/// Current avatar file path (null = use initials).
final avatarPathProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).value?.avatarPath;
});
