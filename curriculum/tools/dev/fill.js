// Prints how much of each page's usable height its content fills.
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 794, height: 1123 } });
  await p.goto('file://' + process.argv[2]);
  await p.evaluate(() => window.fviReady);
  const rows = await p.evaluate(() => [...document.querySelectorAll('.page')].map((pg, i) => {
    const top = pg.getBoundingClientRect().top;
    const head = pg.querySelector('.head');
    const foot = pg.querySelector('.foot');
    const start = head ? head.getBoundingClientRect().bottom - top : 0;
    const end = foot ? foot.getBoundingClientRect().top - top : pg.clientHeight;
    let last = start;
    pg.querySelectorAll('*').forEach((el) => {
      if (el.closest('.foot') || el.closest('.head')) return;
      const r = el.getBoundingClientRect();
      if (r.height > 0) last = Math.max(last, r.bottom - top);
    });
    return [i + 1, pg.dataset.title || pg.className, Math.round(100 * (last - start) / (end - start))];
  }));
  rows.forEach((r) => console.log(r.join('\t')));
  await b.close();
})();
