import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseIntPipe,
  Post,
} from '@nestjs/common';
import { ZodValidationPipe } from '@common/zod-validation.pipe';
import { Roles } from '../auth/auth.decorator';
import { CategoryService } from './category.service';
import { createCategorySchema } from './category.schema';
import { ApiBody, ApiOperation } from '@nestjs/swagger';
import { CreateCategoryDto } from './category.dto';

@Controller('category')
export class CategoryController {
  constructor(private readonly categories: CategoryService) {}

  @Get()
  @ApiOperation({ summary: 'List all categories' })
  list() {
    return this.categories.list();
  }

  @Get(':id')
  @ApiOperation({ summary: 'A category by its ID' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.categories.findOne(id);
  }

  @Post()
  @Roles('admin')
  @ApiBody({ type: CreateCategoryDto })
  @ApiOperation({ summary: 'Create new category' })
  create(
    @Body(new ZodValidationPipe(createCategorySchema)) dto: CreateCategoryDto,
  ) {
    return this.categories.create(dto);
  }

  @Delete(':id')
  @Roles('admin')
  @ApiOperation({ summary: 'Remove a category' })
  remove(@Param('id', ParseIntPipe) id: number) {
    return this.categories.remove(id);
  }
}
