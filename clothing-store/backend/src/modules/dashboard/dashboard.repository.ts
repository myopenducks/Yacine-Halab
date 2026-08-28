import { sql } from 'drizzle-orm';
import type { MySql2Database } from 'drizzle-orm/mysql2';
import {
  and,
  between,
  count,
  desc,
  eq,
  gte,
  lte,
  sum,
} from 'drizzle-orm';
import * as schema from '../../db';
import { products } from '../../db/schema/products';
import { categories } from '../../db/schema/categories';
import { sales } from '../../db/schema/sales';
import { saleItems } from '../../db/schema/sale-items';
import { SaleRepository } from '../sales/sale.repository';

export type DashboardPeriod = 'today' | 'week' | 'month' | 'custom';

export interface DashboardSummary {
  period: DashboardPeriod;
  from: string;
  to: string;
  salesCount: number;
  itemsSold: number;
  revenue: number;
  profit: number;
  lowStockCount: number;
  unpaidDebtCount: number;
  totalUnpaidDebtDA: number;
  categoryQuantities: Array<{
    categoryId: number;
    name: string;
    quantity: number;
  }>;
}

export interface DashboardSalesBucket {
  label: string;
  revenue: number;
  profit: number;
  count: number;
}

const LOW_STOCK_THRESHOLD = 5;

function startOfToday(): Date {
  const d = new Date();
  d.setHours(0, 0, 0, 0);
  return d;
}

function endOfDay(d: Date): Date {
  const copy = new Date(d);
  copy.setHours(23, 59, 59, 999);
  return copy;
}

function startOfWeek(d: Date): Date {
  const copy = new Date(d);
  const day = copy.getDay();
  const diff = (day + 6) % 7;
  copy.setDate(copy.getDate() - diff);
  copy.setHours(0, 0, 0, 0);
  return copy;
}

function startOfMonth(d: Date): Date {
  return new Date(d.getFullYear(), d.getMonth(), 1);
}

function endOfMonth(d: Date): Date {
  return endOfDay(new Date(d.getFullYear(), d.getMonth() + 1, 0));
}

export interface ResolvedRange {
  from: Date;
  to: Date;
}

export function resolvePeriodRange(args: {
  period: DashboardPeriod;
  month?: number;
  year?: number;
  from?: Date;
  to?: Date;
}): ResolvedRange {
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
  constructor(
    private readonly db: MySql2Database<typeof schema>,
    private readonly saleRepo: SaleRepository,
  ) {}

  private buildDateWhere(from: Date, to: Date) {
    return between(sales.createdAt, from, to);
  }

  async getLowStockCount(userId: number): Promise<number> {
    const rows = await this.db
      .select({ value: count(products.id) })
      .from(products)
      .where(and(lte(products.quantity, LOW_STOCK_THRESHOLD), eq(products.userId, userId)));
    return Number(rows[0]?.value ?? 0);
  }

  async getDebts(userId: number): Promise<{ unpaidDebtCount: number; totalUnpaidDebtDA: number }> {
    return this.saleRepo.aggregateDebts(userId);
  }

  async getCategoryQuantities(userId: number): Promise<
    Array<{ categoryId: number; name: string; quantity: number }>
  > {
    const rows = await this.db
      .select({
        categoryId: categories.id,
        name: categories.name,
        quantity: sql<number>`COALESCE(SUM(${products.quantity}), 0)`,
      })
      .from(categories)
      .leftJoin(products, and(eq(products.categoryId, categories.id), eq(products.userId, userId)))
      .where(eq(categories.userId, userId))
      .groupBy(categories.id)
      .orderBy(desc(categories.id));
    return rows.map((r) => ({
      categoryId: r.categoryId,
      name: r.name,
      quantity: Number(r.quantity ?? 0),
    }));
  }

  async getSummary(range: ResolvedRange, userId: number): Promise<{
    salesCount: number;
    itemsSold: number;
    revenue: number;
    profit: number;
  }> {
    return this.saleRepo.aggregateForPeriod({ from: range.from, to: range.to, userId });
  }

  async getBuckets(
    range: ResolvedRange,
    period: DashboardPeriod,
    userId: number,
    month?: number,
    year?: number,
  ): Promise<DashboardSalesBucket[]> {
    const buckets = await this.saleRepo.aggregateBuckets({
      from: range.from,
      to: range.to,
      userId,
      bucketExpr: (col) => {
        if (period === 'today') {
          // Hour of day 0..23 → HOUR(col)
          return sql<number>`LPAD(CAST(HOUR(${col}) AS CHAR), 2, '0')`;
        }
        if (period === 'week') {
          // Mon..Sun: WEEKDAY(col), then map to label
          return sql<number>`DATE_FORMAT(${col}, '%a')`;
        }
        if (period === 'month') {
          return sql<number>`DAYOFMONTH(${col})`;
        }
        // custom: with explicit month+year → day of month; otherwise fall back to YYYY-MM-DD
        if (period === 'custom' && month != null && year != null) {
          return sql<number>`DAYOFMONTH(${col})`;
        }
        return sql<string>`DATE_FORMAT(${col}, '%Y-%m-%d')`;
      },
    });
    return buckets;
  }
}
