import { Inject } from '@nestjs/common';
import { DRIZZLE } from 'src/common/constants';
import { type DrizzleDB } from '../db/db.module';

export class RequestService {
  constructor(@Inject(DRIZZLE) private readonly db: DrizzleDB) {}

  list() {
    return this.db.query.request.findMany({});
  }
}
