import { Inject, Injectable } from '@nestjs/common';
import { PRISMA } from '@common/constants';
import { type PrismaDB } from '@config/db';
import type { Prisma } from '@config/db/generated/prisma/client';
import { type RequestHistoryDraft } from '../request-histories/request-history.schema';
import { publicUserColumns } from '../users/user.schema';
import { type NewRequest } from './request.schema';
import { ListRequestQuery } from './request.dto';

const REQUEST_LIST_SUMMARY_COLUMNS = {
  id: true,
  name: true,
  email: true,
  role: true,
} as const;

export type RequestPatch = Prisma.RequestUncheckedUpdateInput;

@Injectable()
export class RequestRepository {
  constructor(@Inject(PRISMA) private readonly db: PrismaDB) {}

  async findPage(query: ListRequestQuery) {
    const { limit, offset } = query;
    const where = this.buildFilters(query);

    const [rows, total] = await Promise.all([
      this.db.request.findMany({
        where,
        select: {
          id: true,
          title: true,
          description: true,
          priority: true,
          status: true,
          createdAt: true,
          updatedAt: true,
          resolvedAt: true,
          closedAt: true,
          categoryId: true,
          requesterId: true,
          assigneeId: true,
          category: { select: { id: true, name: true } },
          requester: { select: REQUEST_LIST_SUMMARY_COLUMNS },
          assignee: { select: REQUEST_LIST_SUMMARY_COLUMNS },
        },
        orderBy: this.buildOrderBy(query.sort),
        take: limit,
        skip: offset,
      }),
      this.db.request.count({ where }),
    ]);

    return { rows, total };
  }

  findDetail(id: number) {
    return this.db.request.findUnique({
      where: { id },
      include: {
        category: true,
        requester: { select: publicUserColumns },
        assignee: { select: publicUserColumns },
        comments: {
          include: { user: { select: publicUserColumns } },
          orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
        },
        history: {
          include: { user: { select: publicUserColumns } },
          orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        },
      },
    });
  }

  findById(id: number) {
    return this.db.request.findUnique({ where: { id } });
  }

  async exists(id: number) {
    const found = await this.db.request.findUnique({
      where: { id },
      select: { id: true },
    });
    return found != null;
  }

  insertWithHistory(values: NewRequest, entries: RequestHistoryDraft[]) {
    return this.db.$transaction(async (tx) => {
      const created = await tx.request.create({ data: values });

      if (entries.length) {
        await tx.requestHistory.createMany({
          data: entries.map((entry) => ({ ...entry, requestId: created.id })),
        });
      }

      return created.id;
    });
  }

  async updateWithHistory(
    id: number,
    patch: RequestPatch,
    entries: RequestHistoryDraft[],
  ) {
    await this.db.$transaction(async (tx) => {
      await tx.request.update({ where: { id }, data: patch });

      if (entries.length) {
        await tx.requestHistory.createMany({
          data: entries.map((entry) => ({ ...entry, requestId: id })),
        });
      }
    });
  }

  private buildFilters(query: ListRequestQuery): Prisma.RequestWhereInput {
    const where: Prisma.RequestWhereInput = {};

    if (query.q) {
      where.OR = [
        { title: { contains: query.q } },
        { description: { contains: query.q } },
      ];
    }
    if (query.status) where.status = query.status;
    if (query.priority) where.priority = query.priority;
    if (query.categoryId) where.categoryId = query.categoryId;
    if (query.requesterId) where.requesterId = query.requesterId;

    if (query.unassigned) where.assigneeId = null;
    else if (query.assigneeId) where.assigneeId = query.assigneeId;

    return where;
  }

  private buildOrderBy(
    sort: ListRequestQuery['sort'],
  ): Prisma.RequestOrderByWithRelationInput[] {
    switch (sort) {
      case 'oldest':
        return [{ createdAt: 'asc' }, { id: 'asc' }];
      case 'priority':
        // Postgres sorts the native `Priority` enum by declaration order
        // (critical → low), so this alone reproduces "most urgent first".
        return [{ priority: 'asc' }, { createdAt: 'desc' }];
      default:
        return [{ createdAt: 'desc' }, { id: 'desc' }];
    }
  }
}
