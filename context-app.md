# Clothing Store Management App

## 1. Project Overview

Build a small, simple mobile inventory and sales management application for a very small clothing store.

The application is intended for a single shop owner. It is NOT an e-commerce application and customers will not use the app.

The main goals are:

* Manage products and inventory
* Organize products by category
* Record purchases/sales
* Track quantities
* Track daily, weekly, and monthly sales
* View previous months
* Calculate profit
* Provide a very simple authentication system
* Keep the application simple and easy to use

The project should be designed as an MVP. Do not over-engineer it.

---

# 2. Technology Stack

## Mobile Frontend

Use:

* Flutter
* Dart
* Material Design
* Clean and maintainable architecture
* HTTP/REST API communication with the backend

Do NOT implement offline-first functionality for the MVP.

The application assumes that the user normally has an Internet connection.

The Flutter application should NOT directly connect to MySQL.

---

# 3. Backend

Use:

* Node.js
* TypeScript
* Fastify
* Zod for request/response validation
* Drizzle ORM
* MySQL

Do NOT use NestJS.

The backend should expose a REST API consumed by the Flutter application.

Structure the backend by feature/module rather than putting everything into large generic folders.

Suggested structure:

src/
app/
config/
db/
plugins/
modules/
auth/
products/
categories/
sales/
dashboard/
shared/

Each module should separate responsibilities appropriately.

For example:

products/
product.routes.ts
product.handler.ts
product.service.ts
product.schema.ts
product.repository.ts

Do not blindly create unnecessary abstractions. Keep the architecture simple.

---

# 4. Database

Use MySQL.

The database is hosted on the backend/server side.

Architecture:

Flutter
|
| HTTPS REST API
v
Fastify Backend
|
v
MySQL

The Flutter application must never contain MySQL credentials.

Use Drizzle ORM for database access and migrations.

---

# 5. Authentication

The application has a very simple authentication system.

There is currently only one shop owner/user.

The initial username and password will be created manually by the administrator/developer.

The user logs into the mobile application using:

* username
* password

Do not implement:

* Google authentication
* Facebook authentication
* OAuth
* email verification
* complex roles/permissions

Passwords must NEVER be stored as plain text.

Hash passwords using a secure password hashing algorithm such as Argon2id or bcrypt.

Use token-based authentication for the API.

The backend should protect all private endpoints.

---

# 6. Product Categories

The shop has only a small number of categories.

Initial categories:

1. T-Shirt
2. Shoes
3. Slippers
4. Shorts
5. Pants
6. Sets

Do not add unnecessary category-management complexity.

The category should be stored as a database entity and products should reference the category.

---

# 7. Products

A product should contain at least:

* id
* name
* categoryId
* purchasePrice
* sellingPrice
* quantity
* imageUrl (optional)
* createdAt
* updatedAt

The product image is OPTIONAL.

The user should be able to add a product without taking a photo.

Example:

Name:
Nike T-Shirt Black

Category:
T-Shirt

Purchase price:
1200 DA

Selling price:
1800 DA

Quantity:
10

Image:
optional

---

# 8. Add Product Flow

The main action should be an obvious "+" button.

When the user presses it:

1. Enter product name
2. Select category
3. Enter purchase price
4. Enter selling price
5. Enter quantity
6. Optionally take/select a photo
7. Save

The user should NOT be forced to provide an image.

The UI should be optimized for a small shop owner and should require as few steps as possible.

---

# 9. Product Search

The application must provide product search.

The user should be able to search products by name.

Example:

Search:

Nike

Results:

* Nike T-Shirt Black
* Nike T-Shirt White
* Nike Shorts

Search should be fast and simple.

---

# 10. Inventory

The application must show the current quantity of products.

The user should be able to see:

* Product quantity
* Category quantities
* Low-stock products

The dashboard should make inventory information easy to understand.

Example:

T-Shirts: 24
Shoes: 13
Slippers: 8
Shorts: 17
Pants: 11
Sets: 6

The system should prevent selling more units than are currently available.

---

# 11. Sales

The user must be able to record a sale.

A sale can contain one or multiple products.

Example:

Customer buys:

2 × T-Shirt
1 × Shorts

The system records:

* sale
* sale items
* quantity sold
* selling price at the time of sale
* total amount
* paid amount
* remaining amount

For the MVP, normal sales should be fully paid.

However, the database and sale model should already contain:

* totalAmount
* paidAmount

This is intentional because partial payments/debts may be implemented in a future version.

Do not implement the full debt-management system yet.

---

# 12. Important Pricing Rule

When a product is sold, store the actual selling price used in the SaleItem.

Do NOT rely only on the current Product.sellingPrice.

Reason:

If the product price changes later, old sales must keep their original price.

Example:

Product current selling price:
2000 DA

Old sale:
1800 DA

The old sale must remain 1800 DA.

---

# 13. Inventory Update

When a sale is completed:

Product quantity should decrease according to the sold quantity.

Example:

Before sale:

T-Shirt quantity = 10

Customer buys:

2

After sale:

T-Shirt quantity = 8

This operation must be handled safely on the backend.

Use a database transaction when creating a sale and updating inventory.

The system must not allow inventory to become negative.

---

# 14. Revenue and Profit

The dashboard should show both sales revenue and profit.

Revenue:

sum of actual selling prices of sold products.

Profit:

selling price - purchase price

Example:

Purchase price:
1200 DA

Selling price:
1800 DA

Profit:
600 DA

For multiple units:

2 × 600 = 1200 DA profit.

The dashboard should support:

* Today
* This week
* This month
* Previous months

---

# 15. Dashboard

The home screen should provide a simple business overview.

Example:

Today's Sales
12,500 DA

Today's Profit
4,200 DA

Products Sold
8

Low Stock
3

Then provide time filters:

* Today
* This Week
* This Month

And allow viewing previous months.

Keep charts simple.

Do not introduce a complex analytics system.

---

# 16. Sales History

The user should be able to see previous sales.

Each sale should show:

* date/time
* products
* quantities
* total
* paid amount
* remaining amount

The user should be able to open a sale to see its details.

---

# 17. Future Debt Feature

Do NOT implement the complete debt system in the MVP.

Future functionality may include:

Customer

* name
* phone number

Debt

* customer
* sale
* total
* paid
* remaining

DebtPayment

* amount
* date

The architecture should not make this future feature difficult to add.

However, do not prematurely implement these tables/features unless they are actually required for the MVP.

---

# 18. API Design

Use REST APIs.

Suggested endpoints:

Authentication:

POST /auth/login
GET /auth/me

Products:

GET /products
GET /products/:id
POST /products
PATCH /products/:id
DELETE /products/:id

Categories:

GET /categories

Sales:

GET /sales
GET /sales/:id
POST /sales

Dashboard:

GET /dashboard/summary
GET /dashboard/sales
GET /dashboard/profit

The exact endpoint design can be adjusted if there is a strong architectural reason.

---

# 19. Validation

Use Zod for all incoming API data.

Validate:

* product name
* category
* prices
* quantity
* sale items
* authentication input
* query parameters

Do not trust client-side validation alone.

Backend validation is mandatory.

Return consistent API error responses.

---

# 20. Database Transactions

Sales are financially important.

Creating a sale should be transactional.

A sale operation should roughly:

1. Validate products
2. Check stock
3. Calculate totals
4. Create Sale
5. Create SaleItems
6. Decrease inventory
7. Commit transaction

If any step fails, rollback the entire operation.

Avoid race conditions that could result in selling more inventory than available.

---

# 21. Money

Prices are in Algerian Dinar (DA).

Do not use floating-point numbers for monetary calculations.

Use integer values representing DA.

Example:

2500 DA should be stored as:

2500

not:

25.00

---

# 22. Flutter Architecture

Keep Flutter architecture clean but not over-engineered.

Suggested structure:

lib/
core/
network/
storage/
theme/
utils/

features/
auth/
dashboard/
products/
categories/
sales/

Each feature can contain:

* models
* screens
* widgets
* services/repositories
* state management

Choose a lightweight and maintainable state-management solution.

Do not introduce unnecessary complexity.

---

# 23. UX Requirements

The user is a small shop owner, not a technical user.

The UI must prioritize:

* Large buttons
* Clear Arabic/French-friendly labels if needed
* Simple navigation
* Minimal steps
* Fast product search
* Easy product creation
* Easy sale creation
* Clear prices in DA
* Clear inventory quantities

Avoid enterprise-style interfaces.

---

# 24. MVP Scope

The first version MUST focus on:

Authentication
Products
Categories
Inventory
Search
Sales
Sales history
Dashboard
Revenue
Profit
Monthly history

The first version MUST NOT focus on:

Online shopping
Customer accounts
Payments gateways
Delivery
Complex roles
Complex permissions
Debt management
Notifications
Barcode scanning
Advanced accounting
Offline-first architecture

---

# 25. Development Rules

Before writing large amounts of code:

1. Inspect the project structure.
2. Create a clear implementation plan.
3. Define the database schema.
4. Define API contracts.
5. Define module boundaries.
6. Then implement incrementally.

Do not generate the entire project blindly in one step.

After each major feature, verify that the code compiles and tests pass.

Prefer small, maintainable components over large files.

Do not duplicate business logic between Flutter and Fastify.

Business rules must be enforced by the backend.

The Flutter application is a client of the API.

---

# 26. First Task

Before implementing the application, produce:

1. Recommended project folder structure
2. Database ERD/schema
3. Database tables and relationships
4. REST API endpoint specification
5. Authentication flow
6. Sale/inventory transaction flow
7. Flutter architecture
8. Backend architecture
9. Required environment variables
10. Development phases

Do not start implementing all features yet.

First show the architecture and wait for approval.
