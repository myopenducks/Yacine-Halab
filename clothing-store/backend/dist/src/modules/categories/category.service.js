import { AppError } from '../../shared/errors';
function toPublic(c) {
    return { id: c.id, name: c.name };
}
export class CategoryService {
    repo;
    constructor(repo) {
        this.repo = repo;
    }
    async list() {
        const rows = await this.repo.findAll();
        return rows.map(toPublic);
    }
    async getById(id) {
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
}
//# sourceMappingURL=category.service.js.map