import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import { loadEnv } from '../config/env';
import * as schema from '.';
export * from './schema/users';
export * from './schema/categories';
export * from './schema/products';
export * from './schema/sales';
export * from './schema/sale-items';
let cachedDb = null;
export function getDb() {
    if (cachedDb)
        return cachedDb;
    const env = loadEnv();
    const pool = mysql.createPool({
        host: env.DB_HOST,
        port: env.DB_PORT,
        user: env.DB_USER,
        password: env.DB_PASSWORD,
        database: env.DB_NAME,
        waitForConnections: true,
        connectionLimit: 10,
        queueLimit: 0,
    });
    cachedDb = drizzle(pool, { schema, mode: 'default' });
    return cachedDb;
}
//# sourceMappingURL=index.js.map