import { z } from 'zod';
import type { PaginatedResult } from '../../shared/pagination';

export const createSaleSchema = z.object({
  items: z
    .array(
      z.object({
        productId: z.number().int().positive(),
        quantity: z.number().int().min(1),
      }),
    )
    .min(1, 'Sale must have at least 1 item'),
  paidAmount: z.coerce.number().int().min(0).optional(),
  customerName: z.string().trim().max(120).optional(),
  notes: z.string().trim().max(500).optional(),
});

export type CreateSaleDto = z.infer<typeof createSaleSchema>;

export const saleListQuerySchema = z.object({
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  hasDebt: z.coerce.boolean().optional(),
  debtOnly: z.coerce.boolean().optional(),
});

export type SaleListQuery = z.infer<typeof saleListQuerySchema>;

export const saleIdParamSchema = z.object({
  id: z.coerce.number().int().positive(),
});

export type SaleIdParam = z.infer<typeof saleIdParamSchema>;

export const recordPaymentSchema = z.object({
  amount: z.coerce.number().int().positive('Payment amount must be positive'),
  note: z.string().trim().max(200).optional(),
});

export type RecordPaymentDto = z.infer<typeof recordPaymentSchema>;

export const updateSaleSchema = z.object({
  customerName: z.string().trim().max(120).nullable().optional(),
  notes: z.string().trim().max(500).nullable().optional(),
});

export type UpdateSaleDto = z.infer<typeof updateSaleSchema>;

export interface SaleItemDetail {
  id: number;
  productId: number;
  productName: string;
  quantity: number;
  unitPrice: number;
  purchasePrice: number;
  lineTotal: number;
}

export interface SaleHeader {
  id: number;
  totalAmount: number;
  paidAmount: number;
  remainingAmount: number;
  customerName: string | null;
  notes: string | null;
  itemCount: number;
  createdAt: Date;
}

export interface SaleDetail extends Omit<SaleHeader, 'itemCount'> {
  items: SaleItemDetail[];
}

export type SaleListResult = PaginatedResult<SaleHeader>;

