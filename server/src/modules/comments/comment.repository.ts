import { Inject, Injectable } from '@nestjs/common';
import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { publicUserColumns } from '../users/user.schema';
import { comment } from './comment.schema';
import { type CreateCommentDto } from './comment.dto';

@Injectable()
export class CommentRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  /**
   * Oldest first — a comment thread reads top to bottom. `id` breaks ties:
   * the column default has second precision, so two comments posted in the
   * same second would otherwise come back in an arbitrary order.
   */
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

  /**
   * The author is passed in rather than read off the DTO: it comes from the
   * caller's token, and the DTO no longer has a field for it.
   */
  insert(requestId: number, values: CreateCommentDto & { userId: number }) {
    return this.db
      .insert(comment)
      .values({ requestId, userId: values.userId, content: values.content })
      .returning()
      .get();
  }
}
