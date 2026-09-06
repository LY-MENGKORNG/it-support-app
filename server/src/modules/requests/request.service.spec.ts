import { describe, it, expect } from 'bun:test';
import { ForbiddenException, NotFoundException } from '@nestjs/common';
import { RequestService } from './request.service';
import type { RequestRepository } from './request.repository';
import type { AuthenticatedUser } from '../auth/auth.schema';
import type { NewRequest, Request } from './request.schema';
import { RequestHistoryDraft } from '@modules/request-histories/request-history.schema';

const EMPLOYEE: AuthenticatedUser = {
  id: 11,
  email: 'malis@example.com',
  role: 'employee',
};
const OTHER_EMPLOYEE: AuthenticatedUser = {
  id: 12,
  email: 'kosal@example.com',
  role: 'employee',
};
const STAFF: AuthenticatedUser = {
  id: 7,
  email: 'bopha@example.com',
  role: 'staff',
};

const existing = {
  id: 42,
  title: 'Wi-Fi drops',
  description: 'Every afternoon.',
  categoryId: 3,
  priority: 'medium',
  status: 'open',
  requesterId: EMPLOYEE.id,
  assigneeId: null,
  createdAt: new Date(),
  updatedAt: new Date(),
  resolvedAt: null,
  closedAt: null,
} as Request;

function buildService() {
  const updates: { patch: unknown; entries: unknown[] }[] = [];
  const inserts: { values: NewRequest; entries: RequestHistoryDraft[] }[] = [];

  const repository = {
    findById: (id: number) => (id === existing.id ? existing : undefined),
    findDetail: (id: number) =>
      id === existing.id || id === 99 ? { ...existing, id } : undefined,
    updateWithHistory: (_id: number, patch: unknown, entries: unknown[]) =>
      updates.push({ patch, entries }),
    insertWithHistory: (values: NewRequest, entries: RequestHistoryDraft[]) => {
      inserts.push({ values, entries });
      return 99;
    },
  } as unknown as RequestRepository;

  return { service: new RequestService(repository), updates, inserts };
}

describe('RequestService authorisation', () => {
  it('attributes a new request to the caller, not to the body', async () => {
    const { service, inserts } = buildService();

    await service.create(
      {
        title: 'Wi-Fi drops',
        description: 'Every afternoon.',
        categoryId: 3,
        priority: 'medium',
      },
      EMPLOYEE,
    );

    expect(inserts[0].values.requesterId).toBe(EMPLOYEE.id);
    expect(inserts[0].entries[0]).toMatchObject({
      userId: EMPLOYEE.id,
      action: 'created',
    });
  });

  it('refuses to let an employee assign a request they are creating', () => {
    const { service } = buildService();

    expect(
      service.create(
        {
          title: 'Wi-Fi drops',
          description: 'Every afternoon.',
          categoryId: 3,
          priority: 'medium',
          assigneeId: STAFF.id,
        },
        EMPLOYEE,
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('lets staff change status, and records who did it', async () => {
    const { service, updates } = buildService();

    await service.update(existing.id, { status: 'resolved' }, STAFF);

    expect(updates[0].entries).toEqual([
      expect.objectContaining({
        action: 'status_changed',
        oldValue: 'open',
        newValue: 'resolved',
        userId: STAFF.id,
      }),
    ]);
  });

  it('refuses a status change from the person who raised it', () => {
    const { service } = buildService();

    expect(
      service.update(existing.id, { status: 'resolved' }, EMPLOYEE),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('refuses an assignment from the person who raised it', () => {
    const { service } = buildService();

    expect(
      service.update(existing.id, { assigneeId: STAFF.id }, EMPLOYEE),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('lets the requester correct their own wording', async () => {
    const { service, updates } = buildService();

    await service.update(existing.id, { title: 'Wi-Fi drops daily' }, EMPLOYEE);

    expect(updates).toHaveLength(1);
  });

  it("hides someone else's request from an employee", () => {
    const { service } = buildService();

    expect(
      service.update(existing.id, { title: 'Not mine' }, OTHER_EMPLOYEE),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
