import { Inject, Injectable } from '@nestjs/common';
import { PRISMA } from '@common/constants';
import { type PrismaDB } from '@config/db';
import { publicUserColumns } from '../users/user.schema';

@Injectable()
export class RequestHistoryRepository {
  constructor(@Inject(PRISMA) private readonly db: PrismaDB) {}

  findByRequest(requestId: number) {
    return this.db.requestHistory.findMany({
      where: { requestId },
      include: { user: { select: publicUserColumns } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
  }
}
