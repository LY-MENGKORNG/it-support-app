import { Inject, Injectable } from '@nestjs/common';
import { asc, eq } from 'drizzle-orm';
import { DRIZZLE } from '@common/constants';
import { type DrizzleDB } from '@config/db';
import { category } from './category.schema';
import { type CreateCategoryDto } from './category.dto';

@Injectable()
export class CategoryRepository {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  findAll() {
    return this.db.select().from(category).orderBy(asc(category.name));
  }

  findById(id: number) {
    return this.db.query.category.findFirst({ where: { id } });
  }

  insert(dto: CreateCategoryDto) {
    return this.db
      .insert(category)
      .values({ name: dto.name, description: dto.description ?? null })
      .returning()
      .get();
  }

  /**
   * Requests reference categories, so SQLite's foreign-key check rejects a
   * category still in use. That surfaces as a 409 via `SQLiteExceptionFilter`
   * rather than being pre-checked here — the database is the only place that
   * can answer "is this still referenced?" without a race.
   */
  deleteById(id: number) {
    return this.db.delete(category).where(eq(category.id, id));
  }
}
