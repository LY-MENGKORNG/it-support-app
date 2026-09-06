import { Inject, Injectable } from '@nestjs/common';
import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { publicUserColumns } from '../users/user.schema';

@Injectable()
export class RequestHistoryRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) { }

  findByRequest(requestId: number) {
    return this.db.query.requestHistory.findMany({
      where: { requestId },
      with: { user: { columns: publicUserColumns } },
      orderBy: { createdAt: 'desc', id: 'desc' },
    });
  }
}
