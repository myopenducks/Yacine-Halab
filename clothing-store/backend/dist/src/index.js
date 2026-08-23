import 'dotenv/config';
import { createApp } from './app/fastify';
async function main() {
    const { app, env } = await createApp();
    try {
        const url = await app.listen({ port: env.PORT, host: env.HOST });
        app.log?.info?.({ env: env.NODE_ENV }, `server listening at ${url}`);
    }
    catch (err) {
        app.log?.error?.(err);
        process.exit(1);
    }
}
main();
//# sourceMappingURL=index.js.map