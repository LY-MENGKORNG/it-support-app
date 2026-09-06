import { Module } from '@nestjs/common';
import { RequestService } from './request.service';
import { RequestRepository } from './request.repository';
import { RequestController } from './request.controller';

@Module({
  providers: [RequestService, RequestRepository],
  controllers: [RequestController],
  exports: [RequestService, RequestRepository],
})
export class RequestModule { }
