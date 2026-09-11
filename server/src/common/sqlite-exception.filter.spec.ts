import { describe, expect, it } from 'bun:test';
import { type ArgumentsHost, ConflictException } from '@nestjs/common';
import { FILTER_CATCH_EXCEPTIONS } from '@nestjs/common/constants';
import { LibsqlError } from '@libsql/client';
import { DrizzleQueryError } from 'drizzle-orm';
import {
  SQLiteExceptionFilter,
  asConflict,
  failureDetail,
  failureStack,
} from './sqlite-exception.filter';

/**
 * The shapes below are copied from what this stack really throws, not invented.
 * That matters: the original filter matched `bun:sqlite`'s `SQLiteError` and the
 * extended `SQLITE_CONSTRAINT_UNIQUE` code, and a real violation carries
 * neither, so a duplicate email answered 500 instead of 409.
 */

/** What a remote Turso database produces: drizzle wrapping one LibsqlError. */
const remote = (detail: string) =>
  new DrizzleQueryError(
    'insert into "user" ("email") values (?)',
    ['taken@example.com'],
    new LibsqlError(`SQLITE_CONSTRAINT: ${detail}`, 'SQLITE_CONSTRAINT'),
  );

/**
 * What a local file produces. `mapSqliteError` copies the native error's code
 * into `extendedCode` and keeps the native error as the cause
 * (`@libsql/client/lib-esm/sqlite3.js`), so the detail arrives three ways at
 * once — which is why the code-only case below has to be tested on its own.
 */
const local = (detail: string, extended: string) => {
  const native = Object.assign(new Error(detail), { code: extended });
  const driver = new LibsqlError(detail, 'SQLITE_CONSTRAINT', extended, 787);
  driver.cause = native;
  return new DrizzleQueryError(
    'insert into "c" ("pid") values (?)',
    [999],
    driver,
  );
};

describe('asConflict', () => {
  it('maps a unique violation from a remote database', () => {
    const conflict = asConflict(remote('UNIQUE constraint failed: user.email'));

    expect(conflict).toBeInstanceOf(ConflictException);
    expect(conflict?.message).toBe('Resource already exists');
  });

  it('maps a foreign key violation from a remote database', () => {
    const conflict = asConflict(remote('FOREIGN KEY constraint failed'));

    expect(conflict).toBeInstanceOf(ConflictException);
    expect(conflict?.message).toBe('Referenced resource does not exist');
  });

  it('reads the extended code a local file buries two causes down', () => {
    expect(
      asConflict(
        local('FOREIGN KEY constraint failed', 'SQLITE_CONSTRAINT_FOREIGNKEY'),
      )?.message,
    ).toBe('Referenced resource does not exist');
  });

  // The half of the mapping every other fixture gets for free from its message.
  // Delete the code from `asConflict` and only this test notices.
  it('maps on the extended code with nothing in the message', () => {
    expect(
      asConflict(
        new LibsqlError(
          'constraint failed',
          'SQLITE_CONSTRAINT',
          'SQLITE_CONSTRAINT_UNIQUE',
        ),
      )?.message,
    ).toBe('Resource already exists');
  });

  it('handles a driver error that reaches the filter unwrapped', () => {
    expect(
      asConflict(
        new LibsqlError(
          'SQLITE_CONSTRAINT: UNIQUE constraint failed: category.name',
          'SQLITE_CONSTRAINT',
        ),
      )?.message,
    ).toBe('Resource already exists');
  });

  // The wrapper's own message is the failed SQL and nothing else, so a filter
  // that only looked at the outermost error could never have worked.
  it('is not fooled by the wrapper alone', () => {
    expect(
      asConflict(
        new DrizzleQueryError('select 1', [], new Error('something else')),
      ),
    ).toBeNull();
  });

  // The wrapper's message includes the bound values, so reading it would let a
  // client pick the answer by choosing what it sends.
  it('ignores the wrapper message, which carries client input', () => {
    const injected = new DrizzleQueryError(
      'insert into "request" ("title") values (?)',
      ['UNIQUE constraint failed'],
      new LibsqlError('SQLITE_BUSY: database is locked', 'SQLITE_BUSY'),
    );

    expect(asConflict(injected)).toBeNull();
  });

  it('leaves a database error that is not a constraint failure alone', () => {
    expect(asConflict(remote('database is locked'))).toBeNull();
    expect(asConflict(new Error('kaboom'))).toBeNull();
    expect(asConflict(undefined)).toBeNull();
  });

  // `code` is typed `unknown` because the chain is arbitrary driver errors, and
  // a throw in here escapes the filter itself: no response would be written.
  it('survives a code that is not a string', () => {
    const odd = Object.assign(new Error('nothing familiar'), {
      code: Symbol('weird'),
    });

    expect(asConflict(odd)).toBeNull();
  });
});

describe('failureDetail', () => {
  it('keeps the query and the driver complaint, drops the values', () => {
    const detail = failureDetail(
      new DrizzleQueryError(
        'insert into "user" ("email", "password_hash") values (?, ?)',
        ['taken@example.com', '$2b$10$hashhashhash'],
        new LibsqlError('SQLITE_BUSY: database is locked', 'SQLITE_BUSY'),
      ),
    );

    expect(detail).toContain('database is locked');
    expect(detail).toContain('insert into "user"');
    expect(detail).not.toContain('$2b$10$hashhashhash');
    expect(detail).not.toContain('taken@example.com');
  });

  it('passes an unwrapped error through', () => {
    expect(failureDetail(new Error('kaboom'))).toBe('kaboom');
  });

  // A stack starts with the message, so redacting one without the other logs
  // the values anyway — which is what the first version of this did.
  it('redacts the stack that goes with it, and keeps the frames', () => {
    const wrapped = new DrizzleQueryError(
      'insert into "user" ("password_hash") values (?)',
      ['$2b$10$hashhashhash'],
      new LibsqlError('SQLITE_BUSY: database is locked', 'SQLITE_BUSY'),
    );

    const stack = failureStack(wrapped);

    expect(stack).not.toContain('$2b$10$hashhashhash');
    expect(stack).toContain('database is locked');
    expect(stack).toContain('at ');
  });
});

/**
 * The filter itself, not just the mapping: `@Catch` matching nothing is exactly
 * how this went unnoticed, and a correct `asConflict` proves nothing about
 * whether anything calls it.
 */
describe('SQLiteExceptionFilter', () => {
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

  const answer = (error: Error) => {
    const adapter = new StubAdapter();
    new SQLiteExceptionFilter(adapter as never).catch(error, host);
    return adapter.replies[0];
  };

  it('is registered for the errors this stack really throws', () => {
    expect(
      Reflect.getMetadata(FILTER_CATCH_EXCEPTIONS, SQLiteExceptionFilter),
    ).toEqual([DrizzleQueryError, LibsqlError]);
  });

  it('answers a constraint violation with 409 and the mapped message', () => {
    expect(answer(remote('UNIQUE constraint failed: user.email'))).toEqual({
      status: 409,
      body: {
        statusCode: 409,
        error: 'Conflict',
        message: 'Resource already exists',
      },
    });
  });

  it("still answers 500 for a database failure that is nobody's fault", () => {
    expect(answer(remote('database is locked'))?.status).toBe(500);
  });
});
