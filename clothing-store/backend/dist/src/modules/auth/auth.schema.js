import { z } from 'zod';
export const loginRequestSchema = z.object({
    username: z.string().min(1).max(50),
    password: z.string().min(6).max(100),
});
//# sourceMappingURL=auth.schema.js.map