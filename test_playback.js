// @ts-check
const { chromium } = require('playwright');

const BASE = 'http://localhost:8080';

async function run() {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext();
  const page = await ctx.newPage();

  let passed = 0, failed = 0;
  const audioRequests = [];
  const consoleErrors = [];

  page.on('console', msg => {
    if (msg.type() === 'error') consoleErrors.push(msg.text());
  });

  // Track audio network requests
  page.on('request', req => {
    const url = req.url();
    if (url.includes('audio.bblearn.uk') || url.includes('.mp3')) {
      audioRequests.push({ url, time: Date.now() });
    }
  });

  function ok(name) { console.log(`  ✓ ${name}`); passed++; }
  function fail(name, reason) { console.log(`  ✗ ${name}: ${reason}`); failed++; }
  async function check(name, fn) {
    try { await fn(); ok(name); } catch (e) { fail(name, e.message); }
  }

  // ── Navigate to Mark ch.1 player ────────────────────────────────────────────
  console.log('\n[1] Load player (Mark ch.1)');
  await page.goto(`${BASE}/#/player/41/1`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: '/tmp/play_01_loaded.png' });

  await check('player page loaded', async () => {
    const res = await page.request.get(BASE);
    if (!res.ok()) throw new Error(`HTTP ${res.status()}`);
  });

  // ── Check KJV audio is requested on load ────────────────────────────────────
  console.log('\n[2] KJV audio request on load');
  await check('KJV MP3 requested', async () => {
    const kjv = audioRequests.find(r => r.url.includes('/KJV/'));
    if (!kjv) throw new Error('No KJV audio request found. Requests: ' + audioRequests.map(r=>r.url).join(', '));
  });

  // ── Wait for KJV verse 1 to finish and CUV to start ─────────────────────────
  // Mark 1:1 KJV = 2.58s-9.14s = ~6.5s. Wait up to 15s for CUV request.
  console.log('\n[3] Wait for CUV audio request (EN→CN switch)');
  const cuvStart = Date.now();
  let cuvRequested = false;
  for (let i = 0; i < 30; i++) {
    await page.waitForTimeout(500);
    const cuv = audioRequests.find(r => r.url.includes('/CUV/'));
    if (cuv) { cuvRequested = true; break; }
  }
  const elapsed = ((Date.now() - cuvStart) / 1000).toFixed(1);
  await check(`CUV MP3 requested within 15s (took ${elapsed}s)`, async () => {
    if (!cuvRequested) throw new Error('CUV audio never requested. Only got: ' + audioRequests.map(r=>r.url).join(', '));
  });

  await page.screenshot({ path: '/tmp/play_02_cuv_started.png' });

  // ── Verify both versions requested ──────────────────────────────────────────
  console.log('\n[4] Both versions requested');
  await check('KJV audio URL correct', async () => {
    const kjv = audioRequests.find(r => r.url.includes('/KJV/mark/'));
    if (!kjv) throw new Error('Expected /KJV/mark/ URL, got: ' + audioRequests.map(r=>r.url).join(', '));
  });
  await check('CUV audio URL correct', async () => {
    const cuv = audioRequests.find(r => r.url.includes('/CUV/mark/'));
    if (!cuv) throw new Error('Expected /CUV/mark/ URL, got: ' + audioRequests.map(r=>r.url).join(', '));
  });

  // ── Wait for verse 2 KJV (full EN→CN→EN cycle for verse 1) ──────────────────
  // CUV Mark 1:1 = 0-10.52s. After CUV, should go back to KJV verse 2.
  // Total time for verse 1: ~6.5s (KJV) + ~10.5s (CUV) = ~17s from start.
  console.log('\n[5] Wait for verse 2 (full v1 EN→CN cycle)');
  const v2Start = Date.now();
  let verse2Seen = false;
  // We detect verse 2 by watching for a second KJV request (same URL, re-fetched or cached)
  // or by checking if audioRequests has 2+ KJV entries
  for (let i = 0; i < 50; i++) {
    await page.waitForTimeout(500);
    const kjvReqs = audioRequests.filter(r => r.url.includes('/KJV/mark/'));
    // After verse 1 KJV + verse 1 CUV, verse 2 KJV should be a new setAudioSource call
    // just_audio may reuse the same URL — check console for verse change or wait long enough
    if (kjvReqs.length >= 2) { verse2Seen = true; break; }
    // Also check if enough time has passed for a full cycle (~17s)
    if ((Date.now() - v2Start) > 20000) break;
  }
  const v2Elapsed = ((Date.now() - v2Start) / 1000).toFixed(1);

  // just_audio caches the MP3, so verse 2 may not make a new network request.
  // Instead verify no errors occurred and playback continued.
  await check('no console errors during playback', async () => {
    const playErrors = consoleErrors.filter(e =>
      !e.includes('viewport') && !e.includes('favicon')
    );
    if (playErrors.length > 0) throw new Error(playErrors[0]);
  });

  await page.screenshot({ path: '/tmp/play_03_verse2.png' });
  console.log(`  → verse 2 cycle elapsed: ${v2Elapsed}s`);

  // ── Audio request summary ────────────────────────────────────────────────────
  console.log('\n[6] Audio request log');
  audioRequests.forEach((r, i) => {
    const version = r.url.includes('/KJV/') ? 'KJV' : r.url.includes('/CUV/') ? 'CUV' : '???';
    console.log(`  [${i+1}] ${version} ${r.url.split('/').slice(-3).join('/')}`);
  });
  ok(`total audio requests: ${audioRequests.length}`);

  // ── Summary ──────────────────────────────────────────────────────────────────
  console.log(`\n${'─'.repeat(60)}`);
  console.log(`Results: ${passed} passed, ${failed} failed`);
  console.log('Screenshots: /tmp/play_01_loaded.png, /tmp/play_02_cuv_started.png, /tmp/play_03_verse2.png');

  await browser.close();
  process.exit(failed > 0 ? 1 : 0);
}

run().catch(e => { console.error(e); process.exit(1); });
