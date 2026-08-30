import { createZodDto } from 'nestjs-zod';
import {
  createRequestSchema,
  listRequestQuerySchema,
  updateRequestSchema,
} from './request.schema';

export class CreateRequestDto extends createZodDto(createRequestSchema) {}
export class ListRequestQuery extends createZodDto(listRequestQuerySchema) {}
export class UpdateRequestDto extends createZodDto(updateRequestSchema) {}
