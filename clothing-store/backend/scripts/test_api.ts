async function test() {
  const loginRes = await fetch('https://yacine-halab-production.up.railway.app/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'admin123' }),
  });
  const loginData: any = await loginRes.json();
  console.log('Login result:', loginData);
  if (!loginData.data?.token) return;

  const catRes = await fetch('https://yacine-halab-production.up.railway.app/api/v1/categories', {
    headers: { Authorization: `Bearer ${loginData.data.token}` },
  });
  const catData: any = await catRes.json();
  console.log('Categories:', catData.data);

  // Also check guest_demo
  const guestLogin = await fetch('https://yacine-halab-production.up.railway.app/api/v1/auth/guest', {
    method: 'POST',
  });
  const guestData: any = await guestLogin.json();
  console.log('Guest user:', guestData.data?.user);
  if (guestData.data?.token) {
    const guestProds = await fetch('https://yacine-halab-production.up.railway.app/api/v1/products?page=1&limit=20', {
      headers: { Authorization: `Bearer ${guestData.data.token}` },
    });
    const gProdData: any = await guestProds.json();
    console.log('Guest products count:', gProdData.data?.total);
  }
  // Direct inspect via public route or test endpoint
  console.log('Done test');
}

test().catch(console.error);

