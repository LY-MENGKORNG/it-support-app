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
import {
  type NewRequest,
  request,
} from './request.schema';
import { ListRequestQuery } from './request.dto';

/** `%` and `_` are wildcards in SQL LIKE, so a user typing them means them literally. */
const escapeLike = (value: string) =>
  value.replace(/[\\%_]/g, (char) => `\\${char}`);

/** Ordering for `sort=priority`: most urgent first, newest first within a level. */
const PRIORITY_RANK = sql`
  case ${request.priority}
    when 'critical' then 0
    when 'high' then 1
    when 'medium' then 2
    else 3
  end`;

/** The columns a request can actually be updated with. */
export type RequestPatch = Partial<NewRequest>;

/**
 * All database access for requests, including the audit trail that belongs to
 * them.
 *
 * History lives here rather than in `RequestHistoryRepository` because a change
 * and its history row must be written atomically — splitting them across two
 * repositories would mean either a transaction leaking into the service layer,
 * or an audit trail that can silently drift from the record it describes.
 */
@Injectable()
export class RequestRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) { }

  /**
   * One page of the list view. Rows are flat — each request carries its
   * requester, assignee and category inline — because a list never needs
   * comments or history. Those come from {@link findDetail}.
   */
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
      // A LEFT JOIN with no match still produces an object of nulls; an
      // unassigned request should read as `assignee: null` on the wire.
      rows: rows.map((row) => ({
        ...row,
        assignee: row.assignee?.id == null ? null : row.assignee,
      })),
      total,
    };
  }

  /** The full record: people, comments and audit trail included. */
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

  /** The bare row, with no relations — enough to diff an update against. */
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

  /**
   * Inserts a request and its opening history rows in one transaction, and
   * returns the new id. The caller re-reads through {@link findDetail} so the
   * response shape matches every other endpoint.
   */
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

  /**
   * Applies a patch and appends its history rows atomically, so the trail can
   * never describe a change that did not land.
   */
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

  /**
   * Turns the query string into SQL conditions. Returns `undefined` when
   * nothing was filtered, which drizzle reads as "no WHERE clause".
   */
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
