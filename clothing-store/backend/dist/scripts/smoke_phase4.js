import 'dotenv/config';
import { getDb } from '../src/db';
import { saleItems, sales, products } from '../src/db';
const BASE = 'http://127.0.0.1:3000';
const checks = [];
function log(name, pass, detail) {
    checks.push({ name, pass, detail });
    const mark = pass ? '✅' : '❌';
    console.log(`${mark}  ${name}${detail ? ` — ${detail}` : ''}`);
}
async function req(method, path, opts = {}) {
    const headers = { 'content-type': 'application/json' };
    if (opts.token)
        headers.authorization = `Bearer ${opts.token}`;
    const res = await fetch(BASE + path, {
        method,
        headers,
        body: opts.body != null ? JSON.stringify(opts.body) : undefined,
    });
    const txt = await res.text();
    let json = undefined;
    try {
        json = JSON.parse(txt);
    }
    catch {
        // ignore
    }
    if (opts.expectStatus != null && res.status !== opts.expectStatus) {
        throw new Error(`${method} ${path} expected ${opts.expectStatus}, got ${res.status}. Body: ${txt.slice(0, 500)}`);
    }
    return { status: res.status, json, text: txt };
}
async function main() {
    // Clean slate
    {
        const db = getDb();
        await db.delete(saleItems);
        await db.delete(sales);
        await db.delete(products);
    }
    // Login
    const login = await req('POST', '/api/v1/auth/login', {
        body: { username: 'admin', password: 'admin123' },
        expectStatus: 200,
    });
    const token = login.json.data.token;
    const T = () => token;
    // Get category ids (tshirt/shoes)
    const cats = await req('GET', '/api/v1/categories', { token: T(), expectStatus: 200 });
    const catList = cats.json.data;
    const tshirtId = catList.find((c) => c.name === 'T-Shirt').id;
    const shoesId = catList.find((c) => c.name === 'Shoes').id;
    log('Got seed category IDs', true, `tshirt=${tshirtId} shoes=${shoesId}`);
    // Create 3 products
    const pA = (await req('POST', '/api/v1/products', {
        token: T(),
        expectStatus: 201,
        body: {
            name: 'Nike T-Shirt Black',
            categoryId: tshirtId,
            purchasePrice: 1200,
            sellingPrice: 1800,
            quantity: 10,
        },
    })).json;
    const pB = (await req('POST', '/api/v1/products', {
        token: T(),
        expectStatus: 201,
        body: {
            name: 'Adidas T-Shirt White',
            categoryId: tshirtId,
            purchasePrice: 1000,
            sellingPrice: 1600,
            quantity: 5,
        },
    })).json;
    const pC = (await req('POST', '/api/v1/products', {
        token: T(),
        expectStatus: 201,
        body: {
            name: 'Adidas Shoes White',
            categoryId: shoesId,
            purchasePrice: 3500,
            sellingPrice: 5500,
            quantity: 3,
        },
    })).json;
    const [A, B, C] = [pA.data, pB.data, pC.data];
    log('Created 3 products', true, `A(q=10), B(q=5), C(q=3)`);
    // ---- SALES MODULE SMOKE ----
    // 1. Valid sale: 2xA + 1xB. Total = 2*1800 + 1600 = 5200 DA. Profit: 2*(1800-1200) + (1600-1000) = 1200+600 = 1800 DA.
    const sale1Body = {
        items: [
            { productId: A.id, quantity: 2 },
            { productId: B.id, quantity: 1 },
        ],
    };
    const s1 = (await req('POST', '/api/v1/sales', {
        token: T(),
        expectStatus: 201,
        body: sale1Body,
    })).json;
    const s1Data = s1.data;
    log('POST /sales: valid 2-item sale', s1Data.totalAmount === 5200 && s1Data.paidAmount === 5200 && s1Data.remainingAmount === 0, `total=${s1Data.totalAmount} paid=${s1Data.paidAmount} items=${s1Data.items.length}`);
    // Items match: verify price snapshots
    const itemA = s1Data.items.find((it) => it.productId === A.id);
    const itemB = s1Data.items.find((it) => it.productId === B.id);
    log('Sale items: price snapshots & qty correct', itemA.unitPrice === 1800 &&
        itemA.purchasePrice === 1200 &&
        itemA.quantity === 2 &&
        itemA.lineTotal === 3600 &&
        itemB.unitPrice === 1600 &&
        itemB.purchasePrice === 1000 &&
        itemB.quantity === 1 &&
        itemB.lineTotal === 1600, `A unitPrice=${itemA.unitPrice} lineTotal=${itemA.lineTotal}; B unitPrice=${itemB.unitPrice} lineTotal=${itemB.lineTotal}`);
    // Verify inventory decremented
    const Aafter = (await req('GET', `/api/v1/products/${A.id}`, { token: T(), expectStatus: 200 })).json;
    const Bafter = (await req('GET', `/api/v1/products/${B.id}`, { token: T(), expectStatus: 200 })).json;
    const Cafter = (await req('GET', `/api/v1/products/${C.id}`, { token: T(), expectStatus: 200 })).json;
    log('Inventory decremented after sale', Aafter.data.quantity === 8 && Bafter.data.quantity === 4 && Cafter.data.quantity === 3, `A: 10→${Aafter.data.quantity}, B:5→${Bafter.data.quantity}, C:3→${Cafter.data.quantity}`);
    // 2. Sale of 1xC
    const s2 = (await req('POST', '/api/v1/sales', {
        token: T(),
        expectStatus: 201,
        body: { items: [{ productId: C.id, quantity: 1 }] },
    })).json;
    log('POST /sales: single C item sale', s2.data.totalAmount === 5500 && s2.data.items.length === 1, `total=${s2.data.totalAmount}`);
    // C should now be 2
    const Cafter2 = (await req('GET', `/api/v1/products/${C.id}`, { token: T(), expectStatus: 200 })).json;
    log('C qty decremented 3→2', Cafter2.data.quantity === 2, `qty=${Cafter2.data.quantity}`);
    // 3. Try oversell B (only 4 left, ask for 5) → 409 INSUFFICIENT_STOCK
    const over = (await req('POST', '/api/v1/sales', {
        token: T(),
        expectStatus: 409,
        body: { items: [{ productId: B.id, quantity: 5 }] },
    })).json;
    const overCode = over.error?.code;
    const overDetails = over.error?.details;
    log('POST /sales oversell → 409 INSUFFICIENT_STOCK with details', overCode === 'INSUFFICIENT_STOCK' &&
        overDetails?.productId === B.id &&
        overDetails?.available === 4 &&
        overDetails?.requested === 5, `code=${overCode} available=${overDetails?.available} requested=${overDetails?.requested}`);
    // Inventory unchanged for B after failed oversell
    const BafterOver = (await req('GET', `/api/v1/products/${B.id}`, { token: T(), expectStatus: 200 })).json;
    log('Inventory NOT decremented on failed oversell', BafterOver.data.quantity === 4, `qty=${BafterOver.data.quantity}`);
    // 4. Invalid productId in sale → 404
    const badProduct = (await req('POST', '/api/v1/sales', {
        token: T(),
        expectStatus: 404,
        body: { items: [{ productId: 99999, quantity: 1 }] },
    })).json;
    log('POST /sales invalid product → 404 PRODUCT_NOT_FOUND', badProduct.error?.code === 'PRODUCT_NOT_FOUND', `code=${badProduct.error?.code}`);
    // 5. Empty items → Zod 400
    const emptyItems = (await req('POST', '/api/v1/sales', {
        token: T(),
        expectStatus: 400,
        body: { items: [] },
    })).json;
    log('POST /sales empty items → 400 VALIDATION_ERROR', emptyItems.error?.code === 'VALIDATION_ERROR', `code=${emptyItems.error?.code}`);
    // 6. Duplicate productId in items (intentional) → 400 VALIDATION_ERROR
    const dup = (await req('POST', '/api/v1/sales', {
        token: T(),
        expectStatus: 400,
        body: {
            items: [
                { productId: A.id, quantity: 1 },
                { productId: A.id, quantity: 1 },
            ],
        },
    })).json;
    log('POST /sales duplicate productId → 400 VALIDATION_ERROR', dup.error?.code === 'VALIDATION_ERROR', `code=${dup.error?.code}`);
    // 7. GET /sales list (no filter): total 2, first=s2 (newest id desc), itemCount
    const list = (await req('GET', '/api/v1/sales', { token: T(), expectStatus: 200 })).json;
    log('GET /sales list → 2 sales, newest first desc by id', list.data.total === 2 && list.data.items.length === 2 && list.data.items[0].id === s2.data.id, `total=${list.data.total} items0.id=${list.data.items[0]?.id}`);
    // itemCount
    const s1Row = list.data.items.find((r) => r.id === s1.data.id);
    const s2Row = list.data.items.find((r) => r.id === s2.data.id);
    log('GET /sales: itemCount correct', s1Row.itemCount === 2 && s2Row.itemCount === 1, `s1 itemCount=${s1Row.itemCount} s2 itemCount=${s2Row.itemCount}`);
    // 8. GET /sales/:id detail for sale #1
    const d1 = (await req('GET', `/api/v1/sales/${s1.data.id}`, { token: T(), expectStatus: 200 })).json;
    log('GET /sales/:id detail → 2 items with productName', d1.data.items.length === 2 && d1.data.totalAmount === 5200, `items=${d1.data.items.length} total=${d1.data.totalAmount} productNames=[${d1.data.items
        .map((it) => it.productName)
        .join(',')}]`);
    // 9. GET /sales/:id not found → 404
    const badSale = (await req('GET', '/api/v1/sales/999999', { token: T(), expectStatus: 404 })).json;
    log('GET /sales/999999 → 404 SALE_NOT_FOUND', badSale.error?.code === 'SALE_NOT_FOUND', `code=${badSale.error?.code}`);
    // ---- DASHBOARD SMOKE ----
    // 10. Summary today
    const s = (await req('GET', '/api/v1/dashboard/summary?period=today', {
        token: T(),
        expectStatus: 200,
    })).json;
    const d = s.data;
    // Expected totals: 2 sales, 5 items sold (2+1+1+1? Wait sale1 = 2+1=3 items, sale2=1 => 4. revenue 5200+5500=10700. profit: (1200+600)+(5500-3500)= 1800+2000=3800
    log('Dashboard summary (period=today): counts correct', d.period === 'today' &&
        d.salesCount === 2 &&
        d.itemsSold === 4, `salesCount=${d.salesCount} itemsSold=${d.itemsSold}`);
    log('Dashboard summary: revenue=10700 profit=3800', d.revenue === 10700 && d.profit === 3800, `revenue=${d.revenue} profit=${d.profit}`);
    // categoryQuantities: T-Shirt = 8+4 = 12, Shoes = 2, other 4 = 0 each = total 6 rows
    const tq = d.categoryQuantities.find((c) => c.name === 'T-Shirt')?.quantity;
    const sq = d.categoryQuantities.find((c) => c.name === 'Shoes')?.quantity;
    log('Dashboard summary: categoryQuantities (T-Shirt=12 Shoes=2)', d.categoryQuantities.length === 6 && tq === 12 && sq === 2, `rows=${d.categoryQuantities.length} T-Shirt=${tq} Shoes=${sq}`);
    // lowStock: threshold <= 5. Products: A(8 no), B(4 yes), C(2 yes) → lowStockCount=2
    log('Dashboard summary: lowStockCount', d.lowStockCount === 2, `lowStockCount=${d.lowStockCount}`);
    // from/to defined
    log('Dashboard summary: from/to ISO dates', !!d.from && !!d.to && typeof d.from === 'string', `${d.from} → ${d.to}`);
    // 11. Dashboard sales chart today (period=today → bucket = LPAD(HOUR(createdAt), 2, '0'))
    const chart = (await req('GET', '/api/v1/dashboard/sales?period=today', {
        token: T(),
        expectStatus: 200,
    })).json;
    log('Dashboard sales buckets: non-empty array, values positive', Array.isArray(chart.data.buckets) && chart.data.buckets.length >= 1, `buckets=${chart.data.buckets?.length} first=${JSON.stringify(chart.data.buckets?.[0])}`);
    const totalRevChart = chart.data.buckets.reduce((acc, b) => acc + Number(b.revenue || 0), 0);
    log('Dashboard sales buckets: sum(revenue) across buckets === 10700', totalRevChart === 10700, `Σrevenue=${totalRevChart}`);
    // 12. Empty dashboard (period=custom + year=2020 + month=1, way before current data)
    const emptySum = (await req('GET', '/api/v1/dashboard/summary?period=custom&year=2020&month=1', {
        token: T(),
        expectStatus: 200,
    })).json;
    log('Dashboard custom past period → zero aggregates + 6 zero category rows', emptySum.data.salesCount === 0 &&
        emptySum.data.itemsSold === 0 &&
        emptySum.data.revenue === 0 &&
        emptySum.data.profit === 0 &&
        emptySum.data.categoryQuantities.length === 6, `salesCount=${emptySum.data.salesCount} rev=${emptySum.data.revenue} catRows=${emptySum.data.categoryQuantities.length}`);
    // 13. Unauthenticated → 401 on /dashboard/* and /sales/*
    const u1 = await req('GET', '/api/v1/dashboard/summary', { expectStatus: 401 });
    const u2 = await req('GET', '/api/v1/sales', { expectStatus: 401 });
    log('No token → 401 on sales + dashboard', u1.json.error?.code === 'UNAUTHORIZED' &&
        u2.json.error?.code === 'UNAUTHORIZED', `summary=${u1.json.error?.code} sales=${u2.json.error?.code}`);
    // ---- Summary ----
    console.log('\n-------');
    const passed = checks.filter((c) => c.pass).length;
    const total = checks.length;
    console.log(`Phase 4 smoke: ${passed}/${total} passed`);
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
//# sourceMappingURL=smoke_phase4.js.map