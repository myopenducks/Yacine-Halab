import type { MySql2Database } from 'drizzle-orm/mysql2';
import { eq } from 'drizzle-orm';
import * as schema from '../../db';
import { users } from '../../db';
import type { User } from '../../db/schema/users';

export class AuthRepository {
  constructor(private readonly db: MySql2Database<typeof schema>) {}

  async findByUsername(username: string): Promise<User | null> {
    const rows = await this.db
      .select()
      .from(users)
      .where(eq(users.username, username))
      .limit(1);
    return rows[0] ?? null;
  }

  async findById(id: number): Promise<User | null> {
    const rows = await this.db
      .select()
      .from(users)
      .where(eq(users.id, id))
      .limit(1);
    return rows[0] ?? null;
  }
}
