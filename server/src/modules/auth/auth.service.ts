import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRepository } from '../users/user.repository';
import {
  accessTokenPayloadSchema,
  type AccessTokenPayload,
  type AuthenticatedUser,
  type LoginDto,
} from './auth.schema';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UserRepository,
    private readonly jwt: JwtService,
  ) { }

  async login({ email, password }: LoginDto) {
    const found = await this.users.findByEmailWithSecret(email);

    const invalid = new UnauthorizedException('Invalid email or password');

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

  async verify(token: string): Promise<AuthenticatedUser> {
    let payload: unknown;
    try {
      payload = await this.jwt.verifyAsync(token);
    } catch {
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

  async currentUser(id: number) {
    const found = await this.users.findById(id);
    if (!found || !found.isActive) {
      throw new UnauthorizedException('This account is no longer active');
    }
    return found;
  }
}

const DUMMY_HASH =
  '$argon2id$v=19$m=65536,t=2,p=1$smcNFpoMF8vnr7GH/LpobNAxlg4jdYIEILjtivFppXA$SvW5ORRGtB9VbvQXsm3UjAo8JT6gczvPYVQVz8KcboU';
