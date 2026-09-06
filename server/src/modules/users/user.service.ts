import { Injectable, NotFoundException } from '@nestjs/common';
import { CreateUserDto, ListUserQuery } from './user.dto';
import { UserRepository } from './user.repository';

@Injectable()
export class UserService {
  constructor(private readonly repository: UserRepository) { }

  list(query: ListUserQuery) {
    return this.repository.findMany(query);
  }

  listAssignable() {
    return this.repository.findAssignable();
  }

  async findOne(id: number) {
    const found = await this.repository.findById(id);
    if (!found) throw new NotFoundException(`User ${id} not found`);
    return found;
  }

  async create({ password, ...rest }: CreateUserDto) {
    return this.repository.insert({
      ...rest,
      password_hash: await Bun.password.hash(password),
    });
  }
}
