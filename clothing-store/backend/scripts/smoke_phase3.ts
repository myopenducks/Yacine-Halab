import 'dotenv/config';
import { getDb } from '../src/db';
import { sales, saleItems, products } from '../src/db';

const BASE = 'http://127.0.0.1:3000';

interface Check {
  name: string;
  pass: boolean;
  detail?: string;
}

const checks: Check[] = [];

function log(name: string, pass: boolean, detail?: string) {
  checks.push({ name, pass, detail });
  const mark = pass ? '✅' : '❌';
  console.log(`${mark}  ${name}${detail ? ` — ${detail}` : ''}`);
}

async function req(
  method: string,
  path: string,
  opts: { body?: unknown; token?: string; expectStatus?: number } = {},
) {
  const headers: Record<string, string> = { 'content-type': 'application/json' };
  if (opts.token) headers.authorization = `Bearer ${opts.token}`;
  const res = await fetch(BASE + path, {
    method,
    headers,
    body: opts.body != null ? JSON.stringify(opts.body) : undefined,
  });
  const txt = await res.text();
  let json: unknown = undefined;
  try {
    json = JSON.parse(txt);
  } catch {
    // ignore
  }
  if (opts.expectStatus != null && res.status !== opts.expectStatus) {
    throw new Error(
      `${method} ${path} expected ${opts.expectStatus}, got ${res.status}. Body: ${txt.slice(0, 300)}`,
    );
  }
  return { status: res.status, json, text: txt };
}

async function main() {
  // Clean up leftover test data from any prior run (deterministic re-runs)
  {
    const db = getDb();
    await db.delete(saleItems);
    await db.delete(sales);
    await db.delete(products);
  }

  // 1. login → token
  const login = await req('POST', '/api/v1/auth/login', {
    body: { username: 'admin', password: 'admin123' },
    expectStatus: 200,
  });
  const token: string = (login.json as any).data.token;
  log('POST /auth/login (admin/admin123)', !!token && token.length > 50, `token len=${token.length}`);

  const T = () => token;

  // 2. categories list
  const cats = await req('GET', '/api/v1/categories', { token: T(), expectStatus: 200 });
  const catList: Array<{ id: number; name: string }> = (cats.json as any).data;
  log('GET /categories → 6 seeded rows', catList.length === 6, `count=${catList.length}`);
  const tshirtCat = catList.find((c) => c.name === 'T-Shirt')!;
  const shoesCat = catList.find((c) => c.name === 'Shoes')!;
  log('T-Shirt + Shoes categories present', !!tshirtCat && !!shoesCat);

  // 3. create product 1 (T-Shirt, qty 10, not low-stock)
  const p1 = await req('POST', '/api/v1/products', {
    token: T(),
    expectStatus: 201,
    body: {
      name: 'Nike T-Shirt Black',
      categoryId: tshirtCat.id,
      purchasePrice: 1200,
      sellingPrice: 1800,
      quantity: 10,
    },
  });
  const p1Data: { id: number; name: string; categoryName: string } = (p1.json as any).data;
  log('POST /products (T-Shirt)', p1Data.categoryName === 'T-Shirt' && p1Data.name === 'Nike T-Shirt Black', `id=${p1Data.id}`);

  // 4. create product 2 (Shoes, qty 2 → low-stock)
  const p2 = await req('POST', '/api/v1/products', {
    token: T(),
    expectStatus: 201,
    body: {
      name: 'Adidas Shoes White',
      categoryId: shoesCat.id,
      purchasePrice: 3500,
      sellingPrice: 5500,
      quantity: 2,
    },
  });
  const p2Data: { id: number; quantity: number; categoryName: string } = (p2.json as any).data;
  log('POST /products (Shoes qty=2 → low stock)', p2Data.quantity === 2, `id=${p2Data.id}`);

  // 5. create with invalid category → 404
  const bad = await req('POST', '/api/v1/products', {
    token: T(),
    expectStatus: 404,
    body: {
      name: 'Ghost',
      categoryId: 99999,
      purchasePrice: 100,
      sellingPrice: 200,
      quantity: 1,
    },
  });
  const badCode = (bad.json as any).error?.code;
  log('POST /products invalid category → 404 CATEGORY_NOT_FOUND', badCode === 'CATEGORY_NOT_FOUND', `code=${badCode}`);

  // 6. list total = 2
  const list0 = await req('GET', '/api/v1/products', { token: T(), expectStatus: 200 });
  const total0 = (list0.json as any).data.total;
  log('GET /products → total=2 after 2 inserts', total0 === 2, `total=${total0}`);

  // 7. search "Nike" → 1
  const s1 = await req('GET', '/api/v1/products?search=Nike', { token: T(), expectStatus: 200 });
  log('GET /products?search=Nike → 1 item', (s1.json as any).data.total === 1, `total=${(s1.json as any).data.total}`);

  // 8. category filter shoes → 1
  const s2 = await req('GET', `/api/v1/products?categoryId=${shoesCat.id}`, { token: T(), expectStatus: 200 });
  log(`GET /products?categoryId=${shoesCat.id} → 1`, (s2.json as any).data.total === 1, `total=${(s2.json as any).data.total}`);

  // 9. lowStock=true → 1 (shoes qty=2 <= 5)
  const s3 = await req('GET', '/api/v1/products?lowStock=true', { token: T(), expectStatus: 200 });
  log('GET /products?lowStock=true → qty≤5', (s3.json as any).data.total === 1, `total=${(s3.json as any).data.total}`);

  // 10. lowStock=false → 1 (qty>5, Nike qty=10)
  const s4 = await req('GET', '/api/v1/products?lowStock=false', { token: T(), expectStatus: 200 });
  log('GET /products?lowStock=false → qty>5', (s4.json as any).data.total === 1, `total=${(s4.json as any).data.total}`);

  // 11. pagination: limit=1, page=2 → should have total still correct, page 2
  const s5 = await req('GET', '/api/v1/products?limit=1&page=2', { token: T(), expectStatus: 200 });
  const s5data = (s5.json as any).data;
  log('GET /products paginated limit=1 page=2', s5data.total === 2 && s5data.page === 2 && s5data.items.length === 1, `total=${s5data.total} items=${s5data.items.length}`);

  // 12. get by id
  const g1 = await req('GET', `/api/v1/products/${p1Data.id}`, { token: T(), expectStatus: 200 });
  log('GET /products/:id → 200', (g1.json as any).data?.id === p1Data.id);

  // 13. get by id not found → 404
  const g2 = await req('GET', '/api/v1/products/9999999', { token: T(), expectStatus: 404 });
  log('GET /products/9999999 → 404 PRODUCT_NOT_FOUND', (g2.json as any).error?.code === 'PRODUCT_NOT_FOUND');

  // 14. patch product 1: name + quantity
  const upd = await req('PATCH', `/api/v1/products/${p1Data.id}`, {
    token: T(),
    expectStatus: 200,
    body: { name: 'Nike T-Shirt Black EDIT', quantity: 7 },
  });
  const updData: { name: string; quantity: number } = (upd.json as any).data;
  log('PATCH /products/:id → update name + qty', updData.name === 'Nike T-Shirt Black EDIT' && updData.quantity === 7, JSON.stringify({ n: updData.name, q: updData.quantity }));

  // 15. DELETE p1 (no sales yet) → 204
  const del1 = await req('DELETE', `/api/v1/products/${p1Data.id}`, { token: T(), expectStatus: 204 });
  log('DELETE product without sales → 204', del1.status === 204, `status=${del1.status}`);

  // Confirm p1 is gone
  const g3 = await req('GET', `/api/v1/products/${p1Data.id}`, { token: T(), expectStatus: 404 });
  log('GET deleted product → 404', (g3.json as any).error?.code === 'PRODUCT_NOT_FOUND');

  // 16. 409 PRODUCT_HAS_SALES: manually insert a sale + sale_item linking to p2Data.id, then try delete
  const db = getDb();
  const [saleInsert] = await db.insert(sales).values({ totalAmount: 5500, paidAmount: 5500, userId: 1 });
  const saleId = Number(saleInsert.insertId);
  await db.insert(saleItems).values({
    saleId,
    productId: p2Data.id,
    quantity: 1,
    unitPrice: 5500,
    purchasePrice: 3500,
  });
  log(`DB inserted dummy sale #${saleId} linking to product#${p2Data.id}`, true);

  const del2 = await req('DELETE', `/api/v1/products/${p2Data.id}`, { token: T(), expectStatus: 409 });
  const errCode = (del2.json as any).error?.code;
  const errMsg: string = (del2.json as any).error?.message ?? '';
  log('DELETE product WITH sales → 409 PRODUCT_HAS_SALES', errCode === 'PRODUCT_HAS_SALES', `code=${errCode} msg=${errMsg.slice(0, 50)}`);

  // 17. 404 DELETE nonexistent
  const del3 = await req('DELETE', '/api/v1/products/8888888', { token: T(), expectStatus: 404 });
  log('DELETE nonexistent product → 404', (del3.json as any).error?.code === 'PRODUCT_NOT_FOUND');

  // 18. invalid create body (missing name) → 400 VALIDATION_ERROR
  const bad2 = await req('POST', '/api/v1/products', {
    token: T(),
    expectStatus: 400,
    body: { categoryId: 1, purchasePrice: 1, sellingPrice: 2, quantity: 0 },
  });
  log('POST invalid body → Zod 400 VALIDATION_ERROR', (bad2.json as any).error?.code === 'VALIDATION_ERROR', `code=${(bad2.json as any).error?.code}`);

  // 19. no token on /products → auth hook 401 (not 404 or 200)
  const noAuth = await req('GET', '/api/v1/products', { expectStatus: 401 });
  log('GET /products NO TOKEN → 401 UNAUTHORIZED', (noAuth.json as any).error?.code === 'UNAUTHORIZED', `code=${(noAuth.json as any).error?.code}`);

  // Summary
  console.log('\n-------');
  const passed = checks.filter((c) => c.pass).length;
  const total = checks.length;
  console.log(`Phase 3 smoke: ${passed}/${total} passed`);
  if (passed !== total) {
    console.log('Failures:');
    for (const c of checks.filter((c) => !c.pass)) {
      console.log(`  ❌ ${c.name}${c.detail ? ` — ${c.detail}` : ''}`);
    }
    process.exit(1);
  }
  process.exit(0);
}

main().catch((err) => {
  console.error('SMOKE CRASHED:', err);
  process.exit(2);
});
