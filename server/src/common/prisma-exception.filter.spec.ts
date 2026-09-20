import { describe, expect, it } from 'bun:test';
import { type ArgumentsHost, ConflictException } from '@nestjs/common';
import { FILTER_CATCH_EXCEPTIONS } from '@nestjs/common/constants';
import { Prisma } from '@config/db/generated/prisma/client';
import { PrismaExceptionFilter, asConflict } from './prisma-exception.filter';

/** What Prisma really throws — no bound values, just the code and metadata. */
const knownError = (
  code: string,
  message: string,
  meta?: Record<string, unknown>,
) =>
  new Prisma.PrismaClientKnownRequestError(message, {
    code,
    clientVersion: '7.10.0',
    meta,
  });

describe('asConflict', () => {
  it('maps a unique violation to 409', () => {
    const conflict = asConflict(
      knownError(
        'P2002',
        'Unique constraint failed on the constraint: `User_email_key`',
        {
          modelName: 'User',
          target: ['email'],
        },
      ),
    );

    expect(conflict).toBeInstanceOf(ConflictException);
    expect(conflict?.message).toBe('Resource already exists');
  });

  it('maps a foreign key violation to 409', () => {
    const conflict = asConflict(
      knownError(
        'P2003',
        'Foreign key constraint violated: `Request_categoryId_fkey`',
      ),
    );

    expect(conflict?.message).toBe('Referenced resource does not exist');
  });

  it('leaves a Prisma error that is not a constraint failure alone', () => {
    expect(
      asConflict(knownError('P2025', 'Record to update not found.')),
    ).toBeNull();
  });

  it('leaves a non-Prisma error alone', () => {
    expect(asConflict(new Error('kaboom'))).toBeNull();
    expect(asConflict(undefined)).toBeNull();
  });
});

describe('PrismaExceptionFilter', () => {
  class StubAdapter {
    readonly replies: { body: unknown; status: number }[] = [];

    isHeadersSent() {
      return false;
    }

    reply(_response: unknown, body: unknown, status: number) {
      this.replies.push({ body, status });
    }

    end() {}
  }

  const host = {
    getArgByIndex: () => ({}),
  } as unknown as ArgumentsHost;

  const answer = (error: Prisma.PrismaClientKnownRequestError) => {
    const adapter = new StubAdapter();
    new PrismaExceptionFilter(adapter as never).catch(error, host);
    return adapter.replies[0];
  };

  it('is registered for PrismaClientKnownRequestError', () => {
    expect(
      Reflect.getMetadata(FILTER_CATCH_EXCEPTIONS, PrismaExceptionFilter),
    ).toEqual([Prisma.PrismaClientKnownRequestError]);
  });

  it('answers a constraint violation with 409 and the mapped message', () => {
    expect(
      answer(
        knownError(
          'P2002',
          'Unique constraint failed on the constraint: `Category_name_key`',
        ),
      ),
    ).toEqual({
      status: 409,
      body: {
        statusCode: 409,
        error: 'Conflict',
        message: 'Resource already exists',
      },
    });
  });

  it("still answers 500 for a Prisma error that is nobody's fault", () => {
    expect(
      answer(
        knownError('P2024', 'Timed out fetching a connection from the pool.'),
      )?.status,
    ).toBe(500);
  });
});
