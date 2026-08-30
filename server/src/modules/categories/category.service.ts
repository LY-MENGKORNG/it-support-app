import { Injectable, NotFoundException } from '@nestjs/common';
import { type CreateCategoryDto } from './category.dto';
import { CategoryRepository } from './category.repository';

@Injectable()
export class CategoryService {
  constructor(private readonly repository: CategoryRepository) {}

  /**
   * Unpaged on purpose: categories populate a dropdown, and a dropdown that
   * paginates is a dropdown nobody can use.
   */
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
    // Fails loudly if it is already gone, rather than reporting success for a
    // delete that deleted nothing.
    await this.findOne(id);
    await this.repository.deleteById(id);
    return { id, deleted: true };
  }
}
