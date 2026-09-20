import { z } from 'zod';
import { PRIORITY, REQUEST_STATUS } from '../../common/constants';
import type { Prisma } from '@config/db/generated/prisma/client';

export type { Request } from '@config/db/generated/prisma/client';
export type NewRequest = Prisma.RequestUncheckedCreateInput;

export const createRequestSchema = z.object({
  title: z.string().trim().min(3).max(120),
  description: z.string().trim().min(1).max(5000),
  categoryId: z.coerce.number().int().positive(),
  priority: z.enum(PRIORITY).default('medium'),
  assigneeId: z.coerce.number().int().positive().nullish(),
});

export const updateRequestSchema = z
  .object({
    title: z.string().trim().min(3).max(120),
    description: z.string().trim().min(1).max(5000),
    categoryId: z.coerce.number().int().positive(),
    priority: z.enum(PRIORITY),
    status: z.enum(REQUEST_STATUS),
    assigneeId: z.coerce.number().int().positive().nullable(),
  })
  .partial()
  .refine((dto) => Object.keys(dto).length > 0, 'No fields to update');

export const listRequestQuerySchema = z.object({
  q: z.string().trim().min(1).optional(),
  status: z.enum(REQUEST_STATUS).optional(),
  priority: z.enum(PRIORITY).optional(),
  categoryId: z.coerce.number().int().positive().optional(),
  requesterId: z.coerce.number().int().positive().optional(),
  assigneeId: z.coerce.number().int().positive().optional(),
  unassigned: z.stringbool().optional(),
  sort: z.enum(['newest', 'oldest', 'priority']).default('newest'),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  offset: z.coerce.number().int().min(0).default(0),
});
