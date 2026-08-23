export interface PaginationParams {
  page: number;
  limit: number;
}

export interface PaginatedResult<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
}

export function computeOffset(params: PaginationParams): number {
  return (params.page - 1) * params.limit;
}
