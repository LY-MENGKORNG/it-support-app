import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Patch,
  Post,
  Query,
} from '@nestjs/common';
import { ZodValidationPipe } from '@common/zod-validation.pipe';
import { CurrentUser } from '../auth/auth.decorator';
import { type AuthenticatedUser } from '../auth/auth.schema';
import { RequestService } from './request.service';
import {
  createRequestSchema,
  listRequestQuerySchema,
  updateRequestSchema,
} from './request.schema';
import {
  CreateRequestDto,
  ListRequestQuery,
  UpdateRequestDto,
} from './request.dto';

@Controller('request')
export class RequestController {
  constructor(private readonly requests: RequestService) {}

  @Get()
  list(
    @Query(new ZodValidationPipe(listRequestQuerySchema))
    query: ListRequestQuery,
  ) {
    return this.requests.list(query);
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.requests.findOne(id);
  }

  @Post()
  create(
    @Body(new ZodValidationPipe(createRequestSchema)) dto: CreateRequestDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.requests.create(dto, actor);
  }

  @Patch(':id')
  update(
    @Param('id', ParseIntPipe) id: number,
    @Body(new ZodValidationPipe(updateRequestSchema)) dto: UpdateRequestDto,
    @CurrentUser() actor: AuthenticatedUser,
  ) {
    return this.requests.update(id, dto, actor);
  }
}
