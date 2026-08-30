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

  /**
   * The only unauthenticated route in the app — it has to be, since it is
   * where a caller gets the token everything else demands.
   */
  @Public()
  @Post('login')
  // 200 rather than Nest's default 201: logging in creates no resource.
  @HttpCode(200)
  @ApiOperation({ summary: 'Exchange credentials for an access token' })
  @ApiBody({ type: LoginBodyDto })
  login(@Body(new ZodValidationPipe(loginSchema)) dto: LoginDto) {
    return this.auth.login(dto);
  }

  /**
   * Who the presented token belongs to.
   *
   * The client calls this on startup to turn a stored token back into a
   * session, which doubles as a check that the token is still good — a
   * deactivated account fails here instead of on the first write.
   */
  @Get('me')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'The signed-in user' })
  me(@CurrentUser('id') id: number) {
    return this.auth.currentUser(id);
  }
}
