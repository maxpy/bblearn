// @ts-check
const { chromium } = require('playwright');

const BASE = 'http://localhost:8080';

async function run() {
  const browser = await chromium.launch({ headless: true });
  const page = await browser.newPage();

  const consoleErrors = [];
  const networkErrors = [];

  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });
  page.on('response', res => {
    if (!res.ok() && res.url().includes('localhost')) {
      networkErrors.push(`${res.status()} ${res.url()}`);
    }
  });

  let passed = 0, failed = 0;
  function ok(name) { console.log(`  ✓ ${name}`); passed++; }
  function fail(name, reason) { console.log(`  ✗ ${name}: ${reason}`); failed++; }
  async function check(name, fn) {
    try { await fn(); ok(name); } catch (e) { fail(name, e.message); }
  }

  // ── 1. Home screen ──────────────────────────────────────────────────────────
  console.log('\n[1] Home screen');
  networkErrors.length = 0;
  await page.goto(BASE, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  await check('home page loads (HTTP 200)', async () => {
    const res = await page.request.get(BASE);
    if (!res.ok()) throw new Error(`HTTP ${res.status()}`);
  });

  await check('no 404s on home page', async () => {
    const errs = networkErrors.filter(e => e.startsWith('404'));
    if (errs.length) throw new Error(errs.join(', '));
  });

  // Take screenshot
  await page.screenshot({ path: '/tmp/screen_home.png', fullPage: true });
  console.log('  → screenshot: /tmp/screen_home.png');

  // ── 2. Book screen ───────────────────────────────────────────────────────────
  console.log('\n[2] Book screen (Mark = book 41)');
  networkErrors.length = 0;
  await page.goto(`${BASE}/#/book/41`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  await check('book screen HTTP 200', async () => {
    const res = await page.request.get(`${BASE}/#/book/41`);
    if (!res.ok()) throw new Error(`HTTP ${res.status()}`);
  });

  await check('no 404s on book screen', async () => {
    const errs = networkErrors.filter(e => e.startsWith('404'));
    if (errs.length) throw new Error(errs.join(', '));
  });

  await page.screenshot({ path: '/tmp/screen_book.png', fullPage: true });
  console.log('  → screenshot: /tmp/screen_book.png');

  // ── 3. Player screen Mark 1 ──────────────────────────────────────────────────
  console.log('\n[3] Player screen (Mark ch.1)');
  networkErrors.length = 0;
  consoleErrors.length = 0;
  await page.goto(`${BASE}/#/player/41/1`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  await check('player screen loads', async () => {
    const res = await page.request.get(BASE);
    if (!res.ok()) throw new Error(`HTTP ${res.status()}`);
  });

  await check('no asset 404s on player', async () => {
    const errs = networkErrors.filter(e => e.startsWith('404') && e.includes('assets'));
    if (errs.length) throw new Error(errs[0]);
  });

  await page.screenshot({ path: '/tmp/screen_player_mark1.png', fullPage: true });
  console.log('  → screenshot: /tmp/screen_player_mark1.png');

  // ── 4. Player screen Exodus 2 ────────────────────────────────────────────────
  console.log('\n[4] Player screen (Exodus ch.2)');
  networkErrors.length = 0;
  consoleErrors.length = 0;
  await page.goto(`${BASE}/#/player/2/2`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  await check('no asset 404s on Exodus player', async () => {
    const errs = networkErrors.filter(e => e.startsWith('404') && e.includes('assets'));
    if (errs.length) throw new Error(errs[0]);
  });

  await page.screenshot({ path: '/tmp/screen_player_exodus2.png', fullPage: true });
  console.log('  → screenshot: /tmp/screen_player_exodus2.png');

  // ── 5. Direct asset HTTP checks ──────────────────────────────────────────────
  console.log('\n[5] Asset HTTP checks');

  const assets = [
    'assets/audio/KJV/OT/02_Exodus/02_Exodus_002.subtitle.json',
    'assets/audio/CUV/OT/02_Exodus/02_Exodus_002.subtitle.json',
    'assets/text/KJV/OT/02_Exodus/02_Exodus_002.txt.json',
    'assets/text/CUV/OT/02_Exodus/02_Exodus_002.txt.json',
    'assets/audio/KJV/NT/41_Mark/41_Mark_001.subtitle.json',
    'assets/audio/CUV/NT/41_Mark/41_Mark_001.subtitle.json',
    'assets/text/KJV/NT/41_Mark/41_Mark_001.txt.json',
    'assets/text/CUV/NT/41_Mark/41_Mark_001.txt.json',
  ];

  for (const asset of assets) {
    await check(asset.split('/').slice(-1)[0], async () => {
      const res = await page.request.get(`${BASE}/${asset}`);
      if (!res.ok()) throw new Error(`HTTP ${res.status()} for ${asset}`);
      const json = await res.json();
      if (!json.verses || json.verses.length === 0) throw new Error('empty verses array');
    });
  }

  // ── 6. All network errors summary ────────────────────────────────────────────
  console.log('\n[6] All network errors captured');
  if (networkErrors.length === 0) {
    ok('no network errors');
  } else {
    fail('network errors found', '');
    networkErrors.forEach(e => console.log('    ' + e));
  }

  // ── Summary ──────────────────────────────────────────────────────────────────
  console.log(`\n${'─'.repeat(60)}`);
  console.log(`Results: ${passed} passed, ${failed} failed`);

  await browser.close();
  process.exit(failed > 0 ? 1 : 0);
}

run().catch(e => { console.error(e); process.exit(1); });
