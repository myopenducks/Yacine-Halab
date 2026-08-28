import {
  bigint,
  index,
  int,
  mysqlTable,
  serial,
  timestamp,
  varchar,
} from 'drizzle-orm/mysql-core';
import { users } from './users';

export const expenses = mysqlTable(
  'expenses',
  {
    id: serial('id').primaryKey(),
    userId: bigint('user_id', { mode: 'number', unsigned: true })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    title: varchar('title', { length: 150 }).notNull(),
    recipientName: varchar('recipient_name', { length: 120 }),
    category: varchar('category', { length: 60 }).notNull().default('other'),
    amount: int('amount').notNull(),
    notes: varchar('notes', { length: 500 }),
    expenseDate: timestamp('expense_date').notNull().defaultNow(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at')
      .notNull()
      .defaultNow()
      .onUpdateNow(),
  },
  (table) => ({
    userIdx: index('expenses_user_idx').on(table.userId),
    expenseDateIdx: index('expenses_expense_date_idx').on(table.expenseDate),
    categoryIdx: index('expenses_category_idx').on(table.category),
  }),
);

export type Expense = typeof expenses.$inferSelect;
export type NewExpense = typeof expenses.$inferInsert;
