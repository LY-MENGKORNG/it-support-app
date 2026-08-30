import { Injectable } from '@nestjs/common';
import { RequestHistoryRepository } from './request-history.repository';

@Injectable()
export class RequestHistoryService {
  constructor(private readonly repository: RequestHistoryRepository) {}

  /**
   * Read-only. History rows are written by `RequestRepository` inside the same
   * transaction as the change they describe — nothing else may append to the
   * audit trail.
   */
  list(requestId: number) {
    return this.repository.findByRequest(requestId);
  }
}
