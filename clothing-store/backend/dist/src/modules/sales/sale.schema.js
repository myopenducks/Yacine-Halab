import { z } from 'zod';
export const createSaleSchema = z.object({
    items: z
        .array(z.object({
        productId: z.number().int().positive(),
        quantity: z.number().int().min(1),
    }))
        .min(1, 'Sale must have at least 1 item'),
});
export const saleListQuerySchema = z.object({
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional(),
});
export const saleIdParamSchema = z.object({
    id: z.coerce.number().int().positive(),
});
//# sourceMappingURL=sale.schema.js.map