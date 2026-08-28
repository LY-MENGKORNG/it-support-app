import { Inject, Injectable } from '@nestjs/common';
import { DRIZZLE } from 'src/common/constants';
import { CreateUserDto, user } from './user.schema';
import { type DrizzleDB } from '../db/db.module';

@Injectable()
export class UserService {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  list({ limit, offset }: { limit: number; offset: number }) {
    return this.db.query.user.findMany({
      columns: { password_hash: false },
      limit,
      offset,
    });
  }

  create(newUser: CreateUserDto) {
    return this.db.insert(user).values(newUser).returning().get();
  }
}
