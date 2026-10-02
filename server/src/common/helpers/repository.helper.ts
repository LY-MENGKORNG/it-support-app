import { PRISMA } from '@common/constants';
import { type PrismaDB } from '@config/db';
import { Inject, Injectable } from '@nestjs/common';

@Injectable()
export abstract class InjectedRespository {
  protected constructor(@Inject(PRISMA) readonly db: PrismaDB) {}
}
