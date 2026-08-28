import { z } from 'zod';

export const CreateExpenseSchema = z.object({
  title: z.string().trim().min(1).max(150),
  recipientName: z.string().trim().max(120).optional().nullable(),
  category: z.string().trim().min(1).max(60).default('other'),
  amount: z.number().int().positive('Amount must be positive'),
  notes: z.string().trim().max(500).optional().nullable(),
  expenseDate: z.string().datetime().optional().nullable(),
});

export const UpdateExpenseSchema = z.object({
  title: z.string().trim().min(1).max(150).optional(),
  recipientName: z.string().trim().max(120).optional().nullable(),
  category: z.string().trim().min(1).max(60).optional(),
  amount: z.number().int().positive('Amount must be positive').optional(),
  notes: z.string().trim().max(500).optional().nullable(),
  expenseDate: z.string().datetime().optional().nullable(),
});

export const ExpenseQuerySchema = z.object({
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
  category: z.string().optional(),
  search: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  limit: z.coerce.number().int().positive().max(100).default(50),
});

export type CreateExpenseDto = z.infer<typeof CreateExpenseSchema>;
export type UpdateExpenseDto = z.infer<typeof UpdateExpenseSchema>;
export type ExpenseQueryDto = z.infer<typeof ExpenseQuerySchema>;

export interface PublicExpense {
  id: number;
  title: string;
  recipientName: string | null;
  category: string;
  amount: number;
  notes: string | null;
  expenseDate: string;
  createdAt: string;
  updatedAt: string;
}

export interface ExpenseSummaryResponse {
  totalExpensesDA: number;
  count: number;
  byCategory: Array<{ category: string; totalDA: number; count: number }>;
}
