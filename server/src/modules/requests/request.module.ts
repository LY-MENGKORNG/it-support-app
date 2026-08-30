import { Module } from '@nestjs/common';
import { RequestService } from './request.service';
import { RequestRepository } from './request.repository';
import { RequestController } from './request.controller';

@Module({
  providers: [RequestService, RequestRepository],
  controllers: [RequestController],
  // `RequestRepository` is exported so `CommentService` can check that a
  // request exists without reaching for the database itself.
  exports: [RequestService, RequestRepository],
})
export class RequestModule {}
