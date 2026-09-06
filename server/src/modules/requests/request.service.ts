import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';

import { type AuthenticatedUser } from '../auth/auth.schema';
import { type RequestHistoryDraft } from '../request-histories/request-history.schema';
import { RequestRepository, type RequestPatch } from './request.repository';
import { type Request } from './request.schema';
import {
  CreateRequestDto,
  ListRequestQuery,
  UpdateRequestDto,
} from './request.dto';

type RequestChanges = UpdateRequestDto;

const STAFF_ONLY_FIELDS = [
  'status',
  'assigneeId',
] as const satisfies readonly (keyof RequestChanges)[];

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

  private assertMayUpdate(
    existing: Request,
    changes: RequestChanges,
    actor: AuthenticatedUser,
  ) {
    if (isSupportStaff(actor)) return;

    if (existing.requesterId !== actor.id) {
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

function isSupportStaff(actor: AuthenticatedUser) {
  return actor.role === 'staff' || actor.role === 'admin';
}
