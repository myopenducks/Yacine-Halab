import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/l10n/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../models/expense.dart';
import '../../providers/expenses_provider.dart';

const _kCream = Color(0xFFFBF8F1);
const _kEspresso = Color(0xFF2C1A11);
const _kEspressoLight = Color(0xFF6B5147);
const _kBorder = Color(0xFFE8DDD4);
const _kBorderDark = Color(0xFF3D342A);
const _kCardDark = Color(0xFF2A2319);
const _kCopper = Color(0xFF9E5240);

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({super.key, this.expenseToEdit});

  final Expense? expenseToEdit;

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _selectedCategory = 'supplier';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.expenseToEdit != null) {
      final e = widget.expenseToEdit!;
      _amountCtrl.text = e.amount.toString();
      _titleCtrl.text = e.title;
      _recipientCtrl.text = e.recipientName ?? '';
      _notesCtrl.text = e.notes ?? '';
      _selectedCategory = e.category;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _titleCtrl.dispose();
    _recipientCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final strings = ref.read(appStringsProvider);
    final amount = int.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (amount == null || amount <= 0) {
      showAppSnackBar(context, strings.isFrench ? 'Veuillez saisir un montant valide' : 'Please enter a valid amount', kind: AppSnackKind.error);
      return;
    }

    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      showAppSnackBar(context, strings.isFrench ? 'Veuillez saisir un motif' : 'Please enter a title/reason', kind: AppSnackKind.error);
      return;
    }

    setState(() => _loading = true);
    try {
      if (widget.expenseToEdit != null) {
        await ref.read(expenseServiceProvider).update(
              widget.expenseToEdit!.id,
              title: title,
              recipientName: _recipientCtrl.text.trim().isEmpty ? null : _recipientCtrl.text.trim(),
              category: _selectedCategory,
              amount: amount,
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            );
        if (!mounted) return;
        ref.invalidate(expensesListProvider);
        ref.invalidate(expenseSummaryProvider);
        Navigator.pop(context, true);
        showAppSnackBar(context, strings.expenseUpdated, kind: AppSnackKind.success);
      } else {
        await ref.read(expenseServiceProvider).create(
              title: title,
              recipientName: _recipientCtrl.text.trim().isEmpty ? null : _recipientCtrl.text.trim(),
              category: _selectedCategory,
              amount: amount,
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            );
        if (!mounted) return;
        ref.invalidate(expensesListProvider);
        ref.invalidate(expenseSummaryProvider);
        Navigator.pop(context, true);
        showAppSnackBar(context, strings.expenseAdded, kind: AppSnackKind.success);
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(context, 'Error: $e', kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = ref.watch(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final isEditing = widget.expenseToEdit != null;

    final categories = [
      {'key': 'supplier', 'label': strings.catSupplier, 'icon': Icons.local_shipping_outlined},
      {'key': 'rent', 'label': strings.catRent, 'icon': Icons.storefront_outlined},
      {'key': 'bills', 'label': strings.catBills, 'icon': Icons.receipt_long_outlined},
      {'key': 'transport', 'label': strings.catTransport, 'icon': Icons.directions_car_outlined},
      {'key': 'personal', 'label': strings.catPersonal, 'icon': Icons.person_outline_rounded},
      {'key': 'other', 'label': strings.catOther, 'icon': Icons.more_horiz_rounded},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isLight ? AppColors.white : _kCardDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 22,
        right: 22,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isLight ? _kBorder : _kBorderDark,
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
                    color: _kCopper.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_outlined, color: _kCopper, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? strings.editExpense : strings.addExpense,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isLight ? _kEspresso : Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Field
            TextField(
              controller: _amountCtrl,
              autofocus: !isEditing,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _kCopper,
              ),
              decoration: InputDecoration(
                labelText: strings.amountPaid,
                hintText: 'ex: 5000',
                prefixIcon: const Icon(Icons.payments_outlined, color: _kCopper),
                suffixText: 'DA',
                suffixStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: _kCopper),
                filled: true,
                fillColor: isLight ? _kCream : Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
              ),
            ),
            const SizedBox(height: 14),

            // Title / Reason
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(
                labelText: strings.expenseTitle,
                hintText: 'ex: Achat tissu / Facture électricité',
                prefixIcon: const Icon(Icons.edit_note_rounded),
                filled: true,
                fillColor: isLight ? _kCream : Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
              ),
            ),
            const SizedBox(height: 14),

            // Recipient / Supplier name
            TextField(
              controller: _recipientCtrl,
              decoration: InputDecoration(
                labelText: strings.recipientSupplier,
                hintText: 'ex: Fournisseur Ahmed / Propriétaire',
                prefixIcon: const Icon(Icons.person_outline_rounded),
                filled: true,
                fillColor: isLight ? _kCream : Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
              ),
            ),
            const SizedBox(height: 18),

            // Category Chips
            Text(
              strings.expenseCategory,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isLight ? _kEspressoLight : Colors.white70,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat['key'];
                return ChoiceChip(
                  avatar: Icon(cat['icon'] as IconData, size: 16, color: isSelected ? Colors.white : (isLight ? _kEspressoLight : Colors.white70)),
                  label: Text(cat['label'] as String),
                  selected: isSelected,
                  selectedColor: _kCopper,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: isSelected ? Colors.white : (isLight ? _kEspresso : Colors.white),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedCategory = cat['key'] as String);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Notes Field
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: '${strings.notes} (${strings.isFrench ? "Optionnel" : "Optional"})',
                hintText: 'ex: Versement 1/2',
                prefixIcon: const Icon(Icons.description_outlined),
                filled: true,
                fillColor: isLight ? _kCream : Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: isLight ? _kBorder : _kBorderDark)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _kCopper, width: 1.6)),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: isLight ? _kBorder : _kBorderDark, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        foregroundColor: isLight ? _kEspresso : Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(strings.cancel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _kCopper,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(isEditing ? strings.saveChanges : strings.addExpense, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
