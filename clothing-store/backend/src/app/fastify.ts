import fastifyCors from '@fastify/cors';
import fastifyJwt from '@fastify/jwt';
import fastify from 'fastify';
import { registerErrorHandling } from '../plugins/error';
import { registerAuth } from '../plugins/auth';
import { getDb } from '../db';
import { AuthRepository } from '../modules/auth/auth.repository';
import { AuthService } from '../modules/auth/auth.service';
import { AuthHandler } from '../modules/auth/auth.handler';
import { registerAuthRoutes } from '../modules/auth/auth.routes';
import { CategoryRepository } from '../modules/categories/category.repository';
import { CategoryService } from '../modules/categories/category.service';
import { CategoryHandler } from '../modules/categories/category.handler';
import { registerCategoryRoutes } from '../modules/categories/category.routes';
import { ProductRepository } from '../modules/products/product.repository';
import { ProductService } from '../modules/products/product.service';
import { ProductHandler } from '../modules/products/product.handler';
import { registerProductRoutes } from '../modules/products/product.routes';
import { SaleRepository } from '../modules/sales/sale.repository';
import { SaleService } from '../modules/sales/sale.service';
import { SaleHandler } from '../modules/sales/sale.handler';
import { registerSaleRoutes } from '../modules/sales/sale.routes';
import { DashboardRepository } from '../modules/dashboard/dashboard.repository';
import { DashboardService } from '../modules/dashboard/dashboard.service';
import { DashboardHandler } from '../modules/dashboard/dashboard.handler';
import { registerDashboardRoutes } from '../modules/dashboard/dashboard.routes';
import { loadEnv } from '../config/env';

export async function createApp() {
  const env = loadEnv();

  const app = fastify({
    logger: env.NODE_ENV === 'production' ? { level: 'error' } : { level: 'info' },
    disableRequestLogging: env.NODE_ENV === 'production',
  });

  await registerErrorHandling(app);

  await app.register(fastifyCors, {
    origin:
      env.CORS_ORIGIN === '*'
        ? true
        : env.CORS_ORIGIN.split(',').map((s) => s.trim()),
  });

  await app.register(fastifyJwt, {
    secret: env.JWT_SECRET,
    sign: { expiresIn: env.JWT_EXPIRES_IN },
  });

  await registerAuth(app);

  app.get('/health', async () => ({ status: 'ok', uptime: process.uptime() }));

  const db = getDb();

  const authRepo = new AuthRepository(db);
  const authService = new AuthService(authRepo, app);
  const authHandler = new AuthHandler(authService);
  registerAuthRoutes(app, authHandler);

  const categoryRepo = new CategoryRepository(db);
  const categoryService = new CategoryService(categoryRepo);
  const categoryHandler = new CategoryHandler(categoryService);
  registerCategoryRoutes(app, categoryHandler);

  const productRepo = new ProductRepository(db);
  const productService = new ProductService(productRepo, categoryRepo);
  const productHandler = new ProductHandler(productService);
  registerProductRoutes(app, productHandler);

  const saleRepo = new SaleRepository(db);
  const saleService = new SaleService(saleRepo);
  const saleHandler = new SaleHandler(saleService);
  registerSaleRoutes(app, saleHandler);

  const dashboardRepo = new DashboardRepository(db, saleRepo);
  const dashboardService = new DashboardService(dashboardRepo);
  const dashboardHandler = new DashboardHandler(dashboardService);
  registerDashboardRoutes(app, dashboardHandler);

  return { app, env };
}
