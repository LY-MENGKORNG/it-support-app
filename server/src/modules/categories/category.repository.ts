import { type CreateCategoryDto } from './category.dto';
import { InjectedRespository } from '@common/helpers/repository.helper';

export class CategoryRepository extends InjectedRespository {
  findAll() {
    return this.db.category.findMany({ orderBy: { name: 'asc' } });
  }

  findById(id: number) {
    return this.db.category.findUnique({ where: { id } });
  }

  insert(dto: CreateCategoryDto) {
    return this.db.category.create({
      data: { name: dto.name, description: dto.description ?? null },
    });
  }

  deleteById(id: number) {
    return this.db.category.delete({ where: { id } });
  }
}
