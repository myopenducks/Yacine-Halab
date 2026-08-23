# Clothing Store Management App — Architecture Plan

---

## 1. Recommended Project Folder Structure

### Root Layout
```
clothing-store/
├── backend/                 # Node.js + Fastify + TypeScript
├── mobile/                  # Flutter mobile app
└── README.md
```

---

### Backend Structure (`backend/`)
Feature-based modules as per spec. No NestJS.

```
backend/
├── package.json
├── tsconfig.json
├── drizzle.config.ts
├── .env
├── .env.example
├── src/
│   ├── index.ts              # App entry, bootstrap Fastify
│   ├── app/
│   │   ├── fastify.ts        # Fastify instance + plugin registration
│   │   └── server.ts         # Listen + graceful shutdown
│   ├── config/
│   │   ├── env.ts            # Zod-validated env vars (NODE_ENV, DB, JWT, PORT)
│   │   └── constants.ts      # Currencies, pagination defaults, etc.
│   ├── db/
│   │   ├── index.ts          # Drizzle instance (mysql2 driver)
│   │   ├── schema/
│   │   │   ├── users.ts
│   │   │   ├── categories.ts
│   │   │   ├── products.ts
│   │   │   ├── sales.ts
│   │   │   └── sale-items.ts
│   │   └── migrations/       # Drizzle generated SQL migrations
│   ├── plugins/
│   │   ├── auth.ts           # JWT verify hook + onRequest protector
│   │   ├── error.ts          # Global error handler → consistent JSON errors
│   │   ├── cors.ts
│   │   └── logger.ts
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.routes.ts
│   │   │   ├── auth.handler.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.schema.ts
│   │   │   └── auth.repository.ts
│   │   ├── categories/
│   │   │   ├── category.routes.ts
│   │   │   ├── category.handler.ts
│   │   │   ├── category.service.ts
│   │   │   ├── category.schema.ts
│   │   │   └── category.repository.ts
│   │   ├── products/
│   │   │   ├── product.routes.ts
│   │   │   ├── product.handler.ts
│   │   │   ├── product.service.ts
│   │   │   ├── product.schema.ts
│   │   │   └── product.repository.ts
│   │   ├── sales/
│   │   │   ├── sale.routes.ts
│   │   │   ├── sale.handler.ts
│   │   │   ├── sale.service.ts      # Transaction logic lives here
│   │   │   ├── sale.schema.ts
│   │   │   └── sale.repository.ts
│   │   └── dashboard/
│   │       ├── dashboard.routes.ts
│   │       ├── dashboard.handler.ts
│   │       ├── dashboard.service.ts
│   │       └── dashboard.schema.ts
│   └── shared/
│       ├── types/            # Shared TS types
│       ├── utils/            # date-fns wrappers, money helpers
│       ├── errors.ts         # AppError class (code, statusCode, message)
│       └── pagination.ts     # limit/offset helpers
└── scripts/
    └── seed.ts               # Seed 6 categories + 1 admin user
```

**Layer responsibilities inside a module:**
- `*.routes.ts` → only route registration, calls handler
- `*.handler.ts` → parse request → call service → format response
- `*.service.ts` → business rules, orchestration, transactions
- `*.repository.ts` → raw Drizzle queries (DB layer only)
- `*.schema.ts` → Zod schemas for body/query/params + response shapes

---

### Mobile Structure (`mobile/`)
Clean feature-first Flutter layout. Lightweight state management = **Riverpod** (simple, well-tested, matches MVP needs).

```
mobile/
├── pubspec.yaml
├── lib/
│   ├── main.dart
│   ├── core/
│   │   ├── theme/           # App colors, text styles, Material 3
│   │   ├── network/
│   │   │   ├── api_client.dart       # Dio wrapper (baseUrl, interceptors)
│   │   │   ├── api_exception.dart
│   │   │   └── auth_interceptor.dart # Attaches token, 401→logout
│   │   ├── storage/
│   │   │   ├── secure_storage.dart   # flutter_secure_storage for token
│   │   │   └── local_storage.dart    # shared_preferences (theme, user)
│   │   ├── utils/
│   │   │   ├── money.dart            # 2500 → "2,500 DA"
│   │   │   ├── date.dart
│   │   │   └── validators.dart
│   │   └── routes/                   # go_router
│   └── features/
│       ├── auth/
│       │   ├── models/user.dart
│       │   ├── services/auth_service.dart
│       │   ├── providers/auth_provider.dart
│       │   └── screens/
│       │       └── login_screen.dart
│       ├── dashboard/
│       │   ├── models/summary.dart
│       │   ├── services/dashboard_service.dart
│       │   ├── providers/dashboard_provider.dart
│       │   └── screens/
│       │       ├── dashboard_screen.dart
│       │       └── widgets/summary_card.dart
│       ├── products/
│       │   ├── models/product.dart
│       │   ├── models/category.dart
│       │   ├── services/product_service.dart
│       │   ├── services/category_service.dart
│       │   ├── providers/
│       │   │   ├── products_provider.dart
│       │   │   ├── search_provider.dart
│       │   │   └── categories_provider.dart
│       │   └── screens/
│       │       ├── products_screen.dart
│       │       ├── product_form_screen.dart  # add/edit
│       │       └── widgets/product_tile.dart
│       └── sales/
│           ├── models/sale.dart
│           ├── models/sale_item.dart
│           ├── services/sale_service.dart
│           ├── providers/
│           │   ├── sales_provider.dart
│           │   └── new_sale_provider.dart
│           └── screens/
│               ├── sales_history_screen.dart
│               ├── sale_detail_screen.dart
│               ├── new_sale_screen.dart
│               └── widgets/cart_item_tile.dart
```

---

## 2. Database ERD / Schema

### Entity Relationship Diagram (textual)
```
┌──────────────┐       ┌──────────────────┐       ┌──────────────┐
│    users     │       │   categories     │       │   products   │
│──────────────│       │──────────────────│       │──────────────│
│ id (PK)      │       │ id (PK)          │◄──────│ id (PK)      │
│ username     │       │ name             │       │ categoryId(FK)│
│ passwordHash │       │ createdAt        │       │ name         │
│ createdAt    │       │ updatedAt        │       │ purchasePrice│
│ updatedAt    │       └──────────────────┘       │ sellingPrice │
└──────────────┘                                    │ quantity     │
                                                    │ imageUrl     │
                                                    │ createdAt    │
┌──────────────┐                                    │ updatedAt    │
│    sales     │                                    └──────┬───────┘
│──────────────│                                           │
│ id (PK)      │                                           │
│ totalAmount  │                                           │
│ paidAmount   │                                           │
│ createdAt    │                                           │
│ updatedAt    │                                           │
└──────┬───────┘                                           │
       │                                                   │
       │        ┌──────────────────┐                       │
       └───────►│   sale_items     │◄──────────────────────┘
                │──────────────────│
                │ id (PK)          │
                │ saleId (FK)      │
                │ productId (FK)   │
                │ quantity         │
                │ unitPrice        │ ← actual selling price snapshot
                │ purchasePrice    │ ← actual purchase price snapshot (for profit calc)
                │ createdAt        │
                └──────────────────┘
```

### Cardinality
- `categories` 1 — N `products`
- `products` 1 — N `sale_items`
- `sales` 1 — N `sale_items`

---

## 3. Database Tables (Drizzle schemas)

### `users`
| Column         | Type        | Constraints                     |
|----------------|-------------|---------------------------------|
| `id`           | int         | PK, auto_inc                    |
| `username`     | varchar(50) | UNIQUE, NOT NULL                |
| `passwordHash` | varchar(255)| NOT NULL (argon2id/bcrypt)      |
| `createdAt`    | datetime    | DEFAULT now()                   |
| `updatedAt`    | datetime    | ON UPDATE now()                 |

### `categories`
| Column      | Type         | Constraints        |
|-------------|--------------|--------------------|
| `id`        | int          | PK, auto_inc       |
| `name`      | varchar(100) | UNIQUE, NOT NULL   |
| `createdAt` | datetime     | DEFAULT now()      |
| `updatedAt` | datetime     | ON UPDATE now()    |

Seed rows: T-Shirt, Shoes, Slippers, Shorts, Pants, Sets.

### `products`
| Column         | Type          | Constraints                          |
|----------------|---------------|--------------------------------------|
| `id`           | int           | PK, auto_inc                         |
| `categoryId`   | int           | FK → categories.id, NOT NULL         |
| `name`         | varchar(200)  | NOT NULL, INDEX                      |
| `purchasePrice`| int           | NOT NULL, >= 0 (integer DA)          |
| `sellingPrice` | int           | NOT NULL, >= 0 (integer DA)          |
| `quantity`     | int           | NOT NULL, DEFAULT 0, CHECK >= 0      |
| `imageUrl`     | varchar(500)  | NULLABLE                             |
| `createdAt`    | datetime      | DEFAULT now()                        |
| `updatedAt`    | datetime      | ON UPDATE now()                      |

### `sales`
| Column        | Type      | Constraints                               |
|---------------|-----------|-------------------------------------------|
| `id`          | int       | PK, auto_inc                              |
| `totalAmount` | int       | NOT NULL, >= 0 (sum of sale items)        |
| `paidAmount`  | int       | NOT NULL, >= 0 (MVP: equals totalAmount)  |
| `createdAt`   | datetime  | DEFAULT now(), INDEX for time queries     |
| `updatedAt`   | datetime  | ON UPDATE now()                           |

Note: For MVP, `paidAmount` == `totalAmount` always, but fields exist per future debt spec.

### `sale_items`
| Column          | Type      | Constraints                                                               |
|-----------------|-----------|---------------------------------------------------------------------------|
| `id`            | int       | PK, auto_inc                                                              |
| `saleId`        | int       | FK → sales.id ON DELETE CASCADE, NOT NULL, INDEX                          |
| `productId`     | int       | FK → products.id ON DELETE RESTRICT (keep history), NOT NULL              |
| `quantity`      | int       | NOT NULL, > 0                                                             |
| `unitPrice`     | int       | NOT NULL (snapshot of product.sellingPrice at sale time)                  |
| `purchasePrice` | int       | NOT NULL (snapshot of product.purchasePrice at sale time → profit calc)   |
| `createdAt`     | datetime  | DEFAULT now()                                                             |

**Indexes:**
- `sales.createdAt` (dashboard time filtering)
- `products.name` (search)
- `sale_items.saleId` (load sale + items join)

---

## 4. REST API Endpoint Specification

Base path: `/api/v1`
All responses are JSON. Envelope: `{ "data": T, "error": null }` / `{ "data": null, "error": { "code": "string", "message": "string" } }`.
All private endpoints require `Authorization: Bearer <JWT>`.
Timezone assumption: server TZ = shop local TZ (Algeria = CET/CEST → UTC+1/+2).

---

### 4.1 Authentication

#### `POST /api/v1/auth/login`
Public.

**Body (Zod):**
```ts
{
  username: z.string().min(1).max(50),
  password: z.string().min(6).max(100)
}
```

**Success 200:**
```json
{
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "username": "admin"
    }
  }
}
```

**Fail 401:** `INVALID_CREDENTIALS`

#### `GET /api/v1/auth/me`
Private. Returns current user from token.

**Success 200:**
```json
{
  "data": { "id": 1, "username": "admin" }
}
```

---

### 4.2 Categories

#### `GET /api/v1/categories`
Private. List all categories (small list, no pagination).

**Response:**
```json
{
  "data": [
    { "id": 1, "name": "T-Shirt" },
    { "id": 2, "name": "Shoes" }
  ]
}
```

---

### 4.3 Products

#### `GET /api/v1/products`
Private. Paginated + search + category filter + low-stock flag.

**Query (Zod):**
```ts
{
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  search: z.string().optional(),            // match name (LIKE %search%)
  categoryId: z.coerce.number().int().optional(),
  lowStock: z.enum(["true","false"]).optional()  // quantity <= 5
}
```

**Response:**
```json
{
  "data": {
    "items": [
      {
        "id": 1,
        "name": "Nike T-Shirt Black",
        "categoryId": 1,
        "categoryName": "T-Shirt",
        "purchasePrice": 1200,
        "sellingPrice": 1800,
        "quantity": 10,
        "imageUrl": null,
        "createdAt": "2026-01-15T09:30:00.000Z"
      }
    ],
    "total": 42,
    "page": 1,
    "limit": 20
  }
}
```

#### `GET /api/v1/products/:id`
Private. Single product.

**Response 200:** same shape as an item above.  
**404:** `PRODUCT_NOT_FOUND`

#### `POST /api/v1/products`
Private. Create.

**Body:**
```ts
{
  name: z.string().min(1).max(200),
  categoryId: z.number().int().positive(),
  purchasePrice: z.number().int().min(0),
  sellingPrice: z.number().int().min(0),
  quantity: z.number().int().min(0),
  imageUrl: z.string().url().max(500).optional()
}
```

**Success 201:** returns full created product.  
**Errors:** 400 `VALIDATION_ERROR`, 404 `CATEGORY_NOT_FOUND`

#### `PATCH /api/v1/products/:id`
Private. Partial update. Same fields as POST, all optional.

**Success 200:** updated product.

#### `DELETE /api/v1/products/:id`
Private. Soft-delete is NOT needed (MVP). Hard delete allowed only if the product has never been sold (`sale_items` FK RESTRICT prevents it).

**Success 204.**  
**409:** `PRODUCT_HAS_SALES` — product has sale history and cannot be deleted (safe FK restriction). UI must explain this to the user and suggest setting quantity to 0 instead.

---

### 4.4 Sales

#### `GET /api/v1/sales`
Private. Paginated + date range filter.

**Query:**
```ts
{
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
  from: z.coerce.date().optional(),   // ISO string
  to:   z.coerce.date().optional()
}
```

**Response:**
```json
{
  "data": {
    "items": [
      {
        "id": 1,
        "totalAmount": 5400,
        "paidAmount": 5400,
        "remainingAmount": 0,
        "itemCount": 3,
        "createdAt": "2026-01-20T10:12:00.000Z"
      }
    ],
    "total": 120,
    "page": 1,
    "limit": 20
  }
}
```

#### `GET /api/v1/sales/:id`
Private. Detail + items + product names.

**Response:**
```json
{
  "data": {
    "id": 1,
    "totalAmount": 5400,
    "paidAmount": 5400,
    "remainingAmount": 0,
    "createdAt": "2026-01-20T10:12:00.000Z",
    "items": [
      {
        "id": 1,
        "productId": 1,
        "productName": "Nike T-Shirt Black",
        "quantity": 2,
        "unitPrice": 1800,
        "purchasePrice": 1200,
        "lineTotal": 3600
      },
      {
        "id": 2,
        "productId": 10,
        "productName": "Adidas Shorts",
        "quantity": 1,
        "unitPrice": 1800,
        "purchasePrice": 1000,
        "lineTotal": 1800
      }
    ]
  }
}
```

#### `POST /api/v1/sales`
Private. Creates a sale + items + deducts inventory — **ALL inside a DB TRANSACTION**.

**Body:**
```ts
{
  items: z.array(z.object({
    productId: z.number().int().positive(),
    quantity:  z.number().int().min(1)
  })).min(1)
  // NOTE: paidAmount is intentionally NOT exposed to the Flutter client for MVP.
  // The backend always sets paidAmount = totalAmount (fully paid sale).
  // The paidAmount column exists only to ease a future debt feature.
}
```

**Success 201:** same shape as `GET /sales/:id` detail.

**Error codes:**
- 400 `VALIDATION_ERROR`
- 404 `PRODUCT_NOT_FOUND` (for any item)
- 409 `INSUFFICIENT_STOCK` (which product, available vs requested)
- Partial payments (paidAmount < totalAmount) are NOT implemented for the MVP.
  A future phase may expose an explicit paidAmount and open the debt path.

---

### 4.5 Dashboard

All dashboard endpoints accept a time period via query. Time filter logic is centralized once in `dashboard.service.ts`.

**Standard period query:**
```ts
{
  period: z.enum(["today","week","month","custom"]).default("today"),
  month: z.coerce.number().int().min(1).max(12).optional(),    // for period==custom → select month
  year:  z.coerce.number().int().optional(),
  from:  z.coerce.date().optional(),
  to:    z.coerce.date().optional()
}
```
Helper: When `month` + `year` provided, use 1st day 00:00 → last day 23:59:59 of that month.

#### `GET /api/v1/dashboard/summary`
Private. Top-of-home-screen numbers.

**Response (period = today as example):**
```json
{
  "data": {
    "period": "today",
    "from": "2026-01-22T00:00:00.000Z",
    "to":   "2026-01-22T23:59:59.000Z",
    "salesCount": 8,
    "itemsSold": 12,
    "revenue": 12500,
    "profit":  4200,
    "lowStockCount": 3,
    "categoryQuantities": [
      { "categoryId": 1, "name": "T-Shirt", "quantity": 24 },
      { "categoryId": 2, "name": "Shoes",   "quantity": 13 },
      { "categoryId": 3, "name": "Slippers","quantity": 8  },
      { "categoryId": 4, "name": "Shorts",  "quantity": 17 },
      { "categoryId": 5, "name": "Pants",   "quantity": 11 },
      { "categoryId": 6, "name": "Sets",    "quantity": 6  }
    ]
  }
}
```

#### `GET /api/v1/dashboard/sales`
Private. Chart data — sales grouped by bucket.
- period == "today" → by hour (0..23)
- period == "week"  → by day (Mon..Sun)
- period == "month" → by day (1..31)
- period == "custom" + month → by day (1..N of month)

**Response:**
```json
{
  "data": [
    { "label": "09", "revenue": 1800, "profit": 600, "count": 1 },
    { "label": "10", "revenue": 5400, "profit": 1800, "count": 3 }
  ]
}
```

---

## 5. Authentication Flow

### Stack
- Hashing: **argon2id** (preferred; OWASP 2023) with sensible params (m=47104, t=1, p=1)
- Token: **JWT** (HS256), issued by Fastify plugin `@fastify/jwt`
- Token payload: `{ sub: userId, username: string, iat, exp }`
- Token expiry: **7 days** (mobile apps don't re-login daily; refresh not needed for MVP)

### Login flow (sequence)
```
Flutter Login Screen
  │ POST /auth/login (username, password)
  ▼
Fastify auth.handler → Zod validate
  │
  ▼ auth.service.login(username, plain)
      ├─ repository.findByUsername(username) → user?
      │   no → throw INVALID_CREDENTIALS
      ├─ argon2.verify(user.passwordHash, plain)
      │   no → throw INVALID_CREDENTIALS
      └─ fastify.jwt.sign({ sub: user.id, username })
  ▼
Response { token, user }
  │
  ▼ Flutter
     ├─ api_client stores token in memory
     └─ secure_storage.write(token) → survives app restart
```

### Protected requests
```
Flutter → any /api/v1/*
 auth_interceptor attaches:
   Authorization: Bearer <token>
   │
   ▼ Fastify plugins/auth.ts onRequest hook
       ├─ skip for /auth/login
       ├─ req.jwtVerify()
       │   fail → 401 UNAUTHORIZED
       └─ req.user = decoded → available in handlers
```

### Logout
Purely client-side: delete token from secure_storage + memory → go to login. No server-side invalidation needed (MVP simplicity).

### Bootstrapping the admin
- `scripts/seed.ts` runs once or during first deploy
- Inserts 6 categories + 1 user with username `admin` and password from env `SEED_ADMIN_PASSWORD`
- Password is hashed before insert

---

## 6. Sale / Inventory Transaction Flow

### Endpoint: `POST /sales` → `sale.service.createSale(dto)`

This is the **most critical** code path. It must be:
- Entirely inside a single MySQL transaction
- Row-locked to prevent overselling under concurrent requests
- Rollback on ANY failure

```
BEGIN TRANSACTION  (READ COMMITTED + FOR UPDATE row locks)

1. Load all products by ids (SELECT ... FOR UPDATE on products rows)
   → Row locks prevent another concurrent sale from mutating quantity mid-check.

2. For each item in dto:
     a. product not found → throw PRODUCT_NOT_FOUND
     b. if product.quantity < item.quantity → throw INSUFFICIENT_STOCK
        with details: { productId, available, requested }
     c. snapshot current unitPrice = product.sellingPrice
     d. snapshot current purchasePrice = product.purchasePrice
     e. accumulate totalAmount += unitPrice * qty
     f. accumulate totalProfit  += (unitPrice - purchasePrice) * qty  (unused for storage)
     g. decrease product.quantity -= item.quantity

3. Compute paidAmount:
     - Always paidAmount = totalAmount (MVP — fully paid sales only).
     - The dto intentionally has NO paidAmount field for the MVP.
   (The paidAmount column is preserved so a future debt feature can simply
    allow an explicit paidAmount < totalAmount without a schema change.)

4. INSERT INTO sales (totalAmount, paidAmount) → saleId

5. Bulk INSERT INTO sale_items (saleId, productId, quantity, unitPrice, purchasePrice)

6. Bulk UPDATE products SET quantity = newQty WHERE id IN (...)
   (We already decremented in-memory; write the new values now.)

7. COMMIT.

On any error at step 1..6 → ROLLBACK and rethrow.
```

### Why row-level locks (`FOR UPDATE`)
Without them: two concurrent sales for the same product with 1 qty left could BOTH read `qty=1`, both pass the check, both decrement, resulting in `qty = -1` or a phantom oversell. `FOR UPDATE` serializes access per product row; second transaction waits until the first commits, then re-reads the updated quantity.

### Remaining amount
`remainingAmount = totalAmount - paidAmount` is returned by APIs (derived, not stored for MVP). Storage-level columns are kept so the debt feature only needs to allow `paidAmount < totalAmount` and add a `debts` + `debt_payments` table + customer FK to sales.

---

## 7. Flutter Architecture

### Why Riverpod (v2 + codegen or not)
- Lightweight, no boilerplate vs Bloc
- Clear separation of UI ↔ provider ↔ service
- Works with paginated lists, search debounce, async loading
- Easy to test

### Screen → Provider → Service layering
```
Screen (UI only)
  │ watches providers, shows loading/error/data
  ▼
Provider (Riverpod Notifier / AsyncNotifier)
  │ holds in-memory state (list of products, cart, summary)
  │ exposes actions: refresh, loadMore, addToCart, submit
  ▼ calls
Service (repository-like)
  │ uses core/network/api_client (Dio)
  │ maps JSON → typed model (fromJson/toJson)
  ▼
HTTP → Fastify REST
```

### New Sale flow (Flutter side)
```
Products screen → tap cart FAB or a product "+"
  │
  ▼
NewSaleScreen (state = NewSaleProvider)
  ├─ search + add products via modal
  ├─ each product added with qty=1, can increment/decrement
  ├─ running total displayed
  └─ "Confirm Sale" (large button)
       │
       ▼ NewSaleProvider.submit()
            ├─ build POST /sales body
            ├─ POST via saleService.createSale(body)
            ├─ success → clear cart, show toast, navigate to sale detail
            └─ error 409 INSUFFICIENT_STOCK → show which product
                     is short; let user adjust.
```

### Search UX requirement
Product search must be **instant** — no/minimal debounce (per user preferences). Implementation:
- `TextFormField` `onChanged` → immediately updates a `searchQuery` provider state
- Provider with `ref.watch(searchQueryProvider)` triggers `productService.search()` directly on every keystroke. Only for very slow networks we cap at **100ms debounce max** (configurable).

### Image handling (optional)
Products can optionally have a photo. For the MVP:
- `imageUrl` remains **nullable** in the DB for future compatibility.
- **Do NOT implement image upload yet.** No upload endpoint, no base64, no local save.
- Product creation must work perfectly without selecting/capturing any image.
- `image_picker` package is NOT required for the MVP.
- Future phase may add: `POST /products/:id/image` multipart endpoint → backend saves to `uploads/` folder, returns URL.

---

## 8. Backend Architecture

### Request pipeline
```
HTTP Request
  │
  ▼ Fastify
      ├─ CORS plugin
      ├─ Logger plugin (pino)
      ├─ JWT plugin
      ├─ onRequest: auth hook (401 if protected & invalid)
      ├─ preParsing: (nothing)
      ├─ preValidation: Zod schema parsing
      │   fails → 400 VALIDATION_ERROR
      ├─ handler (thin)
      │   └─ calls service layer
      │       ├─ business logic
      │       ├─ repository (Drizzle)
      │       └─ DB transactions
      ▼
  Global error plugin → normalize AppError to:
    {
      error: {
        code: "INSUFFICIENT_STOCK",
        message: "Product X has only 2 in stock",
        details?: {...}
      },
      data: null
    }
```

### Module boundaries
- **auth** depends on → users repository, nothing else
- **categories** standalone
- **products** depends on → categories repository (validate categoryId)
- **sales** depends on → products repository (locks & checks), creates sale/sale_items
- **dashboard** depends on → products, sales, sale_items repositories (read-only)
- **shared/** has no outward dependencies (except external libs)

### Centralized error model
```ts
class AppError extends Error {
  readonly code: string;          // INVALID_CREDENTIALS, PRODUCT_NOT_FOUND, ...
  readonly statusCode: number;    // 400, 401, 404, 409, 500
  readonly details?: unknown;     // optional structured info
}
```
All throws in service/repository layers throw `AppError`; global plugin catches it and maps to consistent JSON.

### DB & Drizzle
- Driver: `mysql2/promise` (Drizzle mysql2)
- Single connection pool via env (DATABASE_URL or host/user/pw/name split env vars)
- Migrations: `drizzle-kit generate` → `drizzle-kit migrate`
- Seed: separate `scripts/seed.ts` run once with `tsx`

### Anti-overengineering rule
This is a tiny MVP. Use simple, readable TypeScript. Do NOT introduce:
- abstract / generic repositories
- use-case classes per CRUD operation
- excessive interfaces, ports/adapters, enterprise DI
- factory classes where a plain function works

A module has exactly: `routes → handler → service → repository → schema`. Keep it flat.

### Inventory costing (MVP)
- Keep `products.purchasePrice` (single current purchase price)
- Snapshot it into `sale_items.purchasePrice` at sale time so historical profit is correct
- **Do NOT implement** FIFO, LIFO, weighted average, purchase batches, or inventory valuation. Those are future accounting features.

---

## 9. Required Environment Variables

### Backend `.env`
```env
# Server
NODE_ENV=development              # development | production | test
PORT=3000
HOST=0.0.0.0

# MySQL
DB_HOST=127.0.0.1
DB_PORT=3306
DB_USER=root
DB_PASSWORD=changeme
DB_NAME=clothing_store
# Optionally (alternative to above 4):
# DATABASE_URL=mysql://root:changeme@127.0.0.1:3306/clothing_store

# JWT
JWT_SECRET=super-secret-change-me  # ≥ 32 random chars in production
JWT_EXPIRES_IN=7d                  # 7 days

# Seeding (used only by seed script)
SEED_ADMIN_USERNAME=admin
SEED_ADMIN_PASSWORD=admin123

# Optional image upload (if we implement upload endpoint)
UPLOAD_DIR=./uploads
MAX_UPLOAD_BYTES=5242880           # 5MB

# CORS
CORS_ORIGIN=*                      # or comma-separated allowed origins
```

### Flutter mobile `.env` (load via `flutter_dotenv`)
```env
API_BASE_URL=http://10.0.2.2:3000/api/v1    # Android emulator → host
# API_BASE_URL=http://localhost:3000/api/v1  # iOS simulator
```

---

## 10. Development Phases

### Phase 0 — Scaffolding & Setup
- [ ] Create repo with `backend/` + `mobile/` empty projects
- [ ] Backend: TypeScript, Fastify, Zod, Drizzle, argon2, @fastify/jwt, mysql2 installed
- [ ] Mobile: Flutter, Riverpod, Dio, go_router, flutter_secure_storage, intl, image_picker
- [ ] Shared `.env.example` files

### Phase 1 — DB Schema + Seed
- [ ] Drizzle schemas for all 5 tables (users, categories, products, sales, sale_items)
- [ ] Generate & run first migration
- [ ] Seed script: 6 categories + admin user

### Phase 2 — Backend: Auth skeleton
- [ ] AppError + global error plugin
- [ ] Env validation
- [ ] Auth module (login, me, seed)
- [ ] JWT protect hook applied
- [ ] Smoke-tested via curl/Postman/Thunder Client

### Phase 3 — Backend: Categories + Products CRUD
- [ ] Categories GET
- [ ] Products: GET list (paginated, search, low-stock filter), GET by id, POST, PATCH, DELETE
- [ ] All Zod schemas in place, all endpoints protected

### Phase 4 — Backend: Sales (transactional) + Dashboard
- [ ] `POST /sales` — fully transactional, `FOR UPDATE` locks, stock check
- [ ] `GET /sales`, `GET /sales/:id`
- [ ] `GET /dashboard/summary` (revenue, profit, counts, category qty, low stock)
- [ ] `GET /dashboard/sales` (time-bucketed chart data)
- [ ] Manual integration test: create sale → verify qty decremented; try oversell → verify blocked

### Phase 5 — Mobile: Auth + shared core
- [ ] App shell, theme, go_router, Dio wrapper + auth interceptor, secure_storage
- [ ] Login screen → token persisted → redirects to home
- [ ] 401 → automatic logout + navigate login

### Phase 6 — Mobile: Products & Categories
- [ ] Products list (paginated, pull-to-refresh)
- [ ] Product search (instant, minimal debounce)
- [ ] Category filter chips
- [ ] Low-stock visual indicator
- [ ] Add product form (FAB "+") → fields: name, category dropdown, purchase price, selling price, qty, optional image
- [ ] Edit product

### Phase 7 — Mobile: New Sale flow
- [ ] "New Sale" prominent entry on home or tab
- [ ] Cart screen: add products (search), adjust qty, running total
- [ ] Confirm → POST /sales → success toast + detail view
- [ ] Handle 409 insufficient stock errors gracefully

### Phase 8 — Mobile: Dashboard
- [ ] Home = Dashboard screen
- [ ] Period toggle: Today / Week / Month + month picker for custom
- [ ] Summary cards: Today's Sales, Today's Profit, Items Sold, Low Stock count
- [ ] Category quantities list
- [ ] Simple bar/line chart for sales trend

### Phase 9 — Mobile: Sales History
- [ ] Sales list (paginated, date range filter)
- [ ] Sale detail (items with qty/prices, total, paid/remaining)

### Phase 10 — Polish & MVP Cut
- [ ] Currency formatting "2,500 DA" with Algerian locale
- [ ] Large, readable fonts; big touch targets
- [ ] Empty states, loading states, error toasts
- [ ] Android build (debug → release-ready config)
- [ ] End-to-end walkthrough: login → add products → 5 sales → dashboard numbers match → verify inventory decrements
- [ ] Hardened JWT_SECRET for prod

### Post-MVP (explicitly out of scope per spec)
- Customers & debt management
- Image upload endpoint (replace manual imageUrl)
- Notifications
- Barcode scanning
- Offline / sync
- Advanced accounting / reports
