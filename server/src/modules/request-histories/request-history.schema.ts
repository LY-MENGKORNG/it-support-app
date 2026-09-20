import type { Prisma } from '@config/db/generated/prisma/client';
import z from 'zod/v4';

export const requestResponseSchema = z.object({});

export type { RequestHistory } from '@config/db/generated/prisma/client';

export type RequestHistoryDraft = Omit<
  Prisma.RequestHistoryUncheckedCreateInput,
  'id' | 'requestId' | 'createdAt'
>;
