import { publicUserColumns } from '../users/user.schema';
import { InjectedRespository } from '@common/helpers/repository.helper';

export class RequestHistoryRepository extends InjectedRespository {
  findByRequest(requestId: number) {
    return this.db.requestHistory.findMany({
      where: { requestId },
      include: { user: { select: publicUserColumns } },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
    });
  }
}
