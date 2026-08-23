# Clothing Store Management App (MVP)

Single-shop inventory and sales management for a physical clothing store in Algeria (DA currency, `fr_DZ` locale).

## Stack

| Layer | Tech |
|---|---|
| Mobile | Flutter, Riverpod, Dio, go_router |
| Backend | Node.js, Fastify, Zod, Drizzle ORM, MySQL |
| Auth | argon2id + JWT (HS256) |

## Project layout

```
clothing-store/
├── backend/   # REST API
└── mobile/    # Flutter app
```

---

## Backend setup

```powershell
cd backend
cp .env.example .env
# Edit DB_*, JWT_SECRET (32+ random chars for production), SEED_ADMIN_*
npm install
npm run db:generate
npm run db:migrate
npm run db:seed
npm run dev
```

Server listens at `http://localhost:3000`.

### Production security

- Set `NODE_ENV=production`
- Set `JWT_SECRET` to at least 32 random characters (no placeholder strings). The server **refuses to start** in production with a weak secret.
- Generate one with: `openssl rand -base64 48`

### Automated MVP smoke test

With the server running:

```powershell
npm run smoke:mvp
```

Verifies: login → create product → 5 sales → dashboard totals → inventory decrement.

---

## Mobile setup

```powershell
cd mobile
flutter pub get
flutter run -d windows          # API → http://127.0.0.1:3000
flutter run -d <android_emulator>  # API → http://10.0.2.2:3000
```

Login: `admin` / `admin123` (from seed).

### Custom API URL

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000
```

### Android release APK (MVP)

```powershell
cd mobile
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

- App ID: `dz.boutique.store`
- Display name: **Boutique Store**
- Release builds use debug signing for convenience — replace with a release keystore before Play Store upload.

---

## Manual E2E walkthrough (MVP sign-off)

1. **Login** — `admin` / `admin123` → lands on Home dashboard.
2. **Add products** — Products tab → `+` → create 2–3 items with qty ≥ 10.
3. **Five sales** — Sale tab → search/add → confirm 5 separate sales.
4. **History** — History tab → see 5 new rows → tap one for item detail (paid = total for MVP).
5. **Dashboard** — Home → Today → Sales / Profit / Items sold increased; chart shows buckets.
6. **Inventory** — Products tab → quantities decreased by amounts sold.
7. **Low stock** — set a product qty ≤ 5 → Home shows Low stock count > 0.

Optional backend check: `npm run smoke:mvp` with server running.

---

## Features (Phases 0–10)

- Auth (JWT, secure storage, auto-logout on 401)
- Products CRUD + search + category/low-stock filters
- New sale flow (transactional stock deduction)
- Dashboard KPIs + period toggle + sales chart
- Sales history + detail
- Algerian locale formatting (`fr_DZ`, e.g. `2 500 DA`)
- Android release-ready config

## Out of scope (post-MVP)

Customers/debt, image upload, notifications, barcode, offline sync, advanced reports.
