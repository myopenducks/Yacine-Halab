import 'dotenv/config';
import path from 'node:path';
import mysql from 'mysql2/promise';
import { drizzle } from 'drizzle-orm/mysql2';
import { migrate } from 'drizzle-orm/mysql2/migrator';
import { applyPlatformEnvDefaults, describeDbTarget } from '../src/config/platform-env';
import * as schema from '../src/db';

async function main() {
  applyPlatformEnvDefaults();

  const host = process.env.DB_HOST ?? '127.0.0.1';
  const port = Number(process.env.DB_PORT ?? 3306);
  const user = process.env.DB_USER ?? 'root';
  const password = process.env.DB_PASSWORD ?? '';
  const database = process.env.DB_NAME ?? 'clothing_store';

  console.log('[migrate] connecting to', describeDbTarget());

  const connection = await mysql.createConnection({
    host,
    port,
    user,
    password,
    database,
    connectTimeout: 15_000,
  });

  const db = drizzle(connection, { schema, mode: 'default' });
  const migrationsFolder = path.resolve(process.cwd(), 'src/db/migrations');
  console.log('[migrate] applying migrations from', migrationsFolder);
  try {
    await migrate(db, { migrationsFolder });
  } catch (err: any) {
    if (
      err?.code === 'ER_DUP_FIELDNAME' ||
      err?.code === 'ER_DUP_KEYNAME' ||
      err?.code === 'ER_TABLE_EXISTS_ERROR' ||
      err?.sqlState === '42S21' ||
      err?.message?.includes('Duplicate column') ||
      err?.message?.includes('already exists')
    ) {
      console.warn('[migrate] Notice: Schema already partially or fully updated (' + (err.sqlMessage || err.message) + '). Continuing.');
    } else {
      console.warn('[migrate] Warning during migrations:', err.message);
    }
  }

  // Ensure index on categories is composite (user_id, name)
  try {
    const [indexes] = await connection.query<any[]>(
      "SHOW INDEX FROM `categories` WHERE Key_name = 'categories_name_unique'",
    );
    if (Array.isArray(indexes) && indexes.length === 1 && indexes[0].Column_name === 'name') {
      console.log('[migrate] dropping legacy single-column categories_name_unique index');
      await connection.query('ALTER TABLE `categories` DROP INDEX `categories_name_unique`');
      await connection.query('ALTER TABLE `categories` ADD CONSTRAINT `categories_name_unique` UNIQUE(`user_id`, `name`)');
      console.log('[migrate] created composite categories_name_unique index on (user_id, name)');
    }
  } catch (err: any) {
    console.warn('[migrate] Notice updating categories index:', err.message);
  }

  // Ensure expenses table and indexes exist
  try {
    await connection.query(`
      CREATE TABLE IF NOT EXISTS \`expenses\` (
        \`id\` serial AUTO_INCREMENT NOT NULL,
        \`user_id\` bigint unsigned NOT NULL,
        \`title\` varchar(150) NOT NULL,
        \`recipient_name\` varchar(120),
        \`category\` varchar(60) NOT NULL DEFAULT 'other',
        \`amount\` int NOT NULL,
        \`notes\` varchar(500),
        \`expense_date\` timestamp NOT NULL DEFAULT (now()),
        \`created_at\` timestamp NOT NULL DEFAULT (now()),
        \`updated_at\` timestamp NOT NULL DEFAULT (now()) ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT \`expenses_id\` PRIMARY KEY(\`id\`),
        CONSTRAINT \`expenses_user_id_users_id_fk\` FOREIGN KEY (\`user_id\`) REFERENCES \`users\`(\`id\`) ON DELETE cascade ON UPDATE no action
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    `);
    console.log('[migrate] verified expenses table exists');
  } catch (err: any) {
    console.warn('[migrate] Notice creating expenses table:', err.message);
  }

  // Auto-seed initial categories and default admin if missing
  const INITIAL_CATEGORIES = ['T-Shirt', 'Shoes', 'Slippers', 'Shorts', 'Pants', 'Sets'];
  for (const name of INITIAL_CATEGORIES) {
    try {
      await db
        .insert(schema.categories)
        .values({ name, userId: 1 })
        .onDuplicateKeyUpdate({ set: { name } });
    } catch (_) {}
  }

  const existingUsers = await db.select().from(schema.users).limit(1);
  if (existingUsers.length === 0) {
    const { hash } = await import('argon2');
    const adminUsername = process.env.SEED_ADMIN_USERNAME ?? 'admin';
    const adminPassword = process.env.SEED_ADMIN_PASSWORD ?? 'admin123';
    const passwordHash = await hash(adminPassword);
    await db.insert(schema.users).values({
      username: adminUsername,
      passwordHash,
    });
    console.log(`[migrate] created default admin user (${adminUsername})`);
  }

  await connection.end();
  console.log('[migrate] done');
}

main().catch((err) => {
  console.error('[migrate] failed', err);
  process.exit(1);
});
