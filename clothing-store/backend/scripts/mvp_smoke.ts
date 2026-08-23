/**
 * MVP end-to-end smoke: login → product → 5 sales → dashboard + inventory check.
 * Prerequisite: server running (`npm run dev`) and DB seeded.
 *
 * Usage: tsx scripts/mvp_smoke.ts
 */
import 'dotenv/config';

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
  let json: unknown;
  try {
    json = JSON.parse(txt);
  } catch {
    json = undefined;
  }
  if (opts.expectStatus != null && res.status !== opts.expectStatus) {
    throw new Error(
      `${method} ${path} expected ${opts.expectStatus}, got ${res.status}. Body: ${txt.slice(0, 400)}`,
    );
  }
  return { status: res.status, json, text: txt };
}

async function main() {
  const login = await req('POST', '/api/v1/auth/login', {
    body: { username: 'admin', password: 'admin123' },
    expectStatus: 200,
  });
  const token: string = (login.json as { data: { token: string } }).data.token;
  log('Login', true);

  const dashBefore = await req('GET', '/api/v1/dashboard/summary?period=today', {
    token,
    expectStatus: 200,
  });
  const before = (dashBefore.json as { data: { salesCount: number; revenue: number; itemsSold: number } }).data;

  const cats = await req('GET', '/api/v1/categories', { token, expectStatus: 200 });
  const catList = (cats.json as { data: Array<{ id: number; name: string }> }).data;
  const tshirtId = catList.find((c) => c.name === 'T-Shirt')?.id;
  if (!tshirtId) throw new Error('T-Shirt category missing — run db:seed');

  const created = await req('POST', '/api/v1/products', {
    token,
    expectStatus: 201,
    body: {
      name: 'MVP Smoke Tee',
      categoryId: tshirtId,
      purchasePrice: 1000,
      sellingPrice: 1500,
      quantity: 20,
    },
  });
  const productId = (created.json as { data: { id: number } }).data.id;
  log('Create product', true, `id=${productId} qty=20`);

  let totalSold = 0;
  let totalRevenue = 0;
  const saleQty = 1;
  const unitPrice = 1500;

  for (let i = 1; i <= 5; i++) {
    const sale = await req('POST', '/api/v1/sales', {
      token,
      expectStatus: 201,
      body: { items: [{ productId, quantity: saleQty }] },
    });
    const detail = (sale.json as { data: { id: number; totalAmount: number } }).data;
    totalSold += saleQty;
    totalRevenue += detail.totalAmount;
    log(`Sale ${i}/5`, detail.totalAmount === unitPrice * saleQty, `#${detail.id}`);
  }

  const productAfter = await req('GET', `/api/v1/products/${productId}`, {
    token,
    expectStatus: 200,
  });
  const qtyAfter = (productAfter.json as { data: { quantity: number } }).data.quantity;
  log('Inventory decremented', qtyAfter === 15, `qty=${qtyAfter} (expected 15)`);

  const dashAfter = await req('GET', '/api/v1/dashboard/summary?period=today', {
    token,
    expectStatus: 200,
  });
  const after = (dashAfter.json as { data: { salesCount: number; revenue: number; itemsSold: number } }).data;

  const salesDelta = after.salesCount - before.salesCount;
  const revenueDelta = after.revenue - before.revenue;
  const itemsDelta = after.itemsSold - before.itemsSold;

  log('Dashboard sales +5', salesDelta === 5, `+${salesDelta}`);
  log('Dashboard revenue +7500', revenueDelta === totalRevenue, `+${revenueDelta}`);
  log('Dashboard items +5', itemsDelta === totalSold, `+${itemsDelta}`);

  // Cleanup test product (may 409 if we keep sales — expected)
  const del = await req('DELETE', `/api/v1/products/${productId}`, { token });
  log(
    'Delete product blocked (has sales)',
    del.status === 409,
    `status=${del.status}`,
  );

  const failed = checks.filter((c) => !c.pass);
  console.log(`\n${checks.length - failed.length}/${checks.length} passed`);
  if (failed.length) {
    process.exit(1);
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
