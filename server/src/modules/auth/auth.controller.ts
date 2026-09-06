import { Body, Controller, Get, HttpCode, Post } from '@nestjs/common';
import { ApiBearerAuth, ApiBody, ApiOperation } from '@nestjs/swagger';
import { ZodValidationPipe } from '@common/zod-validation.pipe';
import { AuthService } from './auth.service';
import { CurrentUser, Public } from './auth.decorator';
import { LoginBodyDto } from './auth.dto';
import { loginSchema, type LoginDto } from './auth.schema';

@Controller('auth')
export class AuthController {
  constructor(private readonly auth: AuthService) { }

  @Public()
  @Post('login')
  @HttpCode(200)
  @ApiOperation({ summary: 'Exchange credentials for an access token' })
  @ApiBody({ type: LoginBodyDto })
  login(@Body(new ZodValidationPipe(loginSchema)) dto: LoginDto) {
    return this.auth.login(dto);
  }

  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'The signed-in user' })
  me(@CurrentUser('id') id: number) {
    return this.auth.currentUser(id);
  }
}
