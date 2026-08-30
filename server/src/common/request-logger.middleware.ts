import { Injectable, Logger, type NestMiddleware } from '@nestjs/common';
import type { NextFunction, Request, Response } from 'express';

/**
 * Logs one line per HTTP request: method, path, status and duration.
 *
 * Nest logs nothing about traffic by default, which makes "is the app even
 * reaching the server?" surprisingly hard to answer. This is the cheapest way
 * to see the client and server talking.
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
