import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_loading.dart';
import '../models/expense.dart';
import '../providers/expenses_provider.dart';
import 'widgets/add_expense_sheet.dart';

const _kCream = Color(0xFFFBF8F1);
const _kEspresso = Color(0xFF2C1A11);
const _kEspressoLight = Color(0xFF6B5147);
const _kBorder = Color(0xFFE8DDD4);
const _kBorderDark = Color(0xFF3D342A);
const _kCardBg = Color(0xFFFFFFFF);
const _kCardDark = Color(0xFF2A2319);
const _kCopper = Color(0xFF9E5240);
const _kDebt = Color(0xFFD94F4F);

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openAddSheet([Expense? expense]) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddExpenseSheet(expenseToEdit: expense),
    );
  }

  Future<void> _confirmDelete(Expense expense) async {
    final strings = ref.read(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isLight ? AppColors.white : AppColors.cardDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _kDebt.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded, color: _kDebt, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                strings.deleteExpenseConfirm,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${expense.title} • ${formatDAAmount(expense.amount)}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: isLight ? _kEspressoLight : Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: isLight ? _kBorder : _kBorderDark, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: isLight ? _kEspresso : Colors.white,
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
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
                          backgroundColor: _kDebt,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(strings.delete, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(expenseServiceProvider).delete(expense.id);
        ref.invalidate(expensesListProvider);
        ref.invalidate(expenseSummaryProvider);
        if (mounted) {
          showAppSnackBar(context, strings.expenseDeleted, kind: AppSnackKind.success);
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(context, 'Failed: $e', kind: AppSnackKind.error);
        }
      }
    }
  }

  IconData _iconForCategory(String cat) {
    switch (cat) {
      case 'supplier':
        return Icons.local_shipping_outlined;
      case 'rent':
        return Icons.storefront_outlined;
      case 'bills':
        return Icons.receipt_long_outlined;
      case 'transport':
        return Icons.directions_car_outlined;
      case 'personal':
        return Icons.person_outline_rounded;
      default:
        return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final filters = ref.watch(expenseFiltersProvider);
    final expensesAsync = ref.watch(expensesListProvider);
    final summaryAsync = ref.watch(expenseSummaryProvider);

    final bg = isLight ? _kCream : const Color(0xFF1A1310);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isLight ? _kEspresso : Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          strings.myExpenses,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isLight ? _kEspresso : Colors.white,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                height: 38,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kCopper,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: Text(
                    strings.addExpense,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                  ),
                  onPressed: () => _openAddSheet(),
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(expensesListProvider);
          ref.invalidate(expenseSummaryProvider);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 80),
          children: [
            // ── Total Summary Banner ──────────────────────────────────
            summaryAsync.when(
              loading: () => const SizedBox(height: 100, child: Center(child: AppLoading(size: 44))),
              error: (_, __) => const SizedBox.shrink(),
              data: (summary) {
                return Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: isLight ? _kCardBg : _kCardDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                    boxShadow: [
                      BoxShadow(
                        color: _kCopper.withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.account_balance_wallet_outlined, size: 16, color: isLight ? _kEspressoLight : Colors.white70),
                          const SizedBox(width: 8),
                          Text(
                            strings.totalExpenses,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isLight ? _kEspressoLight : Colors.white70,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: _kCopper.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              '${summary.count} ${strings.isFrench ? "dépenses" : "records"}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _kCopper,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        formatDAAmount(summary.totalExpensesDA),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isLight ? _kEspresso : Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.isFrench
                            ? 'Déduit automatiquement de votre bénéfice net'
                            : 'Automatically deducted from your net income',
                        style: TextStyle(
                          fontSize: 12,
                          color: isLight ? _kEspressoLight : Colors.white60,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            // ── Search & Filter ───────────────────────────────────────
            TextField(
              controller: _searchCtrl,
              onChanged: (val) {
                ref.read(expenseFiltersProvider.notifier).state =
                    filters.copyWith(search: val.trim());
              },
              decoration: InputDecoration(
                hintText: strings.search,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(expenseFiltersProvider.notifier).state =
                              filters.copyWith(clearSearch: true);
                        },
                      )
                    : null,
                filled: true,
                fillColor: isLight ? _kCardBg : _kCardDark,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),

            const SizedBox(height: 14),

            // ── Category Filter Chips ─────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text(strings.all),
                    selected: filters.category == null,
                    selectedColor: _kCopper,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: filters.category == null ? Colors.white : (isLight ? _kEspresso : Colors.white),
                    ),
                    onSelected: (_) {
                      ref.read(expenseFiltersProvider.notifier).state =
                          filters.copyWith(clearCategory: true);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(strings.catSupplier),
                    selected: filters.category == 'supplier',
                    selectedColor: _kCopper,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: filters.category == 'supplier' ? Colors.white : (isLight ? _kEspresso : Colors.white),
                    ),
                    onSelected: (val) {
                      ref.read(expenseFiltersProvider.notifier).state =
                          filters.copyWith(category: val ? 'supplier' : null, clearCategory: !val);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(strings.catRent),
                    selected: filters.category == 'rent',
                    selectedColor: _kCopper,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: filters.category == 'rent' ? Colors.white : (isLight ? _kEspresso : Colors.white),
                    ),
                    onSelected: (val) {
                      ref.read(expenseFiltersProvider.notifier).state =
                          filters.copyWith(category: val ? 'rent' : null, clearCategory: !val);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(strings.catBills),
                    selected: filters.category == 'bills',
                    selectedColor: _kCopper,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: filters.category == 'bills' ? Colors.white : (isLight ? _kEspresso : Colors.white),
                    ),
                    onSelected: (val) {
                      ref.read(expenseFiltersProvider.notifier).state =
                          filters.copyWith(category: val ? 'bills' : null, clearCategory: !val);
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(strings.catPersonal),
                    selected: filters.category == 'personal',
                    selectedColor: _kCopper,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: filters.category == 'personal' ? Colors.white : (isLight ? _kEspresso : Colors.white),
                    ),
                    onSelected: (val) {
                      ref.read(expenseFiltersProvider.notifier).state =
                          filters.copyWith(category: val ? 'personal' : null, clearCategory: !val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ── Expenses List ─────────────────────────────────────────
            expensesAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: AppLoading(size: 56)),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text('Error: $e'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => ref.invalidate(expensesListProvider),
                        child: Text(strings.retry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(36),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isLight ? _kCardBg : _kCardDark,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 48, color: isLight ? _kBorder : _kBorderDark),
                        const SizedBox(height: 12),
                        Text(
                          strings.noExpenses,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isLight ? _kEspressoLight : Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: items.map((expense) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLight ? _kCardBg : _kCardDark,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isLight ? _kBorder : _kBorderDark),
                      ),
                      child: Row(
                        children: [
                          // Icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _kCopper.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(_iconForCategory(expense.category), color: _kCopper, size: 22),
                          ),
                          const SizedBox(width: 14),

                          // Title & Recipient
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: isLight ? _kEspresso : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    if (expense.recipientName != null && expense.recipientName!.isNotEmpty) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: (isLight ? _kEspresso : Colors.white).withValues(alpha: 0.07),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          expense.recipientName!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: isLight ? _kEspressoLight : Colors.white70,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                    Text(
                                      appDateFormat.format(expense.expenseDate.toLocal()),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isLight ? _kEspressoLight : Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Amount & Options Menu
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '- ${formatDAAmount(expense.amount)}',
                                style: const TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: _kDebt,
                                ),
                              ),
                            ],
                          ),
                          PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert_rounded, size: 20, color: isLight ? _kEspressoLight : Colors.white54),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            onSelected: (val) {
                              if (val == 'edit') {
                                _openAddSheet(expense);
                              } else if (val == 'delete') {
                                _confirmDelete(expense);
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text(strings.editExpense),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete_outline_rounded, size: 18, color: _kDebt),
                                    const SizedBox(width: 8),
                                    Text(strings.delete, style: const TextStyle(color: _kDebt)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
