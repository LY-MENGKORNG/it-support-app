import type { IncomingMessage, ServerResponse } from 'node:http';
import { Injectable, Logger, type NestMiddleware } from '@nestjs/common';

/**
 * Logs one line per HTTP request: method, path, status and duration.
 *
 * Under the Fastify adapter this runs through `@fastify/middie`, which hands
 * Express-style middleware the raw Node request/response — not the
 * `FastifyRequest`/`FastifyReply` wrappers — so these are the plain http.*
 * types, not Fastify's.
 */
@Injectable()
export class RequestLoggerMiddleware implements NestMiddleware {
  private readonly logger = new Logger('HTTP');

  use(
    req: IncomingMessage,
    res: ServerResponse,
    next: (err?: unknown) => void,
  ) {
    const startedAt = Date.now();

    // `finish` fires once the response has been handed to the socket, which is
    // the only point where the status code is final.
    res.once('finish', () => {
      const { method, url } = req;
      const message = `${method} ${url} ${res.statusCode} ${Date.now() - startedAt}ms`;

      if (res.statusCode >= 500) this.logger.error(message);
      else if (res.statusCode >= 400) this.logger.warn(message);
      else this.logger.log(message);
    });

    next();
  }
}
