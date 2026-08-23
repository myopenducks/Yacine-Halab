import { sql } from 'drizzle-orm';
import { between, count, desc, eq, lte, } from 'drizzle-orm';
import { products } from '../../db/schema/products';
import { categories } from '../../db/schema/categories';
import { sales } from '../../db/schema/sales';
const LOW_STOCK_THRESHOLD = 5;
function startOfToday() {
    const d = new Date();
    d.setHours(0, 0, 0, 0);
    return d;
}
function endOfDay(d) {
    const copy = new Date(d);
    copy.setHours(23, 59, 59, 999);
    return copy;
}
function startOfWeek(d) {
    const copy = new Date(d);
    const day = copy.getDay();
    const diff = (day + 6) % 7;
    copy.setDate(copy.getDate() - diff);
    copy.setHours(0, 0, 0, 0);
    return copy;
}
function startOfMonth(d) {
    return new Date(d.getFullYear(), d.getMonth(), 1);
}
function endOfMonth(d) {
    return endOfDay(new Date(d.getFullYear(), d.getMonth() + 1, 0));
}
export function resolvePeriodRange(args) {
    const now = new Date();
    switch (args.period) {
        case 'today': {
            return { from: startOfToday(), to: endOfDay(new Date()) };
        }
        case 'week': {
            return { from: startOfWeek(now), to: endOfDay(new Date()) };
        }
        case 'month': {
            return { from: startOfMonth(now), to: endOfDay(new Date()) };
        }
        case 'custom': {
            if (args.month != null && args.year != null) {
                const base = new Date(args.year, args.month - 1, 1);
                return { from: startOfMonth(base), to: endOfMonth(base) };
            }
            if (args.from != null || args.to != null) {
                const from = args.from ?? startOfToday();
                const to = args.to ?? endOfDay(new Date());
                return { from, to };
            }
            return { from: startOfToday(), to: endOfDay(new Date()) };
        }
    }
}
export class DashboardRepository {
    db;
    saleRepo;
    constructor(db, saleRepo) {
        this.db = db;
        this.saleRepo = saleRepo;
    }
    buildDateWhere(from, to) {
        return between(sales.createdAt, from, to);
    }
    async getLowStockCount() {
        const rows = await this.db
            .select({ value: count(products.id) })
            .from(products)
            .where(lte(products.quantity, LOW_STOCK_THRESHOLD));
        return Number(rows[0]?.value ?? 0);
    }
    async getCategoryQuantities() {
        const rows = await this.db
            .select({
            categoryId: categories.id,
            name: categories.name,
            quantity: sql `COALESCE(SUM(${products.quantity}), 0)`,
        })
            .from(categories)
            .leftJoin(products, eq(products.categoryId, categories.id))
            .groupBy(categories.id)
            .orderBy(desc(categories.id));
        return rows.map((r) => ({
            categoryId: r.categoryId,
            name: r.name,
            quantity: Number(r.quantity ?? 0),
        }));
    }
    async getSummary(range) {
        return this.saleRepo.aggregateForPeriod({ from: range.from, to: range.to });
    }
    async getBuckets(range, period, month, year) {
        const buckets = await this.saleRepo.aggregateBuckets({
            from: range.from,
            to: range.to,
            bucketExpr: (col) => {
                if (period === 'today') {
                    // Hour of day 0..23 → HOUR(col)
                    return sql `LPAD(CAST(HOUR(${col}) AS CHAR), 2, '0')`;
                }
                if (period === 'week') {
                    // Mon..Sun: WEEKDAY(col), then map to label
                    return sql `DATE_FORMAT(${col}, '%a')`;
                }
                if (period === 'month') {
                    return sql `DAYOFMONTH(${col})`;
                }
                // custom: with explicit month+year → day of month; otherwise fall back to YYYY-MM-DD
                if (period === 'custom' && month != null && year != null) {
                    return sql `DAYOFMONTH(${col})`;
                }
                return sql `DATE_FORMAT(${col}, '%Y-%m-%d')`;
            },
        });
        return buckets;
    }
}
//# sourceMappingURL=dashboard.repository.js.map