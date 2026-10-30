// Walks the admin app with the student app, both web builds: the student app at
// http://localhost:8123, the admin app at http://localhost:8124 (fresh browser
// storage each run). Three students ask on WhatsApp (opened links are caught),
// the admin issues their codes, the first student activates; then the
// dashboard, the records, a renewal, the settings and the lock. Screenshots
// go to <dir>/adm-*.png and the messages to <dir>/adm-texts.json.
// Flutter's widgets are reached through its accessibility tree.
const { chromium } = require('playwright');
const fs = require('fs');

const dir = (process.argv[2] || '.') + '/';
const texts = {};

async function open(b, url) {
  const ctx = await b.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  await ctx.addInitScript(() => { window.__opened = []; window.open = (u) => { window.__opened.push(String(u)); return null; }; });
  const p = await ctx.newPage();
  p.on('console', (m) => { if (m.type() === 'error') console.log('console:', m.text().slice(0, 200)); });
  await p.goto(url); await p.waitForTimeout(6000);
  await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click()); await p.waitForTimeout(500);
  return p;
}
// The text of the last wa.me link the page opened.
const lastOpened = async (p) => { const o = await p.evaluate(() => window.__opened); return decodeURIComponent(new URL(o[o.length - 1]).searchParams.get('text')); };
const shot = async (p, n) => { await p.mouse.move(380, 120); await p.waitForTimeout(900); await p.screenshot({ path: dir + 'adm-' + n + '.png' }); };

// A student in Arabic fills in the details and asks; returns the page and the message.
async function studentRequest(b, name, phone, level) {
  const s = await open(b, 'http://localhost:8123/');
  await s.getByRole('button', { name: /العربية/ }).click(); await s.waitForTimeout(500);
  await s.getByRole('button', { name: 'متابعة' }).click(); await s.waitForTimeout(800);
  const boxes = s.getByRole('textbox');
  await boxes.nth(0).click(); await s.waitForTimeout(400); await s.keyboard.insertText(name);
  await boxes.nth(1).click(); await s.waitForTimeout(400); await s.keyboard.type(phone);
  await s.getByRole('button', { name: /المستوى الذي تدرس فيه/ }).click(); await s.waitForTimeout(800);
  await s.getByRole('menuitem', { name: new RegExp(level) }).click(); await s.waitForTimeout(400);
  await s.getByRole('button', { name: /اطلب التفعيل عبر واتساب/ }).click(); await s.waitForTimeout(1200);
  return { s, message: await lastOpened(s) };
}

(async () => {
  const b = await chromium.launch();
  const one = await studentRequest(b, 'أحمد محمد عبدالله', '0912 345 678', 'Pre-Intermediate 1');
  texts.request = one.message;
  const a = await open(b, 'http://localhost:8124/');
  await a.screenshot({ path: dir + 'adm-0-create-pin.png' });
  const pin = async () => { for (const d of '2580') { await a.getByRole('button', { name: d, exact: true }).click(); await a.waitForTimeout(150); } await a.waitForTimeout(1500); };
  await pin(); await a.waitForTimeout(400); await pin();
  await shot(a, '1-dashboard-empty');

  const issue = async (message, pick, tag) => {
    await a.getByRole('tab', { name: /تفعيل جديد/ }).click();
    await a.waitForTimeout(800);
    await a.getByRole('textbox').click(); await a.waitForTimeout(400); await a.keyboard.insertText(message); await a.waitForTimeout(1200);
    await shot(a, tag + '-top');
    await a.mouse.move(195, 500); await a.mouse.wheel(0, 2000); await a.waitForTimeout(700);
    if (pick) await pick();
    await shot(a, tag + '-bottom');
    await a.getByRole('button', { name: /إصدار الكود وإرساله عبر واتساب/ }).click(); await a.waitForTimeout(2500);
    return lastOpened(a);
  };
  // The duration chips read as checkboxes.
  const months = (label) => async () => { await a.getByRole('checkbox', { name: label, exact: true }).click(); await a.waitForTimeout(500); };
  const custom = async () => {
    await a.getByRole('checkbox', { name: 'مخصص' }).click(); await a.waitForTimeout(1200);
    await shot(a, '5-sara-picker');
    await a.getByRole('button', { name: /^4, / }).click(); await a.waitForTimeout(400);
    await a.getByRole('button', { name: 'حسنًا' }).click(); await a.waitForTimeout(800);
  };

  const code1 = await issue(one.message, months('شهران'), '3-new');
  texts.code = code1;
  await one.s.getByRole('textbox').click(); await one.s.waitForTimeout(500);
  await one.s.keyboard.type('x'); await one.s.keyboard.press('Backspace');
  await one.s.keyboard.insertText(code1); await one.s.waitForTimeout(400);
  await one.s.getByRole('button', { name: 'تفعيل' }).click(); await one.s.waitForTimeout(1800);
  await one.s.screenshot({ path: dir + 'adm-4-student-activated.png' });

  const two = await studentRequest(b, 'سارة عثمان', '0911 222 333', 'Starter');
  await issue(two.message, custom, '5-sara');
  const three = await studentRequest(b, 'أحمد محمد عبدالله', '0912 345 678', 'Pre-Intermediate 2');
  await issue(three.message, null, '6-again');

  await a.waitForTimeout(4500); // the "issued" note goes away
  await a.getByRole('tab', { name: /الرئيسية/ }).click();
  await shot(a, '2-dashboard');
  await a.getByRole('tab', { name: /الطلاب/ }).click();
  await shot(a, '7-students');
  await a.getByText('سارة عثمان').first().click(); await shot(a, '8-student');
  await a.getByRole('button', { name: /تجديد/ }).click(); await a.waitForTimeout(1000);
  await shot(a, '8-renew-sheet');
  await a.getByRole('button', { name: /ينتهي في/ }).first().click(); await a.waitForTimeout(2500);
  texts.renewal = await lastOpened(a);
  await a.waitForTimeout(4500);
  await shot(a, '8-student-renewed');
  await a.goBack().catch(() => {});
  await a.waitForTimeout(600);
  await a.getByRole('tab', { name: /الإعدادات/ }).click();
  await shot(a, '9-settings');
  await a.mouse.move(195, 500); await a.mouse.wheel(0, 900); await shot(a, '9-settings-bottom');
  await a.reload(); await a.waitForTimeout(6000);
  await a.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click()); await a.waitForTimeout(500);
  for (const d of '25') { await a.getByRole('button', { name: d, exact: true }).click(); await a.waitForTimeout(150); }
  await shot(a, '0-lock');
  fs.writeFileSync(dir + 'adm-texts.json', JSON.stringify(texts, null, 1));
  await b.close();
})();
