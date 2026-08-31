import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:google_fonts/google_fonts.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/providers/settings_provider.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money.dart';
import '../../../auth/auth_provider.dart';
import '../../../products/providers/products_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../../../core/widgets/app_loading.dart';
import '../widgets/kpi_card.dart';

class DashboardHomeTab extends ConsumerWidget {
  const DashboardHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final auth = ref.watch(authNotifierProvider);
    final displayName = ref.watch(displayNameProvider);
    final avatarPath = ref.watch(avatarPathProvider);
    final name = displayName ?? auth.user?.username ?? 'Shop';
    final filter = ref.watch(dashboardFilterProvider);
    final summaryAsync = ref.watch(dashboardSummaryProvider);

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
              strings: strings,
              onPeriod: (p) =>
                  ref.read(dashboardFilterProvider.notifier).setPeriod(p),
              onPickMonth: () => _pickMonth(context, ref, filter),
            ),
            const SizedBox(height: 22),
            Text(
              _getOverviewTitle(filter, strings),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            summaryAsync.when(
              loading: () => const _KpiSkeleton(),
              error: (e, _) => _ErrorBanner(
                message: '$e',
                strings: strings,
                onRetry: () => refreshDashboard(ref),
              ),
              data: (s) => _KpiGrid(summary: s, strings: strings, filter: filter),
            ),
            const SizedBox(height: 22),
            Text(strings.stockByCategory, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            summaryAsync.when(
              loading: () => const _CategorySkeleton(),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) => _CategoryStockList(items: s.categoryQuantities, strings: strings),
            ),
            const SizedBox(height: 26),
            Text(strings.quickActions, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 14),
            _QuickActions(strings: strings),
          ],
        ),
      ),
    );
  }

  String _getOverviewTitle(DashboardFilter filter, AppStrings strings) {
    switch (filter.period) {
      case DashboardPeriod.today:
        return strings.todayOverview;
      case DashboardPeriod.week:
        return strings.thisWeek;
      case DashboardPeriod.month:
        return strings.thisMonth;
      case DashboardPeriod.custom:
        final m = filter.customMonth;
        final y = filter.customYear;
        if (m != null && y != null && m >= 1 && m <= 12) {
          final monthName = strings.shortMonthNames[m - 1];
          return '$monthName $y';
        }
        return strings.range;
    }
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
    final strings = ref.read(appStringsProvider);
    final now = DateTime.now();
    var month = filter.customMonth ?? now.month;
    var year = filter.customYear ?? now.year;

    final picked = await showDialog<({int month, int year})>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocal) {
            return AlertDialog(
              title: Text(strings.pickMonth),
              content: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: month,
                      decoration: InputDecoration(labelText: strings.monthLabel),
                      items: List.generate(12, (i) {
                        return DropdownMenuItem(
                          value: i + 1,
                          child: Text(strings.monthNames[i]),
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
                      decoration: InputDecoration(labelText: strings.yearLabel),
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
                  child: Text(strings.cancel),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, (month: month, year: year)),
                  child: Text(strings.apply),
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
    required this.strings,
    required this.onPeriod,
    required this.onPickMonth,
  });

  final DashboardFilter filter;
  final AppStrings strings;
  final ValueChanged<DashboardPeriod> onPeriod;
  final VoidCallback onPickMonth;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final customActive = filter.period == DashboardPeriod.custom;

    String customLabel = strings.pickMonth;
    if (customActive && filter.customMonth != null && filter.customYear != null) {
      final m = filter.customMonth!;
      final y = filter.customYear!;
      if (m >= 1 && m <= 12) {
        customLabel = '${strings.shortMonthNames[m - 1]} $y';
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _PeriodChip(
            label: strings.today,
            selected: filter.period == DashboardPeriod.today,
            onTap: () => onPeriod(DashboardPeriod.today),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: strings.week,
            selected: filter.period == DashboardPeriod.week,
            onTap: () => onPeriod(DashboardPeriod.week),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: strings.month,
            selected: filter.period == DashboardPeriod.month,
            onTap: () => onPeriod(DashboardPeriod.month),
          ),
          const SizedBox(width: 8),
          _PeriodChip(
            label: customLabel,
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

class _KpiGrid extends ConsumerWidget {
  const _KpiGrid({
    required this.summary,
    required this.strings,
    required this.filter,
  });

  final DashboardSummary summary;
  final AppStrings strings;
  final DashboardFilter filter;

  void _openSoldItems(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SoldItemsSheet(filter: filter),
    );
  }

  void _openLowStock(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _LowStockSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: [
        KpiCard(
          title: strings.revenue,
          value: formatDAAmount(summary.revenue),
          icon: Icons.point_of_sale_outlined,
          onTap: () => GoRouter.of(context).go(AppRouteNames.homeHistoryPath),
        ),
        KpiCard(
          title: strings.netProfit,
          value: formatDAAmount(summary.netProfit),
          icon: Icons.trending_up_rounded,
          onTap: () => GoRouter.of(context).go(AppRouteNames.homeHistoryPath),
        ),
        KpiCard(
          title: strings.itemsSold,
          value: '${summary.itemsSold}',
          icon: Icons.shopping_bag_outlined,
          onTap: () => _openSoldItems(context, ref),
        ),
        KpiCard(
          title: strings.lowStock,
          value: '${summary.lowStockCount}',
          icon: Icons.warning_amber_rounded,
          highlight: summary.lowStockCount > 0,
          onTap: () => _openLowStock(context, ref),
        ),
        KpiCard(
          title: strings.totalExpenses,
          value: formatDAAmount(summary.expenses),
          icon: Icons.receipt_long_outlined,
          highlight: summary.expenses > 0,
          onTap: () => context.push(AppRouteNames.expensesPath),
        ),
        KpiCard(
          title: strings.customerDebts,
          value: formatDAAmount(summary.totalUnpaidDebtDA),
          icon: Icons.pending_actions_rounded,
          highlight: summary.totalUnpaidDebtDA > 0,
          onTap: () => context.push(AppRouteNames.debtsPath),
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
        6,
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

// ─── Sold Items Detail Bottom Sheet ──────────────────────────────────────────

class _SoldItemsSheet extends ConsumerWidget {
  const _SoldItemsSheet({required this.filter});

  final DashboardFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final query = DashboardQuery(
      period: filter.period,
      month: filter.customMonth,
      year: filter.customYear,
    );

    final soldItemsFuture = ref.watch(dashboardServiceProvider).getSoldItems(query);

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : const Color(0xFF2A2319),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isLight ? AppColors.gray200 : AppColors.gray700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.soldItemsBreakdown,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isLight ? AppColors.dark : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<List<SoldItemDetail>>(
              future: soldItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: AppLoading(size: 50));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final items = snapshot.data ?? [];
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 48, color: isLight ? AppColors.gray300 : AppColors.gray700),
                        const SizedBox(height: 12),
                        Text(
                          strings.noSoldItems,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLight ? AppColors.gray500 : AppColors.gray400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final totalQty = items.fold<int>(0, (s, i) => s + i.quantitySold);
                final totalRev = items.fold<int>(0, (s, i) => s + i.totalRevenue);

                return ListView(
                  children: [
                    // Summary sub-header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isLight ? AppColors.gray100 : AppColors.gray800,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$totalQty ${strings.itemsCount}',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          Text(
                            formatDAAmount(totalRev),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.success),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...items.map((item) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isLight ? AppColors.white : AppColors.gray900,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isLight ? AppColors.gray200 : AppColors.gray800),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.checkroom_outlined, size: 20, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${item.categoryName} • ${formatDAAmount(item.averagePrice)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLight ? AppColors.gray500 : AppColors.gray400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'x ${item.quantitySold}',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatDAAmount(item.totalRevenue),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Low Stock Items Bottom Sheet ────────────────────────────────────────────

class _LowStockSheet extends ConsumerWidget {
  const _LowStockSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final productsState = ref.watch(productsListProvider);

    // Filter low stock products (qty <= 5)
    final lowStockItems = productsState.items.where((p) => p.isLowStock).toList();

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : const Color(0xFF2A2319),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 32),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isLight ? AppColors.gray200 : AppColors.gray700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  strings.lowStockItems,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isLight ? AppColors.dark : Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: lowStockItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success),
                        const SizedBox(height: 12),
                        Text(
                          strings.allInStock,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isLight ? AppColors.gray600 : AppColors.gray300,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    children: lowStockItems.map((prod) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isLight ? AppColors.white : AppColors.gray900,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.inventory_2_outlined, color: AppColors.warning, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prod.name,
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${prod.categoryName} • ${formatDAAmount(prod.sellingPrice)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isLight ? AppColors.gray500 : AppColors.gray400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: prod.quantity == 0
                                        ? AppColors.danger.withValues(alpha: 0.12)
                                        : AppColors.warning.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    prod.quantity == 0
                                        ? (strings.isFrench ? 'Épuisé' : 'Out of stock')
                                        : '${prod.quantity} ${strings.isFrench ? "restants" : "left"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: prod.quantity == 0 ? AppColors.danger : AppColors.warning,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () {
                                Navigator.pop(context);
                                context.push(AppRouteNames.productEditPath(prod.id));
                              },
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CategoryStockList extends StatelessWidget {
  const _CategoryStockList({required this.items, required this.strings});

  final List<CategoryQuantity> items;
  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;

    if (items.isEmpty) {
      return Text(
        strings.noCategories,
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
  const _ErrorBanner({
    required this.message,
    required this.onRetry,
    required this.strings,
  });

  final String message;
  final VoidCallback onRetry;
  final AppStrings strings;

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
          Text(
            strings.couldNotLoadDashboard,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(message),
          const SizedBox(height: 10),
          TextButton(onPressed: onRetry, child: Text(strings.retry)),
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
  const _QuickActions({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final actions = [
      (
        label: strings.newSale,
        icon: Icons.add_shopping_cart_rounded,
        onTap: () => GoRouter.of(context).go(AppRouteNames.homeCartPath),
      ),
      (
        label: strings.myExpenses,
        icon: Icons.account_balance_wallet_outlined,
        onTap: () => context.push(AppRouteNames.expensesPath),
      ),
      (
        label: strings.customerDebts,
        icon: Icons.pending_actions_rounded,
        onTap: () => context.push(AppRouteNames.debtsPath),
      ),
      (
        label: strings.navProducts,
        icon: Icons.inventory_2_outlined,
        onTap: () => GoRouter.of(context).go(AppRouteNames.homeProductsPath),
      ),
      (
        label: strings.navHistory,
        icon: Icons.receipt_long_outlined,
        onTap: () => GoRouter.of(context).go(AppRouteNames.homeHistoryPath),
      ),
    ];
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 12,
      childAspectRatio: 0.9,
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
