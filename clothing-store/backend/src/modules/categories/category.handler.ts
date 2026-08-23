import { ok } from '../../shared/types';
import { CategoryService } from './category.service';

export class CategoryHandler {
  constructor(private readonly service: CategoryService) {}

  async list() {
    const result = await this.service.list();
    return ok(result);
  }
}
