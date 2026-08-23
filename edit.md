We already have an architecture plan for this project.

IMPORTANT:
Do NOT rebuild the architecture from scratch.
Do NOT implement the entire application.
Use the current architecture plan as the baseline and apply ONLY the adjustments below.

## Required Architecture Adjustments

### 1. MVP payment handling

The database may keep:

* sales.totalAmount
* sales.paidAmount

However, for the MVP, all sales are fully paid.

Therefore:

* Flutter does NOT need to send `paidAmount` when creating a normal sale.
* Backend should automatically set:
  `paidAmount = totalAmount`
* Do NOT implement debt management.
* Do NOT create customers, debts, or debt payments yet.
* Do NOT expose partial-payment functionality in the UI.

The existence of `paidAmount` is only to make future debt support easier.

Future behavior may allow:
`paidAmount < totalAmount`

but this must NOT be implemented now.

---

### 2. Product images

Product images are OPTIONAL.

For the MVP:

* A product can be created without an image.
* Do NOT implement image upload yet.
* Do NOT use Base64 image storage.
* Do NOT create an upload endpoint yet.
* `imageUrl` may remain nullable in the database if useful for future compatibility.
* Do NOT make `image_picker` a required dependency unless it is actually needed now.

The MVP product creation flow must work perfectly without an image.

Future phase may add:

`POST /products/:id/image`

---

### 3. Product deletion

Keep product history safe.

A product that already appears in `sale_items` must not be physically deleted.

Use the existing FK restriction.

For the MVP, if a product has sales history:

* backend returns a clear `PRODUCT_HAS_SALES` error
* UI should explain that the product cannot be deleted because it has sales history
* user can instead set its quantity to 0

Do NOT implement soft-delete unless it becomes necessary.

---

### 4. Avoid over-engineering

Keep the current feature-based architecture:

routes
handlers
services
repositories
schemas

Do NOT introduce unnecessary abstractions such as:

* abstract repositories
* generic repository frameworks
* unnecessary factories
* use-case classes for every CRUD operation
* excessive interfaces
* ports/adapters layers
* enterprise-level dependency injection architecture

Use simple, readable TypeScript.

The project is a very small shop-management MVP.

Architecture should be clean but pragmatic.

---

### 5. Inventory costing

For the MVP:

Keep:

`products.purchasePrice`

and snapshot it into:

`sale_items.purchasePrice`

Do NOT implement:

* FIFO
* LIFO
* weighted average cost
* inventory valuation
* purchase batches

Those are future accounting features.

---

## Important Development Rule

DO NOT implement all phases.

Start ONLY with:

### Phase 0 — Scaffolding & Setup

and

### Phase 1 — Database Schema + Seed

Do not implement:

* authentication endpoints
* products CRUD
* sales
* dashboard
* Flutter screens
* image upload
* debt management

yet.

---

# Phase 0

Create the project structure:

clothing-store/
backend/
mobile/
README.md

Backend:

* Node.js
* TypeScript
* Fastify
* Zod
* Drizzle ORM
* MySQL
* mysql2
* argon2
* @fastify/jwt

Mobile:

* Flutter
* Dart
* Riverpod
* Dio
* go_router
* flutter_secure_storage
* intl

Do not add packages that are not currently necessary.

For example, image_picker is NOT required in Phase 0/1.

Create:

* package.json
* tsconfig.json
* drizzle.config.ts
* .env.example
* Flutter pubspec
* basic README

Create the folder structure, but do not implement future business logic yet.

---

# Phase 1 — Database Schema + Seed

Create the initial database schema using Drizzle.

Tables:

1. users
2. categories
3. products
4. sales
5. sale_items

Use MySQL.

### users

Fields:

* id
* username
* passwordHash
* createdAt
* updatedAt

Requirements:

* username unique
* passwordHash never stores plain text

---

### categories

Fields:

* id
* name
* createdAt
* updatedAt

Seed exactly these initial categories:

* T-Shirt
* Shoes
* Slippers
* Shorts
* Pants
* Sets

---

### products

Fields:

* id
* categoryId
* name
* purchasePrice
* sellingPrice
* quantity
* imageUrl nullable
* createdAt
* updatedAt

Money must use integer Algerian Dinar values.

Example:

2500 DA → 2500

Do not use floating-point values for money.

Quantity must never be negative.

---

### sales

Fields:

* id
* totalAmount
* paidAmount
* createdAt
* updatedAt

For the MVP assumption:

`paidAmount = totalAmount`

Do not add debt tables.

---

### sale_items

Fields:

* id
* saleId
* productId
* quantity
* unitPrice
* purchasePrice
* createdAt

`unitPrice` is the selling-price snapshot at sale time.

`purchasePrice` is the purchase-price snapshot at sale time.

This is required so historical profit remains correct if the product prices change later.

---

# Database Relationships

Use:

categories 1 → N products

products 1 → N sale_items

sales 1 → N sale_items

Use foreign keys.

Use restrictive deletion for products that already have sale history.

---

# Seed

Create a seed script that inserts:

* 6 categories
* 1 admin user

The admin credentials must come from environment variables.

Example:

SEED_ADMIN_USERNAME=admin
SEED_ADMIN_PASSWORD=...

The seed must hash the password before storing it.

Never store the password directly.

---

# What I want you to do NOW

Do ONLY Phase 0 and Phase 1.

At the end, STOP.

Do not continue to Phase 2.

Show me:

1. Final generated folder tree
2. `package.json`
3. `pubspec.yaml`
4. Drizzle database schema
5. Database relationships
6. Migration files or migration output
7. Seed script
8. `.env.example`
9. Short explanation of every database table
10. Any assumptions you had to make

Then wait for my review.

Do not silently implement future phases.

Do not generate authentication routes, product routes, sales routes, dashboard routes, or Flutter business screens yet.
