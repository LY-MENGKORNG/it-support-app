import { Controller, Get } from '@nestjs/common';
import { RequestService } from './request.service';

@Controller('request')
export class RequestController {
  constructor(private readonly request: RequestService) {}

  @Get()
  getRequests() {
    return this.request.list();
  }
}
