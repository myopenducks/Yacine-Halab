import { z } from 'zod';
import type { DashboardPeriod, DashboardSalesBucket, DashboardSummary } from './dashboard.repository';

export const summaryQuerySchema = z.object({
  period: z.enum(['today', 'week', 'month', 'custom']).default('today'),
  month: z.coerce.number().int().min(1).max(12).optional(),
  year: z.coerce.number().int().optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
});

export type SummaryQuery = z.infer<typeof summaryQuerySchema>;

export interface SummaryResponse extends DashboardSummary {}

export const salesQuerySchema = summaryQuerySchema;

export type SalesQuery = SummaryQuery;

export interface SalesChartResponse {
  period: DashboardPeriod;
  from: string;
  to: string;
  buckets: DashboardSalesBucket[];
}
