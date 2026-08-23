import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/settings_provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/auth_provider.dart';
import '../../models/dashboard.dart';
import '../../providers/dashboard_provider.dart';
import '../widgets/kpi_card.dart';
import '../widgets/sales_bar_chart.dart';

class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final auth = ref.watch(authNotifierProvider);
    final displayName = ref.watch(displayNameProvider);
    final avatarPath = ref.watch(avatarPathProvider);
    final name = displayName ?? auth.user?.username ?? 'Shop';
    final filter = ref.watch(dashboardFilterProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final chartAsync = ref.watch(dashboardChartProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => context.go(AppRouteNames.homeProfilePath),
              child: _Avatar(
                size: 42,
                text: _initials(name),
                imagePath: avatarPath,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, Welcome 👋',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isLight ? AppColors.gray500 : AppColors.gray400,
                    ),
                  ),
                  Text(name, style: theme.textTheme.titleLarge),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => refreshDashboard(ref),
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor: isLight ? AppColors.gray100 : AppColors.gray800,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              fixedSize: const Size(44, 44),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => refreshDashboard(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _PeriodToggle(
              filter: filter,
              onPeriod: (p) =>
                  ref.read(dashboardFilterProvider.notifier).setPeriod(p),
              onPickMonth: () => _pickMonth(context, ref, filter),
            ),
            const SizedBox(height: 22),
            Text(filter.overviewTitle, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            summaryAsync.when(
              loading: () => const _KpiSkeleton(),
              error: (e, _) => _ErrorBanner(
                message: '$e',
                onRetry: () => refreshDashboard(ref),
              ),
              data: (s) => _KpiGrid(summary: s),
            ),
            const SizedBox(height: 22),
            chartAsync.when(
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const SizedBox.shrink(),
              data: (chart) => SalesBarChart(
                buckets: chart.buckets,
                period: filter.period,
              ),
            ),
            const SizedBox(height: 22),
            Text('Stock by category', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const _CategorySkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) => _CategoryStockList(items: s.categoryQuantities),
            ),
            const SizedBox(height: 26),
            Text('Quick actions', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            const _QuickActions(),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'S';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  Future<void> _pickMonth(
    BuildContext context,
    WidgetRef ref,
    DashboardFilter filter,
  ) async {
    final now = DateTime.now();
    var month = filter.customMonth ?? now.month;
    var year = filter.customYear ?? now.year;

    final picked = await showDialog<({int month, int year})>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: const Text('Pick month'),
              content: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: month,
                      decoration: const InputDecoration(labelText: 'Month'),
                      items: List.generate(12, (i) {
                        const names = [
                          'January',
                          'February',
                          'March',
                          'April',
                          'May',
                          'June',
                          'July',
                          'August',
                          'September',
                          'October',
                          'November',
                          'December',
                        ];
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text(names[i]),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) setLocal(() => month = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: year,
                      decoration: const InputDecoration(labelText: 'Year'),
                      items: List.generate(6, (i) {
                        final y = now.year - 2 + i;
                        return DropdownMenuItem(
                          value: y,
                          child: Text('$y'),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) setLocal(() => year = v);
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, (month: month, year: year)),
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      ref
          .read(dashboardFilterProvider.notifier)
          .setCustomMonth(picked.month, picked.year);
    }
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.filter,
    required this.onPeriod,
    required this.onPickMonth,
  });

  final DashboardFilter filter;
  final ValueChanged<DashboardPeriod> onPeriod;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final customActive = filter.period == DashboardPeriod.custom;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _PeriodChip(
            label: 'Today',
            selected: filter.period == DashboardPeriod.today,
            onTap: () => onPeriod(DashboardPeriod.today),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'Week',
            selected: filter.period == DashboardPeriod.week,
            onTap: () => onPeriod(DashboardPeriod.week),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: 'Month',
            selected: filter.period == DashboardPeriod.month,
            onTap: () => onPeriod(DashboardPeriod.month),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: customActive ? filter.overviewTitle : 'Pick month',
            selected: customActive,
            icon: Icons.calendar_month_outlined,
            onTap: onPickMonth,
          ),
          if (customActive) ...[
            const SizedBox(width: 8),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onPickMonth,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  height: 42,
                  width: 42,
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.white : AppColors.gray800,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isLight ? AppColors.gray200 : AppColors.gray700,
                    ),
                  ),
                  child: Icon(
                    Icons.edit_calendar_outlined,
                    size: 18,
                    color: isLight ? AppColors.black : AppColors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final bg = selected
        ? AppColors.chipSelectedBg(brightness)
        : AppColors.chipUnselectedBg(brightness);
    final fg = selected
        ? AppColors.chipSelectedFg(brightness)
        : AppColors.chipUnselectedFg(brightness);
    final border = AppColors.chipBorder(brightness);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? Colors.transparent : border,
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        KpiCard(
          title: 'Sales',
          value: formatDAAmount(summary.revenue),
          icon: Icons.attach_money_rounded,
        ),
        KpiCard(
          title: 'Profit',
          value: formatDAAmount(summary.profit),
          icon: Icons.trending_up_rounded,
        ),
        KpiCard(
          title: 'Items sold',
          value: '${summary.itemsSold}',
          icon: Icons.shopping_bag_outlined,
        ),
        KpiCard(
          title: 'Low stock',
          value: '${summary.lowStockCount}',
          icon: Icons.warning_amber_rounded,
          highlight: summary.lowStockCount > 0,
        ),
      ],
    );
  }
}

class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: List.generate(
        4,
        (_) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryStockList extends StatelessWidget {
  const _CategoryStockList({required this.items});

  final List<CategoryQuantity> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (items.isEmpty) {
      return Text(
        'No categories',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: isLight ? AppColors.gray500 : AppColors.gray400,
        ),
      );
    }

    final maxQty = items.fold<int>(
      0,
      (m, c) => c.quantity > m ? c.quantity : m,
    );

    return Column(
      children: items.map((c) {
        final ratio = maxQty <= 0 ? 0.0 : c.quantity / maxQty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isLight ? AppColors.white : AppColors.gray900,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLight ? AppColors.gray200 : AppColors.gray800,
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 6,
                          backgroundColor:
                              isLight ? AppColors.gray100 : AppColors.gray800,
                          color: isLight ? AppColors.black : AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${c.quantity}',
                  style: const TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Could not load dashboard',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _CategorySkeleton extends StatelessWidget {
  const _CategorySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.size,
    required this.text,
    this.imagePath,
  });

  final double size;
  final String text;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final hasImage = imagePath != null && imagePath!.isNotEmpty && File(imagePath!).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isLight ? AppColors.primary : AppColors.accent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isLight ? AppColors.border : AppColors.borderDark,
          width: 1.5,
        ),
        image: hasImage
            ? DecorationImage(
                image: FileImage(File(imagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: hasImage
          ? null
          : Text(
              text,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.38,
                color: isLight ? AppColors.onPrimary : AppColors.dark,
              ),
            ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: 'New Sale',
        icon: Icons.point_of_sale_outlined,
        onTap: () => GoRouter.of(context).go(AppRouteNames.homeCartPath),
      ),
      (
        label: 'Products',
        icon: Icons.inventory_2_outlined,
        onTap: () => GoRouter.of(context).go(AppRouteNames.homeProductsPath),
      ),
      (
        label: 'History',
        icon: Icons.receipt_long_outlined,
        onTap: () => GoRouter.of(context).go(AppRouteNames.homeHistoryPath),
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 12,
      children: actions
          .map(
            (a) => _QuickAction(label: a.label, icon: a.icon, onTap: a.onTap),
          )
          .toList(growable: false),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: isLight ? AppColors.primary : AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: isLight ? AppColors.onPrimary : AppColors.dark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
