import { PrismaPg } from '@prisma/adapter-pg';
import { env } from '@config/env.config';
import { PrismaClient } from './generated/prisma/client';

const adapter = new PrismaPg({ connectionString: env.DATABASE_URL });

export const db = new PrismaClient({ adapter });

export type PrismaDB = typeof db;
