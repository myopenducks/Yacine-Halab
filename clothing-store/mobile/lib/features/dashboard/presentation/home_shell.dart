import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../sales/providers/sales_history_provider.dart';

class HomeShell extends ConsumerWidget {
  const HomeShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<TabConfig> tabs = [
    TabConfig(
      label: 'Home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      location: '/',
    ),
    TabConfig(
      label: 'Products',
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront,
      location: '/products',
    ),
    TabConfig(
      label: 'Sale',
      icon: Icons.point_of_sale_outlined,
      activeIcon: Icons.point_of_sale,
      location: '/cart',
    ),
    TabConfig(
      label: 'History',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      location: '/history',
      hasDebtBadge: true,
    ),
    TabConfig(
      label: 'Profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      location: '/profile',
    ),
  ];

  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
    final debtCount = ref.watch(debtBadgeCountProvider);
    final hasDebt = debtCount.valueOrNull != null && debtCount.valueOrNull! > 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isLight ? AppColors.white : AppColors.gray900,
          border: Border(
            top: BorderSide(
              color: isLight ? AppColors.gray200 : AppColors.gray800,
              width: 1,
            ),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom,
          top: 8,
          left: 8,
          right: 8,
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _goToBranch,
          destinations: tabs.asMap().entries.map((entry) {
            final t = entry.value;
            final icon = t.hasDebtBadge && hasDebt
                ? Badge(
                    backgroundColor: AppColors.debtRed,
                    child: Icon(t.icon),
                  )
                : Icon(t.icon);
            final selectedIcon = t.hasDebtBadge && hasDebt
                ? Badge(
                    backgroundColor: AppColors.debtRed,
                    child: Icon(t.activeIcon),
                  )
                : Icon(t.activeIcon);
            return NavigationDestination(
              icon: icon,
              selectedIcon: selectedIcon,
              label: t.label,
            );
          }).toList(growable: false),
        ),
      ),
    );
  }
}

class TabConfig {
  const TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.location,
    this.hasDebtBadge = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String location;
  final bool hasDebtBadge;
}
