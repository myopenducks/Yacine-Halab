import { z } from 'zod';
export const productIdParamSchema = z.object({
    id: z.coerce.number().int().positive(),
});
export const productListQuerySchema = z.object({
    page: z.coerce.number().int().min(1).default(1),
    limit: z.coerce.number().int().min(1).max(100).default(20),
    search: z.string().optional(),
    categoryId: z.coerce.number().int().optional(),
    lowStock: z.enum(['true', 'false']).optional(),
});
export const createProductSchema = z.object({
    name: z.string().min(1).max(200),
    categoryId: z.number().int().positive(),
    purchasePrice: z.number().int().min(0),
    sellingPrice: z.number().int().min(0),
    quantity: z.number().int().min(0).default(0),
    imageUrl: z.string().max(500).url().nullable().optional(),
});
export const updateProductSchema = z.object({
    name: z.string().min(1).max(200).optional(),
    categoryId: z.number().int().positive().optional(),
    purchasePrice: z.number().int().min(0).optional(),
    sellingPrice: z.number().int().min(0).optional(),
    quantity: z.number().int().min(0).optional(),
    imageUrl: z.string().max(500).url().nullable().optional(),
});
//# sourceMappingURL=product.schema.js.map