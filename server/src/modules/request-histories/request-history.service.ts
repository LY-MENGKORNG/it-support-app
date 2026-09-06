import { Injectable } from '@nestjs/common';
import { RequestHistoryRepository } from './request-history.repository';

@Injectable()
export class RequestHistoryService {
  constructor(private readonly repository: RequestHistoryRepository) { }

  list(requestId: number) {
    return this.repository.findByRequest(requestId);
  }
}
