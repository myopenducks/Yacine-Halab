import type { MySql2Database } from 'drizzle-orm/mysql2';
import { eq, ne } from 'drizzle-orm';
import * as schema from '../../db';
import { categories } from '../../db/schema/categories';
import { products } from '../../db/schema/products';
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

  async findByName(name: string): Promise<Category | null> {
    const rows = await this.db
      .select()
      .from(categories)
      .where(eq(categories.name, name))
      .limit(1);
    return rows[0] ?? null;
  }

  async create(name: string): Promise<Category> {
    const [result] = await this.db.insert(categories).values({ name });
    const inserted = await this.findById(result.insertId);
    return inserted!;
  }

  async deleteAndReassign(id: number): Promise<{ success: boolean; movedProductsCount: number }> {
    return this.db.transaction(async (tx) => {
      // 1. Find or create the "Autre" / "Other" fallback category
      let otherCategory = await tx
        .select()
        .from(categories)
        .where(eq(categories.name, 'Autre'))
        .limit(1)
        .then((r) => r[0]);

      if (!otherCategory) {
        otherCategory = await tx
          .select()
          .from(categories)
          .where(eq(categories.name, 'Other'))
          .limit(1)
          .then((r) => r[0]);
      }

      if (!otherCategory) {
        const [res] = await tx.insert(categories).values({ name: 'Autre' });
        const [created] = await tx.select().from(categories).where(eq(categories.id, res.insertId)).limit(1);
        otherCategory = created!;
      }

      // If user tries to delete the fallback category itself, reassign to another existing category if any
      let fallbackId = otherCategory.id;
      if (fallbackId === id) {
        const [alternative] = await tx.select().from(categories).where(ne(categories.id, id)).limit(1);
        if (alternative) {
          fallbackId = alternative.id;
        } else {
          // Last remaining category in store, create a generic one
          const [res] = await tx.insert(categories).values({ name: 'Général' });
          fallbackId = res.insertId;
        }
      }

      // 2. Reassign all products from category `id` to `fallbackId`
      const affectedProducts = await tx
        .select({ id: products.id })
        .from(products)
        .where(eq(products.categoryId, id));

      if (affectedProducts.length > 0) {
        await tx
          .update(products)
          .set({ categoryId: fallbackId })
          .where(eq(products.categoryId, id));
      }

      // 3. Delete the category
      await tx.delete(categories).where(eq(categories.id, id));

      return {
        success: true,
        movedProductsCount: affectedProducts.length,
      };
    });
  }
}
