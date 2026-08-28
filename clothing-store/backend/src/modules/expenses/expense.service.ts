import { AppError } from '../../shared/errors';
import { ExpenseRepository } from './expense.repository';
import type {
  CreateExpenseDto,
  ExpenseQueryDto,
  ExpenseSummaryResponse,
  PublicExpense,
  UpdateExpenseDto,
} from './expense.schema';
import type { Expense } from '../../db/schema/expenses';

function toPublic(e: Expense): PublicExpense {
  return {
    id: e.id,
    title: e.title,
    recipientName: e.recipientName,
    category: e.category,
    amount: e.amount,
    notes: e.notes,
    expenseDate: e.expenseDate.toISOString(),
    createdAt: e.createdAt.toISOString(),
    updatedAt: e.updatedAt.toISOString(),
  };
}

export class ExpenseService {
  constructor(private readonly repo: ExpenseRepository) {}

  async create(dto: CreateExpenseDto, userId: number): Promise<PublicExpense> {
    const expense = await this.repo.create({
      userId,
      title: dto.title,
      recipientName: dto.recipientName ?? null,
      category: dto.category ?? 'other',
      amount: dto.amount,
      notes: dto.notes ?? null,
      expenseDate: dto.expenseDate ? new Date(dto.expenseDate) : new Date(),
    });
    return toPublic(expense);
  }

  async getById(id: number, userId: number): Promise<PublicExpense> {
    const expense = await this.repo.findById(id, userId);
    if (!expense) {
      throw new AppError({
        code: 'EXPENSE_NOT_FOUND',
        statusCode: 404,
        message: `Expense with id ${id} not found`,
      });
    }
    return toPublic(expense);
  }

  async update(id: number, dto: UpdateExpenseDto, userId: number): Promise<PublicExpense> {
    await this.getById(id, userId);
    const updated = await this.repo.update(id, userId, {
      ...(dto.title !== undefined && { title: dto.title }),
      ...(dto.recipientName !== undefined && { recipientName: dto.recipientName }),
      ...(dto.category !== undefined && { category: dto.category }),
      ...(dto.amount !== undefined && { amount: dto.amount }),
      ...(dto.notes !== undefined && { notes: dto.notes }),
      ...(dto.expenseDate !== undefined && { expenseDate: dto.expenseDate ? new Date(dto.expenseDate) : undefined }),
    });
    return toPublic(updated!);
  }

  async delete(id: number, userId: number): Promise<void> {
    await this.getById(id, userId);
    await this.repo.delete(id, userId);
  }

  async list(
    query: ExpenseQueryDto,
    userId: number,
  ): Promise<{ items: PublicExpense[]; total: number; page: number; limit: number }> {
    const result = await this.repo.list(query, userId);
    return {
      items: result.items.map(toPublic),
      total: result.total,
      page: query.page,
      limit: query.limit,
    };
  }

  async summary(
    query: { from?: string; to?: string },
    userId: number,
  ): Promise<ExpenseSummaryResponse> {
    const from = query.from ? new Date(query.from) : undefined;
    const to = query.to ? new Date(query.to) : undefined;

    const [totalAgg, byCategory] = await Promise.all([
      this.repo.aggregateForPeriod({
        from: from ?? new Date(0),
        to: to ?? new Date(),
        userId,
      }),
      this.repo.aggregateByCategory({ from, to, userId }),
    ]);

    return {
      totalExpensesDA: totalAgg.totalExpensesDA,
      count: totalAgg.count,
      byCategory,
    };
  }
}
