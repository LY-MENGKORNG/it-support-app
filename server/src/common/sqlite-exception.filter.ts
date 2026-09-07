import {
  type ArgumentsHost,
  Catch,
  ConflictException,
  type ExceptionFilter,
  IntrinsicException,
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
 *   whose own `message` is the failed SQL *and the values bound to it* — it
 *   carries no constraint information at all, and no `code`.
 * - Under that, the driver throws `LibsqlError`, not `bun:sqlite`'s
 *   `SQLiteError`. Nest matches `@Catch` by `instanceof`, so catching the
 *   latter matched nothing.
 * - `LibsqlError.code` is the bare `SQLITE_CONSTRAINT`. *Which* constraint
 *   failed is in its message and in `extendedCode` — which a local file fills
 *   in from SQLite (`SQLITE_CONSTRAINT_UNIQUE`) and a remote Turso database
 *   does not fill in at all.
 *
 * So: catch the wrapper, then read the whole `cause` chain — every link except
 * the wrapper itself, whose message is partly client input.
 */
@Catch(DrizzleQueryError, LibsqlError)
export class SQLiteExceptionFilter
  extends BaseExceptionFilter
  implements ExceptionFilter {
  private readonly logger = new Logger(SQLiteExceptionFilter.name);

  catch(error: Error, host: ArgumentsHost) {
    const conflict = asConflict(error);
    if (conflict) return super.catch(conflict, host);

    const detail = failureDetail(error);
    this.logger.error(detail, failureStack(error));

    // Falls through to the same 500, but as an `IntrinsicException` — Nest's
    // marker for "already logged". Handing `super` the original would log it a
    // second time, message included, and that message is where the bound
    // values are.
    return super.catch(new IntrinsicException(detail), host);
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
    // The wrapper is walked through, never read. Its message is
    // `Failed query: <sql>\nparams: <values>`, so it carries client input: a
    // request whose title is the words "UNIQUE constraint failed" would
    // otherwise choose this filter's answer, and a `database is locked` on the
    // same statement would report 409 instead of the 500 a client should retry.
    if (link instanceof DrizzleQueryError) continue;

    // `extendedCode` names the specific constraint; `code` is the bare
    // `SQLITE_CONSTRAINT` to fall back on. `String` rather than template
    // interpolation because the value is typed `unknown` — a `Symbol` code
    // would throw, from inside an exception filter, where nothing is left to
    // catch it.
    const code = String(link.extendedCode ?? link.code ?? '');

    for (const { pattern, message } of CONSTRAINTS) {
      if (pattern.test(`${code} ${link.message}`)) {
        return new ConflictException(message);
      }
    }
  }
  return null;
}

/**
 * What is safe to log about a database failure.
 *
 * `DrizzleQueryError.message` ends in `params: <values>`, and on `POST /user`
 * those values include the bcrypt hash of somebody's password. The SQL and the
 * driver's own complaint are the half worth having.
 *
 * Exported for the tests: a redaction nothing checks is one the next edit drops.
 */
export function failureDetail(error: Error): string {
  if (!(error instanceof DrizzleQueryError)) return error.message;

  const driver = error.cause?.message ?? 'no driver detail';
  return `${driver} (failed query: ${error.query})`;
}

/**
 * The frames, with the same redaction applied to the line above them.
 *
 * A stack begins `Name: message`, so logging `error.stack` next to a redacted
 * message would put the values right back in the log. Replaced through a
 * function so that a `$` in the SQL cannot be read as a substitution pattern.
 */
export function failureStack(error: Error): string | undefined {
  const detail = failureDetail(error);
  return error.stack?.replace(error.message, () => detail);
}

/** An error and its `cause` chain, nearest first. */
function* causes(
  error: unknown,
): Generator<Error & { code?: unknown; extendedCode?: unknown }> {
  let current = error;

  // The chain is three deep at most here. The bound only exists so that a
  // self-referential `cause` cannot spin forever.
  for (let depth = 0; current instanceof Error && depth < 8; depth++) {
    yield current;
    current = current.cause;
  }
}
