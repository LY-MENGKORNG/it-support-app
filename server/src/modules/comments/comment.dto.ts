import { createZodDto } from 'nestjs-zod';
import { createCommentSchema } from './comment.schema';

export class CreateCommentDto extends createZodDto(createCommentSchema) {}
