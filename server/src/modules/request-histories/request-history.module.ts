import { Module } from '@nestjs/common';
import { RequestHistoryService } from './request-history.service';
import { RequestHistoryRepository } from './request-history.repository';
import { RequestHistoryController } from './request-history.controller';

@Module({
  providers: [RequestHistoryService, RequestHistoryRepository],
  controllers: [RequestHistoryController],
  exports: [RequestHistoryService, RequestHistoryRepository],
})
export class RequestHistoryModule {}
