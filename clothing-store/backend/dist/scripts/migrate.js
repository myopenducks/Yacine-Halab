import 'dotenv/config';
import path from 'node:path';
import mysql from 'mysql2/promise';
import { drizzle } from 'drizzle-orm/mysql2';
import { migrate } from 'drizzle-orm/mysql2/migrator';
import * as schema from '../src/db';
async function main() {
    const host = process.env.DB_HOST ?? '127.0.0.1';
    const port = Number(process.env.DB_PORT ?? 3306);
    const user = process.env.DB_USER ?? 'root';
    const password = process.env.DB_PASSWORD ?? '';
    const database = process.env.DB_NAME ?? 'clothing_store';
    const connection = await mysql.createConnection({
        host,
        port,
        user,
        password,
        database,
    });
    const db = drizzle(connection, { schema, mode: 'default' });
    const migrationsFolder = path.resolve(process.cwd(), 'src/db/migrations');
    console.log('[migrate] applying migrations from', migrationsFolder);
    await migrate(db, { migrationsFolder });
    await connection.end();
    console.log('[migrate] done');
}
main().catch((err) => {
    console.error('[migrate] failed', err);
    process.exit(1);
});
//# sourceMappingURL=migrate.js.map