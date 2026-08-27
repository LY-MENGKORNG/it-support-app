import {
  Body,
  Controller,
  Get,
  ParseIntPipe,
  Post,
  Query,
  UsePipes,
} from '@nestjs/common';
import { ZodValidationPipe } from 'src/common/zod-validation.pipe';
import { type CreateUserDto, createUserSchema } from './user.schema';
import { UserService } from './user.service';

@Controller('user')
export class UserController {
  constructor(private readonly user: UserService) {}

  @Get()
  list(
    @Query('limit', new ParseIntPipe({ optional: true })) limit = 20,
    @Query('offset', new ParseIntPipe({ optional: true })) offset = 0,
  ) {
    return this.user.list({ limit: Math.min(limit, 100), offset });
  }

  @Post()
  @UsePipes(new ZodValidationPipe(createUserSchema))
  create(@Body() dto: CreateUserDto) {
    return this.user.create(dto);
  }
}
