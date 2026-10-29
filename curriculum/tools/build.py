#!/usr/bin/env python3
"""Check and build FVI English curriculum sheets.

Usage:
    python3 curriculum/tools/build.py english/starter --lessons 1-6 --out starter-batch-1
    python3 curriculum/tools/build.py english/starter --check

Lesson content lives in YAML (one file per lesson). Example words use a tiny
markup: c[a]t highlights the letters being taught, mak{e} marks a silent
letter. Every build first checks the content against the curriculum rules
(GUIDELINES.md) and stops on any error.
"""
import argparse
import html
import os
import re
import subprocess
import sys
from pathlib import Path

import yaml
from jinja2 import Environment, FileSystemLoader

ROOT = Path(__file__).resolve().parent.parent  # curriculum/
TOOLS = ROOT / 'tools'

# ---------------------------------------------------------------- markup

_MARK = re.compile(r'\[([^\]]+)\]|\{([^}]+)\}')


def plain(word):
    """c[a]t -> cat"""
    return _MARK.sub(lambda m: m.group(1) or m.group(2), word)


def marked(word):
    """The letters inside [...] (taught) and {...} (silent)."""
    return ([m.group(1) for m in _MARK.finditer(word) if m.group(1)],
            [m.group(2) for m in _MARK.finditer(word) if m.group(2)])


def render_word(word):
    out, pos = [], 0
    for m in _MARK.finditer(word):
        out.append(html.escape(word[pos:m.start()]))
        if m.group(1):
            out.append(f'<span class="hl">{html.escape(m.group(1))}</span>')
        else:
            out.append(f'<span class="sil">{html.escape(m.group(2))}</span>')
        pos = m.end()
    out.append(html.escape(word[pos:]))
    return ''.join(out)


# ------------------------------------------------------- pronunciations

# CMU (ARPAbet, American English) -> the IPA symbols used in the sheets,
# which follow Cambridge Dictionary's US transcriptions.
_VOWELS = {
    'AA': 'ɑː', 'AE': 'æ', 'AO': 'ɔː', 'AW': 'aʊ', 'AY': 'aɪ', 'EH': 'e',
    'EY': 'eɪ', 'IH': 'ɪ', 'OW': 'oʊ', 'OY': 'ɔɪ', 'UH': 'ʊ', 'UW': 'uː',
}
_CONSONANTS = {
    'B': 'b', 'CH': 'tʃ', 'D': 'd', 'DH': 'ð', 'F': 'f', 'G': 'ɡ', 'HH': 'h',
    'JH': 'dʒ', 'K': 'k', 'L': 'l', 'M': 'm', 'N': 'n', 'NG': 'ŋ', 'P': 'p',
    'R': 'r', 'S': 's', 'SH': 'ʃ', 'T': 't', 'TH': 'θ', 'V': 'v', 'W': 'w',
    'Y': 'j', 'Z': 'z', 'ZH': 'ʒ',
}
# American English merges these vowels for most speakers, and dictionaries
# disagree on which symbol to print; either one confirms the example.
_EQUIVALENT = {'ɑː': {'ɑː', 'ɔː'}, 'ɔː': {'ɔː', 'ɑː'}, 'ə': {'ə', 'ɪ0'}, 'ɪ': {'ɪ', 'ɪ0'}}


def to_ipa(phones):
    out = []
    for p in phones:
        base, stress = p.rstrip('012'), p[len(p.rstrip('012')):]
        if base == 'AH':
            out.append('ə' if stress == '0' else 'ʌ')
        elif base == 'ER':
            out.append('ɚ' if stress == '0' else 'ɝː')
        elif base == 'IY':
            out.append('i' if stress == '0' else 'iː')
        elif base == 'IH' and stress == '0':
            out.append('ɪ0')  # reduced vowel; counts as /ə/ (see _EQUIVALENT)
        elif base in _VOWELS:
            out.append(_VOWELS[base])
        else:
            out.append(_CONSONANTS[base])
    return out


def sound_units(ipa):
    """'juː' -> ['j', 'uː'] so multi-symbol sounds can be found in sequence."""
    units, i = [], 0
    symbols = sorted(set(_VOWELS.values()) | set(_CONSONANTS.values()) |
                     {'ə', 'ʌ', 'ɚ', 'ɝː', 'i', 'iː'}, key=len, reverse=True)
    while i < len(ipa):
        for s in symbols:
            if ipa.startswith(s, i):
                units.append(s)
                i += len(s)
                break
        else:
            raise ValueError(f'unknown sound symbol in /{ipa}/')
    return units


def has_sound(prons, ipa):
    want = sound_units(ipa)
    for pron in prons:
        got = to_ipa(pron)
        for start in range(len(got) - len(want) + 1):
            if all(g in _EQUIVALENT.get(w, {w}) for g, w in
                   zip(got[start:start + len(want)], want)):
                return True
    return False


# --------------------------------------------------------------- checks

class Report:
    def __init__(self):
        self.errors, self.warnings = [], []

    def error(self, where, msg):
        self.errors.append(f'{where}: {msg}')

    def warn(self, where, msg):
        self.warnings.append(f'{where}: {msg}')


def check_level(level, lessons, wordlists):
    import cmudict
    cmu = cmudict.dict()
    report = Report()
    banned = {w: reason for reason in ('arabic_sounding', 'sexual', 'gendered')
              for w in wordlists.get(reason, [])}
    order = level['letter_order']
    taught, seen = set(), {}

    def check_word(where, word, target_letters=None, ipa=None):
        w = plain(word)
        key = w.lower()
        if key in banned:
            report.error(where, f'"{w}" is banned ({banned[key]})')
        # CMU also lists surnames, so passing this does not prove the spelling.
        if key not in cmu:
            report.error(where, f'"{w}" is not in the American dictionary (spelling?)')
            return
        if ipa and not has_sound(cmu[key], ipa):
            got = ' | '.join(''.join(to_ipa(p)).replace('ɪ0', 'ɪ') for p in cmu[key])
            report.error(where, f'"{w}" does not contain /{ipa}/ (US: {got})')
        hl, _ = marked(word)
        if target_letters is not None and ''.join(hl).lower() != target_letters:
            report.error(where, f'"{word}" should highlight "{target_letters}"')
        if len(w) > 7:
            report.warn(where, f'"{w}" is long ({len(w)} letters)')
        seen.setdefault(key, []).append(where)

    for lesson in lessons:
        n = lesson['lesson']
        if lesson.get('kind') == 'intro':
            continue
        letters = [l.upper() for l in lesson['letters']]
        taught |= set(letters)
        for s in lesson.get('sounds', []):
            where = f'lesson {n} /{s["ipa"]}/'
            sound_units(s['ipa'])
            if len(s['examples']) != 3:
                report.error(where, 'needs exactly 3 examples')
            for ex in s['examples']:
                check_word(where, ex, letters[0].lower() if len(letters) == 1 else None, s['ipa'])
        silent = lesson.get('silent', {})
        for ex in silent.get('examples', []):
            check_word(f'lesson {n} silent', ex)
        for team in lesson.get('teams', []):
            t = team['letters'].lower()
            where = f'lesson {n} "{t}"'
            missing = sorted(set(t.upper()) - taught)
            if missing:
                report.error(where, f'uses letters not taught yet: {missing}')
            last = max(order.index(c) for c in t.upper())
            if order[last] not in letters:
                report.error(where, f'belongs with its last-taught letter, {order[last]}')
            for s in team['sounds']:
                for ex in s['examples']:
                    check_word(f'{where} /{s["ipa"]}/', ex, t, s['ipa'])

    for word, places in seen.items():
        if len(places) > 1:
            report.warn(places[-1], f'"{word}" is used more than once ({", ".join(places)})')
    return report


# ---------------------------------------------------------------- build

_RELIABILITY = {
    'always': ('ALWAYS', 'always'),
    'almost': ('ALMOST ALWAYS', 'always'),
    'usually': ('USUALLY TRUE', 'usually'),
    'varies': ('NOT FIXED — LEARN EACH WORD', 'varies'),
    'few': ('NOT A RULE — A FEW WORDS', 'varies'),
}


def load(level_dir, lesson_range):
    level = yaml.safe_load((level_dir / 'level.yaml').read_text(encoding='utf-8'))
    lessons = [yaml.safe_load(p.read_text(encoding='utf-8'))
               for p in sorted((level_dir / 'phonics').glob('*.yaml'))]
    lessons.sort(key=lambda l: l['lesson'])
    numbers = [l['lesson'] for l in lessons]
    if numbers != list(range(1, len(lessons) + 1)):
        sys.exit(f'lesson numbers must run 1..n without gaps, got {numbers}')
    selected = [l for l in lessons if l['lesson'] in lesson_range] if lesson_range else lessons
    return level, lessons, selected


def build_html(level, lessons, selected, out_html):
    env = Environment(loader=FileSystemLoader(ROOT / 'templates'), autoescape=True)
    env.filters['word'] = lambda w: __import__('markupsafe').Markup(render_word(w))
    env.globals['reliability'] = _RELIABILITY
    order = level['letter_order']
    taught = []
    pages = []
    for lesson in lessons:
        if lesson.get('kind') != 'intro':
            taught += [l.upper() for l in lesson['letters']]
        if lesson in selected:
            pages.append({'lesson': lesson, 'taught': list(taught)})
    assets = os.path.relpath(ROOT / 'assets', out_html.parent)
    paginate = (TOOLS / 'paginate.js').read_text(encoding='utf-8')
    doc = env.get_template('book.html.j2').render(
        level=level, pages=pages, order=order, assets=assets, paginate_js=paginate)
    out_html.write_text(doc, encoding='utf-8')


def parse_range(text):
    if not text:
        return None
    a, _, b = text.partition('-')
    return range(int(a), int(b or a) + 1)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('level', help='level folder under curriculum/, e.g. english/starter')
    ap.add_argument('--lessons', help='e.g. 1-6')
    ap.add_argument('--out', help='output name (without extension) in the level dist/ folder')
    ap.add_argument('--check', action='store_true', help='only run the checks')
    args = ap.parse_args()

    level_dir = ROOT / args.level
    level, lessons, selected = load(level_dir, parse_range(args.lessons))
    wordlists = yaml.safe_load((ROOT / 'wordlists.yaml').read_text(encoding='utf-8'))
    report = check_level(level, lessons, wordlists)
    for w in report.warnings:
        print('warning:', w)
    for e in report.errors:
        print('ERROR:', e)
    if report.errors:
        sys.exit(f'{len(report.errors)} error(s); nothing was built.')
    print(f'checks passed ({len(lessons)} lessons, {len(report.warnings)} warnings)')
    if args.check:
        return

    out = level_dir / 'dist' / (args.out or 'book')
    out.parent.mkdir(exist_ok=True)
    build_html(level, lessons, selected, out.with_suffix('.html'))
    subprocess.run(['node', str(TOOLS / 'render.js'), str(out.with_suffix('.html')),
                    str(out.with_suffix('.pdf'))], check=True)


if __name__ == '__main__':
    main()
