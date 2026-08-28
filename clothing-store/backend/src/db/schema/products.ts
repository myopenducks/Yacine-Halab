import { relations } from 'drizzle-orm';
import {
  bigint,
  int,
  mysqlTable,
  serial,
  timestamp,
  varchar,
  text,
  index,
} from 'drizzle-orm/mysql-core';
import { categories } from './categories';
import { saleItems } from './sale-items';
import { users } from './users';

export const products = mysqlTable(
  'products',
  {
    id: serial('id').primaryKey(),
    userId: bigint('user_id', { mode: 'number', unsigned: true })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    categoryId: bigint('category_id', { mode: 'number', unsigned: true })
      .notNull()
      .references(() => categories.id, { onDelete: 'restrict' }),
    name: varchar('name', { length: 200 }).notNull(),
    purchasePrice: int('purchase_price').notNull(),
    sellingPrice: int('selling_price').notNull(),
    quantity: int('quantity').notNull().default(0),
    imageUrl: text('image_url'),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at')
      .notNull()
      .defaultNow()
      .onUpdateNow(),
  },
  (table) => ({
    nameIdx: index('products_name_idx').on(table.name),
    categoryIdx: index('products_category_idx').on(table.categoryId),
    userIdx: index('products_user_idx').on(table.userId),
  }),
);

export const productsRelations = relations(products, ({ one, many }) => ({
  category: one(categories, {
    fields: [products.categoryId],
    references: [categories.id],
  }),
  saleItems: many(saleItems),
}));

export type Product = typeof products.$inferSelect;
export type NewProduct = typeof products.$inferInsert;
