"""The listening page of the voice sample, from the output of voice_sample.py.

    python3 docs/voice-sample/build_page.py OUT voice-sample.html

The clips are embedded as data URIs, so the page is one file to publish as a
private Artifact ("Gemini Voice Sample").
"""
import base64, html, json, sys
from pathlib import Path

S, OUT = Path(sys.argv[1]), Path(sys.argv[2])
clips = json.loads((S / 'sample.json').read_text())
tpl = (Path(__file__).parent / 'template.html').read_text()

DESC = {  # Gemini's own one-word descriptions of the voices, in Arabic
    'Sulafat': 'دافئ', 'Erinome': 'واضح', 'Iapetus': 'واضح', 'Charon': 'إخباري', 'Leda': 'شاب',
    'Aoede': 'خفيف', 'Puck': 'مرح', 'Achird': 'ودود', 'Sadaltager': 'رصين', 'Algenib': 'أجش',
    'Schedar': 'هادئ متزن',
}
WHO_AR = {'narrator': 'الراوي', 'teacher': 'المعلّم (الكلمات الجديدة)', 'question': 'صوت السؤال',
          'answer': 'صوت الجواب', 'anchor': 'مذيع الأخبار', 'Sara': 'سارة', 'Clerk': 'موظف الاستقبال',
          'Adam': 'آدم', 'Omar': 'عمر', 'Mr. Ali': 'الأستاذ علي', 'Huda': 'هدى', 'Grandfather': 'الجد'}
FEMALE = {'Sulafat', 'Erinome', 'Leda', 'Aoede'}
LEVEL_AR = {'advanced-1': 'المتقدم 1', 'pre-intermediate-1': 'ما قبل المتوسط 1'}


def src(c):
    return 'data:audio/mpeg;base64,' + base64.b64encode((S / c['file']).read_bytes()).decode()


def level(c):
    return LEVEL_AR[c['id'].split('/')[0]] + '، الدرس ' + str(int(c['id'].split('/')[1]))


def line(c, label=None, extra=''):
    who = label or WHO_AR.get(c['who'], c['who'])
    return (f'<li class="clip" data-voice="{c["voice"]}">'
            f'<button class="play" type="button" aria-label="استمع"><span class="tri"></span></button>'
            f'<div class="body"><div class="who">{html.escape(who)}{extra}</div>'
            f'<p class="en" lang="en" dir="ltr">{html.escape(c["text"])}</p></div>'
            f'<audio preload="none" src="{src(c)}"></audio></li>')


by = {}
for c in clips:
    by.setdefault(c['section'], []).append(c)

conv = ''.join(line(c) for c in by['conversation'])
STORY_LABEL = {('asked', 1.0): 'السرعة الطبيعية، للمتقدم (1.0)',
               ('asked', 0.8): 'بطيء للمبتدئ (0.80): طُلب من Gemini أن يقرأ ببطء',
               ('stretched', 0.8): 'بطيء للمبتدئ (0.80): القراءة الطبيعية نفسها مُبطّأة'}
story_order = [('asked', 1.0), ('asked', 0.8), ('stretched', 0.8)]
story = ''.join(line(c, label=STORY_LABEL[(c['how'], c['speed'])],
                     extra=f'<span class="wpm">{c["wpm"]} كلمة في الدقيقة</span>')
                for c in sorted(by['story'], key=lambda c: story_order.index((c['how'], c['speed']))))
qa = ''.join(line(c) for c in by['questions'])
word = ''.join(line(c) for c in by['word'])
news = ''.join(line(c) for c in by['news'])
cast_order = ['Adam', 'Omar', 'Mr. Ali', 'Huda', 'Grandfather']
cast = ''.join(line(c, extra=f'<span class="lvl">{level(c)}</span>')
               for c in sorted(by['cast'], key=lambda c: cast_order.index(c['who'])))

rows = ''
order = ['narrator', 'teacher', 'question', 'answer', 'anchor', 'Sara', 'Huda', 'Adam', 'Omar', 'Mr. Ali',
         'Grandfather', 'Clerk']
roles = {c['role']: c for c in clips}
roles.setdefault('teacher', roles.get('narrator'))
for r in order:
    c = roles.get(r) or next((x for x in clips if x['who'] == r), None)
    if not c:
        continue
    v = c['voice'] if r != 'teacher' else roles['narrator']['voice']
    same = [x['pitch'] for x in clips if x['voice'] == v and x['pitch']]
    g = 'امرأة' if v in FEMALE else 'رجل'
    rows += (f'<tr><td>{WHO_AR[r]}</td><td lang="en" dir="ltr" class="vname">{v}</td>'
             f'<td>{DESC[v]}</td><td>{g}</td><td class="num">{round(sum(same) / len(same))}</td></tr>')

checks = ''.join(
    f'<tr><td lang="en" dir="ltr" class="mono">{c["id"]}{" " + c["how"] + " " + str(c["speed"]) if c["section"] == "story" else ""}</td>'
    f'<td class="num">{round(c["match"] * 100)}%</td><td class="num">{c["pitch"]}</td>'
    f'<td lang="en" dir="ltr" class="mono">{c["model"].replace("gemini-", "").replace("-preview", "")}</td></tr>'
    for c in clips)
ok = sum(1 for c in clips if c['match'] >= 0.9 and c['ok'])
secs = sum(c['seconds'] for c in clips)

out = (tpl.replace('{{CONV}}', conv).replace('{{STORY}}', story).replace('{{QA}}', qa)
       .replace('{{WORD}}', word).replace('{{NEWS}}', news).replace('{{CAST}}', cast)
       .replace('{{ROWS}}', rows).replace('{{CHECKS}}', checks).replace('{{N}}', str(len(clips)))
       .replace('{{OK}}', str(ok)).replace('{{MIN}}', f'{secs / 60:.1f}')
       .replace('{{MODEL}}', ', '.join(sorted({c['model'] for c in clips}))))
OUT.write_text(out)
print('written', len(out) // 1024, 'KB')
