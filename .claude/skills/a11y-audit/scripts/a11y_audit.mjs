#!/usr/bin/env node
// Accessibility audit: load a URL in Playwright chromium, inject axe-core, run
// WCAG 2.0/2.1/2.2 A+AA checks, and report violations grouped by impact.
// Usage: node a11y_audit.mjs <url>
import process from 'node:process';

const url = process.argv[2];
if (!url) {
  console.error('Usage: node a11y_audit.mjs <url>   (the app must be running)');
  process.exit(2);
}

let chromium;
try {
  ({ chromium } = await import('playwright'));
} catch {
  console.error('Playwright not found. Install: npm i -D playwright && npx playwright install chromium');
  process.exit(3);
}

const browser = await chromium.launch();
const page = await browser.newPage();
try {
  await page.goto(url, { waitUntil: 'networkidle', timeout: 30000 });
} catch (e) {
  console.error(`Failed to load ${url}: ${e.message}`);
  await browser.close();
  process.exit(4);
}

// Inject axe-core from CDN — no local dependency needed.
await page.addScriptTag({ url: 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.10.2/axe.min.js' });
const results = await page.evaluate(async () =>
  await window.axe.run(document, {
    runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa', 'wcag22aa'] },
  }),
);
await browser.close();

const order = { critical: 0, serious: 1, moderate: 2, minor: 3 };
const violations = (results.violations || []).sort(
  (a, b) => (order[a.impact] ?? 9) - (order[b.impact] ?? 9),
);

console.log(`axe-core WCAG 2.2 AA scan — ${url}`);
if (!violations.length) {
  console.log('✓ no automated violations found.');
  console.log('  (~30-40% coverage only — still run the manual keyboard/focus/contrast pass.)');
  process.exit(0);
}

let total = 0;
for (const v of violations) {
  const n = v.nodes.length;
  total += n;
  console.log(`\n[${(v.impact || '?').toUpperCase()}] ${v.id} — ${v.help} (${n} element${n > 1 ? 's' : ''})`);
  console.log(`  ${v.helpUrl}`);
  for (const node of v.nodes.slice(0, 5)) console.log(`  • ${node.target.join(' ')}`);
  if (v.nodes.length > 5) console.log(`  … +${v.nodes.length - 5} more`);
}
console.log(`\n✗ ${violations.length} rule(s) failed, ${total} element(s) affected.`);
process.exit(1);
