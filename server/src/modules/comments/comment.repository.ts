import { Inject, Injectable } from '@nestjs/common';
import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { publicUserColumns } from '../users/user.schema';
import { comment } from './comment.schema';
import { type CreateCommentDto } from './comment.dto';

@Injectable()
export class CommentRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) { }

  findByRequest(requestId: number) {
    return this.db.query.comment.findMany({
      where: { requestId },
      with: { user: { columns: publicUserColumns } },
      orderBy: { createdAt: 'asc', id: 'asc' },
    });
  }

  findById(id: number) {
    return this.db.query.comment.findFirst({
      where: { id },
      with: { user: { columns: publicUserColumns } },
    });
  }

  insert(requestId: number, values: CreateCommentDto & { userId: number }) {
    return this.db
      .insert(comment)
      .values({ requestId, userId: values.userId, content: values.content })
      .returning()
      .get();
  }
}
