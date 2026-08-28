import { AppError } from '../../shared/errors';
import { SaleRepository } from './sale.repository';
import type {
  CreateSaleDto,
  SaleDetail,
  SaleListQuery,
  SaleListResult,
} from './sale.schema';

export class SaleService {
  constructor(private readonly repo: SaleRepository) {}

  async create(dto: CreateSaleDto, userId: number): Promise<SaleDetail> {
    const productIds = [...new Set(dto.items.map((i) => i.productId))];
    if (productIds.length !== dto.items.length) {
      throw new AppError({
        code: 'VALIDATION_ERROR',
        statusCode: 400,
        message: 'Duplicate productId in sale items. Combine quantities instead.',
      });
    }

    return this.repo.transaction(async (tx) => {
      const locked = await this.repo.lockProductsByIds(tx, productIds);
      const productMap = new Map(locked.map((p) => [p.id, p]));

      for (const item of dto.items) {
        const prod = productMap.get(item.productId);
        if (!prod) {
          throw new AppError({
            code: 'PRODUCT_NOT_FOUND',
            statusCode: 404,
            message: `Product with id ${item.productId} not found`,
            details: { productId: item.productId },
          });
        }
        if (prod.quantity < item.quantity) {
          throw new AppError({
            code: 'INSUFFICIENT_STOCK',
            statusCode: 409,
            message: `Product "${prod.name}" has only ${prod.quantity} in stock, ${item.quantity} requested`,
            details: {
              productId: prod.id,
              productName: prod.name,
              available: prod.quantity,
              requested: item.quantity,
            },
          });
        }
      }

      let totalAmount = 0;
      const saleItemInserts: Array<{
        saleId: number;
        productId: number;
        quantity: number;
        unitPrice: number;
        purchasePrice: number;
      }> = [];
      const quantityUpdates: Array<{ id: number; quantity: number }> = [];

      for (const item of dto.items) {
        const prod = productMap.get(item.productId)!;
        const unitPrice = item.unitPrice !== undefined ? item.unitPrice : prod.sellingPrice;
        const purchasePrice = prod.purchasePrice;
        const lineTotal = unitPrice * item.quantity;
        totalAmount += lineTotal;
        saleItemInserts.push({
          saleId: 0,
          productId: prod.id,
          quantity: item.quantity,
          unitPrice,
          purchasePrice,
        });
        quantityUpdates.push({
          id: prod.id,
          quantity: prod.quantity - item.quantity,
        });
      }

      const paidAmount =
        dto.paidAmount !== undefined
          ? Math.min(Math.max(0, dto.paidAmount), totalAmount)
          : totalAmount;
      const customerName = dto.customerName ?? null;
      const notes = dto.notes ?? null;

      const saleId = await this.repo.insertSale(tx, {
        totalAmount,
        paidAmount,
        customerName,
        notes,
        userId,
      });
      for (const it of saleItemInserts) it.saleId = saleId;
      await this.repo.bulkInsertSaleItems(tx, saleItemInserts);
      await this.repo.bulkUpdateProductQuantities(tx, quantityUpdates);

      const detail = await this.repo.findByIdOn(tx, saleId, userId);
      return detail as SaleDetail;
    });
  }

  async list(query: SaleListQuery, userId: number): Promise<SaleListResult> {
    const { page, limit, from, to } = query;
    const hasDebt = query.hasDebt ?? query.debtOnly;
    const { items, total } = await this.repo.list(
      { page, limit },
      { from, to, hasDebt },
      userId,
    );
    return { items, total, page, limit };
  }

  async getById(id: number, userId: number): Promise<SaleDetail> {
    const row = await this.repo.findById(id, userId);
    if (!row) {
      throw new AppError({
        code: 'SALE_NOT_FOUND',
        statusCode: 404,
        message: `Sale with id ${id} not found`,
      });
    }
    return row;
  }

  async recordPayment(
    id: number,
    dto: { amount: number; note?: string },
    userId: number,
  ): Promise<SaleDetail> {
    const sale = await this.getById(id, userId);
    const remaining = sale.remainingAmount;
    if (remaining <= 0) {
      throw new AppError({
        code: 'SALE_ALREADY_PAID',
        statusCode: 400,
        message: 'This sale is already fully paid.',
      });
    }

    const payAmount = Math.min(dto.amount, remaining);
    const newPaidAmount = sale.paidAmount + payAmount;

    let updatedNotes = sale.notes;
    if (dto.note) {
      updatedNotes = updatedNotes
        ? `${updatedNotes} | Payment: +${payAmount} DA (${dto.note})`
        : `Payment: +${payAmount} DA (${dto.note})`;
    }

    await this.repo.updatePaidAmount(id, newPaidAmount, updatedNotes);
    return this.getById(id, userId);
  }

  async update(
    id: number,
    dto: { customerName?: string | null; notes?: string | null },
    userId: number,
  ): Promise<SaleDetail> {
    await this.getById(id, userId);
    await this.repo.updateSale(id, dto);
    return this.getById(id, userId);
  }

  async delete(id: number, userId: number): Promise<{ success: boolean; message: string }> {
    await this.getById(id, userId);
    await this.repo.deleteSale(id, userId);
    return { success: true, message: 'Sale deleted and inventory restored successfully' };
  }
}
