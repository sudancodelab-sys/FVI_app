// Renders a built sheet (HTML) to an A4 PDF, after paginate.js has run.
// Usage: node render.js book.html book.pdf
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const [, , htmlPath, pdfPath] = process.argv;
  const browser = await chromium.launch();
  const page = await browser.newPage({ viewport: { width: 794, height: 1123 } });
  page.on('console', (m) => { if (m.type() === 'warning') console.warn(m.text()); });
  await page.goto('file://' + path.resolve(htmlPath));
  const stillOverflowing = await page.evaluate(() => window.fviReady);
  const pages = await page.evaluate(() => document.querySelectorAll('.page').length);
  await page.pdf({ path: pdfPath, format: 'A4', printBackground: true, preferCSSPageSize: true });
  await browser.close();
  console.log(`${pdfPath}: ${pages} pages`);
  if (stillOverflowing) {
    console.error(`${stillOverflowing} page(s) still overflow`);
    process.exit(1);
  }
})();
