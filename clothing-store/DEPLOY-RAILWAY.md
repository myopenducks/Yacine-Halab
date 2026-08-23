# Deploy backend to Railway

Repo: [myopenducks/Yacine-Halab](https://github.com/myopenducks/Yacine-Halab)

Railway failed because the **repo root** only contains a `clothing-store/` folder — Railpack had no `package.json` to detect Node.js. This repo now includes root-level deploy config that builds `clothing-store/backend`.

## 1. Create Railway project

1. [Railway](https://railway.com) → **New Project** → **Deploy from GitHub repo** → `myopenducks/Yacine-Halab`
2. Push the latest commits (with `package.json` + `railway.toml` at repo root) before redeploying.

### Option A — use repo root (simplest after this fix)

Leave **Root Directory** empty (`/`). Railway uses `/railway.toml` at the repo root.

### Option B — point directly at the API (recommended long-term)

Service → **Settings** → **Root Directory** = `clothing-store/backend`

Then set **Config file path** = `/clothing-store/backend/railway.toml`  
(Railway config paths are always absolute from the repo root.)

## 2. Add MySQL

1. In the same Railway project: **+ New** → **Database** → **MySQL**
2. Open your **API service** → **Variables** → **Add references** from the MySQL service, then map:

| Variable     | Value (Railway MySQL reference) |
|-------------|----------------------------------|
| `DB_HOST`   | `${{MySQL.MYSQLHOST}}`           |
| `DB_PORT`   | `${{MySQL.MYSQLPORT}}`           |
| `DB_USER`   | `${{MySQL.MYSQLUSER}}`           |
| `DB_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}`     |
| `DB_NAME`   | `${{MySQL.MYSQLDATABASE}}`         |

(Replace `MySQL` with your database service name if different.)

## 3. Required environment variables (API service)

| Variable | Example / notes |
|----------|-----------------|
| `NODE_ENV` | `production` |
| `JWT_SECRET` | 32+ random chars — `openssl rand -base64 48` |
| `JWT_EXPIRES_IN` | `7d` |
| `CORS_ORIGIN` | `*` or your app origin |
| `PORT` | Railway sets this automatically — do not override unless needed |

## 4. First deploy — seed admin user

After the first successful deploy, run once from your machine (Railway CLI):

```bash
npm i -g @railway/cli
railway login
railway link
cd clothing-store/backend
railway run npm run db:seed
```

Set `SEED_ADMIN_USERNAME` / `SEED_ADMIN_PASSWORD` in Railway variables before seeding if you want non-default credentials.

Default seed: `admin` / `admin123`

## 5. Verify

```bash
curl https://YOUR-RAILWAY-URL.up.railway.app/health
# → {"status":"ok","uptime":...}

curl -X POST https://YOUR-RAILWAY-URL.up.railway.app/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

## 6. Point the Flutter app at Railway

```powershell
cd clothing-store/mobile
flutter run --dart-define=API_BASE_URL=https://YOUR-RAILWAY-URL.up.railway.app
```

## Troubleshooting

| Build error | Fix |
|-------------|-----|
| `Railpack could not determine how to build` | Push root `package.json` + `railway.toml`, or set Root Directory to `clothing-store/backend` |
| `JWT_SECRET` validation failed | Use 32+ random characters in production |
| DB connection refused | Check MySQL variables are referenced on the API service |
| 401 on login | Run `railway run npm run db:seed` once |

Migrations run automatically on each deploy (`npm start` → migrate → server).
