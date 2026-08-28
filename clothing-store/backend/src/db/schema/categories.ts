import {
  mysqlTable,
  serial,
  timestamp,
  uniqueIndex,
  varchar,
  bigint,
  index,
} from 'drizzle-orm/mysql-core';
import { users } from './users';

export const categories = mysqlTable(
  'categories',
  {
    id: serial('id').primaryKey(),
    userId: bigint('user_id', { mode: 'number', unsigned: true })
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    name: varchar('name', { length: 100 }).notNull(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at')
      .notNull()
      .defaultNow()
      .onUpdateNow(),
  },
  (table) => ({
    nameUniqueIdx: uniqueIndex('categories_name_unique').on(table.userId, table.name),
    userIdx: index('categories_user_idx').on(table.userId),
  }),
);

export type Category = typeof categories.$inferSelect;
export type NewCategory = typeof categories.$inferInsert;
