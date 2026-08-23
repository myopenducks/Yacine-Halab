import { mysqlTable, serial, timestamp, uniqueIndex, varchar, } from 'drizzle-orm/mysql-core';
export const categories = mysqlTable('categories', {
    id: serial('id').primaryKey(),
    name: varchar('name', { length: 100 }).notNull(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at')
        .notNull()
        .defaultNow()
        .onUpdateNow(),
}, (table) => ({
    nameUniqueIdx: uniqueIndex('categories_name_unique').on(table.name),
}));
//# sourceMappingURL=categories.js.map