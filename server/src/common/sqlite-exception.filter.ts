import {
  type ArgumentsHost, Catch, ConflictException,
  type ExceptionFilter, Logger,
} from '@nestjs/common';
import { BaseExceptionFilter } from '@nestjs/core';
import { SQLiteError } from 'bun:sqlite';

@Catch(SQLiteError)
export class SQLiteExceptionFilter extends BaseExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(SQLiteExceptionFilter.name);

  catch(error: SQLiteError, host: ArgumentsHost) {
    const code = error.code ?? '';

    if (code.startsWith('SQLITE_CONSTRAINT_UNIQUE')) {
      return super.catch(new ConflictException('Resource already exists'), host);
    }
    if (code.startsWith('SQLITE_CONSTRAINT_FOREIGNKEY')) {
      return super.catch(new ConflictException('Referenced resource does not exist'), host);
    }

    this.logger.error(`${code}: ${error.message}`, error.stack);
    return super.catch(error, host);   // falls through to 500
  }
}
