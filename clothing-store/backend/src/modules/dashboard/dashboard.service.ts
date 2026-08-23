import {
  DashboardRepository,
  resolvePeriodRange,
} from './dashboard.repository';
import type {
  SalesQuery,
  SalesChartResponse,
  SummaryQuery,
  SummaryResponse,
} from './dashboard.schema';

export class DashboardService {
  constructor(private readonly repo: DashboardRepository) {}

  async summary(query: SummaryQuery): Promise<SummaryResponse> {
    const range = resolvePeriodRange({
      period: query.period,
      month: query.month,
      year: query.year,
      from: query.from,
      to: query.to,
    });

    const [periodAgg, lowStockCount, debts, categoryQuantities] =
      await Promise.all([
        this.repo.getSummary(range),
        this.repo.getLowStockCount(),
        this.repo.getDebts(),
        this.repo.getCategoryQuantities(),
      ]);

    return {
      period: query.period,
      from: range.from.toISOString(),
      to: range.to.toISOString(),
      salesCount: periodAgg.salesCount,
      itemsSold: periodAgg.itemsSold,
      revenue: periodAgg.revenue,
      profit: periodAgg.profit,
      lowStockCount,
      unpaidDebtCount: debts.unpaidDebtCount,
      totalUnpaidDebtDA: debts.totalUnpaidDebtDA,
      categoryQuantities,
    };
  }

  async salesChart(query: SalesQuery): Promise<SalesChartResponse> {
    const range = resolvePeriodRange({
      period: query.period,
      month: query.month,
      year: query.year,
      from: query.from,
      to: query.to,
    });

    const buckets = await this.repo.getBuckets(
      range,
      query.period,
      query.month,
      query.year,
    );

    return {
      period: query.period,
      from: range.from.toISOString(),
      to: range.to.toISOString(),
      buckets,
    };
  }
}
