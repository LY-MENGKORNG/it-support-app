import { Inject, Injectable } from '@nestjs/common';
import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { publicUserColumns, user } from './user.schema';
import { CreateUserDto, ListUserQuery } from './user.dto';

@Injectable()
export class UserRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) { }

  findMany({ q, role, limit, offset }: ListUserQuery) {
    return this.db.query.user.findMany({
      columns: publicUserColumns,
      where: {
        ...(role ? { role } : {}),
        ...(q
          ? {
            OR: [{ name: { like: `%${q}%` } }, { email: { like: `%${q}%` } }],
          }
          : {}),
      },
      orderBy: { name: 'asc', id: 'asc' },
      limit,
      offset,
    });
  }

  findAssignable() {
    return this.db.query.user.findMany({
      columns: publicUserColumns,
      where: { role: { in: ['staff', 'admin'] }, isActive: true },
      orderBy: { name: 'asc', id: 'asc' },
    });
  }

  findById(id: number) {
    return this.db.query.user.findFirst({
      where: { id },
      columns: publicUserColumns,
    });
  }

  findByEmailWithSecret(email: string) {
    return this.db.query.user.findFirst({
      where: { email },
      columns: { ...publicUserColumns, password_hash: true },
    });
  }

  insert(values: Omit<CreateUserDto, 'password'> & { password_hash: string }) {
    const created = this.db.insert(user).values(values).returning().get();

    const { password_hash: _hash, ...safe } = created;
    return safe;
  }
}
