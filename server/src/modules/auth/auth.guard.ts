import {
  ForbiddenException,
  Injectable,
  UnauthorizedException,
  type CanActivate,
  type ExecutionContext,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Request } from 'express';
import type { Role } from '@common/constants';
import { AuthService } from './auth.service';
import { IS_PUBLIC, REQUIRED_ROLES } from './auth.decorator';
import type { AuthenticatedUser } from './auth.schema';

/**
 * The single gate in front of every route.
 *
 * Registered globally in {@link AuthModule}, so the default is "authentication
 * required" and opting out is an explicit `@Public()`. It does two things and
 * no more: prove who the caller is, and check that role against whatever
 * `@Roles()` the handler asked for. Rules about *what a user may do to a
 * particular record* are business logic and belong in the services.
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly auth: AuthService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext) {
    // `getAllAndOverride` reads the handler first, then the controller, so a
    // single public route inside a protected controller works as written.
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest<Request>();
    const token = bearerTokenFrom(request.headers.authorization);
    if (!token) throw new UnauthorizedException('Missing bearer token');

    const user = await this.auth.verify(token);

    // Handlers read this through `@CurrentUser()` rather than touching the
    // request object themselves.
    (request as Request & { user: AuthenticatedUser }).user = user;

    const required = this.reflector.getAllAndOverride<Role[]>(REQUIRED_ROLES, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (required?.length && !required.includes(user.role)) {
      // 403, not 401: the caller is authenticated, just not allowed. Answering
      // 401 here would send a client into a pointless sign-in loop.
      throw new ForbiddenException('Your role does not allow this action');
    }

    return true;
  }
}

/** `Authorization: Bearer <token>` — case-insensitive scheme, per RFC 6750. */
function bearerTokenFrom(header: string | undefined): string | null {
  const [scheme, token] = header?.split(' ') ?? [];
  return scheme?.toLowerCase() === 'bearer' && token ? token : null;
}
