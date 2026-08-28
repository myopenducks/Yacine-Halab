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

    const [periodAgg, lowStockCount, debts, categoryQuantities, expenses] =
      await Promise.all([
        this.repo.getSummary(range, userId),
        this.repo.getLowStockCount(userId),
        this.repo.getDebts(userId),
        this.repo.getCategoryQuantities(userId),
        this.repo.getExpenses(range, userId),
      ]);

    const netRevenue = Math.max(0, periodAgg.revenue - expenses);
    const netProfit = periodAgg.profit - expenses;

    return {
      period: query.period,
      from: range.from.toISOString(),
      to: range.to.toISOString(),
      salesCount: periodAgg.salesCount,
      itemsSold: periodAgg.itemsSold,
      revenue: periodAgg.revenue,
      profit: periodAgg.profit,
      expenses,
      netRevenue,
      netProfit,
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

  async soldItems(query: SummaryQuery, userId: number) {
    const range = resolvePeriodRange({
      period: query.period,
      month: query.month,
      year: query.year,
      from: query.from,
      to: query.to,
    });

    const items = await this.repo.getSoldItems(range, userId);
    return {
      period: query.period,
      from: range.from.toISOString(),
      to: range.to.toISOString(),
      items,
    };
  }
}
