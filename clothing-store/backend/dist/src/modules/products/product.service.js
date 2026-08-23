import { AppError } from '../../shared/errors';
const FK_RESTRICT_ERRNOS = new Set([1217, 1451]);
function isFkRestrictError(err) {
    if (!err || typeof err !== 'object')
        return false;
    const e = err;
    if (e.errno != null && FK_RESTRICT_ERRNOS.has(e.errno))
        return true;
    if (e.cause?.errno != null && FK_RESTRICT_ERRNOS.has(e.cause.errno))
        return true;
    if (typeof e.code === 'string' && e.code.includes('REFERENCED'))
        return true;
    if (e.code === 'ER_ROW_IS_REFERENCED' || e.code === 'ER_ROW_IS_REFERENCED_2')
        return true;
    return false;
}
export class ProductService {
    repo;
    categoryRepo;
    constructor(repo, categoryRepo) {
        this.repo = repo;
        this.categoryRepo = categoryRepo;
    }
    async list(query) {
        const { page, limit, search, categoryId, lowStock } = query;
        const { items, total } = await this.repo.findMany({ page, limit }, {
            search,
            categoryId,
            lowStock: lowStock === 'true' ? true : lowStock === 'false' ? false : undefined,
        });
        return { items, total, page, limit };
    }
    async getById(id) {
        const row = await this.repo.findById(id);
        if (!row) {
            throw new AppError({
                code: 'PRODUCT_NOT_FOUND',
                statusCode: 404,
                message: `Product with id ${id} not found`,
            });
        }
        return row;
    }
    async create(dto) {
        const category = await this.categoryRepo.findById(dto.categoryId);
        if (!category) {
            throw new AppError({
                code: 'CATEGORY_NOT_FOUND',
                statusCode: 404,
                message: `Category with id ${dto.categoryId} not found`,
            });
        }
        const created = await this.repo.create(dto);
        return this.getById(created.id);
    }
    async update(id, dto) {
        if (dto.categoryId != null) {
            const category = await this.categoryRepo.findById(dto.categoryId);
            if (!category) {
                throw new AppError({
                    code: 'CATEGORY_NOT_FOUND',
                    statusCode: 404,
                    message: `Category with id ${dto.categoryId} not found`,
                });
            }
        }
        const updated = await this.repo.update(id, dto);
        if (!updated) {
            throw new AppError({
                code: 'PRODUCT_NOT_FOUND',
                statusCode: 404,
                message: `Product with id ${id} not found`,
            });
        }
        return this.getById(id);
    }
    async delete(id) {
        const exists = await this.repo.findById(id);
        if (!exists) {
            throw new AppError({
                code: 'PRODUCT_NOT_FOUND',
                statusCode: 404,
                message: `Product with id ${id} not found`,
            });
        }
        try {
            const affected = await this.repo.delete(id);
            if (affected === 0) {
                throw new AppError({
                    code: 'PRODUCT_NOT_FOUND',
                    statusCode: 404,
                    message: `Product with id ${id} not found`,
                });
            }
        }
        catch (err) {
            if (isFkRestrictError(err)) {
                throw new AppError({
                    code: 'PRODUCT_HAS_SALES',
                    statusCode: 409,
                    message: 'Product cannot be deleted because it has sales history. Set its quantity to 0 instead.',
                    details: { productId: id },
                });
            }
            throw err;
        }
    }
}
//# sourceMappingURL=product.service.js.map