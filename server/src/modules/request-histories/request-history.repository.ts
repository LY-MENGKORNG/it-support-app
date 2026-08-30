import { Inject, Injectable } from '@nestjs/common';
import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { publicUserColumns } from '../users/user.schema';

/**
 * Read-only by design.
 *
 * History rows are written by `RequestRepository`, in the same transaction as
 * the change they describe. There is deliberately no `insert` here — nothing
 * should be able to append to the audit trail independently of the change it
 * claims to record.
 */
@Injectable()
export class RequestHistoryRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  findByRequest(requestId: number) {
    return this.db.query.requestHistory.findMany({
      where: { requestId },
      with: { user: { columns: publicUserColumns } },
      orderBy: { createdAt: 'desc', id: 'desc' },
    });
  }
}
