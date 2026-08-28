import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/routes/app_router.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/providers/app_refresh.dart';
import '../../../core/widgets/app_feedback.dart';
import '../models/sale.dart';
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

  Future<void> _quickEdit(SaleHeader sale) async {
    final strings = ref.read(appStringsProvider);
    final nameCtrl = TextEditingController(text: sale.customerName ?? '');
    final notesCtrl = TextEditingController(text: sale.notes ?? '');

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isLight = Theme.of(ctx).brightness == Brightness.light;
        return Container(
          decoration: BoxDecoration(
            color: isLight ? AppColors.white : AppColors.cardDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isLight ? AppColors.border : AppColors.borderDark,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, size: 24, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      '${strings.editCustomerNotes} #${sale.id}',
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: strings.customerName,
                    hintText: 'e.g. Yacine',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesCtrl,
                  maxLines: 4,
                  minLines: 3,
                  decoration: InputDecoration(
                    labelText: strings.notes,
                    hintText: 'e.g. Paid 1000 DA, remaining 6520 DA',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: isLight ? AppColors.inputFill : AppColors.inputFillDark,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(strings.cancel),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 50,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(strings.saveChanges),
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

    if (result == true && mounted) {
      try {
        await ref.read(saleServiceProvider).updateSale(
              sale.id,
              customerName: nameCtrl.text.trim().isEmpty ? null : nameCtrl.text.trim(),
              notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
            );
        ref.invalidate(saleByIdProvider(sale.id));
        ref.read(salesListProvider.notifier).refresh();
        if (mounted) {
          showAppSnackBar(context, 'Sale #${sale.id} updated', kind: AppSnackKind.success);
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(context, 'Update failed: $e', kind: AppSnackKind.error);
        }
      }
    }
  }

  Future<void> _quickMarkPaid(SaleHeader sale) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Mark Sale #${sale.id} as Finished?'),
          content: Text(
            'Remaining due is ${formatDAAmount(sale.remainingAmount)}.\nDo you want to mark this sale as fully paid?',
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: AppColors.success),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Mark as Fully Paid'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      try {
        await ref.read(saleServiceProvider).recordPayment(
              sale.id,
              sale.remainingAmount,
              note: 'Full settlement',
            );
        ref.invalidate(saleByIdProvider(sale.id));
        refreshAfterInventoryChange(ref);
        if (mounted) {
          showAppSnackBar(
            context,
            'Sale #${sale.id} marked as fully paid!',
            kind: AppSnackKind.success,
          );
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(context, 'Failed: $e', kind: AppSnackKind.error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final strings = ref.watch(appStringsProvider);
    final filters = ref.watch(salesFiltersProvider);
    final list = ref.watch(salesListProvider);
    final debtCount = ref.watch(debtBadgeCountProvider);
    final unpaidDebts = debtCount.valueOrNull ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Sales history', style: theme.textTheme.headlineSmall),
        actions: [
          if (list.total > 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLight ? AppColors.gray100 : AppColors.gray800,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${list.total} sales',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: isLight ? AppColors.secondary : AppColors.accent,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _FilterChip(
                  label: strings.all,
                  selected: filters.preset == SalesDatePreset.all && !filters.debtOnly,
                  onTap: () {
                    if (filters.debtOnly) {
                      ref.read(salesFiltersProvider.notifier).toggleDebtOnly();
                    }
                    ref.read(salesFiltersProvider.notifier).setPreset(SalesDatePreset.all);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: unpaidDebts > 0 ? '${strings.debts} ($unpaidDebts)' : strings.debts,
                  selected: filters.debtOnly,
                  onTap: () => ref.read(salesFiltersProvider.notifier).toggleDebtOnly(),
                  accentColor: AppColors.debtRed,
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: strings.today,
                  selected: filters.preset == SalesDatePreset.today && !filters.debtOnly,
                  onTap: () => ref.read(salesFiltersProvider.notifier).setPreset(SalesDatePreset.today),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: strings.week,
                  selected: filters.preset == SalesDatePreset.week && !filters.debtOnly,
                  onTap: () => ref.read(salesFiltersProvider.notifier).setPreset(SalesDatePreset.week),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: strings.month,
                  selected: filters.preset == SalesDatePreset.month && !filters.debtOnly,
                  onTap: () => ref.read(salesFiltersProvider.notifier).setPreset(SalesDatePreset.month),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: filters.preset == SalesDatePreset.custom ? _customLabel(filters) : strings.range,
                  selected: filters.preset == SalesDatePreset.custom,
                  icon: Icons.date_range_outlined,
                  onTap: _pickCustomRange,
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

  Future<void> _confirmDelete(SaleHeader sale) async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.debtRed, size: 26),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${strings.deleteSale} #${sale.id}',
                style: const TextStyle(fontFamily: AppTheme.fontFamily, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          strings.deleteSaleConfirm,
          style: const TextStyle(fontFamily: AppTheme.fontFamily, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.debtRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(strings.delete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await ref.read(salesListProvider.notifier).deleteSale(sale.id);
    if (!mounted) return;
    if (success) {
      refreshAfterInventoryChange(ref);
      showAppSnackBar(context, strings.saleDeleted, kind: AppSnackKind.success);
    } else {
      showAppSnackBar(context, 'Failed to delete sale', kind: AppSnackKind.error);
    }
  }

  Widget _buildList(SalesListState list, bool isLight, ThemeData theme) {
    final strings = ref.watch(appStringsProvider);

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
            title: strings.noData,
            subtitle: list.error!,
            isLight: isLight,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => ref.read(salesListProvider.notifier).refresh(),
            child: Text(strings.cancel),
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
            title: strings.noSalesRecorded,
            subtitle: strings.noData,
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
          onLongPress: () => _confirmDelete(sale),
          onEdit: () => _quickEdit(sale),
          onMarkPaid: sale.hasDebt ? () => _quickMarkPaid(sale) : null,
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
        ? accentColor!.withValues(alpha: 0.4)
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
              color: selected && accentColor == null ? Colors.transparent : border,
              width: selected ? 1.5 : 1.2,
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
                  fontWeight: FontWeight.w700,
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
