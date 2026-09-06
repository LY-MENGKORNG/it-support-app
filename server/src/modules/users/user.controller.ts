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
import { ApiBody, ApiOperation, ApiQuery } from '@nestjs/swagger';
import { CreateUserDto, ListUserQuery } from './user.dto';

@Controller('user')
export class UserController {
  constructor(private readonly users: UserService) { }

  @Get()
  @ApiQuery({ type: ListUserQuery })
  @ApiOperation({ summary: 'List users' })
  list(
    @Query(new ZodValidationPipe(listUserQuerySchema)) query: ListUserQuery,
  ) {
    return this.users.list(query);
  }

  @Get('assignable')
  @Roles('staff', 'admin')
  @ApiOperation({ summary: 'IT staff who can be assigned to a request' })
  listAssignable() {
    return this.users.listAssignable();
  }

  @Get(':id')
  @ApiOperation({ summary: 'User by ID' })
  findOne(@Param('id', ParseIntPipe) id: number) {
    return this.users.findOne(id);
  }

  @Post()
  @Roles('admin')
  @ApiOperation({ summary: 'Create new user' })
  @ApiBody({ type: CreateUserDto })
  create(@Body(new ZodValidationPipe(createUserSchema)) dto: CreateUserDto) {
    return this.users.create(dto);
  }
}
