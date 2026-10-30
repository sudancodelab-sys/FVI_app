// Renders the two announcement pages to PNG at their exact pixel sizes.
const { chromium } = require('playwright');
const out = require('path').resolve(__dirname, '../../build/launch-post');
(async () => {
  const b = await chromium.launch();
  for (const [name, w, h] of [['fb', 1080, 1350], ['status', 1080, 1920]]) {
    const p = await b.newPage({ viewport: { width: w, height: h }, deviceScaleFactor: 1 });
    await p.goto('file://' + out + '/' + name + '.html');
    await p.evaluate(() => document.fonts.ready); await p.waitForTimeout(600);
    await p.screenshot({ path: out + '/FVI-' + name + '.png' });
  }
  await b.close();
})();
