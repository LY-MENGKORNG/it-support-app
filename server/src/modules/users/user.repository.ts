import { Inject, Injectable } from '@nestjs/common';
import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { publicUserColumns, user } from './user.schema';
import { CreateUserDto, ListUserQuery } from './user.dto';

/**
 * All database access for users.
 *
 * Repositories answer questions about storage and nothing else: they take
 * plain arguments, return plain rows, and return `undefined` rather than
 * throwing when something is absent. Deciding that a missing user is a 404 is
 * the service's job, not the database's.
 *
 * Every read here goes through {@link publicUserColumns}, so `password_hash`
 * cannot escape this file by accident.
 */
@Injectable()
export class UserRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

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

  /** Staff and admins who are still active — the assignee dropdown. */
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

  /**
   * The one read that returns `password_hash`, for the one caller that needs
   * it: verifying a login.
   *
   * Named so that it cannot be mistaken for the ordinary lookup, and it stays
   * the *only* exception to the `publicUserColumns` rule above — anything that
   * calls this is responsible for dropping the hash before the row travels any
   * further.
   */
  findByEmailWithSecret(email: string) {
    return this.db.query.user.findFirst({
      where: { email },
      columns: { ...publicUserColumns, password_hash: true },
    });
  }

  /**
   * Takes an already-hashed password. Hashing is a policy decision, so it
   * stays in the service — the repository only persists what it is handed.
   */
  insert(values: Omit<CreateUserDto, 'password'> & { password_hash: string }) {
    const created = this.db.insert(user).values(values).returning().get();

    const { password_hash: _hash, ...safe } = created;
    return safe;
  }
}
