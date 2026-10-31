"""The Kids levels: letters written on the four guide lines of a copybook.

Every letter is drawn here as pen strokes (ball-and-stick print), not taken
from a font, so that it sits exactly in its place on the four lines and its
strokes can be numbered in the order a child writes them.

Units: one band (the space between two lines) is 1. The red line (the base
line) is y = 0, the middle line y = 1, the top line y = 2 and the bottom
line y = -1; y goes up.

    top line     2  ── capital letters and tall letters (b d f h k l) start here
    middle line  1  ── small letters start here
    red line     0  ── every letter sits here
    bottom line -1  ── tails (g j p q y) end here
"""
import html
import math


def arc(cx, cy, rx, ry, a0, a1):
    """Points along an ellipse from angle a0 to a1 (degrees, y up):
    a1 > a0 turns anticlockwise ("circle back"), a1 < a0 clockwise."""
    n = max(6, int(abs(a1 - a0) / 5))
    return [(cx + rx * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             cy + ry * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(n + 1)]


def st(*parts):
    """One pen stroke: points and arcs joined in order."""
    pts = []
    for part in parts:
        for p in ([part] if isinstance(part[0], (int, float)) else part):
            if not pts or math.dist(pts[-1], p) > 1e-6:
                pts.append(p)
    return pts


CIRCLE = arc(.5, .5, .5, .5, 60, 420)          # a d g o q: start at the top right, circle back
FORWARD = arc(.5, .5, .5, .5, 180, -180)       # b p: from the stick, circle forward
ARCH = arc(.5, .5, .5, .5, 180, 0)             # h n: up and over

GLYPHS = {
    'a': [st(CIRCLE), st((1, 1), (1, 0))],
    'b': [st((0, 2), (0, 0)), st(FORWARD)],
    'c': [st(arc(.5, .5, .5, .5, 50, 310))],
    'd': [st(CIRCLE), st((1, 2), (1, 0))],
    'e': [st((0, .5), (1, .5), arc(.5, .5, .5, .5, 0, 315))],
    'f': [st(arc(.72, 1.7, .3, .3, 20, 180), (.42, 0)), st((.05, 1), (.85, 1))],
    'g': [st(CIRCLE), st((1, 1), (1, -.6), arc(.6, -.6, .4, .4, 0, -160))],
    'h': [st((0, 2), (0, 0)), st(ARCH, (1, 0))],
    'i': [st((0, 1), (0, 0)), st((0, 1.5))],
    'j': [st((.5, 1), (.5, -.6), arc(.1, -.6, .4, .4, 0, -160)), st((.5, 1.5))],
    'k': [st((0, 2), (0, 0)), st((.85, 1), (0, .42), (.9, 0))],
    'l': [st((0, 2), (0, 0))],
    'm': [st((0, 1), (0, 0)),
          st(arc(.4, .6, .4, .4, 180, 0), (.8, 0), (.8, .6), arc(1.2, .6, .4, .4, 180, 0), (1.6, 0))],
    'n': [st((0, 1), (0, 0)), st(ARCH, (1, 0))],
    'o': [st(CIRCLE)],
    'p': [st((0, 1), (0, -1)), st(FORWARD)],
    'q': [st(CIRCLE), st((1, 1), (1, -.75), arc(1.25, -.75, .25, .25, 180, 270))],
    'r': [st((0, 1), (0, 0)), st(arc(.45, .55, .45, .45, 180, 40))],
    's': [st(arc(.42, .75, .36, .25, 25, 270), arc(.42, .25, .38, .25, 90, -155))],
    't': [st((.4, 1.7), (.4, 0)), st((0, 1), (.8, 1))],
    'u': [st((0, 1), (0, .5), arc(.5, .5, .5, .5, 180, 360), (1, 1), (1, 0))],
    'v': [st((0, 1), (.45, 0), (.9, 1))],
    'w': [st((0, 1), (.35, 0), (.7, 1), (1.05, 0), (1.4, 1))],
    'x': [st((0, 1), (.85, 0)), st((.85, 1), (0, 0))],
    'y': [st((0, 1), (.45, 0)), st((.9, 1), (0, -1))],
    'z': [st((0, 1), (.85, 1), (0, 0), (.85, 0))],
    '-': [st((0, .5), (.5, .5))],

    'A': [st((.8, 2), (0, 0)), st((.8, 2), (1.6, 0)), st((.28, .7), (1.32, .7))],
    'B': [st((0, 2), (0, 0)),
          st((0, 2), (.7, 2), arc(.7, 1.5, .5, .5, 90, -90), (0, 1), (.8, 1),
             arc(.8, .5, .5, .5, 90, -90), (0, 0))],
    'C': [st(arc(1, 1, .95, 1, 45, 315))],
    'D': [st((0, 2), (0, 0)), st((0, 2), (.45, 2), arc(.45, 1, .9, 1, 90, -90), (0, 0))],
    'E': [st((0, 2), (0, 0)), st((0, 2), (1.1, 2)), st((0, 1), (.9, 1)), st((0, 0), (1.1, 0))],
    'F': [st((0, 2), (0, 0)), st((0, 2), (1.1, 2)), st((0, 1), (.9, 1))],
    'G': [st(arc(1, 1, .95, 1, 45, 360), (1.2, 1))],
    'H': [st((0, 2), (0, 0)), st((1.4, 2), (1.4, 0)), st((0, 1), (1.4, 1))],
    'I': [st((.55, 2), (.55, 0)), st((0, 2), (1.1, 2)), st((0, 0), (1.1, 0))],
    'J': [st((1, 2), (1, .55), arc(.5, .55, .5, .55, 0, -170))],
    'K': [st((0, 2), (0, 0)), st((1.3, 2), (0, .95), (1.35, 0))],
    'L': [st((0, 2), (0, 0), (1.1, 0))],
    'M': [st((0, 2), (0, 0)), st((0, 2), (.85, 0), (1.7, 2), (1.7, 0))],
    'N': [st((0, 2), (0, 0)), st((0, 2), (1.4, 0), (1.4, 2))],
    'O': [st(arc(1, 1, .95, 1, 60, 420))],
    'P': [st((0, 2), (0, 0)), st((0, 2), (.75, 2), arc(.75, 1.5, .5, .5, 90, -90), (0, 1))],
    'Q': [st(arc(1, 1, .95, 1, 60, 420)), st((1.2, .5), (1.9, 0))],
    'R': [st((0, 2), (0, 0)), st((0, 2), (.75, 2), arc(.75, 1.5, .5, .5, 90, -90), (0, 1), (1.3, 0))],
    'S': [st(arc(.72, 1.5, .62, .5, 25, 270), arc(.72, .5, .66, .5, 90, -155))],
    'T': [st((.7, 2), (.7, 0)), st((0, 2), (1.4, 2))],
    'U': [st((0, 2), (0, .7), arc(.7, .7, .7, .7, 180, 360), (1.4, 2))],
    'V': [st((0, 2), (.75, 0), (1.5, 2))],
    'W': [st((0, 2), (.5, 0), (1, 2), (1.5, 0), (2, 2))],
    'X': [st((0, 2), (1.4, 0)), st((1.4, 2), (0, 0))],
    'Y': [st((0, 2), (.7, 1)), st((1.4, 2), (.7, 1), (.7, 0))],
    'Z': [st((0, 2), (1.4, 2), (0, 0), (1.4, 0))],
}


def glyph(ch):
    """The strokes of a letter, moved so that its left edge is x = 0, and its width."""
    strokes = GLYPHS[ch]
    x0 = min(x for s in strokes for x, _ in s)
    x1 = max(x for s in strokes for x, _ in s)
    return [[(x - x0, y) for x, y in s] for s in strokes], x1 - x0


# ------------------------------------------------------------------ drawing

U = 100            # SVG units in one band
PEN = 12           # pen width
GAP = 30           # between the letters of a word
PAD = 42           # room above the top line and below the bottom line
BADGE = 18         # radius of a stroke number
LEAD, TAIL = 55, 40  # room before and after the writing


def _dense(points, step=4):
    out = [points[0]]
    for a, b in zip(points, points[1:]):
        n = max(1, int(math.dist(a, b) / step))
        out += [(a[0] + (b[0] - a[0]) * i / n, a[1] + (b[1] - a[1]) * i / n) for i in range(1, n + 1)]
    return out


def _unit(a, b):
    d = math.dist(a, b) or 1
    return ((b[0] - a[0]) / d, (b[1] - a[1]) / d)


def _path(points):
    return 'M' + ' L'.join(f'{x:.1f} {y:.1f}' for x, y in points)


class Strip:
    """One line of a copybook: the four guide lines and what is written on them.

    write(text, model=True) writes letters with their stroke numbers;
    write(word, mark=i) writes a word with its letter i in orange."""

    def __init__(self):
        self.items, self.x = [], 0

    def space(self, bands):
        self.x += bands * U

    def write(self, text, model=False, mark=None):
        for i, ch in enumerate(text):
            if ch == ' ':
                self.x += U * .6
                continue
            strokes, width = glyph(ch)
            pts = [[(self.x + x * U, PAD + (2 - y) * U) for x, y in s] for s in strokes]
            self.items.append({'strokes': pts, 'model': model, 'mark': mark is not None and i in mark})
            self.x += width * U + GAP + PEN
        self.x -= GAP + PEN

    def width(self, lead=LEAD, tail=TAIL):
        return self.x + lead + tail

    def svg(self, width=None, cls='strip', lead=LEAD, tail=TAIL, labels=None):
        """width: the lines run this many units (the writing stays at the left).
        labels: the names of the four lines, written at their left."""
        w = max(self.width(lead, tail), width or 0)
        h = 3 * U + 2 * PAD
        out = [f'<svg class="{cls}" viewBox="0 0 {w:.0f} {h}" xmlns="http://www.w3.org/2000/svg">']
        top, mid, base, bottom = (PAD + k * U for k in range(4))
        x0 = lead - 40 if labels else 0
        out.append(f'<rect class="band" x="{x0}" y="{mid}" width="{w - x0:.0f}" height="{U}"/>')
        for k, (y, c) in enumerate(((top, 'gl'), (mid, 'gl mid'), (base, 'gl base'), (bottom, 'gl'))):
            out.append(f'<line class="{c}" x1="{x0}" y1="{y}" x2="{w:.0f}" y2="{y}"/>')
            if labels:
                out.append(f'<g class="lname{" base" if k == 2 else ""}"><circle cx="22" cy="{y}" r="17"/>'
                           f'<text class="n" x="22" y="{y + 7}">{k + 1}</text>'
                           f'<text x="50" y="{y + 9}">{html.escape(labels[k])}</text></g>')
        out.append(f'<g transform="translate({lead} 0)">')
        badges, marks = [], []
        for item in self.items:
            cls = 'ink mark' if item['mark'] else 'ink'
            for s in item['strokes']:
                if len(s) == 1:
                    out.append(f'<circle class="{cls} dot" cx="{s[0][0]:.1f}" cy="{s[0][1]:.1f}" r="{PEN * .75}"/>')
                else:
                    out.append(f'<path class="{cls}" d="{_path(s)}"/>')
            if item['model']:
                marks += self._order(item['strokes'], badges, h)
        out += marks  # numbers and arrows on top of every letter
        out.append('</g></svg>')
        return '\n'.join(out)

    @staticmethod
    def _order(strokes, badges, h):
        """Arrowheads at the end of each stroke, and its number just before
        its start, where it touches no ink and no other number. A spot
        outside the letter is better than one closed in by it (the bowl of d)."""
        out = []
        ink = [p for s in strokes for p in _dense(s)]

        def walls(c):
            """In how many of the four directions ink closes this spot in."""
            return sum(any(abs(p[1 - axis] - c[1 - axis]) < 10 and (p[axis] - c[axis]) * sign > 0
                           for p in ink) for axis in (0, 1) for sign in (1, -1))
        for n, s in enumerate(strokes, 1):
            start = s[0]
            back = (0, -1) if len(s) == 1 else _unit(s[1], s[0])
            base = math.atan2(back[1], back[0])
            best = None
            for k, turn in enumerate((0, 30, -30, 60, -60, 90, -90, 120, -120, 150, -150, 180)):
                for reach in (BADGE + PEN * .5 + 3, BADGE + PEN * .5 + 14):
                    a = base + math.radians(turn)
                    c = (start[0] + reach * math.cos(a), start[1] + reach * math.sin(a))
                    if not (all(math.dist(c, p) > BADGE + PEN * .5 + 1 for p in ink)
                            and all(math.dist(c, b) > 2 * BADGE + 2 for b in badges)
                            and BADGE < c[1] < h - BADGE):
                        continue
                    score = k + reach / 100 + {4: 100, 3: 30}.get(walls(c), 0)
                    if not best or score < best[0]:
                        best = (score, c)
            spot = best[1] if best else (start[0] + back[0] * 30, start[1] + back[1] * 30)
            badges.append(spot)
            if len(s) > 1:
                end, d = s[-1], _unit(s[-2], s[-1])
                nx, ny = -d[1], d[0]
                tip = (end[0] + d[0] * 9, end[1] + d[1] * 9)
                bx, by = end[0] - d[0] * 13, end[1] - d[1] * 13
                out.append(f'<path class="arrow" d="M{tip[0]:.1f} {tip[1]:.1f} L{bx + nx * 11:.1f} {by + ny * 11:.1f} '
                           f'L{bx - nx * 11:.1f} {by - ny * 11:.1f}Z"/>')
            out.append(f'<g class="badge"><circle cx="{spot[0]:.1f}" cy="{spot[1]:.1f}" r="{BADGE}"/>'
                       f'<text x="{spot[0]:.1f}" y="{spot[1] + 8:.1f}">{n}</text></g>')
        return out


def make_strip(*runs, space=None):
    """make_strip(('A', 'model'), ('a', 'model'), ('apple', 'word', {0}))"""
    s = Strip()
    for k, run in enumerate(runs):
        if k:
            s.space(space or (.9 if run[1] == 'model' else 1.1))
        if run[1] == 'model':
            s.write(run[0], model=True)
        else:
            s.write(run[0], mark=run[2] if len(run) > 2 else None)
    return s


def letter_strip(entry):
    """The copybook line of a letter: the big letter, the small letter, the word."""
    return make_strip((entry['letter'], 'model'), (entry['letter'].lower(), 'model'),
                      (entry['word'], 'word', {entry.get('mark', 0)}))


# ------------------------------------------------------- level, checks, book

import os
import re
import subprocess
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent  # curriculum/
PICTURES = ROOT / 'assets' / 'kids'

# Line icons of the speaking lessons (the same drawings as in book.html.j2).
ICONS = {
    'chat': '<path d="M21 12a8 8 0 0 1-11.6 7.1L4 20.5l1.4-4.8A8 8 0 1 1 21 12z"/><path d="M8.5 11h.01M12 11h.01M15.5 11h.01"/>',
    'card': '<rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="2.2"/><path d="M5.8 16a3.4 3.4 0 0 1 6.4 0M14.5 10h4M14.5 13.5h3"/>',
    'users': '<circle cx="9" cy="8" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><path d="M16 4.5a3.5 3.5 0 0 1 0 7M18 14a6 6 0 0 1 3.5 6"/>',
    'pin': '<path d="M12 21s-7-6.2-7-11.5a7 7 0 0 1 14 0C19 14.8 12 21 12 21z"/><circle cx="12" cy="9.5" r="2.5"/>',
    'sunrise': '<path d="M3 18h18M6 18a6 6 0 0 1 12 0M12 4v3M4.9 9.9l1.4 1.4M19.1 9.9l-1.4 1.4"/>',
    'cake': '<path d="M4 21h16M5 21v-7a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v7M5 16.5c2.3 1.4 4.7 1.4 7 0s4.7-1.4 7 0M12 12V8"/><path d="M12 5.8c.9-.9.9-1.9 0-2.8-.9.9-.9 1.9 0 2.8z"/>',
    'heart': '<path d="M12 20.5s-7.5-4.6-9.3-9.4A4.9 4.9 0 0 1 12 6.4a4.9 4.9 0 0 1 9.3 4.7c-1.8 4.8-9.3 9.4-9.3 9.4z"/>',
    'color': '<path d="M12 3a9 9 0 1 0 0 18c1.4 0 2-1 2-2 0-1.5-1.2-1.8-1.2-3 0-1.1.9-2 2-2H17a4 4 0 0 0 4-4c0-3.9-4-7-9-7z"/><circle cx="7.5" cy="11" r="1.2"/><circle cx="10" cy="7" r="1.2"/><circle cx="15" cy="7.5" r="1.2"/>',
    'pencil': '<path d="M4 20l1-4L16 5l3 3L8 19z"/><path d="M14 7l3 3"/>',
}

_ARABIC = re.compile(r'[؀-ۿݐ-ݿﭐ-﷿ﹰ-﻿]')


def _strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for v in value.values():
            yield from _strings(v)
    elif isinstance(value, list):
        for v in value:
            yield from _strings(v)


def picture(name):
    path = PICTURES / f'{name}.svg'
    return path.read_text(encoding='utf-8') if path.exists() else ''


def load(level_dir):
    read = lambda p: yaml.safe_load(p.read_text(encoding='utf-8'))
    level = read(level_dir / 'level.yaml')
    speaking = sorted((read(p) for p in (level_dir / 'speaking').glob('*.yaml')),
                      key=lambda l: l['lesson'])
    return level, read(level_dir / 'intro.yaml'), read(level_dir / 'letters.yaml')['letters'], speaking


def check(level, intro, letters, speaking, wordlists, report, selected):
    """The rules of GUIDELINES.md that apply to a Kids level."""
    import cmudict
    cmu = cmudict.dict()
    banned = {w: reason for reason in ('arabic_sounding', 'sexual', 'gendered')
              for w in wordlists.get(reason, [])}
    want = [chr(c) for c in range(ord('A'), ord('Z') + 1)]
    got = [e.get('letter') for e in letters]
    if got != want:
        report.error('letters.yaml', f'the letters must be A to Z in order, got {got}')
    seen = set()
    for e in letters:
        where = f'letter {e.get("letter")}'
        word = e.get('word')
        if not isinstance(word, str):
            report.error(where, f'the word {word!r} is not text; put it in quotes in the YAML')
            continue
        mark = e.get('mark', 0)
        if not 0 <= mark < len(word) or word[mark] != e['letter'].lower():
            report.error(where, f'"{word}": letter {mark} is not {e["letter"].lower()}')
        missing = sorted(set(word + e['letter'] + e['letter'].lower()) - set(GLYPHS))
        if missing:
            report.error(where, f'"{word}": no handwriting for {missing}')
        for part in word.split('-'):
            if part in banned:
                report.error(where, f'"{word}" is banned ({banned[part]})')
            if part not in cmu:
                report.error(where, f'"{word}" is not in the American dictionary (spelling?)')
        if word in seen:
            report.error(where, f'"{word}" is used twice')
        seen.add(word)
        if not (PICTURES / f'{word}.svg').exists():
            (report.error if e['letter'] in selected else report.warn)(where, f'no picture yet: assets/kids/{word}.svg')
    for group in intro['groups']['items']:
        missing = sorted(set(group['letters'].replace(' ', '')) - set(GLYPHS))
        if missing:
            report.error('intro', f'no handwriting for {missing}')

    cast = level.get('cast', {})
    sexual = set(wordlists.get('sexual', []))
    for lesson in speaking:
        where = f'speaking lesson {lesson["lesson"]}'
        speakers = [who for who, _ in lesson.get('conversation', [])] + (
            [lesson['speaker']] if lesson.get('speaker') else [])
        for who in speakers:
            if who not in cast:
                report.error(where, f'"{who}" is not in the level cast ({", ".join(cast)})')
        if len(lesson.get('conversation', [])) > 10:
            report.error(where, 'more than 10 conversation lines')
        if len(lesson.get('phrases', [])) > 6:
            report.error(where, 'more than 6 phrase boxes')
        for line in lesson.get('about', []):
            if line['icon'] not in ICONS and not (PICTURES / f'{line["icon"]}.svg').exists():
                report.error(where, f'no icon or picture called {line["icon"]!r}')
        for token in re.findall(r"[A-Za-z']+", ' '.join(_strings(lesson))):
            if token.lower() in sexual:
                report.error(where, f'"{token}" is banned (sexual)')
    for name, value in [('level.yaml', level), ('intro.yaml', intro), ('letters.yaml', letters)] + [
            (f'speaking lesson {l["lesson"]}', l) for l in speaking]:
        for text in _strings(value):
            if _ARABIC.search(text):
                report.error(name, f'contains Arabic text: "{text}"')


def build(level_dir, args, wordlists, report_cls):
    from jinja2 import Environment, FileSystemLoader
    from markupsafe import Markup
    level, intro, letters, speaking = load(level_dir)
    level['course'] = yaml.safe_load((level_dir.parent / 'course.yaml').read_text(encoding='utf-8'))
    wanted = args.letters.upper().split('-') if args.letters else ['A', 'Z']
    selected = [chr(c) for c in range(ord(wanted[0]), ord(wanted[-1]) + 1)]
    report = report_cls()
    # A missing picture stops a build of its letter; --check only warns.
    check(level, intro, letters, speaking, wordlists, report, [] if args.check else selected)
    for w in report.warnings:
        print('warning:', w)
    for e in report.errors:
        print('ERROR:', e)
    if report.errors:
        raise SystemExit(f'{len(report.errors)} error(s); nothing was built.')
    print(f'checks passed (26 letters, {len(speaking)} speaking lessons, {len(report.warnings)} warnings)')
    if args.check:
        return

    # Every letter line is drawn at the same size: the size that fits the longest one.
    width = max(letter_strip(e).width() for e in letters)
    cards = [dict(e, strip=Markup(letter_strip(e).svg(width=width)), picture=Markup(picture(e['word'])))
             for e in letters if e['letter'] in selected]
    lines = make_strip(('A', 'word'), ('a', 'word'), ('b', 'word'), ('g', 'word'), space=1.6)
    groups = [dict(g, n=n, strip=Markup(make_strip(*[(c, 'word') for c in g['letters'].split()], space=.75)
                                  .svg(width=1250, lead=40, tail=20)))
              for n, g in enumerate(intro['groups']['items'], 1)]
    cover_lines = [Markup(make_strip(*[(p, 'word', {1}) for p in row], space=.8).svg(width=1250, lead=50, tail=10))
                   for row in (('Aa', 'Bb', 'Cc'),)]

    env = Environment(loader=FileSystemLoader(ROOT / 'templates'), autoescape=True)
    env.globals.update(picture=lambda name: Markup(picture(name)), icons=ICONS)
    out = level_dir / 'dist' / (args.out or 'book')
    out.parent.mkdir(exist_ok=True)
    html_path = out.with_suffix('.html')
    doc = env.get_template('kids.html.j2').render(
        level=level, intro=intro, cards=cards, speaking=speaking, book=args.book,
        sample=len(selected) < 26, selected=selected, groups=groups,
        lines_svg=Markup(lines.svg(lead=330, tail=60, labels=intro['lines']['names'])),
        how_svg=Markup(make_strip((intro['how']['letter'], 'model')).svg(lead=70, tail=70)),
        cover_lines=cover_lines,
        assets=os.path.relpath(ROOT / 'assets', html_path.parent),
        paginate_js=(ROOT / 'tools' / 'kids-paginate.js').read_text(encoding='utf-8'))
    html_path.write_text(doc, encoding='utf-8')
    subprocess.run(['node', str(ROOT / 'tools' / 'render.js'), str(html_path),
                    str(out.with_suffix('.pdf'))], check=True)
