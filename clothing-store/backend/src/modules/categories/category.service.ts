import { AppError } from '../../shared/errors';
import { CategoryRepository } from './category.repository';
import type { PublicCategory } from './category.schema';

function toPublic(c: { id: number; name: string }): PublicCategory {
  return { id: c.id, name: c.name };
}

export class CategoryService {
  constructor(private readonly repo: CategoryRepository) {}

  async list(): Promise<PublicCategory[]> {
    const rows = await this.repo.findAll();
    return rows.map(toPublic);
  }

  async getById(id: number): Promise<PublicCategory> {
    const row = await this.repo.findById(id);
    if (!row) {
      throw new AppError({
        code: 'CATEGORY_NOT_FOUND',
        statusCode: 404,
        message: `Category with id ${id} not found`,
      });
    }
    return toPublic(row);
  }

  async create(dto: { name: string }): Promise<PublicCategory> {
    const existing = await this.repo.findByName(dto.name);
    if (existing) {
      return toPublic(existing);
    }
    const created = await this.repo.create(dto.name);
    return toPublic(created);
  }

  async delete(id: number): Promise<{ success: boolean; movedProductsCount: number; message: string }> {
    await this.getById(id);
    const result = await this.repo.deleteAndReassign(id);
    return {
      success: true,
      movedProductsCount: result.movedProductsCount,
      message: `Category deleted. ${result.movedProductsCount} product(s) moved to "Autre".`,
    };
  }
}
