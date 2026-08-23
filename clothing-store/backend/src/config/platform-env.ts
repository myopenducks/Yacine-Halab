/**
 * Maps Railway / PlanetScale / common PaaS MySQL env names onto DB_* before Zod parse.
 * Call once before loadEnv() or any direct process.env DB reads.
 */
export function applyPlatformEnvDefaults(): void {
  const map: Array<[target: string, sources: string[]]> = [
    ['DB_HOST', ['MYSQLHOST', 'MYSQL_HOST']],
    ['DB_PORT', ['MYSQLPORT', 'MYSQL_PORT']],
    ['DB_USER', ['MYSQLUSER', 'MYSQL_USER']],
    ['DB_PASSWORD', ['MYSQLPASSWORD', 'MYSQL_PASSWORD']],
    ['DB_NAME', ['MYSQLDATABASE', 'MYSQL_DATABASE', 'MYSQL_DATABASE_NAME']],
  ];

  for (const [target, sources] of map) {
    if (process.env[target]) continue;
    for (const source of sources) {
      const value = process.env[source];
      if (value) {
        process.env[target] = value;
        break;
      }
    }
  }

  const mysqlUrl = process.env.MYSQL_URL ?? process.env.DATABASE_URL;
  if (mysqlUrl && !process.env.DB_HOST) {
    try {
      const url = new URL(mysqlUrl);
      process.env.DB_HOST = url.hostname;
      process.env.DB_PORT = url.port || '3306';
      process.env.DB_USER = decodeURIComponent(url.username);
      process.env.DB_PASSWORD = decodeURIComponent(url.password);
      process.env.DB_NAME = url.pathname.replace(/^\//, '');
    } catch {
      // ignore malformed URL — Zod / connection layer will surface the error
    }
  }
}

export function describeDbTarget(): string {
  const host = process.env.DB_HOST ?? '127.0.0.1';
  const port = process.env.DB_PORT ?? '3306';
  const name = process.env.DB_NAME ?? 'clothing_store';
  return `${host}:${port}/${name}`;
}
