import { describe, it, expect } from 'bun:test';
import { UnauthorizedException } from '@nestjs/common';
import type { JwtService } from '@nestjs/jwt';
import { AuthService } from './auth.service';
import type { UserRepository } from '../users/user.repository';

/**
 * Login's failure behaviour, which is the part worth pinning down: every
 * rejection has to look identical from the outside, or the endpoint becomes a
 * way to find out who works here and whose account is disabled.
 */

const PASSWORD = 'password-123';

function buildService({
  found,
}: {
  found?: Record<string, unknown> | undefined;
} = {}) {
  const users = {
    findByEmailWithSecret: () => found,
    findById: (id: number) =>
      found ? { ...found, id, password_hash: undefined } : undefined,
  } as unknown as UserRepository;

  const jwt = {
    signAsync: (payload: unknown) => `signed:${JSON.stringify(payload)}`,
    verifyAsync: (token: string) => {
      if (!token.startsWith('signed:')) throw new Error('bad signature');
      return JSON.parse(token.slice('signed:'.length)) as unknown;
    },
  } as unknown as JwtService;

  return new AuthService(users, jwt);
}

async function activeUser() {
  return {
    id: 7,
    name: 'Bopha Lim',
    email: 'bopha@example.com',
    role: 'staff' as const,
    isActive: true,
    password_hash: await Bun.password.hash(PASSWORD),
  };
}

describe('AuthService.login', () => {
  it('issues a token carrying the id, email and role', async () => {
    const service = buildService({ found: await activeUser() });

    const session = await service.login({
      email: 'bopha@example.com',
      password: PASSWORD,
    });

    expect(session.accessToken).toContain('"sub":7');
    expect(session.accessToken).toContain('"role":"staff"');
    // The hash must not travel with the user, ever.
    expect(session.user).not.toHaveProperty('password_hash');
  });

  it('rejects a wrong password', async () => {
    const service = buildService({ found: await activeUser() });

    expect(
      service.login({ email: 'bopha@example.com', password: 'wrong' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  // Same message for "no such account" as for "wrong password", so the
  // endpoint cannot be used to enumerate who has an account here.
  it('rejects an unknown email with the same message', async () => {
    const unknown = buildService({ found: undefined });
    const wrongPassword = buildService({ found: await activeUser() });

    const first = await unknown
      .login({ email: 'nobody@example.com', password: PASSWORD })
      .catch((error: UnauthorizedException) => error.message);
    const second = await wrongPassword
      .login({ email: 'bopha@example.com', password: 'wrong' })
      .catch((error: UnauthorizedException) => error.message);

    expect(first).toBe(second);
  });

  it('rejects a deactivated account even with the right password', async () => {
    const service = buildService({
      found: { ...(await activeUser()), isActive: false },
    });

    expect(
      service.login({ email: 'bopha@example.com', password: PASSWORD }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});

describe('AuthService.verify', () => {
  it('turns a valid token into the caller it stands for', async () => {
    const service = buildService({ found: await activeUser() });
    const { accessToken } = await service.login({
      email: 'bopha@example.com',
      password: PASSWORD,
    });

    expect(await service.verify(accessToken)).toEqual({
      id: 7,
      email: 'bopha@example.com',
      role: 'staff',
    });
  });

  it('rejects a token this server did not sign', () => {
    const service = buildService();

    expect(service.verify('not.a.token')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  // A signature only proves *we* issued it, not that its claims still match
  // what the code expects — an old token from before a schema change is signed
  // perfectly well.
  it('rejects a correctly signed token with the wrong claims', () => {
    const service = buildService();

    expect(
      service.verify(`signed:${JSON.stringify({ sub: 'seven' })}`),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});

describe('AuthService.currentUser', () => {
  it('refuses an account that has since been deactivated', async () => {
    const service = buildService({
      found: { ...(await activeUser()), isActive: false },
    });

    expect(service.currentUser(7)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });
});
