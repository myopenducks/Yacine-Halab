import type { ErrorCode } from './errors';

export interface ApiSuccess<T> {
  data: T;
  error: null;
}

export interface ApiErrorPayload {
  code: ErrorCode;
  message: string;
  details?: unknown;
}

export interface ApiFailure {
  data: null;
  error: ApiErrorPayload;
}

export type ApiResponse<T> = ApiSuccess<T> | ApiFailure;

export function ok<T>(data: T): ApiSuccess<T> {
  return { data, error: null };
}

export function fail(
  code: ErrorCode,
  message: string,
  details?: unknown,
): ApiFailure {
  return {
    data: null,
    error: { code, message, details },
  };
}
