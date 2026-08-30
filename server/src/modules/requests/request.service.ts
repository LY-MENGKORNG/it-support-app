import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { type AuthenticatedUser } from '../auth/auth.schema';
import { type RequestHistoryDraft } from '../request-histories/request-history.schema';
import { RequestRepository, type RequestPatch } from './request.repository';
import {
  type Request,
} from './request.schema';
import { CreateRequestDto, ListRequestQuery, UpdateRequestDto } from './request.dto';

/** The fields an update is allowed to touch. */
type RequestChanges = UpdateRequestDto;

/**
 * Changes only IT staff may make.
 *
 * Anyone may correct the wording or urgency of their own request; deciding that
 * it is resolved, or who is going to handle it, is the support team's call.
 */
const STAFF_ONLY_FIELDS = [
  'status',
  'assigneeId',
] as const satisfies readonly (keyof RequestChanges)[];

/**
 * Business rules for requests: what a change *means*.
 *
 * Deciding which changes are worth recording, and which timestamps a status
 * implies, is policy — it lives here. Where the rows actually go is
 * {@link RequestRepository}'s problem.
 */
@Injectable()
export class RequestService {
  constructor(private readonly repository: RequestRepository) { }

  async list(query: ListRequestQuery) {
    const { rows, total } = await this.repository.findPage(query);
    const { limit, offset } = query;

    return {
      items: rows,
      total,
      limit,
      offset,
      hasMore: offset + rows.length < total,
    };
  }

  async findOne(id: number) {
    const found = await this.repository.findDetail(id);
    if (!found) throw new NotFoundException(`Request ${id} not found`);
    return found;
  }

  /**
   * The requester is the caller, full stop — there is no way to raise a request
   * in someone else's name, because there is no field in which to say so.
   */
  // `async` so the guard below rejects rather than throwing synchronously: a
  // method that returns a promise on the happy path and throws on the unhappy
  // one forces every caller to handle failure twice.
  async create(dto: CreateRequestDto, actor: AuthenticatedUser) {
    const { assigneeId, ...rest } = dto;
    const assignee = assigneeId ?? null;
    const requesterId = actor.id;

    if (assignee !== null && !isSupportStaff(actor)) {
      throw new ForbiddenException('Only IT staff can assign a request');
    }

    const entries: RequestHistoryDraft[] = [
      {
        userId: requesterId,
        action: 'created',
        oldValue: null,
        newValue: 'open',
      },
      // A request created already assigned is two events, not one.
      ...(assignee == null
        ? []
        : [
          {
            userId: requesterId,
            action: 'assigned' as const,
            oldValue: null,
            newValue: String(assignee),
          },
        ]),
    ];

    const id = this.repository.insertWithHistory(
      { ...rest, requesterId, assigneeId: assignee, status: 'open' },
      entries,
    );

    return this.findOne(id);
  }

  async update(
    id: number,
    changes: UpdateRequestDto,
    actor: AuthenticatedUser,
  ) {
    const existing = await this.repository.findById(id);
    if (!existing) throw new NotFoundException(`Request ${id} not found`);

    this.assertMayUpdate(existing, changes, actor);

    const entries = this.diff(existing, changes).map((entry) => ({
      ...entry,
      userId: actor.id,
    }));
    const patch: RequestPatch = {
      ...changes,
      ...this.statusTimestamps(existing, changes),
    };

    this.repository.updateWithHistory(id, patch, entries);

    return this.findOne(id);
  }

  /**
   * Who may change what.
   *
   * This is a rule about *this record and this caller*, not about the route, so
   * it lives here rather than in a guard — `AuthGuard` can tell that you are an
   * employee, but only the service knows whether this is your request.
   */
  private assertMayUpdate(
    existing: Request,
    changes: RequestChanges,
    actor: AuthenticatedUser,
  ) {
    if (isSupportStaff(actor)) return;

    if (existing.requesterId !== actor.id) {
      // 404, not 403: a request you cannot touch is one you have no business
      // knowing exists.
      throw new NotFoundException(`Request ${existing.id} not found`);
    }

    const reserved = STAFF_ONLY_FIELDS.filter(
      (field) => changes[field] !== undefined,
    );
    if (reserved.length) {
      throw new ForbiddenException(
        `Only IT staff can change: ${reserved.join(', ')}`,
      );
    }
  }

  /** One history entry per field that actually changed value. */
  private diff(
    before: Request,
    changes: RequestChanges,
  ): Omit<RequestHistoryDraft, 'userId'>[] {
    const entries: Omit<RequestHistoryDraft, 'userId'>[] = [];
    const changed = <K extends keyof RequestChanges>(key: K) =>
      changes[key] !== undefined && changes[key] !== before[key];

    if (changed('status')) {
      entries.push({
        action: 'status_changed',
        oldValue: before.status,
        newValue: changes.status!,
      });
    }
    if (changed('priority')) {
      entries.push({
        action: 'priority_changed',
        oldValue: before.priority,
        newValue: changes.priority!,
      });
    }
    if (changed('categoryId')) {
      entries.push({
        action: 'category_changed',
        oldValue: String(before.categoryId),
        newValue: String(changes.categoryId!),
      });
    }
    if (changed('assigneeId')) {
      const next = changes.assigneeId ?? null;
      entries.push({
        action: next == null ? 'unassigned' : 'assigned',
        oldValue: before.assigneeId == null ? null : String(before.assigneeId),
        newValue: next == null ? null : String(next),
      });
    }

    return entries;
  }

  /**
   * `resolvedAt` / `closedAt` are derived from status, never set by the client —
   * otherwise a reopened request keeps a stale resolution date.
   */
  private statusTimestamps(
    before: Request,
    changes: RequestChanges,
  ): RequestPatch {
    if (!changes.status || changes.status === before.status) return {};

    const now = new Date();
    switch (changes.status) {
      case 'resolved':
        return { resolvedAt: now, closedAt: null };
      case 'closed':
        return { resolvedAt: before.resolvedAt ?? now, closedAt: now };
      default:
        return { resolvedAt: null, closedAt: null };
    }
  }
}

/** Staff and admins; everyone else is an employee raising their own requests. */
function isSupportStaff(actor: AuthenticatedUser) {
  return actor.role === 'staff' || actor.role === 'admin';
}
