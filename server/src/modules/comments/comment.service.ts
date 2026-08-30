import { Injectable, NotFoundException } from '@nestjs/common';
import { RequestRepository } from '../requests/request.repository';
import { type CreateCommentDto } from './comment.dto';
import { CommentRepository } from './comment.repository';

@Injectable()
export class CommentService {
  constructor(
    private readonly repository: CommentRepository,
    private readonly requests: RequestRepository,
  ) {}

  list(requestId: number) {
    return this.repository.findByRequest(requestId);
  }

  async create(requestId: number, dto: CreateCommentDto, userId: number) {
    // Without this the foreign-key violation would surface as a 409
    // "Referenced resource does not exist", which is the wrong shape for
    // "that request isn't there".
    if (!(await this.requests.exists(requestId))) {
      throw new NotFoundException(`Request ${requestId} not found`);
    }

    const created = this.repository.insert(requestId, { ...dto, userId });

    // Re-read so the response carries the author, matching what `list` returns.
    return this.repository.findById(created.id);
  }
}
