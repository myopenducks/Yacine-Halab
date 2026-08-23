export type ErrorCode =
  | 'VALIDATION_ERROR'
  | 'INVALID_CREDENTIALS'
  | 'UNAUTHORIZED'
  | 'FORBIDDEN'
  | 'CATEGORY_NOT_FOUND'
  | 'PRODUCT_NOT_FOUND'
  | 'PRODUCT_HAS_SALES'
  | 'INSUFFICIENT_STOCK'
  | 'SALE_NOT_FOUND'
  | 'SALE_ALREADY_PAID'
  | 'INTERNAL_ERROR';

export class AppError extends Error {
  readonly code: ErrorCode;
  readonly statusCode: number;
  readonly details?: unknown;

  constructor(params: {
    code: ErrorCode;
    statusCode: number;
    message: string;
    details?: unknown;
  }) {
    super(params.message);
    this.name = 'AppError';
    this.code = params.code;
    this.statusCode = params.statusCode;
    this.details = params.details;
  }
}

export function isAppError(err: unknown): err is AppError {
  return (
    typeof err === 'object' &&
    err !== null &&
    (err as AppError).name === 'AppError' &&
    typeof (err as AppError).code === 'string' &&
    typeof (err as AppError).statusCode === 'number'
  );
}
