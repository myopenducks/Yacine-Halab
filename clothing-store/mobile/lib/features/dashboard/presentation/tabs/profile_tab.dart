import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

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
    final ctrl = TextEditingController(text: current);
    final saved = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Display name'),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'Your name',
              helperText: 'Shown in the app. Login username stays the same.',
            ),
            onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    if (saved == null || !context.mounted) return;
    await ref.read(settingsProvider.notifier).setDisplayName(saved);
    if (context.mounted) {
      showAppSnackBar(context, 'Name updated', kind: AppSnackKind.success);
    }
  }

  Future<void> _changeAvatar(BuildContext context, WidgetRef ref) async {
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
      showAppSnackBar(context, 'Photo updated', kind: AppSnackKind.success);
    }
  }

  void _openThemeSheet(BuildContext context, WidgetRef ref) {
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
                  'Theme',
                  style: Theme.of(ctx).textTheme.titleMedium,
                ),
              ),
              _ThemeOptionTile(
                label: 'System default',
                selected: current == ThemeMode.system,
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.system);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              _ThemeOptionTile(
                label: 'Light',
                selected: current == ThemeMode.light,
                onTap: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
              _ThemeOptionTile(
                label: 'Dark',
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

  void _openAbout(BuildContext context) {
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
        child: const Text(
          'BS',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: AppColors.onPrimary,
          ),
        ),
      ),
      children: const [
        SizedBox(height: 8),
        Text(
          'Inventory and sales management for a small clothing shop.',
        ),
        SizedBox(height: 16),
        DevelopedByZiadFooter(),
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
    final isLight = theme.brightness == Brightness.light;
    final auth = ref.watch(authNotifierProvider);
    final user = auth.user;
    final displayName = ref.watch(displayNameProvider);
    final avatarPath = ref.watch(avatarPathProvider);
    final shownName = displayName ?? user?.username ?? 'User';
    final loginName = user?.username;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Profile', style: theme.textTheme.headlineSmall),
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
                color: isLight ? AppColors.gray200 : AppColors.gray800,
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
                                ? AppColors.skyBlue
                                : AppColors.softBlue,
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
                            ? 'Login: $loginName'
                            : 'Signed out',
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
          _SectionTitle(label: 'Store', isLight: isLight),
          const SizedBox(height: 10),
          _TileRow(
            label: 'Products inventory',
            subtitle: 'Browse and manage stock',
            icon: Icons.storefront_outlined,
            isDivider: true,
            onTap: () {
              _goToProducts(ref);
              context.go(AppRouteNames.homeProductsPath);
            },
          ),
          _TileRow(
            label: 'Low stock alerts',
            subtitle: 'Items running low',
            icon: Icons.notifications_outlined,
            onTap: () {
              _goToProducts(ref, lowStock: true);
              context.go(AppRouteNames.homeProductsPath);
            },
          ),
          const SizedBox(height: 22),
          _SectionTitle(label: 'App', isLight: isLight),
          const SizedBox(height: 10),
          _TileRow(
            label: 'Theme',
            subtitle: 'Light, dark, or system',
            icon: Icons.dark_mode_outlined,
            isDivider: true,
            onTap: () => _openThemeSheet(context, ref),
          ),
          _TileRow(
            label: 'About',
            subtitle: 'App info',
            icon: Icons.info_outline,
            onTap: () => _openAbout(context),
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
              label: const Text('Sign Out'),
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
