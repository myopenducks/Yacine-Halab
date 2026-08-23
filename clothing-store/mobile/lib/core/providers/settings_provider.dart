import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeMode = 'settings.theme_mode';
const _kDisplayName = 'settings.display_name';
const _kAvatarPath = 'settings.avatar_path';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.displayName,
    this.avatarPath,
  });

  final ThemeMode themeMode;
  final String? displayName;
  /// Absolute file path to the user's chosen avatar image.
  final String? avatarPath;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? displayName,
    bool clearDisplayName = false,
    String? avatarPath,
    bool clearAvatarPath = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      displayName: clearDisplayName ? null : (displayName ?? this.displayName),
      avatarPath: clearAvatarPath ? null : (avatarPath ?? this.avatarPath),
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
    return AppSettings(
      themeMode: _parseThemeMode(modeRaw),
      displayName: displayName?.trim().isEmpty == true ? null : displayName,
      avatarPath: avatarPath?.trim().isEmpty == true ? null : avatarPath,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final current = state.value ?? const AppSettings();
    state = AsyncData(current.copyWith(themeMode: mode));
    await _prefs?.setString(_kThemeMode, mode.name);
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

  /// Saves the given [filePath] as the avatar. Replaces any previous one.
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

/// Shop-owner display name shown in profile / dashboard greeting.
final displayNameProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).value?.displayName;
});

/// Current avatar file path (null = use initials).
final avatarPathProvider = Provider<String?>((ref) {
  return ref.watch(settingsProvider).value?.avatarPath;
});
