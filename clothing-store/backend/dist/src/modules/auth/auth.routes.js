export function registerAuthRoutes(app, handler) {
    app.post('/api/v1/auth/login', async (req, reply) => {
        const result = await handler.login(req);
        return reply.status(200).send(result);
    });
    app.get('/api/v1/auth/me', async (req, reply) => {
        const result = await handler.me(req);
        return reply.status(200).send(result);
    });
}
//# sourceMappingURL=auth.routes.js.map