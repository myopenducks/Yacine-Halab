import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/dashboard/providers/dashboard_provider.dart';
import '../../features/products/providers/products_provider.dart';
import '../../features/sales/providers/sales_history_provider.dart';

/// Call after a sale/payment from a [ConsumerWidget] or [ConsumerStatefulWidget].
void refreshAfterInventoryChange(WidgetRef ref) {
  ref.read(productsListProvider.notifier).refresh();
  ref.read(salesListProvider.notifier).refresh();
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(dashboardChartProvider);
  ref.invalidate(debtBadgeCountProvider);
}

/// Call after a sale/payment from inside a [Notifier] or provider callback.
void refreshAfterInventoryChangeFromNotifier(Ref ref) {
  ref.read(productsListProvider.notifier).refresh();
  ref.read(salesListProvider.notifier).refresh();
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(dashboardChartProvider);
  ref.invalidate(debtBadgeCountProvider);
}
