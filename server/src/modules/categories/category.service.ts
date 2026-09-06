import { Injectable, NotFoundException } from '@nestjs/common';
import { type CreateCategoryDto } from './category.dto';
import { CategoryRepository } from './category.repository';

@Injectable()
export class CategoryService {
  constructor(private readonly repository: CategoryRepository) { }

  list() {
    return this.repository.findAll();
  }

  async findOne(id: number) {
    const found = await this.repository.findById(id);
    if (!found) throw new NotFoundException(`Category ${id} not found`);
    return found;
  }

  create(dto: CreateCategoryDto) {
    return this.repository.insert(dto);
  }

  async remove(id: number) {
    await this.findOne(id);
    await this.repository.deleteById(id);
    return { id, deleted: true };
  }
}
