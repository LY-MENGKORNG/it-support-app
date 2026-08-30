import {
  SetMetadata,
  createParamDecorator,
  type ExecutionContext,
} from '@nestjs/common';
import type { Role } from '@common/constants';
import type { AuthenticatedUser } from './auth.schema';

export const IS_PUBLIC = 'auth:public';
export const REQUIRED_ROLES = 'auth:roles';

/**
 * Opens a route to unauthenticated callers.
 *
 * The guard is registered globally, so *everything* needs a token unless it
 * says otherwise here. Defaulting to closed means a new controller is
 * protected the moment it is written, rather than the moment someone
 * remembers to protect it.
 */
export const Public = () => SetMetadata(IS_PUBLIC, true);

/**
 * Restricts a route to the listed roles.
 *
 * Checked by {@link AuthGuard} after the token is verified, so a handler
 * carrying this decorator can assume both that the caller is who they say they
 * are and that they are allowed to be here.
 */
export const Roles = (...roles: Role[]) => SetMetadata(REQUIRED_ROLES, roles);

/**
 * Injects the caller the token identified.
 *
 * This is the whole point of token auth: a handler asks *who is calling*
 * instead of trusting an id in the body, so a client cannot act as someone
 * else by editing a JSON field.
 */
export const CurrentUser = createParamDecorator(
  (key: keyof AuthenticatedUser | undefined, context: ExecutionContext) => {
    const user = context.switchToHttp().getRequest<{
      user?: AuthenticatedUser;
    }>().user;

    // Unreachable behind the guard; a loud failure beats silently attributing
    // a write to `undefined` if a route is ever made public by mistake.
    if (!user) throw new Error('No authenticated user on the request');

    return key ? user[key] : user;
  },
);
