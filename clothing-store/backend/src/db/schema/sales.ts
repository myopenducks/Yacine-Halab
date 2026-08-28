import { relations } from 'drizzle-orm';
import {
  int,
  mysqlTable,
  serial,
  timestamp,
  varchar,
  index,
  bigint,
} from 'drizzle-orm/mysql-core';
import { saleItems } from './sale-items';
import { users } from './users';

export const sales = mysqlTable(
  'sales',
  {
    id: serial('id').primaryKey(),
    userId: bigint('user_id', { mode: 'number', unsigned: true })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    totalAmount: int('total_amount').notNull(),
    paidAmount: int('paid_amount').notNull(),
    customerName: varchar('customer_name', { length: 120 }),
    notes: varchar('notes', { length: 500 }),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at')
      .notNull()
      .defaultNow()
      .onUpdateNow(),
  },
  (table) => ({
    createdAtIdx: index('sales_created_at_idx').on(table.createdAt),
    userIdx: index('sales_user_idx').on(table.userId),
  }),
);

export const salesRelations = relations(sales, ({ many }) => ({
  saleItems: many(saleItems),
}));

export type Sale = typeof sales.$inferSelect;
export type NewSale = typeof sales.$inferInsert;
