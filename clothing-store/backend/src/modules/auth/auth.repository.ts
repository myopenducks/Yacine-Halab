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
    const demoUsername = 'guest_demo';
    const existing = await this.findByUsername(demoUsername);
    if (existing) {
      return existing;
    }

    const dummyHash = '$argon2id$v=19$m=65536,t=3,p=4$guestdummy$guestdummy';
    const [result] = await this.db.insert(users).values({
      username: demoUsername,
      passwordHash: dummyHash,
    });
    const guestUser = (await this.findById(result.insertId))!;

    const INITIAL_CATEGORIES = ['T-Shirt', 'Shoes', 'Slippers', 'Shorts', 'Pants', 'Sets'];
    const catMap = new Map<string, number>();
    for (const name of INITIAL_CATEGORIES) {
      try {
        const [catRes] = await this.db.insert(schema.categories).values({
          name,
          userId: guestUser.id,
        });
        catMap.set(name, catRes.insertId);
      } catch (_) {}
    }

    // Seed initial demo products
    const sampleProducts = [
      { name: 'T-Shirt Oversize Coton Noir', cat: 'T-Shirt', buy: 1200, sell: 2200, qty: 15 },
      { name: 'Polo Classique Blanc', cat: 'T-Shirt', buy: 1800, sell: 3000, qty: 10 },
      { name: 'Jean Slim Bleu Denim', cat: 'Pants', buy: 2500, sell: 4500, qty: 8 },
      { name: 'Pantalon Cargo Kaki', cat: 'Pants', buy: 2800, sell: 4800, qty: 4 },
      { name: 'Sneakers Streetwear Blanche', cat: 'Shoes', buy: 4000, sell: 6500, qty: 6 },
      { name: 'Claquettes Confort Cuir', cat: 'Slippers', buy: 1500, sell: 2500, qty: 12 },
      { name: 'Short Jogging Gris', cat: 'Shorts', buy: 1400, sell: 2400, qty: 3 },
      { name: 'Ensemble Sport Tech Noir', cat: 'Sets', buy: 5500, sell: 8500, qty: 7 },
    ];

    for (const p of sampleProducts) {
      const catId = catMap.get(p.cat);
      if (catId) {
        try {
          await this.db.insert(schema.products).values({
            name: p.name,
            categoryId: catId,
            userId: guestUser.id,
            purchasePrice: p.buy,
            sellingPrice: p.sell,
            quantity: p.qty,
          });
        } catch (_) {}
      }
    }

    return guestUser;
  }
}

