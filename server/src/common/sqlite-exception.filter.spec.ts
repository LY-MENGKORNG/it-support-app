import { describe, expect, it } from 'bun:test';
import { ConflictException } from '@nestjs/common';
import { LibsqlError } from '@libsql/client';
import { DrizzleQueryError } from 'drizzle-orm';
import { asConflict } from './sqlite-exception.filter';

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

/** A local file adds a second cause carrying SQLite's extended code. */
const local = (detail: string, extended: string) => {
  const native = Object.assign(new Error(detail), { code: extended });
  const driver = new LibsqlError(
    `SQLITE_CONSTRAINT: ${detail}`,
    'SQLITE_CONSTRAINT',
  );
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

  it('leaves a database error that is not a constraint failure alone', () => {
    expect(asConflict(remote('database is locked'))).toBeNull();
    expect(asConflict(new Error('kaboom'))).toBeNull();
    expect(asConflict(undefined)).toBeNull();
  });
});
