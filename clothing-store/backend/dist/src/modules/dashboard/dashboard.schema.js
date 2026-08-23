import { z } from 'zod';
export const summaryQuerySchema = z.object({
    period: z.enum(['today', 'week', 'month', 'custom']).default('today'),
    month: z.coerce.number().int().min(1).max(12).optional(),
    year: z.coerce.number().int().optional(),
    from: z.coerce.date().optional(),
    to: z.coerce.date().optional(),
});
export const salesQuerySchema = summaryQuerySchema;
//# sourceMappingURL=dashboard.schema.js.map