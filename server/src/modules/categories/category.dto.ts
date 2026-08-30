import { createZodDto } from 'nestjs-zod';
import { createCategorySchema } from './category.schema';

export class CreateCategoryDto extends createZodDto(createCategorySchema) {}
