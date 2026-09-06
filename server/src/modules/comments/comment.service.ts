import { Injectable, NotFoundException } from '@nestjs/common';
import { RequestRepository } from '../requests/request.repository';
import { type CreateCommentDto } from './comment.dto';
import { CommentRepository } from './comment.repository';

@Injectable()
export class CommentService {
  constructor(
    private readonly repository: CommentRepository,
    private readonly requests: RequestRepository,
  ) { }

  list(requestId: number) {
    return this.repository.findByRequest(requestId);
  }

  async create(requestId: number, dto: CreateCommentDto, userId: number) {
    if (!(await this.requests.exists(requestId))) {
      throw new NotFoundException(`Request ${requestId} not found`);
    }

    const created = this.repository.insert(requestId, { ...dto, userId });

    return this.repository.findById(created.id);
  }
}
