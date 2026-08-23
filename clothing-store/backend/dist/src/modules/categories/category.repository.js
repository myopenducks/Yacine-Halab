import { eq } from 'drizzle-orm';
import { categories } from '../../db/schema/categories';
export class CategoryRepository {
    db;
    constructor(db) {
        this.db = db;
    }
    async findAll() {
        return this.db.select().from(categories).orderBy(categories.id);
    }
    async findById(id) {
        const rows = await this.db
            .select()
            .from(categories)
            .where(eq(categories.id, id))
            .limit(1);
        return rows[0] ?? null;
    }
}
//# sourceMappingURL=category.repository.js.map