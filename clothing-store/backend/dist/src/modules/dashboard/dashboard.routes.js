export function registerDashboardRoutes(app, handler) {
    app.get('/api/v1/dashboard/summary', async (req, reply) => {
        const result = await handler.summary(req);
        return reply.status(200).send(result);
    });
    app.get('/api/v1/dashboard/sales', async (req, reply) => {
        const result = await handler.sales(req);
        return reply.status(200).send(result);
    });
}
//# sourceMappingURL=dashboard.routes.js.map