import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/home_shell.dart';
import '../../features/dashboard/presentation/tabs/dashboard_tab.dart';
import '../../features/dashboard/presentation/tabs/products_tab.dart';
import '../../features/dashboard/presentation/tabs/cart_tab.dart';
import '../../features/dashboard/presentation/tabs/history_tab.dart';
import '../../features/dashboard/presentation/tabs/profile_tab.dart';
import '../../features/products/presentation/product_form_screen.dart';
import '../../features/sales/presentation/sale_detail_screen.dart';

class AppRouteNames {
  AppRouteNames._();
  static const String login = 'login';
  static const String loginPath = '/login';

  static const String home = 'home';
  static const String homePath = '/';

  static const String homeProducts = 'home.products';
  static const String homeProductsPath = '/products';

  static const String homeCart = 'home.cart';
  static const String homeCartPath = '/cart';

  static const String homeHistory = 'home.history';
  static const String homeHistoryPath = '/history';

  static const String homeProfile = 'home.profile';
  static const String homeProfilePath = '/profile';

  static const String productNew = 'product.new';
  static const String productNewPath = '/products/new';

  static const String productEdit = 'product.edit';
  static String productEditPath(int id) => '/products/$id/edit';

  static const String saleDetail = 'sale.detail';
  static String saleDetailPath(int id) => '/sales/$id';
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<AuthState>(AuthState.unknown());

  ref.listen<AuthState>(authNotifierProvider, (_, next) {
    notifier.value = next;
  });

  Future.microtask(
    () => ref.read(authNotifierProvider.notifier).bootstrap(),
  );

  return GoRouter(
    initialLocation: AppRouteNames.homePath,
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authNotifierProvider);
      if (auth.status == AuthStatus.unknown) return null;

      final loggedIn = auth.isLoggedIn;
      final onLogin = state.matchedLocation == AppRouteNames.loginPath;

      if (!loggedIn && !onLogin) return AppRouteNames.loginPath;
      if (loggedIn && onLogin) return AppRouteNames.homePath;
      return null;
    },
    routes: [
      GoRoute(
        name: AppRouteNames.login,
        path: AppRouteNames.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        name: AppRouteNames.productNew,
        path: AppRouteNames.productNewPath,
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        name: AppRouteNames.productEdit,
        path: '/products/:id/edit',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid product id')),
            );
          }
          return ProductFormScreen(productId: id);
        },
      ),
      GoRoute(
        name: AppRouteNames.saleDetail,
        path: '/sales/:id',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '');
          if (id == null) {
            return const Scaffold(
              body: Center(child: Text('Invalid sale id')),
            );
          }
          return SaleDetailScreen(saleId: id);
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            HomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouteNames.home,
                path: AppRouteNames.homePath,
                builder: (context, state) => const DashboardHomeTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouteNames.homeProducts,
                path: AppRouteNames.homeProductsPath,
                builder: (context, state) => const ProductsTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouteNames.homeCart,
                path: AppRouteNames.homeCartPath,
                builder: (context, state) => const CartTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouteNames.homeHistory,
                path: AppRouteNames.homeHistoryPath,
                builder: (context, state) => const HistoryTab(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                name: AppRouteNames.homeProfile,
                path: AppRouteNames.homeProfilePath,
                builder: (context, state) => const ProfileTab(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
