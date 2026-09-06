import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { ZodValidationPipe } from '@common/zod-validation.pipe';
import { CurrentUser } from '../auth/auth.decorator';
import { CommentService } from './comment.service';
import { createCommentSchema } from './comment.schema';
import { CreateCommentDto } from './comment.dto';
import { ApiBody, ApiOperation } from '@nestjs/swagger';

@Controller('request/:requestId/comment')
export class CommentController {
  constructor(private readonly comments: CommentService) { }

  @Get()
  list(@Param('requestId', ParseIntPipe) requestId: number) {
    return this.comments.list(requestId);
  }

  @Post()
  @ApiOperation({ summary: 'Create new comment on the existing request!' })
  @ApiBody({ type: CreateCommentDto })
  create(
    @Param('requestId', ParseIntPipe) requestId: number,
    @Body(new ZodValidationPipe(createCommentSchema)) dto: CreateCommentDto,
    @CurrentUser('id') userId: number,
  ) {
    return this.comments.create(requestId, dto, userId);
  }
}
