import { AppError } from '../../shared/errors';
export class SaleService {
    repo;
    constructor(repo) {
        this.repo = repo;
    }
    async create(dto) {
        const productIds = [...new Set(dto.items.map((i) => i.productId))];
        if (productIds.length !== dto.items.length) {
            throw new AppError({
                code: 'VALIDATION_ERROR',
                statusCode: 400,
                message: 'Duplicate productId in sale items. Combine quantities instead.',
            });
        }
        return this.repo.transaction(async (tx) => {
            const locked = await this.repo.lockProductsByIds(tx, productIds);
            const productMap = new Map(locked.map((p) => [p.id, p]));
            for (const item of dto.items) {
                const prod = productMap.get(item.productId);
                if (!prod) {
                    throw new AppError({
                        code: 'PRODUCT_NOT_FOUND',
                        statusCode: 404,
                        message: `Product with id ${item.productId} not found`,
                        details: { productId: item.productId },
                    });
                }
                if (prod.quantity < item.quantity) {
                    throw new AppError({
                        code: 'INSUFFICIENT_STOCK',
                        statusCode: 409,
                        message: `Product "${prod.name}" has only ${prod.quantity} in stock, ${item.quantity} requested`,
                        details: {
                            productId: prod.id,
                            productName: prod.name,
                            available: prod.quantity,
                            requested: item.quantity,
                        },
                    });
                }
            }
            let totalAmount = 0;
            const saleItemInserts = [];
            const quantityUpdates = [];
            for (const item of dto.items) {
                const prod = productMap.get(item.productId);
                const unitPrice = prod.sellingPrice;
                const purchasePrice = prod.purchasePrice;
                const lineTotal = unitPrice * item.quantity;
                totalAmount += lineTotal;
                saleItemInserts.push({
                    saleId: 0,
                    productId: prod.id,
                    quantity: item.quantity,
                    unitPrice,
                    purchasePrice,
                });
                quantityUpdates.push({
                    id: prod.id,
                    quantity: prod.quantity - item.quantity,
                });
            }
            const paidAmount = totalAmount;
            const saleId = await this.repo.insertSale(tx, { totalAmount, paidAmount });
            for (const it of saleItemInserts)
                it.saleId = saleId;
            await this.repo.bulkInsertSaleItems(tx, saleItemInserts);
            await this.repo.bulkUpdateProductQuantities(tx, quantityUpdates);
            const detail = await this.repo.findByIdOn(tx, saleId);
            return detail;
        });
    }
    async list(query) {
        const { page, limit, from, to } = query;
        const { items, total } = await this.repo.list({ page, limit }, { from, to });
        return { items, total, page, limit };
    }
    async getById(id) {
        const row = await this.repo.findById(id);
        if (!row) {
            throw new AppError({
                code: 'SALE_NOT_FOUND',
                statusCode: 404,
                message: `Sale with id ${id} not found`,
            });
        }
        return row;
    }
}
//# sourceMappingURL=sale.service.js.map