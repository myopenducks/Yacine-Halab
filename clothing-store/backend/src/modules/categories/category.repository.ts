import type { MySql2Database } from 'drizzle-orm/mysql2';
import { eq } from 'drizzle-orm';
import * as schema from '../../db';
import { categories } from '../../db/schema/categories';
import type { Category } from '../../db/schema/categories';

export class CategoryRepository {
  constructor(private readonly db: MySql2Database<typeof schema>) {}

  async findAll(): Promise<Category[]> {
    return this.db.select().from(categories).orderBy(categories.id);
  }

  async findById(id: number): Promise<Category | null> {
    const rows = await this.db
      .select()
      .from(categories)
      .where(eq(categories.id, id))
      .limit(1);
    return rows[0] ?? null;
  }
}
