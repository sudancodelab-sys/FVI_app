// The cover of a book as a JPEG for its download page: node cover.js <book.html> <out.jpg>
const { chromium } = require('playwright');
(async () => {
  const [, , html, out] = process.argv;
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 794, height: 1123 }, deviceScaleFactor: 640 / 794 });
  await p.goto('file://' + html);
  await p.evaluate(() => window.fviReady);
  await p.locator('.page').first().screenshot({ path: out, type: 'jpeg', quality: 88 });
  await b.close();
})();
