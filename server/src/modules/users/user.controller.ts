import {
  Body,
  Controller,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
} from '@nestjs/common';
import { ZodValidationPipe } from '@common/zod-validation.pipe';
import { Roles } from '../auth/auth.decorator';
import { createUserSchema, listUserQuerySchema } from './user.schema';
import { UserService } from './user.service';
import { ApiBody, ApiOperation, ApiParam, ApiQuery } from '@nestjs/swagger';
import { CreateUserDto, ListUserQuery } from './user.dto';

@Controller('user')
export class UserController {
  constructor(private readonly users: UserService) { }

  @Get()
  @ApiQuery({ type: ListUserQuery })
  list(
    @Query(new ZodValidationPipe(listUserQuerySchema)) query: ListUserQuery,
  ) {
    return this.users.list(query);
  }

  /**
   * Declared before `:id` — Nest matches routes in order, so a literal segment
   * has to come first or `assignable` would be parsed as an id.
   */
  @Get('assignable')
  @Roles('staff', 'admin')
  listAssignable() {
    return this.users.listAssignable();
  }

  @Get(':id')
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.users.findOne(id);
  }

  /**
   * Accounts are created by an administrator, not by self-registration: this is
   * an internal tool, and everyone in it already works here.
   */
  @Post()
  @Roles('admin')
  @ApiOperation({ summary: 'Create new user' })
  @ApiBody({ type: CreateUserDto })
  create(@Body(new ZodValidationPipe(createUserSchema)) dto: CreateUserDto) {
    return this.users.create(dto);
  }
}
