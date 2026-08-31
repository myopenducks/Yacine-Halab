import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/category_icon.dart';
import '../../models/product.dart';

class CategoryDropdownSelector extends StatelessWidget {
  const CategoryDropdownSelector({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
    required this.onAddCategory,
    this.onManageCategories,
    required this.allCategoriesLabel,
    required this.addCategoryLabel,
    this.manageCategoriesLabel,
    this.isLight = true,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onSelectCategory;
  final VoidCallback onAddCategory;
  final VoidCallback? onManageCategories;
  final String allCategoriesLabel;
  final String addCategoryLabel;
  final String? manageCategoriesLabel;
  final bool isLight;

  String get _currentLabel {
    if (selectedCategoryId == null) return allCategoriesLabel;
    final match = categories.where((c) => c.id == selectedCategoryId).firstOrNull;
    return match?.name ?? allCategoriesLabel;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isLight ? AppColors.white : AppColors.gray900;
    final borderColor = selectedCategoryId != null
        ? (isLight ? AppColors.black : AppColors.white)
        : (isLight ? AppColors.gray200 : AppColors.gray800);

    return PopupMenuButton<int?>(
      tooltip: '',
      offset: const Offset(0, 50),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      color: isLight ? AppColors.white : const Color(0xFF241D18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isLight ? AppColors.gray200 : const Color(0xFF3D342A),
          width: 1.2,
        ),
      ),
      constraints: const BoxConstraints(minWidth: 260, maxWidth: 360),
      onSelected: (val) {
        if (val == -2) {
          onAddCategory();
        } else if (val == -1 && onManageCategories != null) {
          onManageCategories!();
        } else {
          onSelectCategory(val);
        }
      },
      itemBuilder: (ctx) => [
        // "All categories" item
        PopupMenuItem<int?>(
          value: null,
          height: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selectedCategoryId == null
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.grid_view_rounded,
                  size: 18,
                  color: selectedCategoryId == null
                      ? AppColors.primary
                      : (isLight ? AppColors.gray700 : AppColors.gray300),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    allCategoriesLabel,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: selectedCategoryId == null
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selectedCategoryId == null
                          ? AppColors.primary
                          : (isLight ? AppColors.black : Colors.white),
                    ),
                  ),
                ),
                if (selectedCategoryId == null)
                  const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(height: 8),
        // Dynamic categories list
        ...categories.map((c) {
          final isSelected = selectedCategoryId == c.id;
          return PopupMenuItem<int?>(
            value: c.id,
            height: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    getCategoryIcon(c.name),
                    size: 18,
                    color: isSelected
                        ? AppColors.primary
                        : (isLight ? AppColors.gray600 : AppColors.gray400),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      c.name,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isLight ? AppColors.black : Colors.white),
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
        const PopupMenuDivider(height: 8),
        // Add Category item
        PopupMenuItem<int?>(
          value: -2,
          height: 44,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '+ $addCategoryLabel',
                    style: const TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Manage Categories item (if provided)
        if (onManageCategories != null && manageCategoriesLabel != null)
          PopupMenuItem<int?>(
            value: -1,
            height: 44,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: isLight ? AppColors.gray600 : AppColors.gray400,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      manageCategoriesLabel!,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w600,
                        color: isLight ? AppColors.gray700 : AppColors.gray300,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: selectedCategoryId != null ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selectedCategoryId == null
                  ? Icons.grid_view_rounded
                  : getCategoryIcon(_currentLabel),
              size: 17,
              color: selectedCategoryId != null
                  ? AppColors.primary
                  : (isLight ? AppColors.gray600 : AppColors.gray400),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _currentLabel,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13,
                  fontWeight: selectedCategoryId != null
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: isLight ? AppColors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: isLight ? AppColors.gray600 : AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}
