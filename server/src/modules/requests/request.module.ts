import { Module } from '@nestjs/common';
import { RequestService } from './request.service';
import { RequestController } from './request.controller';

@Module({
  imports: [],
  providers: [RequestService],
  controllers: [RequestController],
  exports: [],
})
export class RequestModule {}
