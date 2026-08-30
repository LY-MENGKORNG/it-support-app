import { Module } from '@nestjs/common';
import { RequestModule } from '../requests/request.module';
import { CommentService } from './comment.service';
import { CommentRepository } from './comment.repository';
import { CommentController } from './comment.controller';

@Module({
  imports: [RequestModule],
  providers: [CommentService, CommentRepository],
  controllers: [CommentController],
  exports: [CommentService, CommentRepository],
})
export class CommentModule {}
