import { z } from 'zod';

export type { Category } from '@config/db/generated/prisma/client';

export const createCategorySchema = z.object({
  name: z.string().trim().min(2).max(60),
  description: z.string().trim().max(500).nullish(),
});
