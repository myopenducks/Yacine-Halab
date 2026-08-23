import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/providers.dart';
import '../models/dashboard.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(ref.watch(dioClientProvider));
});

class DashboardFilter {
  const DashboardFilter({
    this.period = DashboardPeriod.today,
    this.customMonth,
    this.customYear,
  });

  final DashboardPeriod period;
  final int? customMonth;
  final int? customYear;

  DashboardQuery get query {
    if (period == DashboardPeriod.custom) {
      final now = DateTime.now();
      return DashboardQuery(
        period: DashboardPeriod.custom,
        month: customMonth ?? now.month,
        year: customYear ?? now.year,
      );
    }
    return DashboardQuery(period: period);
  }

  String get overviewTitle {
    switch (period) {
      case DashboardPeriod.today:
        return 'Today overview';
      case DashboardPeriod.week:
        return 'This week';
      case DashboardPeriod.month:
        return 'This month';
      case DashboardPeriod.custom:
        final m = customMonth;
        final y = customYear;
        if (m != null && y != null) {
          const names = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          return '${names[m - 1]} $y';
        }
        return 'Custom period';
    }
  }

  DashboardFilter copyWith({
    DashboardPeriod? period,
    int? customMonth,
    int? customYear,
    bool clearCustom = false,
  }) {
    return DashboardFilter(
      period: period ?? this.period,
      customMonth: clearCustom ? null : (customMonth ?? this.customMonth),
      customYear: clearCustom ? null : (customYear ?? this.customYear),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is DashboardFilter &&
        other.period == period &&
        other.customMonth == customMonth &&
        other.customYear == customYear;
  }

  @override
  int get hashCode => Object.hash(period, customMonth, customYear);
}

class DashboardFilterNotifier extends Notifier<DashboardFilter> {
  @override
  DashboardFilter build() => const DashboardFilter();

  void setPeriod(DashboardPeriod period) {
    if (period == DashboardPeriod.custom) {
      final now = DateTime.now();
      state = DashboardFilter(
        period: DashboardPeriod.custom,
        customMonth: now.month,
        customYear: now.year,
      );
      return;
    }
    state = DashboardFilter(period: period);
  }

  void setCustomMonth(int month, int year) {
    state = DashboardFilter(
      period: DashboardPeriod.custom,
      customMonth: month,
      customYear: year,
    );
  }
}

final dashboardFilterProvider =
    NotifierProvider<DashboardFilterNotifier, DashboardFilter>(
  DashboardFilterNotifier.new,
);

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) {
  final filter = ref.watch(dashboardFilterProvider);
  return ref.watch(dashboardServiceProvider).getSummary(filter.query);
});

final dashboardChartProvider =
    FutureProvider.autoDispose<DashboardChart>((ref) {
  final filter = ref.watch(dashboardFilterProvider);
  return ref.watch(dashboardServiceProvider).getSalesChart(filter.query);
});

void refreshDashboard(WidgetRef ref) {
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(dashboardChartProvider);
}
