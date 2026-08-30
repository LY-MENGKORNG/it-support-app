import { Controller, Get, Param, ParseIntPipe } from '@nestjs/common';
import { RequestHistoryService } from './request-history.service';

@Controller('request/:requestId/history')
export class RequestHistoryController {
  constructor(private readonly history: RequestHistoryService) {}

  @Get()
  list(@Param('requestId', ParseIntPipe) requestId: number) {
    return this.history.list(requestId);
  }
}
