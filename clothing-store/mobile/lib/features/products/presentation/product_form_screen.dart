import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_strings.dart';
import '../../../core/network/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/app_refresh.dart';
import '../../../core/widgets/app_feedback.dart';
import '../../../core/widgets/app_loading.dart';
import '../models/product.dart';
import '../providers/products_provider.dart';

class ProductFormScreen extends ConsumerStatefulWidget {
  const ProductFormScreen({super.key, this.productId});

  final int? productId;

  bool get isEdit => productId != null;

  @override
  ConsumerState<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends ConsumerState<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _purchaseCtrl = TextEditingController();
  final _sellingCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '0');
  final _imageCtrl = TextEditingController();

  int? _categoryId;
  bool _ready = false;
  bool _saving = false;
  bool _deleting = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit) {
      Future.microtask(_loadProduct);
    } else {
      _ready = true;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purchaseCtrl.dispose();
    _sellingCtrl.dispose();
    _qtyCtrl.dispose();
    _imageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    try {
      final p =
          await ref.read(productServiceProvider).getById(widget.productId!);
      if (!mounted) return;
      _fillFrom(p);
      setState(() {
        _ready = true;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = true;
        _loadError = _errMsg(e);
      });
    }
  }

  void _fillFrom(Product p) {
    _nameCtrl.text = p.name;
    _purchaseCtrl.text = '${p.purchasePrice}';
    _sellingCtrl.text = '${p.sellingPrice}';
    _qtyCtrl.text = '${p.quantity}';
    _imageCtrl.text = p.imageUrl ?? '';
    _categoryId = p.categoryId;
  }

  Future<void> _save() async {
    final strings = ref.read(appStringsProvider);
    if (!_formKey.currentState!.validate()) return;
    if (_categoryId == null) {
      _toast(strings.selectCategory);
      return;
    }

    setState(() => _saving = true);
    try {
      final service = ref.read(productServiceProvider);
      final name = _nameCtrl.text.trim();
      final purchase = int.parse(_purchaseCtrl.text.trim());
      final selling = int.parse(_sellingCtrl.text.trim());
      final qty = int.parse(_qtyCtrl.text.trim());


      if (widget.isEdit) {
        await service.update(
          id: widget.productId!,
          name: name,
          categoryId: _categoryId!,
          purchasePrice: purchase,
          sellingPrice: selling,
          quantity: qty,
        );
      } else {
        await service.create(
          name: name,
          categoryId: _categoryId!,
          purchasePrice: purchase,
          sellingPrice: selling,
          quantity: qty,
        );
      }

      if (!mounted) return;
      refreshAfterInventoryChange(ref);
      _toast(
        strings.productSaved,
        kind: AppSnackKind.success,
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      _toast(_errMsg(e), kind: AppSnackKind.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _quickAddCategory() async {
    final strings = ref.read(appStringsProvider);
    final isLight = Theme.of(context).brightness == Brightness.light;
    final ctrl = TextEditingController();

    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isLight ? AppColors.white : AppColors.cardDark,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      strings.addCategory,
                      style: const TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: ctrl,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: strings.categoryName,
                  hintText: strings.isFrench ? 'ex: Chemises' : 'ex: Shirts',
                  filled: true,
                  fillColor: isLight ? AppColors.gray100 : AppColors.gray900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
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
                        child: Text(strings.confirm, style: const TextStyle(fontWeight: FontWeight.w700)),
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

    if (created != null && created.isNotEmpty && mounted) {
      try {
        final newCat = await ref.read(categoryServiceProvider).create(created);
        ref.invalidate(categoriesProvider);
        refreshAfterInventoryChange(ref);
        if (mounted) {
          setState(() {
            _categoryId = newCat.id;
          });
          _toast(strings.categoryCreated, kind: AppSnackKind.success);
        }
      } catch (e) {
        if (mounted) {
          _toast('Erreur lors de la création de la catégorie', kind: AppSnackKind.error);
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
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
                  color: AppColors.danger.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: AppColors.danger,
                  size: 30,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                strings.deleteProduct,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                strings.deleteProductConfirm,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14,
                  color: isLight ? AppColors.textMuted : AppColors.textMutedDark,
                  height: 1.4,
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
                          side: BorderSide(color: isLight ? AppColors.border : AppColors.borderDark, width: 1.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          foregroundColor: isLight ? AppColors.dark : AppColors.onDark,
                        ),
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(
                          strings.cancel,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          strings.delete,
                          style: const TextStyle(
                            fontFamily: AppTheme.fontFamily,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
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

    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref.read(productServiceProvider).delete(widget.productId!);
      if (!mounted) return;
      refreshAfterInventoryChange(ref);
      _toast(
        strings.productDeleted,
        kind: AppSnackKind.success,
      );
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      final code = _errCode(e);
      final msg = _errMsg(e);
      if (code == 'PRODUCT_HAS_SALES' || code == 'CONFLICT') {
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(strings.deleteProduct),
            content: Text(
              msg.isNotEmpty
                  ? msg
                  : (strings.isFrench
                      ? 'Ce produit a un historique de ventes. Définissez la quantité à 0.'
                      : 'This product has sales history. Set quantity to 0 instead.'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(strings.isFrench ? 'D\'accord' : 'OK'),
              ),
            ],
          ),
        );
      } else {
        _toast(msg);
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  String? _errCode(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).error.code;
    }
    if (e is ApiException) return e.error.code;
    return null;
  }

  String _errMsg(Object e) {
    if (e is DioException && e.error is ApiException) {
      return (e.error as ApiException).error.message;
    }
    if (e is ApiException) return e.error.message;
    if (e is NetworkException) return e.message;
    return 'Erreur de requête';
  }

  void _toast(String msg, {AppSnackKind kind = AppSnackKind.info}) {
    showAppSnackBar(context, msg, kind: kind);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final categoriesAsync = ref.watch(categoriesProvider);
    final busy = _saving || _deleting;
    final strings = ref.watch(appStringsProvider);

    return Scaffold(
      backgroundColor: isLight ? AppColors.gray050 : AppColors.black,
      appBar: AppBar(
        title: Text(widget.isEdit ? strings.editProduct : strings.addProduct),
        actions: [
          if (widget.isEdit && _ready && _loadError == null)
            IconButton(
              tooltip: strings.deleteProduct,
              onPressed: busy ? null : _confirmDelete,
              icon: _deleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, color: AppColors.danger),
            ),
        ],
      ),
      body: !_ready
          ? const Center(child: AppLoading(size: 56))
          : _loadError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_loadError!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => context.pop(),
                          child: Text(strings.cancel),
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: strings.productName,
                          hintText: 'e.g. T-Shirt Nike',
                        ),
                        onChanged: (v) {
                          if (!widget.isEdit) setState(() {});
                        },
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return strings.fillRequiredFields;
                          }
                          if (v.trim().length > 200) {
                            return 'Max 200 caractères';
                          }
                          return null;
                        },
                      ),
                      if (!widget.isEdit && _nameCtrl.text.trim().isNotEmpty)
                        Builder(
                          builder: (context) {
                            final prods = ref.watch(productsListProvider).items;
                            final query = _nameCtrl.text.toLowerCase().trim();
                            final matches = prods.where((p) => p.name.toLowerCase().contains(query)).take(5).toList();
                            
                            if (matches.isEmpty) return const SizedBox.shrink();
                            
                            // Deduplicate by name
                            final uniqueNames = <String>{};
                            final uniqueMatches = <Product>[];
                            for (final m in matches) {
                              if (uniqueNames.add(m.name.toLowerCase())) {
                                uniqueMatches.add(m);
                              }
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: uniqueMatches.map((p) => ActionChip(
                                  label: Text(p.name, style: const TextStyle(fontSize: 13)),
                                  backgroundColor: isLight ? AppColors.gray200 : AppColors.gray800,
                                  side: BorderSide.none,
                                  onPressed: () {
                                    _nameCtrl.text = p.name;
                                    _purchaseCtrl.text = '${p.purchasePrice}';
                                    _sellingCtrl.text = '${p.sellingPrice}';
                                    setState(() {
                                      _categoryId = p.categoryId;
                                    });
                                  },
                                )).toList(),
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      categoriesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          _errMsg(e),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        data: (cats) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<int>(
                                  initialValue: _categoryId,
                                  decoration: InputDecoration(
                                    labelText: strings.category,
                                  ),
                                  items: cats
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        ),
                                      )
                                      .toList(growable: false),
                                  onChanged: busy
                                      ? null
                                      : (v) => setState(() => _categoryId = v),
                                  validator: (v) =>
                                      v == null ? strings.selectCategory : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: SizedBox(
                                  height: 52,
                                  width: 52,
                                  child: IconButton.filledTonal(
                                    tooltip: strings.addCategory,
                                    icon: const Icon(Icons.add_rounded),
                                    onPressed: busy ? null : _quickAddCategory,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _purchaseCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: strings.purchasePrice,
                              ),
                              validator: _nonNegInt,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _sellingCtrl,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: strings.sellingPrice,
                              ),
                              validator: _nonNegInt,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _qtyCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          labelText: strings.quantity,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline_rounded),
                                color: isLight ? AppColors.secondary : AppColors.accent,
                                tooltip: 'Diminuer',
                                onPressed: busy
                                    ? null
                                    : () {
                                        final current =
                                            int.tryParse(_qtyCtrl.text) ?? 0;
                                        if (current > 0) {
                                          HapticFeedback.selectionClick();
                                          setState(() {
                                            _qtyCtrl.text = '${current - 1}';
                                          });
                                        }
                                      },
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded),
                                color: isLight ? AppColors.secondary : AppColors.accent,
                                tooltip: 'Augmenter',
                                onPressed: busy
                                    ? null
                                    : () {
                                        final current =
                                            int.tryParse(_qtyCtrl.text) ?? 0;
                                        HapticFeedback.selectionClick();
                                        setState(() {
                                          _qtyCtrl.text = '${current + 1}';
                                        });
                                      },
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                        validator: _nonNegInt,
                      ),

                      const SizedBox(height: 10),
                      Text(
                        strings.moneyNote,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              isLight ? AppColors.gray500 : AppColors.gray400,
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: !_ready || _loadError != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: busy ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.white,
                            ),
                          )
                        : Text(
                            strings.saveChanges,
                            style: const TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }

  String? _nonNegInt(String? v) {
    if (v == null || v.trim().isEmpty) return 'Obligatoire';
    final n = int.tryParse(v.trim());
    if (n == null) return 'Entrez un nombre entier';
    if (n < 0) return 'Doit être ≥ 0';
    return null;
  }
}
