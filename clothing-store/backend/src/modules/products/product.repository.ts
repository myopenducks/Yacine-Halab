import type { MySql2Database } from 'drizzle-orm/mysql2';
import { and, count, desc, eq, gt, inArray, like, lte } from 'drizzle-orm';
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

  private buildWhere(filters: FindManyFilters) {
    const clauses = [];
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
    return clauses.length > 0 ? and(...clauses) : undefined;
  }

  private toPublic(row: {
    id: number;
    name: string;
    categoryId: number;
    categoryName: string;
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
      categoryName: row.categoryName,
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
  ): Promise<{ items: PublicProduct[]; total: number }> {
    const where = this.buildWhere(filters);
    const offset = computeOffset(pagination);

    const itemsQuery = this.db
      .select({
        id: products.id,
        name: products.name,
        categoryId: products.categoryId,
        categoryName: categories.name,
        purchasePrice: products.purchasePrice,
        sellingPrice: products.sellingPrice,
        quantity: products.quantity,
        imageUrl: products.imageUrl,
        createdAt: products.createdAt,
      })
      .from(products)
      .innerJoin(categories, eq(products.categoryId, categories.id))
      .orderBy(desc(products.id))
      .limit(pagination.limit)
      .offset(offset);

    const countQuery = this.db
      .select({ value: count(products.id) })
      .from(products);

    if (where) {
      itemsQuery.where(where);
      countQuery.where(where);
    }

    const [items, countRows] = await Promise.all([itemsQuery, countQuery]);
    const total = Number(countRows[0]?.value ?? 0);

    return { items: items.map(this.toPublic), total };
  }

  async findById(id: number): Promise<PublicProduct | null> {
    const rows = await this.db
      .select({
        id: products.id,
        name: products.name,
        categoryId: products.categoryId,
        categoryName: categories.name,
        purchasePrice: products.purchasePrice,
        sellingPrice: products.sellingPrice,
        quantity: products.quantity,
        imageUrl: products.imageUrl,
        createdAt: products.createdAt,
      })
      .from(products)
      .innerJoin(categories, eq(products.categoryId, categories.id))
      .where(eq(products.id, id))
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
    data: Partial<{
      name: string;
      categoryId: number;
      purchasePrice: number;
      sellingPrice: number;
      quantity: number;
      imageUrl: string | null;
    }>,
  ): Promise<Product | null> {
    await this.db.update(products).set(data).where(eq(products.id, id));
    const rows = await this.db
      .select()
      .from(products)
      .where(eq(products.id, id))
      .limit(1);
    return rows[0] ?? null;
  }

  async delete(id: number): Promise<number> {
    const result = await this.db.delete(products).where(eq(products.id, id));
    return Number(result[0].affectedRows ?? 0);
  }

  async bulkUpdateCategory(productIds: number[], categoryId: number): Promise<number> {
    if (productIds.length === 0) return 0;
    const result = await this.db
      .update(products)
      .set({ categoryId })
      .where(inArray(products.id, productIds));
    return Number(result[0].affectedRows ?? 0);
  }
}
