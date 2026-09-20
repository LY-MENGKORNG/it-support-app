import { Inject, Injectable } from '@nestjs/common';
import { PRISMA } from '@common/constants';
import { type PrismaDB } from '@config/db';
import { type CreateCategoryDto } from './category.dto';

@Injectable()
export class CategoryRepository {
  constructor(@Inject(PRISMA) private readonly db: PrismaDB) {}

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
