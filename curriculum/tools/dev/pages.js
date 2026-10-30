// Screenshots chosen pages of a book: node pages.js <book.html> <prefix> 3 4 5
const { chromium } = require('playwright');
(async () => {
  const [, , html, prefix, ...nums] = process.argv;
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 794, height: 1123 }, deviceScaleFactor: 1 });
  await p.goto('file://' + html);
  await p.evaluate(() => window.fviReady);
  for (const n of nums) await p.locator('.page').nth(Number(n) - 1).screenshot({ path: `${prefix}-${n}.png` });
  await b.close();
})();
