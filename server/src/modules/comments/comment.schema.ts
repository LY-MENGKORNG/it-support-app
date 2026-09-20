import { z } from 'zod';

export type { Comment } from '@config/db/generated/prisma/client';

export const createCommentSchema = z.object({
  content: z.string().trim().min(1).max(2000),
});
