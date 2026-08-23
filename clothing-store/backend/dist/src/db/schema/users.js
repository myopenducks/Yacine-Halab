import { mysqlTable, serial, timestamp, uniqueIndex, varchar, } from 'drizzle-orm/mysql-core';
export const users = mysqlTable('users', {
    id: serial('id').primaryKey(),
    username: varchar('username', { length: 50 }).notNull(),
    passwordHash: varchar('password_hash', { length: 255 }).notNull(),
    createdAt: timestamp('created_at').notNull().defaultNow(),
    updatedAt: timestamp('updated_at')
        .notNull()
        .defaultNow()
        .onUpdateNow(),
}, (table) => ({
    usernameUniqueIdx: uniqueIndex('users_username_unique').on(table.username),
}));
//# sourceMappingURL=users.js.map