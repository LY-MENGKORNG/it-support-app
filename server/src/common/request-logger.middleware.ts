import { Injectable, Logger, type NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

/**
 * Logs one line per HTTP request: method, path, status and duration.
 */
@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction) {
    const startedAt = Date.now();

    // `finish` fires once the response has been handed to the socket, which is
    // the only point where the status code is final.
    res.once('finish', () => {
      const { method, originalUrl } = req;
      const message = `${method} ${originalUrl} ${res.statusCode} ${Date.now() - startedAt}ms`;

      if (res.statusCode >= 500) this.logger.error(message);
      else if (res.statusCode >= 400) this.logger.warn(message);
      else this.logger.log(message);
    });

    next();
  }
}
