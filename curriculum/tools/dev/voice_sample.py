#!/usr/bin/env python3
"""The voice sample for the institute (docs/VOICES.md, step 1 of the plan).

Makes a few clips of every kind with the voice generator, checks them as the
full run will, and writes one page with a player and the text beside each
clip (the audio is inside the page):

    ~/.venvs/voices/bin/python curriculum/tools/dev/voice_sample.py [--out build/voice-sample]
"""

import argparse
import base64
import html
import json
import re
import subprocess
import sys
from pathlib import Path

import yaml

DEV = Path(__file__).resolve().parent
sys.path.insert(0, str(DEV.parent))
import voices  # noqa: E402

PAGE = DEV / 'voice-sample.html'

# (key, title, note, [(audio id, speed or None for the level's own)])
SECTIONS = [
    ('conversation', 'محادثة: امرأة ورجل',
     'Advanced 1، الدرس 3: سارة تتصل باستقبال الفندق في بورتسودان. لكل متكلم صوته.',
     [(f'advanced-1/03/conversation.{i}', None) for i in range(10)]),
    ('speed', 'السرعة: نفس الفقرة بسرعة Starter ثم بسرعة Advanced',
     'فقرة من قصة Pre-Intermediate 1، الدرس 1، بصوت الراوية. سرعة Starter هي 80%. وسرعة Advanced هي 100%، أي سرعة الكلام الطبيعية.',
     [('pre-intermediate-1/01/story.1', 0.80), ('pre-intermediate-1/01/story.1', 1.0)]),
    ('questions', 'الأسئلة والأجوبة',
     'السؤال بصوت امرأة، والجواب بصوت رجل. Pre-Intermediate 1، الدرس 1.',
     [(f'pre-intermediate-1/01/questions.{i}.{x}', None) for i in range(3) for x in 'qa']),
    ('cast', 'الشخصيات',
     'لكل شخصية صوت واحد في المستويات العشرة. جملة لكل منها من دروسها.',
     [('intermediate-1/03/conversation.1', None), ('pre-intermediate-3/04/pov.0', None),
      ('advanced-1/09/pov.0', None), ('intermediate-1/11/conversation.1', None),
      ('intermediate-1/09/pov.0', None), ('intermediate-1/04/pov.0', None)]),
    ('roles', 'المذيع والمعلمة',
     'الخبر الصحفي بصوت المذيع. الكلمات الجديدة والتعابير وكلمات الصوتيات بصوت المعلمة: الكلمة ثم معناها، والتعبير ثم معناه ثم المثال.',
     [('advanced-1/13/headline', None), ('advanced-1/13/standfirst', None),
      ('pre-intermediate-1/01/words.0', None), ('advanced-2/01/idioms.0', None),
      *[(f'starter/p02/parts.0.sounds.{s}.examples.{i}', None) for s in (0, 1) for i in range(3)]]),
    ('names', 'الأسماء السودانية',
     'المدن والأسماء التي لا يعرفها القاموس الأمريكي، بالنطق الذي أضفناه.',
     [('pre-intermediate-3/05/text.0', None), ('pre-intermediate-3/05/text.2', None),
      ('advanced-2/11/conversation.9', None), ('advanced-3/08/questions.6.q', None),
      ('advanced-2/05/questions.3.q', None), ('advanced-3/07/questions.4.q', None),
      ('advanced-1/01/questions.5.a', None)]),
]

WHO = {'narrator': 'الراوية', 'teacher': 'المعلمة', 'anchor': 'المذيع', 'question': 'السؤال', 'answer': 'الجواب'}
WHO_EN = {'Clerk': 'موظف الاستقبال'}


def _ltr(arabic):
    """Isolates the English and the numbers in Arabic text, so they keep their order."""
    return re.sub(r'[A-Za-z0-9][A-Za-z0-9 .%-]*[A-Za-z0-9%]|\d', lambda m: f'<bdi>{m.group(0)}</bdi>', arabic)


def _count(n, few, many):
    """An Arabic count: 3 to 10 take the plural, 11 to 99 the singular."""
    return f'{n} {few if 3 <= n % 100 <= 10 else many}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=str(voices.REPO / 'build' / 'voice-sample'))
    args = ap.parse_args()
    out = Path(args.out)
    cfg = yaml.safe_load(voices.CONFIG.read_text(encoding='utf-8'))

    wanted = [(aid, speed) for *_, ids in SECTIONS for aid, speed in ids]
    levels = sorted({f'english/{aid.split("/")[0]}' for aid, _ in wanted})
    planned, items = voices.plan(levels, cfg, only=[aid for aid, _ in wanted])
    by_id = {c.id: c for c in planned}
    clips, rows = [], []
    for aid, speed in wanted:
        base = by_id[aid]
        key = aid if speed is None else f'{aid}@{speed:.2f}'
        clip = voices.Clip(key, base.text, base.voice, speed or base.speed)  # no podcast silence here
        clips.append(clip)
        rows.append((key, aid, clip))
    items = {key: items[aid] for key, aid, _ in rows}
    voices.REPORT = out / 'report.json'  # the sample's own; the full run keeps build/voices-report.json
    report = voices.run(clips, items, out, cfg)
    voices.REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding='utf-8')

    # The app plays Ogg Opus; Safari on an older iPhone cannot, so the page
    # also carries an MP3 of each clip for such a phone.
    media = {}
    for c in clips:
        mp3 = out / 'mp3' / c.file.replace('.ogg', '.mp3')
        if not mp3.exists():
            mp3.parent.mkdir(exist_ok=True)
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(out / c.file), '-ac', '1', '-b:a', '48k', str(mp3)],
                           check=True)
        media[c.id] = {'ogg': base64.b64encode((out / c.file).read_bytes()).decode(),
                       'mp3': base64.b64encode(mp3.read_bytes()).decode()}

    problems = {p['id'] for p in report['problems']}
    sections = []
    for key, title, note, ids in SECTIONS:
        lines = []
        for aid, speed in ids:
            c = next(c for k, _, c in rows if k == (aid if speed is None else f'{aid}@{speed:.2f}'))
            who = items[c.id]['v']
            label = WHO.get(who) or WHO_EN.get(who) or who
            ok = c.id not in problems
            lines.append(
                f'<li class="clip" data-clip="{html.escape(c.id)}">'
                f'<button class="play" type="button" aria-label="استمع"><svg viewBox="0 0 24 24" aria-hidden="true">'
                f'<path class="i-play" d="M8 5.5v13l10.5-6.5z"/><path class="i-stop" d="M7 7h10v10H7z"/></svg></button>'
                f'<div class="body"><div class="meta"><span class="who">{html.escape(label)}</span>'
                f'<span class="voice" dir="ltr">{c.voice} · {round(c.speed * 100)}%</span>'
                f'<span class="time" dir="ltr">{c.ms / 1000:.1f} s</span>'
                f'<span class="{"ok" if ok else "bad"}">{"سمعها الفحص الآلي صحيحة" if ok else "يحتاج مراجعة"}</span></div>'
                f'<p class="text" dir="ltr" lang="en">{html.escape(c.text)}</p></div></li>')
        all_btn = ('<button class="all" type="button">استمع للمحادثة كلها</button>' if key == 'conversation' else '')
        sections.append(f'<section class="part {key}" aria-labelledby="h-{key}"><header><h2 id="h-{key}">{_ltr(title)}</h2>'
                        f'<p>{_ltr(note)}</p>{all_btn}</header><ol class="clips">{"".join(lines)}</ol></section>')

    s = report['summary']
    voices_used = sorted({c.voice for c in clips})
    facts = [_count(len(clips), 'مقاطع', 'مقطعاً'), _count(len(voices_used), 'أصوات', 'صوتاً'), f'{s["minutes"]:.1f} دقيقة',
             'الفحص الآلي: ' + ('كلها سليمة' if not report['problems'] else f'{len(report["problems"])} للمراجعة')]
    page = PAGE.read_text(encoding='utf-8')
    page = page.replace('<!--FACTS-->', ''.join(f'<li>{f}</li>' for f in facts))
    page = page.replace('<!--SECTIONS-->', '\n'.join(sections))
    page = page.replace('/*MEDIA*/{}', json.dumps(media))
    (out / 'voice-sample.html').write_text(page, encoding='utf-8')
    print(f'{out / "voice-sample.html"}: {len(clips)} clips, {len(report["problems"])} problem(s), '
          f'{(out / "voice-sample.html").stat().st_size / 1e6:.1f} MB')
    for p in report['problems']:
        print(' ', p)


if __name__ == '__main__':
    main()
