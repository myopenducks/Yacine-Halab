import type { MySql2Database } from 'drizzle-orm/mysql2';
import { eq, ne, and } from 'drizzle-orm';
import * as schema from '../../db';
import { categories } from '../../db/schema/categories';
import { products } from '../../db/schema/products';
import type { Category } from '../../db/schema/categories';

export class CategoryRepository {
  constructor(private readonly db: MySql2Database<typeof schema>) {}

  async findAll(userId: number): Promise<Category[]> {
    let rows = await this.db.select().from(categories).where(eq(categories.userId, userId)).orderBy(categories.id);
    if (rows.length === 0) {
      const INITIAL_CATEGORIES = ['T-Shirt', 'Shoes', 'Slippers', 'Shorts', 'Pants', 'Sets'];
      for (const name of INITIAL_CATEGORIES) {
        try {
          await this.db.insert(categories).values({ name, userId });
        } catch (_) {}
      }
      rows = await this.db.select().from(categories).where(eq(categories.userId, userId)).orderBy(categories.id);
    }
    return rows;
  }

  async findById(id: number, userId: number): Promise<Category | null> {
    const rows = await this.db
      .select()
      .from(categories)
      .where(and(eq(categories.id, id), eq(categories.userId, userId)))
      .limit(1);
    return rows[0] ?? null;
  }

  async findByName(name: string, userId: number): Promise<Category | null> {
    const rows = await this.db
      .select()
      .from(categories)
      .where(and(eq(categories.name, name), eq(categories.userId, userId)))
      .limit(1);
    return rows[0] ?? null;
  }

  async create(name: string, userId: number): Promise<Category> {
    const [result] = await this.db.insert(categories).values({ name, userId });
    const inserted = await this.findById(result.insertId, userId);
    return inserted!;
  }

  async deleteAndReassign(id: number, userId: number): Promise<{ success: boolean; movedProductsCount: number }> {
    return this.db.transaction(async (tx) => {
      // 1. Find or create the "Autre" / "Other" fallback category
      let otherCategory = await tx
        .select()
        .from(categories)
        .where(and(eq(categories.name, 'Autre'), eq(categories.userId, userId)))
        .limit(1)
        .then((r) => r[0]);

      if (!otherCategory) {
        otherCategory = await tx
          .select()
          .from(categories)
          .where(and(eq(categories.name, 'Other'), eq(categories.userId, userId)))
          .limit(1)
          .then((r) => r[0]);
      }

      if (!otherCategory) {
        const [res] = await tx.insert(categories).values({ name: 'Autre', userId });
        const [created] = await tx.select().from(categories).where(eq(categories.id, res.insertId)).limit(1);
        otherCategory = created!;
      }

      // If user tries to delete the fallback category itself, reassign to another existing category if any
      let fallbackId = otherCategory.id;
      if (fallbackId === id) {
        const [alternative] = await tx.select().from(categories).where(and(ne(categories.id, id), eq(categories.userId, userId))).limit(1);
        if (alternative) {
          fallbackId = alternative.id;
        } else {
          // Last remaining category in store, create a generic one
          const [res] = await tx.insert(categories).values({ name: 'Général', userId });
          fallbackId = res.insertId;
        }
      }

      // 2. Reassign all products from category `id` to `fallbackId`
      const affectedProducts = await tx
        .select({ id: products.id })
        .from(products)
        .where(and(eq(products.categoryId, id), eq(products.userId, userId)));

      if (affectedProducts.length > 0) {
        await tx
          .update(products)
          .set({ categoryId: fallbackId })
          .where(and(eq(products.categoryId, id), eq(products.userId, userId)));
      }

      // 3. Delete the category
      await tx.delete(categories).where(and(eq(categories.id, id), eq(categories.userId, userId)));

      return {
        success: true,
        movedProductsCount: affectedProducts.length,
      };
    });
  }
}
