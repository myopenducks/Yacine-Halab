import type { MySql2Database } from 'drizzle-orm/mysql2';
import { and, count, desc, eq, gt, inArray, like, lte, sql } from 'drizzle-orm';
import * as schema from '../../db';
import { products } from '../../db/schema/products';
import { categories } from '../../db/schema/categories';
import type { Product } from '../../db/schema/products';
import {
  computeOffset,
  type PaginationParams,
} from '../../shared/pagination';
import type {
  ProductListQuery,
  PublicProduct,
} from './product.schema';

interface FindManyFilters {
  search?: string;
  categoryId?: number;
  lowStock?: boolean;
}

const LOW_STOCK_THRESHOLD = 5;

export class ProductRepository {
  constructor(private readonly db: MySql2Database<typeof schema>) {}

  private buildWhere(filters: FindManyFilters, userId: number) {
    const clauses = [eq(products.userId, userId)];
    if (filters.search) {
      clauses.push(like(products.name, `%${filters.search}%`));
    }
    if (filters.categoryId != null) {
      clauses.push(eq(products.categoryId, filters.categoryId));
    }
    if (filters.lowStock === true) {
      clauses.push(lte(products.quantity, LOW_STOCK_THRESHOLD));
    } else if (filters.lowStock === false) {
      clauses.push(gt(products.quantity, LOW_STOCK_THRESHOLD));
    }
    return and(...clauses);
  }

  private toPublic(row: {
    id: number;
    name: string;
    categoryId: number;
    categoryName: string | null;
    purchasePrice: number;
    sellingPrice: number;
    quantity: number;
    imageUrl: string | null;
    createdAt: Date;
  }): PublicProduct {
    return {
      id: row.id,
      name: row.name,
      categoryId: row.categoryId,
      categoryName: row.categoryName || 'Autre',
      purchasePrice: row.purchasePrice,
      sellingPrice: row.sellingPrice,
      quantity: row.quantity,
      imageUrl: row.imageUrl,
      createdAt: row.createdAt,
    };
  }

  async findMany(
    pagination: PaginationParams,
    filters: FindManyFilters,
    userId: number,
  ): Promise<{ items: PublicProduct[]; total: number }> {
    const where = this.buildWhere(filters, userId);
    const offset = computeOffset(pagination);

    const itemsQuery = this.db
      .select({
        id: products.id,
        name: products.name,
        categoryId: products.categoryId,
        categoryName: sql<string>`COALESCE(${categories.name}, 'Autre')`,
        purchasePrice: products.purchasePrice,
        sellingPrice: products.sellingPrice,
        quantity: products.quantity,
        imageUrl: products.imageUrl,
        createdAt: products.createdAt,
      })
      .from(products)
      .leftJoin(categories, eq(products.categoryId, categories.id))
      .where(where)
      .orderBy(desc(products.id))
      .limit(pagination.limit)
      .offset(offset);

    const countQuery = this.db
      .select({ value: count(products.id) })
      .from(products)
      .where(where);

    const [items, countRows] = await Promise.all([itemsQuery, countQuery]);
    let total = Number(countRows[0]?.value ?? 0);

    // Auto-seed starter catalog if user has 0 products and no filters were applied
    if (total === 0 && !filters.search && filters.categoryId == null && filters.lowStock == null) {
      const userCats = await this.db.select().from(categories).where(eq(categories.userId, userId));
      const catMap = new Map<string, number>();
      for (const c of userCats) catMap.set(c.name, c.id);

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

      for (const p of sampleProducts) {
        const cId = catMap.get(p.cat) ?? (userCats[0]?.id || 1);
        try {
          await this.db.insert(products).values({
            name: p.name,
            categoryId: cId,
            userId,
            purchasePrice: p.buy,
            sellingPrice: p.sell,
            quantity: p.qty,
          });
        } catch (_) {}
      }

      // Re-run query after seeding
      const [newItems, newCount] = await Promise.all([itemsQuery, countQuery]);
      return { items: newItems.map(this.toPublic), total: Number(newCount[0]?.value ?? 0) };
    }

    return { items: items.map(this.toPublic), total };
  }

  async findById(id: number, userId: number): Promise<PublicProduct | null> {
    const rows = await this.db
      .select({
        id: products.id,
        name: products.name,
        categoryId: products.categoryId,
        categoryName: sql<string>`COALESCE(${categories.name}, 'Autre')`,
        purchasePrice: products.purchasePrice,
        sellingPrice: products.sellingPrice,
        quantity: products.quantity,
        imageUrl: products.imageUrl,
        createdAt: products.createdAt,
      })
      .from(products)
      .leftJoin(categories, eq(products.categoryId, categories.id))
      .where(and(eq(products.id, id), eq(products.userId, userId)))
      .limit(1);
    return rows[0] ? this.toPublic(rows[0]) : null;
  }

  async create(data: {
    name: string;
    categoryId: number;
    purchasePrice: number;
    sellingPrice: number;
    quantity: number;
    imageUrl?: string | null;
    userId: number;
  }): Promise<Product> {
    const result = await this.db.insert(products).values(data);
    const insertedId = Number(result[0].insertId);
    const created = await this.db
      .select()
      .from(products)
      .where(eq(products.id, insertedId))
      .limit(1);
    return created[0];
  }

  async update(
    id: number,
    userId: number,
    data: Partial<{
      name: string;
      categoryId: number;
      purchasePrice: number;
      sellingPrice: number;
      quantity: number;
      imageUrl: string | null;
    }>,
  ): Promise<Product | null> {
    await this.db.update(products).set(data).where(and(eq(products.id, id), eq(products.userId, userId)));
    const rows = await this.db
      .select()
      .from(products)
      .where(and(eq(products.id, id), eq(products.userId, userId)))
      .limit(1);
    return rows[0] ?? null;
  }

  async delete(id: number, userId: number): Promise<number> {
    const result = await this.db.delete(products).where(and(eq(products.id, id), eq(products.userId, userId)));
    return Number(result[0].affectedRows ?? 0);
  }

  async bulkUpdateCategory(productIds: number[], categoryId: number, userId: number): Promise<number> {
    if (productIds.length === 0) return 0;
    const result = await this.db
      .update(products)
      .set({ categoryId })
      .where(and(inArray(products.id, productIds), eq(products.userId, userId)));
    return Number(result[0].affectedRows ?? 0);
  }
}
