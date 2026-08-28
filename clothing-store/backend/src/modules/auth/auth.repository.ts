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

  async create(username: string, passwordHash: string): Promise<User> {
    const [result] = await this.db.insert(users).values({
      username,
      passwordHash,
    });
    const created = await this.findById(result.insertId);
    return created!;
  }

  async updatePassword(id: number, passwordHash: string): Promise<void> {
    await this.db
      .update(users)
      .set({ passwordHash })
      .where(eq(users.id, id));
  }

  async createGuest(): Promise<User> {
    const randomSuffix = Math.random().toString(36).substring(2, 8);
    const guestUsername = `guest_${randomSuffix}`;
    const dummyHash = '$argon2id$v=19$m=65536,t=3,p=4$guestdummy$guestdummy';
    const [result] = await this.db.insert(users).values({
      username: guestUsername,
      passwordHash: dummyHash,
    });
    const guestUser = (await this.findById(result.insertId))!;

    const INITIAL_CATEGORIES = ['T-Shirt', 'Shoes', 'Slippers', 'Shorts', 'Pants', 'Sets'];
    for (const name of INITIAL_CATEGORIES) {
      await this.db.insert(schema.categories).values({
        name,
        userId: guestUser.id,
      });
    }

    return guestUser;
  }
}

