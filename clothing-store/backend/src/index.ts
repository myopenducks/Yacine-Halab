import 'dotenv/config';
import { createApp } from './app/fastify';

async function main() {
  const { app, env } = await createApp();

  try {
    const url = await app.listen({ port: env.PORT, host: env.HOST });
    const message = `server listening at ${url}`;
    if (app.log) {
      app.log.info({ env: env.NODE_ENV }, message);
    } else {
      console.log(`[startup] ${message}`);
    }
  } catch (err) {
    console.error('[startup] listen failed', err);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error('[startup] fatal', err);
  process.exit(1);
});
