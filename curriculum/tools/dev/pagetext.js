// Prints each page's text, one JSON array, for comparing two builds.
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 794, height: 1123 } });
  await p.goto('file://' + process.argv[2]);
  await p.evaluate(() => window.fviReady);
  const t = await p.evaluate(() => [...document.querySelectorAll('.page')].map((pg) => pg.innerText.replace(/\s+/g, ' ')));
  console.log(JSON.stringify(t));
  await b.close();
})();
