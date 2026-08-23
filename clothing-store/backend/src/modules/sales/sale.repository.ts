import type { MySql2Database } from 'drizzle-orm/mysql2';
import {
  and,
  asc,
  between,
  count,
  desc,
  eq,
  gte,
  inArray,
  lte,
  sql,
  sum,
} from 'drizzle-orm';
import * as schema from '../../db';
import { sales } from '../../db/schema/sales';
import { saleItems } from '../../db/schema/sale-items';
import { products } from '../../db/schema/products';
import type { Sale } from '../../db/schema/sales';
import type { SaleItem } from '../../db/schema/sale-items';
import {
  computeOffset,
  type PaginationParams,
} from '../../shared/pagination';
import type {
  SaleDetail,
  SaleHeader,
  SaleItemDetail,
  SaleListQuery,
} from './sale.schema';

export class SaleRepository {
  constructor(private readonly db: MySql2Database<typeof schema>) {}

  private buildDateRangeWhere(from?: Date, to?: Date) {
    if (from != null && to != null) return between(sales.createdAt, from, to);
    if (from != null) return gte(sales.createdAt, from);
    if (to != null) return lte(sales.createdAt, to);
    return undefined;
  }

  async list(
    pagination: PaginationParams,
    filters: Pick<SaleListQuery, 'from' | 'to'>,
  ): Promise<{ items: SaleHeader[]; total: number }> {
    const dateWhere = this.buildDateRangeWhere(filters.from, filters.to);
    const offset = computeOffset(pagination);

    const itemsBase = this.db
      .select({
        id: sales.id,
        totalAmount: sales.totalAmount,
        paidAmount: sales.paidAmount,
        createdAt: sales.createdAt,
      })
      .from(sales);

    const itemsQuery = itemsBase
      .orderBy(desc(sales.id))
      .limit(pagination.limit)
      .offset(offset);

    const countQuery = this.db
      .select({ value: count(sales.id) })
      .from(sales);

    if (dateWhere) {
      itemsQuery.where(dateWhere);
      countQuery.where(dateWhere);
    }

    const [rows, countRows] = await Promise.all([itemsQuery, countQuery]);
    const saleIds = rows.map((r) => r.id);

    const itemCounts =
      saleIds.length > 0
        ? await this.db
            .select({
              saleId: saleItems.saleId,
              itemCount: count(saleItems.id),
            })
            .from(saleItems)
            .where(inArray(saleItems.saleId, saleIds))
            .groupBy(saleItems.saleId)
        : [];

    const countMap = new Map<number, number>();
    for (const r of itemCounts) countMap.set(r.saleId, Number(r.itemCount));

    const items: SaleHeader[] = rows.map((r) => {
      const itemCount = countMap.get(r.id) ?? 0;
      return {
        id: r.id,
        totalAmount: r.totalAmount,
        paidAmount: r.paidAmount,
        remainingAmount: r.totalAmount - r.paidAmount,
        itemCount,
        createdAt: r.createdAt,
      };
    });

    const total = Number(countRows[0]?.value ?? 0);
    return { items, total };
  }

  async findById(id: number): Promise<SaleDetail | null> {
    return this.findByIdOn(this.db, id);
  }

  /** Read-only variant usable inside an ongoing transaction (reads tx-scoped, uncommitted rows). */
  async findByIdOn(
    scope: MySql2Database<typeof schema>,
    id: number,
  ): Promise<SaleDetail | null> {
    const headers = await scope
      .select({
        id: sales.id,
        totalAmount: sales.totalAmount,
        paidAmount: sales.paidAmount,
        createdAt: sales.createdAt,
      })
      .from(sales)
      .where(eq(sales.id, id))
      .limit(1);
    if (headers.length === 0) return null;
    const h = headers[0];

    const itemRows = await scope
      .select({
        id: saleItems.id,
        productId: saleItems.productId,
        productName: products.name,
        quantity: saleItems.quantity,
        unitPrice: saleItems.unitPrice,
        purchasePrice: saleItems.purchasePrice,
      })
      .from(saleItems)
      .innerJoin(products, eq(saleItems.productId, products.id))
      .where(eq(saleItems.saleId, id))
      .orderBy(asc(saleItems.id));

    const items: SaleItemDetail[] = itemRows.map((it) => ({
      id: it.id,
      productId: it.productId,
      productName: it.productName,
      quantity: it.quantity,
      unitPrice: it.unitPrice,
      purchasePrice: it.purchasePrice,
      lineTotal: it.unitPrice * it.quantity,
    }));

    return {
      id: h.id,
      totalAmount: h.totalAmount,
      paidAmount: h.paidAmount,
      remainingAmount: h.totalAmount - h.paidAmount,
      createdAt: h.createdAt,
      items,
    };
  }

  /**
   * Lock product rows for sale creation. Uses `FOR UPDATE` inside a transaction to block
   * concurrent sale mutations that could oversell.
   */
  async lockProductsByIds(
    tx: MySql2Database<typeof schema>,
    productIds: number[],
  ): Promise<
    Array<{
      id: number;
      name: string;
      quantity: number;
      sellingPrice: number;
      purchasePrice: number;
    }>
  > {
    if (productIds.length === 0) return [];
    const rows = await tx
      .select({
        id: products.id,
        name: products.name,
        quantity: products.quantity,
        sellingPrice: products.sellingPrice,
        purchasePrice: products.purchasePrice,
      })
      .from(products)
      .where(inArray(products.id, productIds))
      .for('update');
    return rows;
  }

  async insertSale(
    tx: MySql2Database<typeof schema>,
    data: { totalAmount: number; paidAmount: number },
  ): Promise<number> {
    const result = await tx.insert(sales).values(data);
    return Number(result[0].insertId);
  }

  async bulkInsertSaleItems(
    tx: MySql2Database<typeof schema>,
    items: Array<Omit<SaleItem, 'id' | 'createdAt'>>,
  ): Promise<void> {
    if (items.length === 0) return;
    await tx.insert(saleItems).values(items);
  }

  async bulkUpdateProductQuantities(
    tx: MySql2Database<typeof schema>,
    updates: Array<{ id: number; quantity: number }>,
  ): Promise<void> {
    if (updates.length === 0) return;
    await Promise.all(
      updates.map((u) =>
        tx.update(products).set({ quantity: u.quantity }).where(eq(products.id, u.id)),
      ),
    );
  }

  /**
   * Shared helpers for dashboard (kept here since they read sales/sale_items).
   */

  async aggregateForPeriod(args: {
    from?: Date;
    to?: Date;
  }): Promise<{
    salesCount: number;
    itemsSold: number;
    revenue: number;
    profit: number;
  }> {
    const dateWhere = this.buildDateRangeWhere(args.from, args.to);

    const salesCountPromise = (async () => {
      const q = this.db.select({ value: count(sales.id) }).from(sales);
      if (dateWhere) q.where(dateWhere);
      const r = await q;
      return Number(r[0]?.value ?? 0);
    })();

    const totalsPromise = (async () => {
      const q = this.db
        .select({
          qty: sum(saleItems.quantity),
          revenue: sum(sql<number>`${saleItems.quantity} * ${saleItems.unitPrice}`),
          cost: sum(sql<number>`${saleItems.quantity} * ${saleItems.purchasePrice}`),
        })
        .from(saleItems)
        .innerJoin(sales, eq(saleItems.saleId, sales.id));
      if (dateWhere) q.where(dateWhere);
      const r = await q;
      const row = r[0];
      const itemsSold = Number(row?.qty ?? 0);
      const revenue = Number(row?.revenue ?? 0);
      const cost = Number(row?.cost ?? 0);
      return { itemsSold, revenue, profit: revenue - cost };
    })();

    const [salesCount, totals] = await Promise.all([salesCountPromise, totalsPromise]);
    return { salesCount, ...totals };
  }

  async aggregateBuckets(args: {
    from: Date;
    to: Date;
    bucketExpr: (col: typeof sales.createdAt) => any;
  }): Promise<Array<{ label: string; revenue: number; profit: number; count: number }>> {
    const { from, to, bucketExpr } = args;
    const dateWhere = between(sales.createdAt, from, to);
    const labelCol = bucketExpr(sales.createdAt);
    const rows = await this.db
      .select({
        label: labelCol,
        revenue: sum(sql<number>`${saleItems.quantity} * ${saleItems.unitPrice}`),
        profit: sum(
          sql<number>`${saleItems.quantity} * (${saleItems.unitPrice} - ${saleItems.purchasePrice})`,
        ),
        count: count(sales.id),
      })
      .from(saleItems)
      .innerJoin(sales, eq(saleItems.saleId, sales.id))
      .where(dateWhere)
      .groupBy(labelCol)
      .orderBy(labelCol);

    return rows.map((r) => ({
      label: String(r.label),
      revenue: Number(r.revenue ?? 0),
      profit: Number(r.profit ?? 0),
      count: Number(r.count ?? 0),
    }));
  }

  async transaction<T>(fn: (tx: MySql2Database<typeof schema>) => Promise<T>): Promise<T> {
    return this.db.transaction(fn);
  }

  // Kept for backward-compat helper (not used by service currently)
  async findSaleHeaderById(id: number): Promise<Sale | null> {
    const rows = await this.db.select().from(sales).where(eq(sales.id, id)).limit(1);
    return rows[0] ?? null;
  }
}
