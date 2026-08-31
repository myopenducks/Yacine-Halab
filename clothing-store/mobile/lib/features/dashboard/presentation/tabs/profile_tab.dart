import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_branding.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../auth/auth_provider.dart';
import '../../../products/providers/products_provider.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  Future<void> _editDisplayName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final strings = ref.read(appStringsProvider);
    final ctrl = TextEditingController(text: current);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final saved = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: isLight ? AppColors.white : AppColors.cardDark,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.displayName,
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: strings.yourName,
                    helperText: strings.displayNameHelper,
                    filled: true,
                    fillColor: isLight ? AppColors.gray100 : AppColors.gray900,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isLight ? AppColors.gray200 : AppColors.gray800,
                      ),
                    ),
                  ),
                  onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(strings.cancel, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
                          child: Text(strings.save, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    ctrl.dispose();
    if (saved == null || !context.mounted) return;
    await ref.read(settingsProvider.notifier).setDisplayName(saved);
    if (context.mounted) {
      showAppSnackBar(context, strings.nameUpdated, kind: AppSnackKind.success);
    }
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
    final strings = ref.read(appStringsProvider);
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;
    await ref.read(settingsProvider.notifier).setAvatarPath(picked.path);
    if (context.mounted) {
      showAppSnackBar(context, strings.photoUpdated, kind: AppSnackKind.success);
    }
  }

  void _openThemeSheet(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    final current =
        ref.read(settingsProvider).value?.themeMode ?? ThemeMode.system;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  strings.theme,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              _ThemeOptionTile(
                label: strings.systemDefault,
                selected: current == ThemeMode.system,
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              _ThemeOptionTile(
                label: strings.light,
                selected: current == ThemeMode.light,
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              _ThemeOptionTile(
                label: strings.dark,
                selected: current == ThemeMode.dark,
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _openLanguageSheet(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    final current = ref.read(localeProvider);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(
                  strings.language,
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              _ThemeOptionTile(
                label: 'Français 🇫🇷',
                selected: current.languageCode == 'fr',
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setLocale(const Locale('fr'));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              _ThemeOptionTile(
                label: 'English 🇬🇧',
                selected: current.languageCode == 'en',
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setLocale(const Locale('en'));
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final uri = Uri.parse('https://wa.me/213549256794');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnackBar(context, 'WhatsApp: 0549256794', kind: AppSnackKind.info);
      }
    }
  }

  void _openAbout(BuildContext context, WidgetRef ref) {
    final strings = ref.read(appStringsProvider);
    showAboutDialog(
      context: context,
      applicationName: 'Boutique Store',
      applicationVersion: '0.1.0',
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.checkroom_rounded,
          color: AppColors.onPrimary,
          size: 26,
        ),
      ),
      children: [
        const SizedBox(height: 8),
        Text(strings.aboutDescription),
        const SizedBox(height: 16),
        const DevelopedByZiadFooter(),
      ],
    );
  }

  void _goToProducts(WidgetRef ref, {bool lowStock = false}) {
    final filters = ref.read(productFiltersProvider.notifier);
    if (lowStock) {
      filters.setLowStockOnly(true);
    } else {
      filters.clear();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final strings = ref.watch(appStringsProvider);
    final isLight = theme.brightness == Brightness.light;
    final auth = ref.watch(authNotifierProvider);
    final user = auth.user;
    final displayName = ref.watch(displayNameProvider);
    final avatarPath = ref.watch(avatarPathProvider);
    final shownName = displayName ?? user?.username ?? strings.profile;
    final loginName = user?.username;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(strings.profile, style: theme.textTheme.headlineSmall),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          // ── Avatar + name card ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isLight ? AppColors.white : AppColors.gray900,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isLight ? AppColors.border : AppColors.gray800,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () => _changeAvatar(context, ref),
                  child: Stack(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isLight ? AppColors.primary : AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                          image: avatarPath != null
                              ? DecorationImage(
                                  image: FileImage(File(avatarPath)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: avatarPath == null
                            ? Text(
                                _initials(shownName),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: isLight
                                      ? AppColors.onPrimary
                                      : AppColors.dark,
                                ),
                              )
                            : null,
                      ),
                      // Camera badge
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isLight
                                ? AppColors.primary
                                : AppColors.accent,
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color:
                                  isLight ? AppColors.white : AppColors.gray900,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shownName, style: theme.textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(
                        loginName != null
                            ? '${strings.loginLabel}$loginName'
                            : strings.signedOutStatus,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isLight
                              ? AppColors.gray500
                              : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editDisplayName(context, ref, shownName),
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: isLight ? AppColors.gray500 : AppColors.gray400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          _SectionTitle(label: strings.store, isLight: isLight),
          const SizedBox(height: 10),
          _TileRow(
            label: strings.productsInventory,
            subtitle: strings.browseAndManageStock,
            icon: Icons.storefront_outlined,
            isDivider: true,
            onTap: () {
              _goToProducts(ref);
              context.go(AppRouteNames.homeProductsPath);
            },
          ),
          _TileRow(
            label: strings.lowStockAlerts,
            subtitle: strings.itemsRunningLow,
            icon: Icons.notifications_outlined,
            onTap: () {
              _goToProducts(ref, lowStock: true);
              context.go(AppRouteNames.homeProductsPath);
            },
          ),
          const SizedBox(height: 22),
          _SectionTitle(label: strings.appSection, isLight: isLight),
          const SizedBox(height: 10),
          _TileRow(
            label: strings.language,
            subtitle: ref.watch(localeProvider).languageCode == 'fr'
                ? strings.french
                : strings.english,
            icon: Icons.language_rounded,
            isDivider: true,
            onTap: () => _openLanguageSheet(context, ref),
          ),
          _TileRow(
            label: strings.theme,
            subtitle: strings.themeSubtitle,
            icon: Icons.dark_mode_outlined,
            isDivider: true,
            onTap: () => _openThemeSheet(context, ref),
          ),
          _TileRow(
            label: 'WhatsApp Direct',
            subtitle: '0549256794 (Support & Contact)',
            icon: Icons.chat_bubble_outline_rounded,
            isDivider: true,
            onTap: () => _launchWhatsApp(context),
          ),
          _TileRow(
            label: strings.about,
            subtitle: strings.appInfo,
            icon: Icons.info_outline,
            onTap: () => _openAbout(context, ref),
          ),
          const SizedBox(height: 16),
          const Center(child: DevelopedByZiadFooter()),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                ref.read(authNotifierProvider.notifier).logout();
              },
              icon: const Icon(Icons.logout_outlined),
              label: Text(strings.signOut),
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: selected ? const Icon(Icons.check_rounded) : null,
      onTap: onTap,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label, required this.isLight});

  final String label;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: isLight ? AppColors.gray500 : AppColors.gray400,
      ),
    );
  }
}

class _TileRow extends StatelessWidget {
  const _TileRow({
    required this.label,
    required this.icon,
    required this.onTap,
    this.subtitle,
    this.isDivider = false,
  });

  final String label;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    Widget tile = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : AppColors.gray900,
            borderRadius: BorderRadius.vertical(
              top: isDivider ? const Radius.circular(18) : Radius.zero,
              bottom: isDivider ? Radius.zero : const Radius.circular(18),
            ),
            border: Border.all(
              color: isLight ? AppColors.gray200 : AppColors.gray800,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isLight ? AppColors.gray100 : AppColors.gray800,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isLight ? AppColors.secondary : AppColors.onDark,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: isLight ? AppColors.gray500 : AppColors.gray400,
              ),
            ],
          ),
        ),
      ),
    );

    if (!isDivider) return tile;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        tile,
        Container(
          height: 1.2,
          color: isLight ? AppColors.gray200 : AppColors.gray800,
          margin: const EdgeInsets.only(left: 68, right: 4),
        ),
      ],
    );
  }
}
