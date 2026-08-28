import 'dotenv/config';
import { drizzle } from 'drizzle-orm/mysql2';
import mysql from 'mysql2/promise';
import * as schema from '../src/db';
import { hash } from 'argon2';
import { categories, users } from '../src/db';

const INITIAL_CATEGORIES: string[] = [
  'T-Shirt',
  'Shoes',
  'Slippers',
  'Shorts',
  'Pants',
  'Sets',
];

async function main() {
  const host = process.env.DB_HOST ?? '127.0.0.1';
  const port = Number(process.env.DB_PORT ?? 3306);
  const user = process.env.DB_USER ?? 'root';
  const password = process.env.DB_PASSWORD ?? '';
  const database = process.env.DB_NAME ?? 'clothing_store';

  const adminUsername = process.env.SEED_ADMIN_USERNAME ?? 'admin';
  const adminPassword = process.env.SEED_ADMIN_PASSWORD;
  if (!adminPassword) {
    throw new Error('SEED_ADMIN_PASSWORD is required');
  }

  const connection = await mysql.createConnection({
    host,
    port,
    user,
    password,
    database,
  });

  const db = drizzle(connection, { schema, mode: 'default' });

  console.log('[seed] inserting categories...');
  for (const name of INITIAL_CATEGORIES) {
    await db
      .insert(categories)
      .values({ name, userId: 1 })
      .onDuplicateKeyUpdate({ set: { name } });
  }
  console.log(`[seed] categories ready (${INITIAL_CATEGORIES.length} total)`);

  const passwordHash = await hash(adminPassword);
  console.log('[seed] inserting admin user...');
  await db
    .insert(users)
    .values({
      username: adminUsername,
      passwordHash,
    })
    .onDuplicateKeyUpdate({ set: { passwordHash } });
  console.log(`[seed] admin user ready (username = ${adminUsername})`);

  await connection.end();
  console.log('[seed] done.');
}

main().catch((e) => {
  console.error('[seed] failed:', e);
  process.exit(1);
});
