import { z } from 'zod';

export const loginRequestSchema = z.object({
  username: z.string().min(1).max(50),
  password: z.string().min(6).max(100),
});

export type LoginRequest = z.infer<typeof loginRequestSchema>;

export const registerRequestSchema = z.object({
  username: z.string().trim().min(3, 'Username must be at least 3 chars').max(50),
  password: z.string().min(6, 'Password must be at least 6 chars').max(100),
});

export type RegisterRequest = z.infer<typeof registerRequestSchema>;

export const changePasswordSchema = z.object({
  currentPassword: z.string().min(1, 'Current password is required'),
  newPassword: z.string().min(6, 'New password must be at least 6 chars').max(100),
});

export type ChangePasswordRequest = z.infer<typeof changePasswordSchema>;

export interface PublicUser {
  id: number;
  username: string;
}

export interface LoginResponse {
  token: string;
  user: PublicUser;
}

export type MeResponse = PublicUser;
