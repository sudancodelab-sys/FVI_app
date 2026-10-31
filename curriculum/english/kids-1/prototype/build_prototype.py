from base64 import b64encode
from pathlib import Path
import subprocess
from playwright.sync_api import sync_playwright

HERE = Path(__file__).resolve().parent
REPO = Path('/home/ubuntu/FVI_app')
ART = HERE / 'kids1-cover-art-v2.png'
LOGO = REPO / 'curriculum/assets/institute-logo.png'
HTML = HERE / 'kids1-prototype.html'
PDF = HERE / 'kids1-prototype.pdf'

art = 'data:image/png;base64,' + b64encode(ART.read_bytes()).decode('ascii')
logo = 'data:image/png;base64,' + b64encode(LOGO.read_bytes()).decode('ascii')

TEMPLATE = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Kids English — Level 1 | Design Prototype</title>
<style>
@font-face{font-family:Lexend;font-weight:400;src:url('../../../assets/fonts/lexend-latin-400-normal.woff2') format('woff2')}
@font-face{font-family:Lexend;font-weight:500;src:url('../../../assets/fonts/lexend-latin-500-normal.woff2') format('woff2')}
@font-face{font-family:Lexend;font-weight:600;src:url('../../../assets/fonts/lexend-latin-600-normal.woff2') format('woff2')}
@font-face{font-family:Lexend;font-weight:700;src:url('../../../assets/fonts/lexend-latin-700-normal.woff2') format('woff2')}
@font-face{font-family:Lexend;font-weight:800;src:url('../../../assets/fonts/lexend-latin-800-normal.woff2') format('woff2')}
:root{--navy:#262E62;--orange:#E4451A;--ink:#000;--muted:#676E85;--line:#D9DDE7;--pale:#F5F6FA;--teal:#2B9DA5}
@page{size:A4;margin:0}
*{box-sizing:border-box}
html,body{margin:0;padding:0;background:#e9ebf0;color:var(--ink);font-family:Lexend,Arial,sans-serif;-webkit-print-color-adjust:exact;print-color-adjust:exact}
.page{width:210mm;height:297mm;position:relative;overflow:hidden;background:white;break-after:page;page-break-after:always}
.page:last-child{break-after:auto;page-break-after:auto}

/* Full cover hierarchy follows the institute's existing illustrated covers. */
.cover{background:#fff}
.cover-art{position:absolute;inset:0;width:100%;height:100%;object-fit:fill}
.cover-head{position:absolute;z-index:2;top:2mm;left:10mm;right:10mm;display:flex;flex-direction:column;align-items:center;text-align:center}
.cover-logo{width:38mm;height:38mm;object-fit:contain}
.cover-institute{margin:0;color:var(--navy);font-size:16pt;font-weight:800;line-height:1.05}
.cover-mark{display:flex;gap:1.2mm;margin-top:1.4mm}
.cover-mark i{display:block;width:28mm;height:1.2mm;background:var(--navy)}
.cover-mark i:nth-child(2){background:var(--orange)}
.cover-course{margin-top:2.4mm;color:var(--navy);font-size:14pt;font-weight:700;line-height:1.1}
.cover-title{margin:2mm 0 0;color:var(--orange);font-size:34pt;font-weight:800;line-height:1;letter-spacing:.2px}
.cover-level{margin-top:1.7mm;padding:1.5mm 7mm;border-radius:99px;background:var(--navy);color:white;font-size:11.5pt;font-weight:800;letter-spacing:1px}
.cover-book{margin-top:1.8mm;padding:1.6mm 9mm;border-radius:99px;background:var(--orange);color:white;font-size:14pt;font-weight:800}
.cover-tagline{margin-top:1.8mm;color:var(--navy);font-size:9.6pt;font-weight:600;line-height:1.15}
.cover-categories{margin-top:1.3mm;color:var(--orange);font-size:8.7pt;font-weight:700;letter-spacing:.15px}
.cover-student{position:absolute;z-index:3;left:27mm;right:27mm;bottom:13mm;display:flex;align-items:center;gap:3mm;height:10mm;padding:1.5mm 3mm;border:1px solid var(--navy);border-radius:2mm;background:rgba(255,255,255,.96);color:var(--navy);font-size:9.5pt;font-weight:800}
.cover-student i{flex:1;height:4mm;border-bottom:.4mm solid var(--navy)}

.letter-page{padding:9mm 11mm 8mm;display:flex;flex-direction:column;gap:2mm}
.page-head{display:flex;justify-content:space-between;align-items:center;border-bottom:1mm solid var(--orange);padding-bottom:2mm}
.brandline{font-size:8pt;font-weight:700;letter-spacing:.5px;color:var(--navy)}
.pageno{font-size:8pt;font-weight:700;color:var(--muted);background:var(--pale);padding:1.3mm 3mm;border-radius:99px}
.lesson-banner{display:flex;justify-content:space-between;align-items:center;border-left:1.4mm solid var(--orange);background:#F5F6FA;border-radius:2.5mm;padding:2mm 3.5mm}
.lesson-banner h1{margin:0;color:var(--navy);font-size:15pt;font-weight:800;line-height:1.1}
.lesson-banner p{margin:.8mm 0 0;color:var(--muted);font-size:8pt;font-weight:600}
.eyebrow{color:var(--orange);font-size:7pt;font-weight:800;letter-spacing:.9px;text-transform:uppercase}
.step-tags{display:flex;gap:1.2mm;white-space:nowrap}
.step-tags span{padding:1mm 2mm;border-radius:99px;background:white;border:1px solid var(--line);color:var(--navy);font-size:6.5pt;font-weight:800}
.guide-note{border-left:1.2mm solid var(--teal);background:#F0FAFA;border-radius:2.5mm;padding:1.7mm 3mm;font-size:8pt;line-height:1.38;color:#263B46}
.guide-key{display:grid;grid-template-columns:repeat(4,1fr);gap:2mm}
.key-item{display:flex;align-items:center;gap:2mm;border:1px solid var(--line);border-radius:2mm;padding:1.3mm 2mm;font-size:7pt;font-weight:700;color:var(--muted)}
.key-mark{width:8mm;height:0;border-top:.4mm solid #8790A4}
.key-mark.middle{border-top:.4mm dashed var(--orange)}
.key-mark.base{border-top:.7mm solid var(--navy)}
.key-mark.bottom{border-top:.4mm solid #BAC1CE}
.practice-block{display:flex;flex-direction:column;gap:1mm}
.practice-head{display:flex;align-items:baseline;gap:2mm;color:var(--navy)}
.practice-head b{font-size:8.7pt;font-weight:800}
.practice-head span{font-size:7.2pt;color:var(--muted)}
.writing-row{height:31mm;position:relative;border:1px solid #E5E8EF;border-radius:2.5mm;background:#fff;overflow:hidden}
.guide-line{position:absolute;left:2mm;right:2mm;height:0}
.guide-line.top{top:2mm;border-top:.35mm solid #8994AB}
.guide-line.middle{top:33.333%;border-top:.35mm dashed var(--orange)}
.guide-line.base{top:66.666%;border-top:.65mm solid var(--navy)}
.guide-line.bottom{bottom:2mm;border-top:.35mm solid #BBC3D0}
.model{position:absolute;left:6mm;bottom:6.5mm;color:#000;line-height:1;font-weight:700;white-space:nowrap}
.model.cap{font-size:78pt;letter-spacing:4mm}
.model.small{font-size:52pt;letter-spacing:4mm}
.model.word{font-size:42pt;letter-spacing:1.2mm}
.write-label{position:absolute;right:4mm;top:2mm;background:#fff;color:var(--muted);font-size:6.4pt;font-weight:800;padding:.4mm 1.2mm;border-radius:1mm;letter-spacing:.5px;text-transform:uppercase}
.footer{margin-top:auto;border-top:.35mm solid var(--line);padding-top:1.5mm;display:flex;justify-content:space-between;align-items:center;color:var(--muted);font-size:7pt}
.footer b{color:var(--navy)}
.star{color:var(--orange);font-size:11pt}
@media screen{.page{margin:8mm auto;box-shadow:0 3mm 14mm rgba(26,32,60,.18)}}
@media print{html,body{background:white}.page{margin:0;box-shadow:none}}
</style>
</head>
<body>
<section class="page cover">
  <img class="cover-art" src="__ART__" alt="Two children practicing English writing at a classroom desk">
  <div class="cover-head">
    <img class="cover-logo" src="__LOGO__" alt="Future Vision Institute logo">
    <h1 class="cover-institute">Future Vision Institute</h1>
    <div class="cover-mark"><i></i><i></i><i></i></div>
    <div class="cover-course">Future Vision English Course</div>
    <div class="cover-title">KIDS ENGLISH</div>
    <div class="cover-level">LEVEL 1</div>
    <div class="cover-book">Student Book</div>
    <div class="cover-tagline">Learn the alphabet, write clearly, and start speaking</div>
    <div class="cover-categories">Alphabet · Handwriting · Conversations</div>
  </div>
  <div class="cover-student"><b>Student Name:</b><i></i></div>
</section>

<section class="page letter-page">
  <header class="page-head">
    <div class="brandline">FUTURE VISION INSTITUTE · KIDS ENGLISH 1</div>
    <div class="pageno">LETTER 1 / 26</div>
  </header>

  <div class="lesson-banner">
    <div><div class="eyebrow">LETTER PRACTICE</div><h1>Look · Copy · Write</h1><p>Use the four guide lines for every letter and word.</p></div>
    <div class="step-tags"><span>CAPITAL</span><span>SMALL</span><span>WORD</span></div>
  </div>

  <div class="guide-note"><b>Letter placement:</b> Capital letters reach from the top line to the base line. Small letters sit between the middle and base lines. Letter tails can reach the bottom line.</div>

  <div class="guide-key">
    <div class="key-item"><i class="key-mark"></i>TOP LINE</div>
    <div class="key-item"><i class="key-mark middle"></i>MIDDLE LINE</div>
    <div class="key-item"><i class="key-mark base"></i>BASE LINE</div>
    <div class="key-item"><i class="key-mark bottom"></i>BOTTOM LINE</div>
  </div>

  <section class="practice-block">
    <div class="practice-head"><b>CAPITAL LETTER</b><span>Four models to copy.</span></div>
    <div class="writing-row"><i class="guide-line top"></i><i class="guide-line middle"></i><i class="guide-line base"></i><i class="guide-line bottom"></i><span class="model cap">A A A A</span><span class="write-label">MODEL</span></div>
    <div class="writing-row"><i class="guide-line top"></i><i class="guide-line middle"></i><i class="guide-line base"></i><i class="guide-line bottom"></i><span class="write-label">YOUR TURN</span></div>
  </section>

  <section class="practice-block">
    <div class="practice-head"><b>SMALL LETTER</b><span>Four models to copy.</span></div>
    <div class="writing-row"><i class="guide-line top"></i><i class="guide-line middle"></i><i class="guide-line base"></i><i class="guide-line bottom"></i><span class="model small">a a a a</span><span class="write-label">MODEL</span></div>
    <div class="writing-row"><i class="guide-line top"></i><i class="guide-line middle"></i><i class="guide-line base"></i><i class="guide-line bottom"></i><span class="write-label">YOUR TURN</span></div>
  </section>

  <section class="practice-block">
    <div class="practice-head"><b>WORD EXAMPLE</b><span>Copy the example word on the four lines.</span></div>
    <div class="writing-row"><i class="guide-line top"></i><i class="guide-line middle"></i><i class="guide-line base"></i><i class="guide-line bottom"></i><span class="model word">apple</span><span class="write-label">MODEL</span></div>
    <div class="writing-row"><i class="guide-line top"></i><i class="guide-line middle"></i><i class="guide-line base"></i><i class="guide-line bottom"></i><span class="write-label">YOUR TURN</span></div>
  </section>

  <footer class="footer"><span><b>Kids English 1</b> · Handwriting</span><span>Future Vision Institute</span><span class="star">★</span></footer>
</section>
</body>
</html>'''

HTML.write_text(TEMPLATE.replace('__ART__', art).replace('__LOGO__', logo), encoding='utf-8')
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path='/usr/bin/chromium', args=['--no-sandbox'])
    page = browser.new_page(viewport={'width':794,'height':1123}, device_scale_factor=2)
    page.goto(HTML.as_uri(), wait_until='load', timeout=120000)
    page.evaluate('document.fonts.ready')
    page.pdf(path=str(PDF), format='A4', print_background=True, prefer_css_page_size=True,
             margin={'top':'0mm','right':'0mm','bottom':'0mm','left':'0mm'})
    heights = page.locator('.page').evaluate_all('(xs)=>xs.map(x=>({scroll:x.scrollHeight,client:x.clientHeight}))')
    print('Prototype pages:', page.locator('.page').count())
    print('Page heights:', heights)
    if page.locator('.page').count() != 2 or any(x['scroll'] > x['client'] + 1 for x in heights):
        raise SystemExit('Prototype overflow or page-count error')
    browser.close()

for n, name in [(1,'kids1-cover-preview'),(2,'kids1-letter-a-preview')]:
    subprocess.run(['pdftoppm','-f',str(n),'-l',str(n),'-singlefile','-r','140','-png',str(PDF),str(HERE/name)],check=True,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
print('Created:', HTML, PDF)
