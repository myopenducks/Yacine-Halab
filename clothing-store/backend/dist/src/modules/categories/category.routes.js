export function registerCategoryRoutes(app, handler) {
    app.get('/api/v1/categories', async (req, reply) => {
        const result = await handler.list();
        return reply.status(200).send(result);
    });
}
//# sourceMappingURL=category.routes.js.map