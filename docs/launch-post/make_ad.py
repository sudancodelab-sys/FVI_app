"""The launch announcement of the FVI app (30 October 2026): a Facebook post
(1080x1350) and a WhatsApp status (1080x1920), written as HTML into
build/launch-post/; render.js turns them into PNG. The screens are the student
app's web build in Arabic, with every level open, at 3x.

    python3 docs/launch-post/make_ad.py && node docs/launch-post/render.js
"""
from pathlib import Path

HERE = Path(__file__).parent
ROOT = HERE.parents[1]
OUT = ROOT / 'build' / 'launch-post'
FONTS = (ROOT / 'apps/student/assets/fonts').as_uri() + '/'
LOGO = (ROOT / 'apps/student/assets/branding/logo.png').as_uri()

ICONS = {
    'levels': '<path d="M12 2 2 7l10 5 10-5-10-5z"/><path d="m2 17 10 5 10-5"/><path d="m2 12 10 5 10-5"/>',
    'exercise': '<path d="m9 11 3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/>',
    'offline': '<path d="m1 1 22 22"/><path d="M16.72 11.06A10.94 10.94 0 0 1 19 12.55"/><path d="M5 12.55a10.94 10.94 0 0 1 5.17-2.39"/><path d="M10.71 5.05A16 16 0 0 1 22.58 9"/><path d="M1.42 9a15.91 15.91 0 0 1 4.7-2.88"/><path d="M8.53 16.11a6 6 0 0 1 6.95 0"/><path d="M12 20h.01"/>',
    'language': '<path d="m5 8 6 6"/><path d="m4 14 6-6 2-3"/><path d="M2 5h12"/><path d="M7 2h1"/><path d="m22 22-5-10-5 10"/><path d="M14 18h6"/>',
    'chat': '<path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/>',
}

def icon(name):
    return f'<svg viewBox="0 0 24 24" aria-hidden="true">{ICONS[name]}</svg>'

FEATURES = [
    ('levels', '10 مستويات', 'من المبتدئ حتى المتقدم'),
    ('exercise', 'قصص ومحادثات', 'وتمارين بعد كل درس'),
    ('offline', 'بلا إنترنت', 'الدروس كلها داخل التطبيق'),
    ('language', 'بالعربية أو الإنجليزية', 'اختر لغة الواجهة'),
]

# The ten levels and their CEFR codes, coloured as in the app.
LEVELS = [('Pre-A1', 'a'), ('A1.1', 'a'), ('A1.2', 'a'), ('A2.1', 'a'), ('A2.2', 'a'),
          ('B1.1', 'b'), ('B1.2', 'b'), ('B2.1', 'c'), ('B2.2', 'c'), ('C1.1', 'c')]

CSS = '''
@font-face { font-family: Cairo; src: url(FONTS/Cairo-Regular.ttf); font-weight: 400; }
@font-face { font-family: Cairo; src: url(FONTS/Cairo-SemiBold.ttf); font-weight: 600; }
@font-face { font-family: Cairo; src: url(FONTS/Cairo-Bold.ttf); font-weight: 700; }
@font-face { font-family: Cairo; src: url(FONTS/Cairo-ExtraBold.ttf); font-weight: 800; }
@font-face { font-family: Lexend; src: url(FONTS/Lexend-Regular.ttf); font-weight: 400; }
@font-face { font-family: Lexend; src: url(FONTS/Lexend-SemiBold.ttf); font-weight: 600; }
@font-face { font-family: Lexend; src: url(FONTS/Lexend-Bold.ttf); font-weight: 700; }
@font-face { font-family: Lexend; src: url(FONTS/Lexend-ExtraBold.ttf); font-weight: 800; }
:root {
  --navy: #1E2556; --navy-2: #2A3373; --ink: #FFFFFF; --soft: #C9CEF2;
  --orange: #E4451A; --orange-2: #FF7A52; --green: #14935A; --green-2: #1FA855; --indigo: #6573D9;
  --ar: Cairo, sans-serif; --en: Lexend, sans-serif;
}
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { width: Wpx; height: Hpx; overflow: hidden; background: var(--navy); }
body { font-family: var(--ar); color: var(--ink); }
.en { font-family: var(--en); }
.poster { position: relative; width: Wpx; height: Hpx; overflow: hidden;
  background:
    radial-gradient(circle at 22% GLOWY, rgba(228, 69, 26, .38), transparent 34%),
    radial-gradient(circle at 92% 8%, rgba(101, 115, 217, .30), transparent 30%),
    linear-gradient(170deg, #252E68 0%, var(--navy) 55%, #161C44 100%); }
.dots { position: absolute; inset: 0; background-image: radial-gradient(rgba(255,255,255,.07) 1.6px, transparent 1.6px); background-size: 34px 34px; }
.letters { position: absolute; font-family: var(--en); font-weight: 800; color: rgba(255,255,255,.035); line-height: .8; letter-spacing: -8px; direction: ltr; }
.brand { display: flex; align-items: center; gap: 22px; }
.brand img { width: 112px; height: 112px; border-radius: 50%; background: #fff; box-shadow: 0 10px 30px rgba(0,0,0,.35); }
.brand .inst { font-size: 33px; font-weight: 800; line-height: 1.35; }
.brand .inst-en { font-family: var(--en); font-size: 21px; font-weight: 600; color: var(--soft); letter-spacing: .5px; direction: ltr; text-align: right; }
.pill { display: inline-flex; align-items: center; gap: 12px; background: var(--orange); color: #fff; font-size: 27px; font-weight: 700; padding: 8px 26px 10px; border-radius: 99px; box-shadow: 0 10px 26px rgba(228,69,26,.45); }
.pill i { width: 12px; height: 12px; border-radius: 50%; background: #fff; display: inline-block; }
h1 { font-weight: 800; line-height: 1.05; letter-spacing: -1px; }
h1 .en { font-weight: 800; letter-spacing: -2px; }
.lead { font-weight: 800; color: var(--orange-2); line-height: 1.3; }
.features { list-style: none; display: grid; }
.features li { display: flex; align-items: center; gap: 18px; }
.features li div { display: flex; flex-direction: column; min-width: 0; }
.features b { font-weight: 800; line-height: 1.3; }
.features span { font-weight: 600; color: var(--soft); line-height: 1.35; }
.features svg { flex: none; stroke: var(--orange-2); fill: none; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; background: rgba(255,255,255,.09); border-radius: 16px; }
.phone { position: absolute; background: #0B0F2A; border-radius: 52px; padding: 13px; box-shadow: 0 50px 90px rgba(5, 8, 30, .6), 0 0 0 2px rgba(255,255,255,.10) inset; }
.phone img { display: block; width: 100%; border-radius: 40px; }
.ladder { position: absolute; display: flex; flex-direction: column; gap: 16px; }
.ladder .row { position: relative; display: flex; justify-content: space-between; direction: rtl; }
.ladder .row::before { content: ""; position: absolute; top: 50%; inset-inline: 30px; height: 4px; background: linear-gradient(to left, var(--orange), var(--green-2) 55%, var(--indigo)); border-radius: 4px; transform: translateY(-50%); }
.ladder .lv { position: relative; width: 74px; height: 74px; border-radius: 50%; display: grid; place-items: center; font-family: var(--en); font-weight: 700; font-size: 16px; color: #fff; border: 4px solid var(--navy); }
.ladder .a { background: var(--orange); } .ladder .b { background: var(--green); } .ladder .c { background: var(--indigo); }
.ladder .title { font-size: 28px; font-weight: 700; color: #fff; text-align: center; }
.ladder .title .en { font-size: 24px; color: var(--soft); }
.ladder .ends { display: flex; justify-content: space-between; font-size: 24px; font-weight: 700; color: var(--soft); }
.ladder .ends b { color: #fff; font-family: var(--en); font-weight: 600; }
.cta { position: absolute; display: flex; align-items: center; gap: 26px; background: #fff; color: var(--navy); border-radius: 36px; box-shadow: 0 24px 60px rgba(0,0,0,.35); }
.cta .bubble { flex: none; width: 96px; height: 96px; border-radius: 28px; background: var(--green-2); display: grid; place-items: center; }
.cta .bubble svg { width: 54px; height: 54px; stroke: #fff; fill: none; stroke-width: 2; stroke-linecap: round; stroke-linejoin: round; }
.cta .words { flex: 1; min-width: 0; }
.cta .say { font-size: 28px; font-weight: 700; color: #4A4F75; line-height: 1.3; }
.cta .num { font-family: var(--en); font-weight: 800; font-size: 64px; letter-spacing: 1px; direction: ltr; text-align: right; line-height: 1.15; color: var(--navy); }
.cta .android { flex: none; font-size: 24px; font-weight: 700; color: var(--green); background: #E3F4EB; padding: 10px 18px; border-radius: 18px; text-align: center; line-height: 1.3; }
'''

def ladder(style):
    lv = ''.join(f'<div class="lv {k}">{c}</div>' for c, k in LEVELS)
    return (f'<div class="ladder" style="{style}"><div class="title">مستويات المنهج وفق الإطار الأوروبي المرجعي <span class="en">(CEFR)</span></div><div class="row">{lv}</div>'
            '<div class="ends"><span>من <b>Starter</b></span><span>حتى <b>Advanced 3</b></span></div></div>')

def features(title, sub, box, columns=1, gap=24):
    """The four features: an icon, a bold title and a line under it."""
    items = ''.join(
        f'<li>{icon(i).replace("<svg", f"<svg style=\"width:{box}px;height:{box}px;padding:{box // 5}px\"")}'
        f'<div><b style="font-size:{title}px">{t}</b><span style="font-size:{sub}px">{u}</span></div></li>'
        for i, t, u in FEATURES)
    return f'<ul class="features" style="gap:{gap}px; grid-template-columns:repeat({columns}, 1fr)">{items}</ul>'

def cta(style):
    return (f'<div class="cta" style="{style}"><div class="bubble">{icon("chat")}</div>'
            '<div class="words"><div class="say">للحصول على التطبيق والتفعيل، راسلونا على واتساب</div>'
            '<div class="num">0904011473</div></div>'
            '<div class="android">لهواتف<br>أندرويد</div></div>')

def phone(src, style):
    return f'<div class="phone" style="{style}"><img src="{(HERE / 'screens' / src).as_uri()}" alt=""></div>'

def page(w, h, glow_y, body):
    css = CSS.replace('FONTS/', FONTS).replace('Wpx', f'{w}px').replace('Hpx', f'{h}px').replace('GLOWY', glow_y)
    return (f'<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><style>{css}</style></head>'
            f'<body><div class="poster"><div class="dots"></div>{body}</div></body></html>')

# Facebook: 1080 x 1350.
FB = page(1080, 1350, '45%', f'''
<div class="letters" style="left:-40px; top:600px; font-size:420px">ABC</div>
<div class="brand" style="position:absolute; top:52px; right:64px">
  <img src="{LOGO}" alt=""><div><div class="inst">معهد الرؤية المستقبلية<br>للحاسوب واللغات</div></div>
</div>
<span class="pill" style="position:absolute; top:84px; left:64px"><i></i>جديد · متاح الآن</span>
<div style="position:absolute; top:212px; right:64px; width:500px; display:flex; flex-direction:column; gap:10px">
  <h1 style="font-size:100px; white-space:nowrap">تطبيق <span class="en">FVI</span></h1>
  <p class="lead" style="font-size:46px">منهج الإنجليزية كاملاً<br>في هاتفك</p>
  <div style="height:26px"></div>
  {features(31, 23, 62, gap=26)}
</div>
{phone('2-course.png', 'width:244px; left:46px; top:236px; transform:rotate(-7deg)')}
{phone('4-lesson.png', 'width:268px; left:228px; top:300px; transform:rotate(5deg)')}
{ladder('left:64px; right:64px; top:930px')}
{cta('left:48px; right:48px; bottom:44px; padding:22px 28px')}
''')

# WhatsApp status: 1080 x 1920; the top ~170 and bottom ~200 px stay clear of WhatsApp's own bars.
STATUS = page(1080, 1920, '48%', f'''
<div class="letters" style="right:-40px; top:640px; font-size:520px">ABC</div>
<div class="brand" style="position:absolute; top:182px; left:0; right:0; justify-content:center">
  <img src="{LOGO}" alt=""><div><div class="inst">معهد الرؤية المستقبلية<br>للحاسوب واللغات</div></div>
</div>
<div style="position:absolute; top:334px; left:0; right:0; display:flex; flex-direction:column; gap:14px; align-items:center; text-align:center">
  <span class="pill"><i></i>جديد · متاح الآن</span>
  <h1 style="font-size:124px">تطبيق <span class="en">FVI</span></h1>
  <p class="lead" style="font-size:50px">منهج الإنجليزية كاملاً في هاتفك</p>
</div>
{phone('2-course.png', 'width:250px; left:96px; top:700px; transform:rotate(-9deg)')}
{phone('5-exercise-right.png', 'width:250px; right:96px; top:700px; transform:rotate(9deg)')}
{phone('4-lesson.png', 'width:292px; left:394px; top:660px; z-index:2')}
<div style="position:absolute; top:1352px; left:64px; right:64px">{features(30, 22, 58, columns=2, gap=22)}</div>
{cta('left:48px; right:48px; bottom:212px; padding:22px 28px')}
''')

OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'fb.html').write_text(FB)
(OUT / 'status.html').write_text(STATUS)
