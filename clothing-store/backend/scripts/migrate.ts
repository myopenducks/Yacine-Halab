import 'dotenv/config';
import path from 'node:path';
import mysql from 'mysql2/promise';
import { eq } from 'drizzle-orm';
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

  // Ensure categories user_id is updated and index is composite (user_id, name)
  try {
    // 1. Drop any old single-column unique indexes on categories
    const [indexes] = await connection.query<any[]>(
      "SHOW INDEX FROM `categories` WHERE Key_name = 'categories_name_unique'",
    );
    if (Array.isArray(indexes) && indexes.length > 0) {
      const cols = indexes.map((i: any) => i.Column_name);
      if (!cols.includes('user_id')) {
        console.log('[migrate] dropping legacy single-column categories_name_unique index');
        await connection.query('ALTER TABLE `categories` DROP INDEX `categories_name_unique`');
      }
    }
  } catch (err: any) {
    console.warn('[migrate] Notice checking categories index:', err.message);
  }

  try {
    // 2. Fix all existing categories and products without user_id
    await connection.query('UPDATE `categories` SET `user_id` = 1 WHERE `user_id` IS NULL OR `user_id` = 0');
    await connection.query('UPDATE `products` SET `user_id` = 1 WHERE `user_id` IS NULL OR `user_id` = 0');
    await connection.query('UPDATE `sales` SET `user_id` = 1 WHERE `user_id` IS NULL OR `user_id` = 0');
    console.log('[migrate] updated legacy rows to user_id = 1');
  } catch (err: any) {
    console.warn('[migrate] Notice fixing user_id:', err.message);
  }

  try {
    // 3. Create composite index (user_id, name)
    await connection.query('ALTER TABLE `categories` ADD CONSTRAINT `categories_name_unique` UNIQUE(`user_id`, `name`)');
    console.log('[migrate] created composite categories_name_unique index on (user_id, name)');
  } catch (_) {}

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

  // Ensure columns exist on sales table
  const salesAlters = [
    "ALTER TABLE `sales` ADD COLUMN `user_id` bigint unsigned NOT NULL DEFAULT 1",
    "ALTER TABLE `sales` ADD COLUMN `total_amount` int NOT NULL DEFAULT 0",
    "ALTER TABLE `sales` ADD COLUMN `paid_amount` int NOT NULL DEFAULT 0",
    "ALTER TABLE `sales` ADD COLUMN `customer_name` varchar(120) NULL",
    "ALTER TABLE `sales` ADD COLUMN `notes` varchar(500) NULL",
    "ALTER TABLE `products` ADD COLUMN `user_id` bigint unsigned NOT NULL DEFAULT 1",
    "ALTER TABLE `categories` ADD COLUMN `user_id` bigint unsigned NOT NULL DEFAULT 1",
  ];
  for (const sql of salesAlters) {
    try {
      await connection.query(sql);
      console.log(`[migrate] applied: ${sql}`);
    } catch (err: any) {
      if (err?.code === 'ER_DUP_FIELDNAME' || err?.message?.includes('Duplicate column')) {
        // already exists, skip
      } else {
        console.warn('[migrate] Notice column check:', err.message);
      }
    }
  }

  // Back-fill existing sales where total_amount is 0: sum from sale_items
  try {
    await connection.query(`
      UPDATE \`sales\` s
      SET s.\`total_amount\` = (
        SELECT COALESCE(SUM(si.\`unit_price\` * si.\`quantity\`), 0)
        FROM \`sale_items\` si WHERE si.\`sale_id\` = s.\`id\`
      ),
      s.\`paid_amount\` = (
        SELECT COALESCE(SUM(si.\`unit_price\` * si.\`quantity\`), 0)
        FROM \`sale_items\` si WHERE si.\`sale_id\` = s.\`id\`
      )
      WHERE s.\`total_amount\` = 0
    `);
    console.log('[migrate] back-filled sales total_amount/paid_amount');
  } catch (err: any) {
    console.warn('[migrate] Notice back-filling sales:', err.message);
  }

  // Auto-seed default admin if missing
  try {
    const [existingAdmin] = await connection.query<any[]>('SELECT id FROM `users` WHERE `username` = "admin" LIMIT 1');
    if (!Array.isArray(existingAdmin) || existingAdmin.length === 0) {
      const { hash } = await import('argon2');
      const adminUsername = process.env.SEED_ADMIN_USERNAME ?? 'admin';
      const adminPassword = process.env.SEED_ADMIN_PASSWORD ?? 'admin123';
      const passwordHash = await hash(adminPassword);
      await connection.query('INSERT INTO `users` (`username`, `password_hash`) VALUES (?, ?)', [
        adminUsername,
        passwordHash,
      ]);
      console.log(`[migrate] created default admin user (${adminUsername})`);
    }
  } catch (err: any) {
    console.warn('[migrate] Notice creating admin:', err.message);
  }

  // Ensure default categories & initial products for every user in the system
  const INITIAL_CATEGORIES = ['T-Shirt', 'Shoes', 'Slippers', 'Shorts', 'Pants', 'Sets'];
  const sampleProducts = [
    { name: 'T-Shirt Oversize Coton Noir', cat: 'T-Shirt', buy: 1200, sell: 2200, qty: 15 },
    { name: 'Polo Classique Blanc', cat: 'T-Shirt', buy: 1800, sell: 3000, qty: 10 },
    { name: 'Jean Slim Bleu Denim', cat: 'Pants', buy: 2500, sell: 4500, qty: 8 },
    { name: 'Pantalon Cargo Kaki', cat: 'Pants', buy: 2800, sell: 4800, qty: 4 },
    { name: 'Sneakers Streetwear Blanche', cat: 'Shoes', buy: 4000, sell: 6500, qty: 6 },
    { name: 'Claquettes Confort Cuir', cat: 'Slippers', buy: 1500, sell: 2500, qty: 12 },
    { name: 'Short Jogging Gris', cat: 'Shorts', buy: 1400, sell: 2400, qty: 3 },
    { name: 'Ensemble Sport Tech Noir', cat: 'Sets', buy: 5500, sell: 8500, qty: 7 },
  ];

  try {
    const [allUsers] = await connection.query<any[]>('SELECT id FROM `users`');
    if (Array.isArray(allUsers)) {
      for (const u of allUsers) {
        const uId = u.id;
        const catMap = new Map<string, number>();

        for (const catName of INITIAL_CATEGORIES) {
          try {
            await connection.query(
              'INSERT INTO `categories` (`name`, `user_id`) VALUES (?, ?) ON DUPLICATE KEY UPDATE `name` = VALUES(`name`)',
              [catName, uId],
            );
          } catch (_) {}
        }

        const [userCats] = await connection.query<any[]>('SELECT id, name FROM `categories` WHERE `user_id` = ?', [uId]);
        if (Array.isArray(userCats)) {
          for (const c of userCats) catMap.set(c.name, c.id);
        }

        const [userProds] = await connection.query<any[]>('SELECT COUNT(*) as count FROM `products` WHERE `user_id` = ?', [uId]);
        const prodCount = Number(userProds[0]?.count ?? 0);
        if (prodCount === 0) {
          for (const p of sampleProducts) {
            const cId = catMap.get(p.cat);
            if (cId) {
              try {
                await connection.query(
                  'INSERT INTO `products` (`name`, `category_id`, `user_id`, `purchase_price`, `selling_price`, `quantity`) VALUES (?, ?, ?, ?, ?, ?)',
                  [p.name, cId, uId, p.buy, p.sell, p.qty],
                );
              } catch (_) {}
            }
          }
          console.log(`[migrate] seeded products for user ${uId}`);
        }
      }
    }
  } catch (err: any) {
    console.warn('[migrate] Notice seeding users catalog:', err.message);
  }
  await connection.end();
  console.log('[migrate] done');
}

main().catch((err) => {
  console.error('[migrate] failed', err);
  process.exit(1);
});
