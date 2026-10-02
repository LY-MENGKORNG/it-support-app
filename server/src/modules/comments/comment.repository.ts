import { publicUserColumns } from '../users/user.schema';
import { type CreateCommentDto } from './comment.dto';
import { InjectedRespository } from '@common/helpers/repository.helper';

export class CommentRepository extends InjectedRespository {
  findByRequest(requestId: number) {
    return this.db.comment.findMany({
      where: { requestId },
      include: { user: { select: publicUserColumns } },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
    });
  }

  findById(id: number) {
    return this.db.comment.findUnique({
      where: { id },
      include: { user: { select: publicUserColumns } },
    });
  }

  insert(requestId: number, values: CreateCommentDto & { userId: number }) {
    return this.db.comment.create({
      data: { requestId, userId: values.userId, content: values.content },
    });
  }
}
