import { createZodDto } from 'nestjs-zod';
import {
  createUserSchema,
  listUserQuerySchema,
  updateUserSchema,
  userResponseSchema,
} from './user.schema';

export class CreateUserDto extends createZodDto(createUserSchema) {
}
export class UpdateUserDto extends createZodDto(updateUserSchema) { }
export class ListUserQuery extends createZodDto(listUserQuerySchema) { }
export class PublicUser extends createZodDto(userResponseSchema) { }
