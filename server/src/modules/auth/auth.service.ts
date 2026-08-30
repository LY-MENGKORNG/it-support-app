import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRepository } from '../users/user.repository';
import {
  accessTokenPayloadSchema,
  type AccessTokenPayload,
  type AuthenticatedUser,
  type LoginDto,
} from './auth.schema';

/**
 * Issues and verifies access tokens.
 *
 * Everything password-shaped lives here: the repository stores a hash and the
 * controller sees a token, so neither ever handles a plaintext password.
 */
@Injectable()
export class AuthService {
  constructor(
    private readonly users: UserRepository,
    private readonly jwt: JwtService,
  ) {}

  async login({ email, password }: LoginDto) {
    const found = await this.users.findByEmailWithSecret(email);

    /**
     * Every failure below answers with the same message on purpose. Saying
     * "no such account" would turn this endpoint into a way to enumerate who
     * works here, and "your account is disabled" tells a locked-out attacker
     * that they had the right password.
     */
    const invalid = new UnauthorizedException('Invalid email or password');

    // Verify even when there is no such user, so the response time does not
    // reveal whether the email exists. `found` is checked afterwards.
    const matches = await Bun.password.verify(
      password,
      found?.password_hash ?? DUMMY_HASH,
    );
    if (!found || !matches || !found.isActive) throw invalid;

    const { password_hash: _hash, ...user } = found;
    const payload: AccessTokenPayload = {
      sub: user.id,
      email: user.email,
      role: user.role,
    };

    return { accessToken: await this.jwt.signAsync(payload), user };
  }

  /**
   * Turns a raw token into the caller it stands for.
   *
   * The payload is re-validated with zod rather than trusted for its shape: the
   * signature proves *this server issued it*, not that its claims still match
   * what the code now expects — an old token from before a schema change is
   * signed perfectly well.
   */
  async verify(token: string): Promise<AuthenticatedUser> {
    let payload: unknown;
    try {
      payload = await this.jwt.verifyAsync(token);
    } catch {
      // Expired, tampered with, or signed by a different key — all the same
      // answer, because none of them are the client's business.
      throw new UnauthorizedException('Invalid or expired session');
    }

    const parsed = accessTokenPayloadSchema.safeParse(payload);
    if (!parsed.success) throw new UnauthorizedException('Malformed token');

    return {
      id: parsed.data.sub,
      email: parsed.data.email,
      role: parsed.data.role,
    };
  }

  /**
   * The token says who you are; this says whether that is still true. A user
   * deactivated an hour ago still holds a valid token, so the client's
   * "restore my session" call reads the row rather than decoding the token.
   */
  async currentUser(id: number) {
    const found = await this.users.findById(id);
    if (!found || !found.isActive) {
      throw new UnauthorizedException('This account is no longer active');
    }
    return found;
  }
}

/**
 * A real argon2 hash of a throwaway string, used only to give the "no such
 * user" path the same cost as the "wrong password" path.
 */
const DUMMY_HASH =
  '$argon2id$v=19$m=65536,t=2,p=1$smcNFpoMF8vnr7GH/LpobNAxlg4jdYIEILjtivFppXA$SvW5ORRGtB9VbvQXsm3UjAo8JT6gczvPYVQVz8KcboU';
