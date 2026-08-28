import type { MySql2Database } from 'drizzle-orm/mysql2';
import { and, desc, eq, gte, lte, sql, count, like, or } from 'drizzle-orm';
import * as schema from '../../db';
import { expenses, type Expense, type NewExpense } from '../../db/schema/expenses';
import type { ExpenseQueryDto } from './expense.schema';

export class ExpenseRepository {
  constructor(private readonly db: MySql2Database<typeof schema>) {}

  async create(values: NewExpense): Promise<Expense> {
    const [result] = await this.db.insert(expenses).values(values);
    const [row] = await this.db
      .select()
      .from(expenses)
      .where(and(eq(expenses.id, result.insertId), eq(expenses.userId, values.userId)))
      .limit(1);
    return row!;
  }

  async findById(id: number, userId: number): Promise<Expense | null> {
    const [row] = await this.db
      .select()
      .from(expenses)
      .where(and(eq(expenses.id, id), eq(expenses.userId, userId)))
      .limit(1);
    return row ?? null;
  }

  async update(id: number, userId: number, patch: Partial<NewExpense>): Promise<Expense | null> {
    await this.db
      .update(expenses)
      .set(patch)
      .where(and(eq(expenses.id, id), eq(expenses.userId, userId)));
    return this.findById(id, userId);
  }

  async delete(id: number, userId: number): Promise<boolean> {
    const [result] = await this.db
      .delete(expenses)
      .where(and(eq(expenses.id, id), eq(expenses.userId, userId)));
    return (result.affectedRows ?? 0) > 0;
  }

  async list(query: ExpenseQueryDto, userId: number): Promise<{ items: Expense[]; total: number }> {
    const conditions = [eq(expenses.userId, userId)];

    if (query.from) {
      conditions.push(gte(expenses.expenseDate, new Date(query.from)));
    }
    if (query.to) {
      conditions.push(lte(expenses.expenseDate, new Date(query.to)));
    }
    if (query.category) {
      conditions.push(eq(expenses.category, query.category));
    }
    if (query.search && query.search.trim().length > 0) {
      const s = `%${query.search.trim()}%`;
      conditions.push(
        or(
          like(expenses.title, s),
          like(expenses.recipientName, s),
          like(expenses.notes, s),
        )!,
      );
    }

    const where = and(...conditions);
    const offset = (query.page - 1) * query.limit;

    const [items, [totalRow]] = await Promise.all([
      this.db
        .select()
        .from(expenses)
        .where(where)
        .orderBy(desc(expenses.expenseDate), desc(expenses.id))
        .limit(query.limit)
        .offset(offset),
      this.db.select({ value: count(expenses.id) }).from(expenses).where(where),
    ]);

    return {
      items,
      total: Number(totalRow?.value ?? 0),
    };
  }

  async aggregateForPeriod(
    period: { from: Date; to: Date; userId: number },
  ): Promise<{ totalExpensesDA: number; count: number }> {
    const [row] = await this.db
      .select({
        total: sql<number>`COALESCE(SUM(${expenses.amount}), 0)`,
        count: count(expenses.id),
      })
      .from(expenses)
      .where(
        and(
          eq(expenses.userId, period.userId),
          gte(expenses.expenseDate, period.from),
          lte(expenses.expenseDate, period.to),
        ),
      );

    return {
      totalExpensesDA: Number(row?.total ?? 0),
      count: Number(row?.count ?? 0),
    };
  }

  async aggregateByCategory(
    period: { from?: Date; to?: Date; userId: number },
  ): Promise<Array<{ category: string; totalDA: number; count: number }>> {
    const conditions = [eq(expenses.userId, period.userId)];
    if (period.from) conditions.push(gte(expenses.expenseDate, period.from));
    if (period.to) conditions.push(lte(expenses.expenseDate, period.to));

    const rows = await this.db
      .select({
        category: expenses.category,
        totalDA: sql<number>`COALESCE(SUM(${expenses.amount}), 0)`,
        count: count(expenses.id),
      })
      .from(expenses)
      .where(and(...conditions))
      .groupBy(expenses.category)
      .orderBy(desc(sql`SUM(${expenses.amount})`));

    return rows.map((r) => ({
      category: r.category,
      totalDA: Number(r.totalDA ?? 0),
      count: Number(r.count ?? 0),
    }));
  }
}
