// Walks the web build: course, a level, a lesson; screenshots on the way.
const { chromium } = require('playwright');
(async () => {
  const [, , prefix, levelY, lessonY, scrolls] = process.argv;
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  p.on('console', (m) => { if (m.type() === 'error') console.log('console:', m.text()); });
  await p.goto('http://localhost:8123/');
  await p.waitForTimeout(6000);
  await p.screenshot({ path: `${prefix}-course.png` });
  await p.mouse.click(195, Number(levelY));
  await p.waitForTimeout(2500);
  await p.screenshot({ path: `${prefix}-level.png` });
  await p.mouse.click(195, Number(lessonY));
  await p.waitForTimeout(2500);
  for (let i = 0; i <= Number(scrolls); i++) {
    await p.screenshot({ path: `${prefix}-lesson-${i}.png` });
    await p.mouse.move(195, 400);
    await p.mouse.wheel(0, Number(process.argv[6] || 640));
    await p.waitForTimeout(900);
  }
  await b.close();
})();
