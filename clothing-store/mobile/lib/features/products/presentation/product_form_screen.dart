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
      final img =
          _imageCtrl.text.trim().isEmpty ? null : _imageCtrl.text.trim();

      if (widget.isEdit) {
        await service.update(
          id: widget.productId!,
          name: name,
          categoryId: _categoryId!,
          purchasePrice: purchase,
          sellingPrice: selling,
          quantity: qty,
          imageUrl: img,
        );
      } else {
        await service.create(
          name: name,
          categoryId: _categoryId!,
          purchasePrice: purchase,
          sellingPrice: selling,
          quantity: qty,
          imageUrl: img,
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

  Future<void> _confirmDelete() async {
    final strings = ref.read(appStringsProvider);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          strings.deleteProduct,
          style: const TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          strings.deleteProductConfirm,
          style: const TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(strings.delete),
          ),
        ],
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
                  : 'Ce produit a un historique de ventes. Définissez la quantité à 0.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
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
          ? const Center(child: CircularProgressIndicator())
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
                      const SizedBox(height: 16),
                      categoriesAsync.when(
                        loading: () => const LinearProgressIndicator(),
                        error: (e, _) => Text(
                          _errMsg(e),
                          style: const TextStyle(color: AppColors.danger),
                        ),
                        data: (cats) {
                          if (cats.isEmpty) {
                            return Text(strings.noData);
                          }
                          return DropdownButtonFormField<int>(
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
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _imageCtrl,
                        keyboardType: TextInputType.url,
                        decoration: InputDecoration(
                          labelText: strings.imageUrlOptional,
                          hintText: 'https://…',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null;
                          final uri = Uri.tryParse(v.trim());
                          if (uri == null ||
                              !(uri.isScheme('http') ||
                                  uri.isScheme('https'))) {
                            return 'URL http(s) invalide';
                          }
                          return null;
                        },
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
