import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/sales_history_provider.dart';
import 'widgets/sale_tile.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 240) {
      ref.read(salesListProvider.notifier).loadMore();
    }
  }

  Future<void> _pickCustomRange() async {
    final filters = ref.read(salesFiltersProvider);
    final now = DateTime.now();
    var from = filters.customFrom ?? now.subtract(const Duration(days: 7));
    var to = filters.customTo ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: DateTimeRange(start: from, end: to),
    );
    if (picked == null) return;
    ref.read(salesFiltersProvider.notifier).setCustomRange(
          picked.start,
          picked.end,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final filters = ref.watch(salesFiltersProvider);
    final list = ref.watch(salesListProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Sales history', style: theme.textTheme.headlineSmall),
        actions: [
          if (list.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '${list.total}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isLight ? AppColors.gray500 : AppColors.gray400,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: 'All',
                  selected: filters.preset == SalesDatePreset.all,
                  onTap: () => ref
                      .read(salesFiltersProvider.notifier)
                      .setPreset(SalesDatePreset.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Today',
                  selected: filters.preset == SalesDatePreset.today,
                  onTap: () => ref
                      .read(salesFiltersProvider.notifier)
                      .setPreset(SalesDatePreset.today),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Week',
                  selected: filters.preset == SalesDatePreset.week,
                  onTap: () => ref
                      .read(salesFiltersProvider.notifier)
                      .setPreset(SalesDatePreset.week),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Month',
                  selected: filters.preset == SalesDatePreset.month,
                  onTap: () => ref
                      .read(salesFiltersProvider.notifier)
                      .setPreset(SalesDatePreset.month),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filters.preset == SalesDatePreset.custom
                      ? _customLabel(filters)
                      : 'Range',
                  selected: filters.preset == SalesDatePreset.custom,
                  icon: Icons.date_range_outlined,
                  onTap: _pickCustomRange,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Debts',
                  selected: filters.debtOnly,
                  icon: Icons.money_off_csred_outlined,
                  onTap: () => ref
                      .read(salesFiltersProvider.notifier)
                      .toggleDebtOnly(),
                  accentColor: AppColors.debtRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(salesListProvider.notifier).refresh(),
              child: _buildList(list, isLight, theme),
            ),
          ),
        ],
      ),
    );
  }

  String _customLabel(SalesFilters filters) {
    if (filters.customFrom == null || filters.customTo == null) {
      return 'Range';
    }
    final fmt = DateFormat('d/M');
    return '${fmt.format(filters.customFrom!)}–${fmt.format(filters.customTo!)}';
  }

  Widget _buildList(SalesListState list, bool isLight, ThemeData theme) {
    if (list.isLoading && list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (list.error != null && list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
        children: [
          _EmptyState(
            icon: Icons.wifi_off_rounded,
            title: 'Could not load sales',
            subtitle: list.error!,
            isLight: isLight,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(salesListProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      );
    }

    if (list.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
        children: [
          _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No sales yet',
            subtitle: 'Completed sales will show up here.',
            isLight: isLight,
          ),
        ],
      );
    }

    return ListView.separated(
      controller: _scrollCtrl,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
      itemCount: list.items.length + (list.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= list.items.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          );
        }
        final sale = list.items[index];
        return SaleTile(
          sale: sale,
          onTap: () => context.push(AppRouteNames.saleDetailPath(sale.id)),
        );
      },
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.accentColor,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final Color bg;
    final Color fg;

    if (accentColor != null && selected) {
      bg = accentColor!.withValues(alpha: 0.15);
      fg = accentColor!;
    } else {
      bg = selected
          ? AppColors.chipSelectedBg(brightness)
          : AppColors.chipUnselectedBg(brightness);
      fg = selected
          ? AppColors.chipSelectedFg(brightness)
          : AppColors.chipUnselectedFg(brightness);
    }
    final border = accentColor != null && selected
        ? accentColor!.withValues(alpha: 0.3)
        : AppColors.chipBorder(brightness);

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
              color: selected && accentColor == null
                  ? Colors.transparent
                  : border,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isLight,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isLight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : AppColors.gray900,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isLight ? AppColors.gray200 : AppColors.gray800,
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 40,
            color: isLight ? AppColors.black : AppColors.white,
          ),
          const SizedBox(height: 14),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isLight ? AppColors.gray500 : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }
}
