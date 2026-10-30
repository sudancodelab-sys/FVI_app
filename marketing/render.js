// Renders every ad in marketing/ads to a PNG in marketing/out:
//   node marketing/render.js [scale] [--theme=white,orange] [name...]
// Each ad sets its own size (--w and --h); scale 2 gives a sharper file for printing.
// With --theme, each ad is rendered once per theme (ad.css) as <name>-<theme>.png.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

(async () => {
  const args = process.argv.slice(2);
  const scale = Number(args.find(a => /^\d+(\.\d+)?$/.test(a))) || 1;
  const themeArg = args.find(a => a.startsWith('--theme='));
  const themes = themeArg ? themeArg.slice(8).split(',') : [null];
  const only = args.filter(a => !/^\d+(\.\d+)?$/.test(a) && !a.startsWith('--'));
  const dir = path.join(__dirname, 'ads');
  const out = path.join(__dirname, 'out');
  fs.mkdirSync(out, { recursive: true });
  const names = fs.readdirSync(dir).filter(f => f.endsWith('.html')).map(f => f.slice(0, -5))
    .filter(n => !only.length || only.includes(n));
  const browser = await chromium.launch();
  for (const name of names) {
    for (const theme of themes) {
      const page = await browser.newPage({ viewport: { width: 1080, height: 1080 }, deviceScaleFactor: scale });
      await page.goto('file://' + path.join(dir, name + '.html'));
      if (theme) await page.evaluate(t => { document.documentElement.dataset.theme = t; }, theme);
      const size = await page.evaluate(() => {
        const s = getComputedStyle(document.documentElement);
        return { width: parseInt(s.getPropertyValue('--w')), height: parseInt(s.getPropertyValue('--h')) };
      });
      await page.setViewportSize(size);
      await page.evaluate(() => document.fonts.ready);
      await page.waitForLoadState('networkidle');
      const file = path.join(out, name + (theme ? `-${theme}` : '') + (scale === 1 ? '' : `@${scale}x`) + '.png');
      await page.screenshot({ path: file });
      console.log(file, `${size.width * scale}x${size.height * scale}`);
      await page.close();
    }
  }
  await browser.close();
})();
