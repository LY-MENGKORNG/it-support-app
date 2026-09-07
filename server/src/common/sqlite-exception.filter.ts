import {
  type ArgumentsHost,
  Catch,
  ConflictException,
  type ExceptionFilter,
  Logger,
} from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import { LibsqlError } from '@libsql/client';
import { DrizzleQueryError } from 'drizzle-orm';

/**
 * Turns a constraint violation into the 409 it deserves instead of a 500.
 *
 * Three things about this stack make it less obvious than it looks, and the
 * first version of this filter got all three wrong, so it never ran once:
 *
 * - Drizzle wraps driver errors. What reaches Nest is a `DrizzleQueryError`
 *   whose own `message` is just the failed SQL — it carries no constraint
 *   information at all, and no `code`.
 * - Under that, the driver throws `LibsqlError`, not `bun:sqlite`'s
 *   `SQLiteError`. Nest matches `@Catch` by `instanceof`, so catching the
 *   latter matched nothing.
 * - `LibsqlError.code` is the bare `SQLITE_CONSTRAINT`. *Which* constraint
 *   failed is only in its message; SQLite's extended `SQLITE_CONSTRAINT_UNIQUE`
 *   code appears one level deeper still, and only when the database is a local
 *   file rather than a remote Turso one.
 *
 * So: catch the wrapper, then read the whole `cause` chain, and match on the
 * message as well as the code.
 */
@Catch(DrizzleQueryError, LibsqlError)
export class SQLiteExceptionFilter
  extends BaseExceptionFilter
  implements ExceptionFilter {
  private readonly logger = new Logger(SQLiteExceptionFilter.name);

  catch(error: Error, host: ArgumentsHost) {
    const conflict = asConflict(error);
    if (conflict) return super.catch(conflict, host);

    this.logger.error(error.message, error.stack);
    return super.catch(error, host); // falls through to 500
  }
}

const CONSTRAINTS = [
  {
    pattern: /UNIQUE constraint failed|SQLITE_CONSTRAINT_UNIQUE/,
    message: 'Resource already exists',
  },
  {
    pattern: /FOREIGN KEY constraint failed|SQLITE_CONSTRAINT_FOREIGNKEY/,
    message: 'Referenced resource does not exist',
  },
] as const;

/**
 * The 409 this error deserves, or `null` when it is not a constraint failure.
 *
 * Exported for the tests: the mapping is the part worth pinning down, and it is
 * the part that was silently broken.
 */
export function asConflict(error: unknown): ConflictException | null {
  for (const link of causes(error)) {
    const detail = `${String(JSON.stringify(link.code ?? ''))} ${link.message}`;

    for (const { pattern, message } of CONSTRAINTS) {
      if (pattern.test(detail)) return new ConflictException(message);
    }
  }
  return null;
}

/** An error and its `cause` chain, nearest first. */
function* causes(error: unknown): Generator<Error & { code?: unknown }> {
  let current = error;

  // The chain is three deep at most here. The bound only exists so that a
  // self-referential `cause` cannot spin forever.
  for (let depth = 0; current instanceof Error && depth < 8; depth++) {
    yield current;
    current = current.cause;
  }
}
