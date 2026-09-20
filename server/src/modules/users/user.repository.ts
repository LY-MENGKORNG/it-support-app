import { Inject, Injectable } from '@nestjs/common';
import { PRISMA } from '@common/constants';
import { type PrismaDB } from '@config/db';
import { publicUserColumns } from './user.schema';
import { CreateUserDto, ListUserQuery } from './user.dto';

@Injectable()
export class UserRepository {
  constructor(@Inject(PRISMA) private readonly db: PrismaDB) {}

  findMany({ q, role, limit, offset }: ListUserQuery) {
    return this.db.user.findMany({
      select: publicUserColumns,
      where: {
        ...(role ? { role } : {}),
        ...(q
          ? { OR: [{ name: { contains: q } }, { email: { contains: q } }] }
          : {}),
      },
      orderBy: [{ name: 'asc' }, { id: 'asc' }],
      take: limit,
      skip: offset,
    });
  }

  findAssignable() {
    return this.db.user.findMany({
      select: publicUserColumns,
      where: { role: { in: ['staff', 'admin'] }, isActive: true },
      orderBy: [{ name: 'asc' }, { id: 'asc' }],
    });
  }

  findById(id: number) {
    return this.db.user.findUnique({
      where: { id },
      select: publicUserColumns,
    });
  }

  findByEmailWithSecret(email: string) {
    return this.db.user.findUnique({
      where: { email },
      select: { ...publicUserColumns, password_hash: true },
    });
  }

  async insert(
    values: Omit<CreateUserDto, 'password'> & { password_hash: string },
  ) {
    const created = await this.db.user.create({ data: values });
    const { password_hash: _hash, ...safe } = created;
    return safe;
  }
}
