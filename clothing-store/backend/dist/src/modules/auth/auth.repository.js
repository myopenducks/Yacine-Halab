import { eq } from 'drizzle-orm';
import { users } from '../../db';
export class AuthRepository {
    db;
    constructor(db) {
        this.db = db;
    }
    async findByUsername(username) {
        const rows = await this.db
            .select()
            .from(users)
            .where(eq(users.username, username))
            .limit(1);
        return rows[0] ?? null;
    }
    async findById(id) {
        const rows = await this.db
            .select()
            .from(users)
            .where(eq(users.id, id))
            .limit(1);
        return rows[0] ?? null;
    }
}
//# sourceMappingURL=auth.repository.js.map