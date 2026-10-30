#!/usr/bin/env python3
"""Check and build FVI English curriculum sheets.

Usage:
    python3 curriculum/tools/build.py english/starter --lessons 1-6 --out starter-batch-1
    python3 curriculum/tools/build.py english/pre-intermediate-1 --book --out pi1-book
    python3 curriculum/tools/build.py english/starter --check

Lesson content lives in YAML (one file per lesson). Starter has phonics/ and
speaking/ folders; later levels have one lessons/ folder of stories, topics
and conversations. Example words use a tiny markup: c[a]t highlights the
letters being taught, mak{e} marks a silent letter. In stories, [is] colors
the grammar the story teaches. Every build first checks the content against
the curriculum rules (GUIDELINES.md) and stops on any error.
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
    """c[a]t -> cat, ((on time)) -> on time"""
    return _MARK.sub(lambda m: m.group(1) or m.group(2), _IDIOM.sub(r'\1', word))


def marked(word):
    """The letters inside [...] (taught) and {...} (silent)."""
    return ([m.group(1) for m in _MARK.finditer(word) if m.group(1)],
            [m.group(2) for m in _MARK.finditer(word) if m.group(2)])


def marked_in_order(word):
    """{k}[n]ow -> 'kn': every marked letter, in reading order."""
    return ''.join(m.group(1) or m.group(2) for m in _MARK.finditer(word))


_BRACKETS = re.compile(r'\[([^\]]+)\]')
# ((spill the beans)): an idiom, proverb or phrase, explained in its own box.
_IDIOM = re.compile(r'\(\(([^()]+)\)\)')
_IDIOM_TYPES = ('idiom', 'proverb', 'phrase')


def render_text(text, how='v'):
    """Running text: [is] -> <span class="v">is</span>, or <em>is</em>;
    ((break the ice)) -> <span class="i">break the ice</span>."""
    out, pos = [], 0
    for m in _BRACKETS.finditer(text):
        out.append(_render_idioms(text[pos:m.start()]))
        inner = html.escape(m.group(1))
        out.append(f'<em>{inner}</em>' if how == 'em' else f'<span class="{how}">{inner}</span>')
        pos = m.end()
    out.append(_render_idioms(text[pos:]))
    return ''.join(out)


def _render_idioms(text):
    out, pos = [], 0
    for m in _IDIOM.finditer(text):
        out.append(html.escape(text[pos:m.start()]))
        out.append(f'<span class="i">{html.escape(m.group(1))}</span>')
        pos = m.end()
    out.append(html.escape(text[pos:]))
    return ''.join(out)


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


def _same(got, want, next_want):
    if got in _EQUIVALENT.get(want, {want}):
        return True
    # Cambridge writes the vowel of "near" as /ɪr/; CMU writes it as IY + R.
    return want == 'ɪ' and next_want == 'r' and got == 'iː'


def has_sound(prons, ipa):
    want = sound_units(ipa)
    for pron in prons:
        got = to_ipa(pron)
        for start in range(len(got) - len(want) + 1):
            if all(_same(got[start + i], w, want[i + 1] if i + 1 < len(want) else None)
                   for i, w in enumerate(want)):
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

    def check_word(where, word, ipa=None, highlight=None, marks=None, silent=None):
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
        hl, sil = marked(word)
        if highlight is not None and ''.join(hl).lower() != highlight:
            report.error(where, f'"{word}" should highlight "{highlight}"')
        if marks is not None and marked_in_order(word).lower() != marks:
            report.error(where, f'"{word}" should mark the letters "{marks}"')
        if silent is not None and ''.join(sil).lower() != silent:
            report.error(where, f'"{word}" should show "{silent}" as silent')
        if len(w) > 7:
            report.warn(where, f'"{w}" is long ({len(w)} letters)')
        seen.setdefault(key, []).append(where)

    for lesson in lessons:
        n = lesson['lesson']
        if lesson.get('kind') == 'intro':
            continue
        for part in lesson['parts']:
            letter = part['letter'].upper()
            taught.add(letter)
            for s in part['sounds']:
                where = f'lesson {n} {letter} /{s["ipa"]}/'
                sound_units(s['ipa'])
                if len(s['examples']) != 3:
                    report.error(where, 'needs exactly 3 examples')
                for ex in s['examples']:
                    check_word(where, ex, s['ipa'], highlight=s.get('highlight', letter).lower())
            for si in part['silent']:
                for ex in si.get('examples', []):
                    check_word(f'lesson {n} {letter} silent', ex, silent=letter.lower())
            for team in part['teams']:
                t = team['letters'].lower()
                where = f'lesson {n} "{t}"'
                missing = sorted(set(t.upper()) - taught)
                if missing:
                    report.error(where, f'uses letters not taught yet: {missing}')
                last = order[max(order.index(c) for c in t.upper())]
                if last != letter:
                    report.error(where, f'belongs with its last-taught letter, {last}')
                for s in team['sounds']:
                    ipa = s.get('ipa')
                    for ex in s['examples']:
                        check_word(f'{where} /{ipa or "silent"}/', ex, ipa, marks=t)

        for group in lesson.get('chart', []):
            for item in group['items']:
                sound_units(item['ipa'])
                check_word(f'lesson {n} chart /{item["ipa"]}/', item['word'], item['ipa'])

    for word, places in seen.items():
        places = [p for p in places if ' chart ' not in p]  # the chart reuses words on purpose
        if len(places) > 1:
            report.warn(places[-1], f'"{word}" is used more than once ({", ".join(places)})')
    return report


_ARABIC = re.compile(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]')


def _strings(value):
    if isinstance(value, str):
        yield value
    elif isinstance(value, dict):
        for v in value.values():
            yield from _strings(v)
    elif isinstance(value, list):
        for v in value:
            yield from _strings(v)


def check_no_arabic(lessons, report):
    """Guidelines: no Arabic on any sheet. The Arabic grammar note in
    learn.ar is shown in the app only, never on a sheet."""
    for lesson in lessons:
        sheet = dict(lesson)
        if isinstance(lesson.get('learn'), dict):
            sheet['learn'] = {k: v for k, v in lesson['learn'].items() if k != 'ar'}
        for text in _strings(sheet):
            if _ARABIC.search(text):
                report.error(f'{lesson.get("kind", "phonics")} lesson {lesson["lesson"]}',
                             f'contains Arabic text: "{text}"')


def check_speaking(level, speaking, wordlists, report):
    cast = level.get('cast', {})
    sexual = set(wordlists.get('sexual', []))
    for lesson in speaking:
        where = f'speaking lesson {lesson["lesson"]}'
        lines = lesson['conversation']
        if len(lines) > 10:
            report.error(where, f'{len(lines)} conversation lines; a page holds 10')
        if len(lesson['phrases']) > 6:
            report.error(where, 'more than 6 phrase boxes')
        if len(lesson['words']) > 6:
            report.error(where, 'more than 6 new words')
        for who, _ in lines:
            if who not in cast:
                report.error(where, f'"{who}" is not in the level cast ({", ".join(cast)})')
        text = ' '.join(line for _, line in lines)
        text += ' ' + ' '.join(' '.join(ph['lines']) + ' ' + ph.get('reply', '')
                               for ph in lesson['phrases'])
        for token in re.findall(r"[A-Za-z']+", text):
            if token.lower() in sexual:
                report.error(where, f'"{token}" is banned (sexual)')
        for w in lesson['words']:
            if w['word'].lower() not in text.lower():
                report.error(where, f'new word "{w["word"]}" is not used in the lesson')
        check_cut_text(level, lesson['words'], where, report)


def check_cut_text(level, entries, where, report):
    """{word: x, meaning: a long, narrow room} ends the meaning at the comma,
    and {meaning: yes, for sure} without quotes can turn into true."""
    say = report.error
    for w in entries:
        name = w.get('word') or w.get('expr')
        if set(w) - {'word', 'meaning', 'expr', 'type', 'example'}:
            say(where, f'"{name}": the meaning stops at a comma; put it in quotes in the YAML')
        elif any(not isinstance(w.get(k), str) for k in ('meaning', 'example') if k in w):
            say(where, f'"{name}": the meaning is not text; put it in quotes in the YAML')


_KINDS = ('story', 'topic', 'science', 'news', 'podcast', 'conversation')


def _words_in(text):
    return re.findall(r"[A-Za-z']+", text)


def check_lessons(level, lessons, wordlists, report):
    """Stories, topics and conversations of the levels after Starter."""
    cast = level.get('cast', {})
    sexual = set(wordlists.get('sexual', []))
    sounding = set(wordlists.get('arabic_sounding', []))
    units = level.get('units', {})
    for lesson in lessons:
        n, kind = lesson['lesson'], lesson.get('kind')
        where = f'lesson {n}'
        if kind not in _KINDS:
            report.error(where, f'kind must be one of {", ".join(_KINDS)}, got {kind!r}')
            continue
        where = f'{kind} lesson {n}'
        if lesson.get('unit') not in units:
            report.error(where, f'unit {lesson.get("unit")!r} is not in level.yaml units')
        for text in _strings(lesson):
            if text.count('[') != text.count(']'):
                report.error(where, f'unbalanced [ ] in "{text}"')
        speakers = []
        if kind == 'story':
            words = len(_words_in(plain(' '.join(lesson['story']))))
            low, high = level.get('story_words', (70, 140))
            if not low <= words <= high:
                report.warn(where, f'story has {words} words; this level aims at {low} to {high}')
            if len(lesson['questions']) != 12:
                report.error(where, f'{len(lesson["questions"])} questions; a story has 12')
            speakers.append(lesson['pov']['speaker'])
            widths = {len(row) for row in lesson['learn']['table']}
            if len(widths) != 1:
                report.error(where, 'the rows of the grammar table differ in length')
            if not lesson['story'] or not any('[' in para for para in lesson['story']):
                report.error(where, 'the story marks no grammar with [ ]')
        elif kind in ('topic', 'science', 'news', 'podcast'):
            if not 4 <= len(lesson['questions']) <= 8:
                report.error(where, f'{len(lesson["questions"])} questions; a topic has 4 to 8')
            if kind == 'news' and not lesson.get('headline'):
                report.error(where, 'a news lesson needs a headline')
            if kind == 'podcast':
                if len(lesson['script']) > 20:
                    report.error(where, f'{len(lesson["script"])} lines; a podcast holds 20')
                speakers += [who for _, who, _ in lesson['script']]
        else:
            if len(lesson['conversation']) > 10:
                report.error(where, f'{len(lesson["conversation"])} lines; a conversation holds 10')
            if len(lesson['phrases']) > 6:
                report.error(where, 'more than 6 phrase boxes')
            speakers += [who for who, _ in lesson['conversation']]
        for who in speakers:
            if who not in cast:
                report.error(where, f'"{who}" is not in the level cast ({", ".join(cast)})')
        check_idioms(level, lesson, where, report)
        check_arabic_note(level, lesson, where, report)
        if len(lesson['words']) > 6:
            report.error(where, 'more than 6 new words')
        check_cut_text(level, lesson['words'] + lesson.get('idioms', []), where, report)
        bad = [w['word'] for w in lesson['words'] if not isinstance(w['word'], str)]
        if bad:
            # YAML reads true, no, on, off as booleans unless they are quoted.
            report.error(where, f'new words {bad} are not text; put them in quotes in the YAML')
            continue
        # Everything the student reads, without the new-words box itself.
        body = plain(' '.join(_strings({k: v for k, v in lesson.items() if k != 'words'})))
        for token in _words_in(body):
            if token.lower() in sexual:
                report.error(where, f'"{token}" is banned (sexual)')
        for w in lesson['words']:
            if w['word'].lower() in sounding:
                report.error(where, f'new word "{w["word"]}" is banned (sounds like a rude Arabic word)')
            if not re.search(r'\b' + re.escape(w['word'].lower()) + r'\b', body.lower()):
                report.error(where, f'new word "{w["word"]}" is not used in the lesson')


def check_arabic_note(level, lesson, where, report):
    """In the levels with arabic_notes: true (Pre-Intermediate 1 to 4), a
    grammar lesson may carry learn.ar: a short explanation in Arabic for
    the app, with a summary and a few points. A point is Arabic only, or a
    pair: the Arabic explanation and its English example, which the app
    shows on its own line, left to right, so the two never mix."""
    note = (lesson.get('learn') or {}).get('ar')
    if note is None:
        if level.get('arabic_notes') and lesson['kind'] == 'story':
            report.error(where, 'every grammar lesson of this level needs its Arabic note (learn.ar)')
        return
    if not level.get('arabic_notes'):
        report.error(where, 'an Arabic grammar note belongs to the levels with arabic_notes: true only')
        return
    if set(note) - {'summary', 'points'} or not note.get('summary') or not note.get('points'):
        report.error(where, 'learn.ar needs a summary and points, nothing else')
        return
    for point in [note['summary']] + list(note['points']):
        text, example = (point, None) if isinstance(point, str) else (point + [None, None])[:2]
        if not isinstance(text, str) or not _ARABIC.search(text):
            report.error(where, f'learn.ar should be written in Arabic: "{text}"')
        if not isinstance(point, str) and (len(point) != 2 or not isinstance(example, str)
                                            or _ARABIC.search(example)):
            report.error(where, f'a learn.ar point is [Arabic, English example]: {point}')


def check_idioms(level, lesson, where, report):
    """From the levels with idioms: true, every lesson teaches idioms,
    proverbs and phrases: a story three, one of them a proverb, and every
    other lesson two. Each one is marked ((like this)) where it is used,
    in the same order as its box."""
    entries = lesson.get('idioms', [])
    for text in _strings(lesson):
        if text.count('((') != text.count('))'):
            report.error(where, f'unbalanced (( )) in "{text}"')
    body = ' '.join(_strings({k: v for k, v in lesson.items() if k not in ('idioms', 'words')}))
    used = _IDIOM.findall(body)
    if not level.get('idioms'):
        if entries or used:
            report.error(where, 'idioms are taught from the levels with idioms: true only')
        return
    want = 3 if lesson['kind'] == 'story' else 2
    if len(entries) != want:
        report.error(where, f'{len(entries)} idioms; a {lesson["kind"]} has {want}')
    for e in entries:
        missing = [k for k in ('expr', 'type', 'meaning', 'example') if not e.get(k)]
        if missing:
            report.error(where, f'idiom {e.get("expr")!r} needs {", ".join(missing)}')
        if e.get('type') not in _IDIOM_TYPES:
            report.error(where, f'idiom {e.get("expr")!r}: type must be one of {", ".join(_IDIOM_TYPES)}')
    if lesson['kind'] == 'story' and sum(e.get('type') == 'proverb' for e in entries) != 1:
        report.error(where, 'a story teaches exactly one proverb')
    if len(used) != len(entries):
        report.error(where, f'{len(used)} (( )) marks in the lesson for {len(entries)} idioms')
        return
    # The mark may be a changed form (turned out for turn out); it must
    # still share the start of a word of four letters or more with the
    # idiom in the box.
    for e, u in zip(entries, used):
        key = {w[:4].lower() for w in _words_in(str(e.get('expr', ''))) if len(w) >= 4}
        if key and not key & {w[:4].lower() for w in _words_in(u)}:
            report.error(where, f'(({u})) does not match the idiom "{e.get("expr")}" in its place in the box')


# ---------------------------------------------------------------- build

_RELIABILITY = {
    'always': ('ALWAYS', 'always'),
    'almost': ('ALMOST ALWAYS', 'always'),
    'usually': ('USUALLY TRUE', 'usually'),
    'varies': ('NOT FIXED — LEARN EACH WORD', 'varies'),
    'few': ('NOT A RULE — A FEW WORDS', 'varies'),
}


def normalize(lesson):
    """A phonics lesson is a list of parts, one per letter. Single-letter
    lessons may write the part's fields at the top level instead."""
    if lesson.get('kind') == 'intro':
        return lesson
    if 'parts' not in lesson:
        lesson['parts'] = [dict(letter=lesson['letters'][0],
                                **{k: lesson[k] for k in ('sounds', 'rules', 'silent', 'teams')
                                   if k in lesson})]
    for part in lesson['parts']:
        silent = part.get('silent', [])
        part['silent'] = silent if isinstance(silent, list) else [silent]
        for key in ('sounds', 'rules', 'teams'):
            part.setdefault(key, [])
    lesson['letters'] = [p['letter'].upper() for p in lesson['parts']]
    return lesson


def load(level_dir):
    level = yaml.safe_load((level_dir / 'level.yaml').read_text(encoding='utf-8'))
    level['course'] = yaml.safe_load((level_dir.parent / 'course.yaml').read_text(encoding='utf-8'))
    lessons = [yaml.safe_load(p.read_text(encoding='utf-8'))
               for p in sorted((level_dir / 'phonics').glob('*.yaml'))]
    lessons = [normalize(l) for l in lessons]
    lessons.sort(key=lambda l: l['lesson'])
    numbers = [l['lesson'] for l in lessons]
    if numbers != list(range(1, len(lessons) + 1)):
        sys.exit(f'lesson numbers must run 1..n without gaps, got {numbers}')
    speaking = [dict(yaml.safe_load(p.read_text(encoding='utf-8')), kind='speaking')
                for p in sorted((level_dir / 'speaking').glob('*.yaml'))]
    speaking.sort(key=lambda l: l['lesson'])
    return level, lessons, speaking


def load_lessons(level_dir):
    """The lessons/ folder of a level after Starter."""
    lessons = [yaml.safe_load(p.read_text(encoding='utf-8'))
               for p in sorted((level_dir / 'lessons').glob('*.yaml'))]
    lessons.sort(key=lambda l: l['lesson'])
    numbers = [l['lesson'] for l in lessons]
    if len(set(numbers)) != len(numbers):
        sys.exit(f'two lessons share a number: {numbers}')
    return lessons


_KIND_LABEL = {'story': 'Story', 'topic': 'Topic', 'science': 'Science', 'news': 'News',
               'podcast': 'Podcast', 'conversation': 'Conversation'}


def stage_contents(level, lessons):
    """Table of contents of a level after Starter: lessons grouped by unit."""
    contents = []
    for unit, name in level['units'].items():
        entries = [(f'lesson-{l["lesson"]}', l['lesson'], l['title'], _KIND_LABEL[l['kind']])
                   for l in lessons if l['unit'] == unit]
        if entries:
            contents.append((f'Unit {unit} — {name}', entries))
    return contents


def render_html(level, pages, contents, out_html, book=False):
    from markupsafe import Markup
    env = Environment(loader=FileSystemLoader(ROOT / 'templates'), autoescape=True)
    env.filters['word'] = lambda w: Markup(render_word(w))
    env.filters['mark'] = lambda text, how='v': Markup(render_text(text, how))
    env.globals['reliability'] = _RELIABILITY
    env.globals['kind_label'] = _KIND_LABEL
    assets = os.path.relpath(ROOT / 'assets', out_html.parent)
    paginate = (TOOLS / 'paginate.js').read_text(encoding='utf-8')
    doc = env.get_template('book.html.j2').render(
        level=level, pages=pages, assets=assets, paginate_js=paginate,
        book=book, contents=contents)
    out_html.write_text(doc, encoding='utf-8')


def build_html(level, phonics, speaking, selected, out_html, book=False):
    taught, pages = [], []
    for lesson in phonics:
        if lesson.get('kind') != 'intro':
            taught += [l.upper() for l in lesson['letters']]
        if lesson in selected:
            pages.append({'lesson': lesson, 'taught': list(taught)})
    pages += [{'lesson': l} for l in speaking if l in selected]
    contents = [
        ('Part 1 — Phonics', [(f'phonics-{l["lesson"]}', l['lesson'], l['title'], '') for l in phonics]
                             + [('chart', '', l['chart_title'], '') for l in phonics if l.get('chart')]),
        ('Part 2 — Speaking', [(f'speaking-{l["lesson"]}', l['lesson'], l['title'], '') for l in speaking]),
    ]
    render_html(level, pages, contents, out_html, book)


def parse_range(text):
    """'1-6' or '10,13' or '1-3,7' -> the lesson numbers."""
    if not text:
        return None
    numbers = set()
    for piece in text.split(','):
        a, _, b = piece.partition('-')
        numbers.update(range(int(a), int(b or a) + 1))
    return numbers


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('level', help='level folder under curriculum/, e.g. english/starter')
    ap.add_argument('--part', choices=['phonics', 'speaking'], default='phonics')
    ap.add_argument('--lessons', help='e.g. 1-6 (default: all lessons of the part)')
    ap.add_argument('--book', action='store_true', help='the whole level, with cover and contents')
    ap.add_argument('--out', help='output name (without extension) in the level dist/ folder')
    ap.add_argument('--check', action='store_true', help='only run the checks')
    args = ap.parse_args()

    level_dir = ROOT / args.level
    wordlists = yaml.safe_load((ROOT / 'wordlists.yaml').read_text(encoding='utf-8'))
    staged = (level_dir / 'lessons').is_dir()
    if staged:
        level = yaml.safe_load((level_dir / 'level.yaml').read_text(encoding='utf-8'))
        level['course'] = yaml.safe_load((level_dir.parent / 'course.yaml').read_text(encoding='utf-8'))
        lessons = load_lessons(level_dir)
        report = Report()
        numbers = [l['lesson'] for l in lessons]
        if numbers != list(range(1, len(lessons) + 1)):
            # Fine while a level is being written (a sample lesson), never in a book.
            (report.error if args.book else report.warn)(
                'level', f'lessons do not run 1..n without gaps: {numbers}')
        check_lessons(level, lessons, wordlists, report)
        check_no_arabic(lessons, report)
        phonics, speaking = [], []
    else:
        level, phonics, speaking = load(level_dir)
        report = check_level(level, phonics, wordlists)
        check_speaking(level, speaking, wordlists, report)
        check_no_arabic(phonics + speaking, report)
    for w in report.warnings:
        print('warning:', w)
    for e in report.errors:
        print('ERROR:', e)
    if report.errors:
        sys.exit(f'{len(report.errors)} error(s); nothing was built.')
    count = (f'{len(lessons)} lessons' if staged
             else f'{len(phonics)} phonics + {len(speaking)} speaking lessons')
    print(f'checks passed ({count}, {len(report.warnings)} warnings)')
    if args.check:
        return

    wanted = None if args.book else parse_range(args.lessons)
    if staged:
        selected = [l for l in lessons if not wanted or l['lesson'] in wanted]
    elif args.book:
        selected = phonics + speaking
    else:
        pool = phonics if args.part == 'phonics' else speaking
        selected = [l for l in pool if not wanted or l['lesson'] in wanted]
    out = level_dir / 'dist' / (args.out or 'book')
    out.parent.mkdir(exist_ok=True)
    if staged:
        render_html(level, [{'lesson': l} for l in selected], stage_contents(level, lessons),
                    out.with_suffix('.html'), args.book)
    else:
        build_html(level, phonics, speaking, selected, out.with_suffix('.html'), book=args.book)
    subprocess.run(['node', str(TOOLS / 'render.js'), str(out.with_suffix('.html')),
                    str(out.with_suffix('.pdf'))], check=True)


if __name__ == '__main__':
    main()
