import { z } from 'zod';

export const loginRequestSchema = z.object({
  username: z.string().min(1).max(50),
  password: z.string().min(6).max(100),
});

export type LoginRequest = z.infer<typeof loginRequestSchema>;

export interface PublicUser {
  id: number;
  username: string;
}

export interface LoginResponse {
  token: string;
  user: PublicUser;
}

export type MeResponse = PublicUser;
