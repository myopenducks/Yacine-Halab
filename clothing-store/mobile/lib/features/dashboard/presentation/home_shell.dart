import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class HomeShell extends StatelessWidget {
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
      badge: true,
    ),
    TabConfig(
      label: 'History',
      icon: Icons.receipt_long_outlined,
      activeIcon: Icons.receipt_long,
      location: '/history',
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLight = theme.brightness == Brightness.light;
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
          destinations: tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon),
                    selectedIcon: Icon(t.activeIcon),
                    label: t.label,
                  ))
              .toList(growable: false),
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
    this.badge = false,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String location;
  final bool badge;
}
