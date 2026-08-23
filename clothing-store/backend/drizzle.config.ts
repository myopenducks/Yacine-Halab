import 'dotenv/config';
import { defineConfig } from 'drizzle-kit';

const host = process.env.DB_HOST ?? '127.0.0.1';
const port = Number(process.env.DB_PORT ?? 3306);
const user = process.env.DB_USER ?? 'root';
const password = process.env.DB_PASSWORD ?? '';
const database = process.env.DB_NAME ?? 'clothing_store';

export default defineConfig({
  schema: './src/db/schema/*.ts',
  out: './src/db/migrations',
  dialect: 'mysql',
  dbCredentials: {
    host,
    port,
    user,
    password,
    database,
  },
});
