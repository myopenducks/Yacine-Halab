import { z } from 'zod';

export const createCategorySchema = z.object({
  name: z.string().trim().min(1, 'Name is required').max(100, 'Max 100 characters'),
});

export const categoryIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export type CreateCategoryDto = z.infer<typeof createCategorySchema>;

export interface PublicCategory {
  id: number;
  name: string;
}
