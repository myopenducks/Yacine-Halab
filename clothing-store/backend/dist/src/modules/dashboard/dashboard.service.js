import { resolvePeriodRange, } from './dashboard.repository';
export class DashboardService {
    repo;
    constructor(repo) {
        this.repo = repo;
    }
    async summary(query) {
        const range = resolvePeriodRange({
            period: query.period,
            month: query.month,
            year: query.year,
            from: query.from,
            to: query.to,
        });
        const [periodAgg, lowStockCount, categoryQuantities] = await Promise.all([
            this.repo.getSummary(range),
            this.repo.getLowStockCount(),
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
            categoryQuantities,
        };
    }
    async salesChart(query) {
        const range = resolvePeriodRange({
            period: query.period,
            month: query.month,
            year: query.year,
            from: query.from,
            to: query.to,
        });
        const buckets = await this.repo.getBuckets(range, query.period, query.month, query.year);
        return {
            period: query.period,
            from: range.from.toISOString(),
            to: range.to.toISOString(),
            buckets,
        };
    }
}
//# sourceMappingURL=dashboard.service.js.map