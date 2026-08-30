import { createZodDto } from 'nestjs-zod';
import { loginSchema, sessionResponseSchema } from './auth.schema';

export class LoginBodyDto extends createZodDto(loginSchema) {}
export class SessionDto extends createZodDto(sessionResponseSchema) {}
