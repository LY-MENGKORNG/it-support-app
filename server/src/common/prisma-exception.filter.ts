import {
  type ArgumentsHost,
  Catch,
  ConflictException,
  type ExceptionFilter,
  IntrinsicException,
  Logger,
} from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import { Prisma } from '@config/db/generated/prisma/client';

/**
 * Turns a constraint violation into the 409 it deserves instead of a 500.
 *
 * Unlike the driver errors Drizzle used to wrap, `PrismaClientKnownRequestError`
 * never carries the bound values — its `message`/`meta`/`stack` only name the
 * constraint and the call site — so there is nothing to redact before logging.
 */
@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter
  extends BaseExceptionFilter
  implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(error: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost) {
    const conflict = asConflict(error);
    if (conflict) return super.catch(conflict, host);

    this.logger.error(`${error.code}: ${error.message}`, error.stack);

    // Falls through to the same 500, but as an `IntrinsicException` — Nest's
    // marker for "already logged". Handing `super` the original would log it
    // a second time.
    return super.catch(new IntrinsicException(error.message), host);
  }
}

const CONFLICT_MESSAGES: Partial<Record<string, string>> = {
  P2002: 'Resource already exists',
  P2003: 'Referenced resource does not exist',
};

/**
 * The 409 this error deserves, or `null` when it is not a constraint failure.
 *
 * Exported for the tests: the mapping is the part worth pinning down.
 */
export function asConflict(error: unknown): ConflictException | null {
  if (!(error instanceof Prisma.PrismaClientKnownRequestError)) return null;

  const message = CONFLICT_MESSAGES[error.code];
  return message ? new ConflictException(message) : null;
}
