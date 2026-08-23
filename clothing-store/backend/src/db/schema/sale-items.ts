import { relations } from 'drizzle-orm';
import {
  bigint,
  int,
  mysqlTable,
  serial,
  timestamp,
  index,
} from 'drizzle-orm/mysql-core';
import { products } from './products';
import { sales } from './sales';

export const saleItems = mysqlTable(
  'sale_items',
  {
    id: serial('id').primaryKey(),
    saleId: bigint('sale_id', { mode: 'number', unsigned: true })
      .notNull()
      .references(() => sales.id, {
        onDelete: 'cascade',
      }),
    productId: bigint('product_id', { mode: 'number', unsigned: true })
      .notNull()
      .references(() => products.id, {
        onDelete: 'restrict',
      }),
    quantity: int('quantity').notNull(),
    unitPrice: int('unit_price').notNull(),
    purchasePrice: int('purchase_price').notNull(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
  },
  (table) => ({
    saleIdx: index('sale_items_sale_id_idx').on(table.saleId),
    productIdx: index('sale_items_product_id_idx').on(table.productId),
  }),
);

export const saleItemsRelations = relations(saleItems, ({ one }) => ({
  sale: one(sales, {
    fields: [saleItems.saleId],
    references: [sales.id],
  }),
  product: one(products, {
    fields: [saleItems.productId],
    references: [products.id],
  }),
}));

export type SaleItem = typeof saleItems.$inferSelect;
export type NewSaleItem = typeof saleItems.$inferInsert;
