// @ts-check
const { chromium } = require('playwright');
const BASE = 'http://localhost:8080';

async function run() {
  const browser = await chromium.launch({ headless: false }); // headed so audio plays
  const ctx = await browser.newContext();
  const page = await ctx.newPage();

  const logs = [];
  page.on('console', msg => {
    const text = msg.text();
    if (text.includes('[APS]')) {
      logs.push({ time: Date.now(), text });
    }
  });

  await page.goto(`${BASE}/#/player/41/1`, { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  console.log('Waiting 30s for playback (KJV v1 ~6.5s + CUV v1 ~10.5s + KJV v2...)');
  const start = Date.now();

  // Wait up to 30s, print logs as they come
  let lastLogCount = 0;
  for (let i = 0; i < 60; i++) {
    await page.waitForTimeout(500);
    if (logs.length > lastLogCount) {
      for (let j = lastLogCount; j < logs.length; j++) {
        const rel = ((logs[j].time - start) / 1000).toFixed(2);
        console.log(`  t+${rel}s ${logs[j].text}`);
      }
      lastLogCount = logs.length;
    }
    // Stop after seeing 2 COMPLETE events (v1 KJV + v1 CUV)
    const completes = logs.filter(l => l.text.includes('COMPLETE'));
    if (completes.length >= 2) {
      console.log('\nSaw 2 COMPLETE events, stopping early.');
      break;
    }
  }

  console.log(`\nTotal logs: ${logs.length}`);
  const completes = logs.filter(l => l.text.includes('COMPLETE'));
  console.log(`COMPLETE events: ${completes.length}`);
  completes.forEach(l => {
    const rel = ((l.time - start) / 1000).toFixed(2);
    console.log(`  t+${rel}s ${l.text}`);
  });

  await browser.close();
}

run().catch(e => { console.error(e); process.exit(1); });
