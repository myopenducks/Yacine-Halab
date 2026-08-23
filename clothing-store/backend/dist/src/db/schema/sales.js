import { relations } from 'drizzle-orm';
import { int, mysqlTable, serial, timestamp, index, } from 'drizzle-orm/mysql-core';
import { saleItems } from './sale-items';
export const sales = mysqlTable('sales', {
    id: serial('id').primaryKey(),
    totalAmount: int('total_amount').notNull(),
    paidAmount: int('paid_amount').notNull(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at')
        .notNull()
        .defaultNow()
        .onUpdateNow(),
}, (table) => ({
    createdAtIdx: index('sales_created_at_idx').on(table.createdAt),
}));
export const salesRelations = relations(sales, ({ many }) => ({
    saleItems: many(saleItems),
}));
//# sourceMappingURL=sales.js.map