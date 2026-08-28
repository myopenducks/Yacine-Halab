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

  async summary(query: SummaryQuery, userId: number): Promise<SummaryResponse> {
    const range = resolvePeriodRange({
      period: query.period,
      month: query.month,
      year: query.year,
      from: query.from,
      to: query.to,
    });

    const [periodAgg, lowStockCount, debts, categoryQuantities] =
      await Promise.all([
        this.repo.getSummary(range, userId),
        this.repo.getLowStockCount(userId),
        this.repo.getDebts(userId),
        this.repo.getCategoryQuantities(userId),
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

  async salesChart(query: SalesQuery, userId: number): Promise<SalesChartResponse> {
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
      userId,
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
