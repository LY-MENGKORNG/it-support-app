import { Inject, Injectable } from '@nestjs/common';
import {
  and,
  asc,
  count,
  desc,
  eq,
  like,
  or,
  sql,
  type SQL,
} from 'drizzle-orm';
import { alias } from 'drizzle-orm/sqlite-core';

import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { category } from '../categories/category.schema';
import {
  type RequestHistoryDraft,
  requestHistory,
} from '../request-histories/request-history.schema';
import { publicUserColumns, user } from '../users/user.schema';
import { type NewRequest, request } from './request.schema';
import { ListRequestQuery } from './request.dto';

const escapeLike = (value: string) =>
  value.replace(/[\\%_]/g, (char) => `\\${char}`);

const PRIORITY_RANK = sql`
  case ${request.priority}
    when 'critical' then 0
    when 'high' then 1
    when 'medium' then 2
    else 3
  end`;

export type RequestPatch = Partial<NewRequest>;

@Injectable()
export class RequestRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) { }

  async findPage(query: ListRequestQuery) {
    const { limit, offset } = query;
    const requester = alias(user, 'requester');
    const assignee = alias(user, 'assignee');
    const where = this.buildFilters(query);

    const rows = await this.db
      .select({
        id: request.id,
        title: request.title,
        description: request.description,
        priority: request.priority,
        status: request.status,
        createdAt: request.createdAt,
        updatedAt: request.updatedAt,
        resolvedAt: request.resolvedAt,
        closedAt: request.closedAt,
        categoryId: request.categoryId,
        requesterId: request.requesterId,
        assigneeId: request.assigneeId,
        category: { id: category.id, name: category.name },
        requester: {
          id: requester.id,
          name: requester.name,
          email: requester.email,
          role: requester.role,
        },
        assignee: {
          id: assignee.id,
          name: assignee.name,
          email: assignee.email,
          role: assignee.role,
        },
      })
      .from(request)
      .innerJoin(category, eq(request.categoryId, category.id))
      .innerJoin(requester, eq(request.requesterId, requester.id))
      .leftJoin(assignee, eq(request.assigneeId, assignee.id))
      .where(where)
      .orderBy(...this.buildOrderBy(query.sort))
      .limit(limit)
      .offset(offset);

    const [{ total }] = await this.db
      .select({ total: count() })
      .from(request)
      .where(where);

    return {
      rows: rows.map((row) => ({
        ...row,
        assignee: row.assignee?.id == null ? null : row.assignee,
      })),
      total,
    };
  }

  findDetail(id: number) {
    return this.db.query.request.findFirst({
      where: { id },
      with: {
        category: true,
        requester: { columns: publicUserColumns },
        assignee: { columns: publicUserColumns },
        comments: {
          with: { user: { columns: publicUserColumns } },
          orderBy: { createdAt: 'asc', id: 'asc' },
        },
        history: {
          with: { user: { columns: publicUserColumns } },
          orderBy: { createdAt: 'desc', id: 'desc' },
        },
      },
    });
  }

  findById(id: number) {
    return this.db.query.request.findFirst({ where: { id } });
  }

  async exists(id: number) {
    const found = await this.db.query.request.findFirst({
      where: { id },
      columns: { id: true },
    });
    return found != null;
  }

  insertWithHistory(values: NewRequest, entries: RequestHistoryDraft[]) {
    return this.db.transaction((tx) => {
      const created = tx.insert(request).values(values).returning().get();

      if (entries.length) {
        tx.insert(requestHistory)
          .values(entries.map((entry) => ({ ...entry, requestId: created.id })))
          .run();
      }

      return created.id;
    });
  }

  updateWithHistory(
    id: number,
    patch: RequestPatch,
    entries: RequestHistoryDraft[],
  ) {
    this.db.transaction((tx) => {
      tx.update(request).set(patch).where(eq(request.id, id)).run();

      if (entries.length) {
        tx.insert(requestHistory)
          .values(entries.map((entry) => ({ ...entry, requestId: id })))
          .run();
      }
    });
  }

  private buildFilters(query: ListRequestQuery): SQL | undefined {
    const conditions: SQL[] = [];

    if (query.q) {
      const pattern = `%${escapeLike(query.q)}%`;
      conditions.push(
        or(like(request.title, pattern), like(request.description, pattern))!,
      );
    }
    if (query.status) conditions.push(eq(request.status, query.status));
    if (query.priority) conditions.push(eq(request.priority, query.priority));
    if (query.categoryId)
      conditions.push(eq(request.categoryId, query.categoryId));
    if (query.requesterId)
      conditions.push(eq(request.requesterId, query.requesterId));

    if (query.unassigned) {
      conditions.push(sql`${request.assigneeId} is null`);
    } else if (query.assigneeId) {
      conditions.push(eq(request.assigneeId, query.assigneeId));
    }

    return conditions.length ? and(...conditions) : undefined;
  }

  private buildOrderBy(sort: ListRequestQuery['sort']) {
    switch (sort) {
      case 'oldest':
        return [asc(request.createdAt), asc(request.id)];
      case 'priority':
        return [PRIORITY_RANK, desc(request.createdAt)];
      default:
        return [desc(request.createdAt), desc(request.id)];
    }
  }
}
