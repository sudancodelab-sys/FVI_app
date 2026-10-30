#!/usr/bin/env python3
"""The exercises of the student app (decision #44 in docs/REQUIREMENTS.md).

The books have no exercises (#28); the app has them in place of audio. Every
exercise is made from what a lesson of the approved books already says, so
there is no new text to approve:

    question  a comprehension question; its answer among the answers to the
              lesson's other questions
    meaning   a new word, idiom or phrase; its meaning among the meanings of
              the others
    form      a sentence of the story with a marked grammar form taken out;
              that form among the lesson's other forms
    reply     a useful phrase of a conversation; its reply among the others
    order     a useful phrase in jumbled words, to put back in order

A choice is never one that could also be right: the same words, the same
first sentence ("Yes, it is." for "Yes, it is. It's big."), or the same form
with "not" ("isn't" for "is", where only the story tells them apart). The
choices are shuffled with a seed from the lesson, so a lesson's exercises are
the same every time.

    python3 curriculum/tools/exercises.py english/pre-intermediate-1 [--lesson 1]
"""

import argparse
import json
import random
import re
import sys
from pathlib import Path

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import build  # noqa: E402

CHOICES = 4    # the right one and three others
FORMS = 6      # form exercises in a lesson at most
ORDER_WORDS = (3, 10)  # a phrase to put in order has this many words

_MARK = re.compile(r'\[([^\]]+)\]')
_SENTENCE = re.compile(r'(?<=[.!?…])(?<!Mr\.)(?<!Mrs\.)(?<!Ms\.)(?<!Dr\.)["”]?\s+(?=["“]?[A-Z])')


def _plain(text):
    return ' '.join(build.plain(text).split())


def _key(text):
    """For comparing: lower case, letters and digits only."""
    return ' '.join(re.findall(r"[a-z0-9']+", text.lower().replace('’', "'")))


def _first_sentence(text):
    return _SENTENCE.split(text, 1)[0]


def _lower(form):
    """'Is' -> 'is', but 'I'm' stays."""
    return form if re.match(r"I\b", form) else form[:1].lower() + form[1:]


def _positive(form):
    """'isn't' -> 'is', 'was not' -> 'was': a form and its negative compare the same."""
    return re.sub(r"\s*\bnot\b|n't\b", '', _key(form)).replace('ca ', 'can ').strip()


def _choice(kind, prompt, right, others, rng, fewest=2, **extra):
    """An exercise with the right answer and up to three others, shuffled; None with fewer than `fewest` others."""
    picked, seen = [], {_key(right)}
    for o in others:
        if _key(o) not in seen and len(picked) < CHOICES - 1:
            picked.append(o)
            seen.add(_key(o))
    if len(picked) < fewest:
        return None
    choices = [right, *picked]
    rng.shuffle(choices)
    return {'type': 'choice', 'kind': kind, 'prompt': prompt, 'choices': choices,
            'answer': choices.index(right), **extra}


def _questions(lesson, rng):
    pairs = [(_plain(qa['question']['t']), _plain(qa['answer']['t'])) for qa in lesson.get('questions') or []]
    out = []
    for i, (q, a) in enumerate(pairs):
        first, asked = _key(_first_sentence(a)), set(_key(q).split())
        # Not the answer to the same question asked again ("Is Omar nervous now?" after "Is Omar nervous?").
        others = [(oq, oa) for j, (oq, oa) in enumerate(pairs)
                  if j != i and _key(_first_sentence(oa)) != first and _key(oa) != _key(a)
                  and not (asked <= set(_key(oq).split()) or set(_key(oq).split()) <= asked)]
        rng.shuffle(others)
        # Answers to questions of the same kind first: a place for "Where", a person for "Who".
        word = q.split()[0].lower()
        others.sort(key=lambda o: o[0].split()[0].lower() != word)
        ex = _choice('question', q, a, [oa for _, oa in others], rng)
        if ex:
            out.append(ex)
    return out


def _meanings(kind, entries, pool, rng):
    """entries: (shown, meaning, example) of the lesson; pool: meanings of the level, for a lesson with few."""
    out = []
    for i, (shown, meaning, example) in enumerate(entries):
        others = [m for j, (_, m, _) in enumerate(entries) if j != i]
        rng.shuffle(others)
        rest = [m for m in pool if m not in others and m != meaning]
        rng.shuffle(rest)
        ex = _choice(kind, shown, meaning, others + rest, rng, **({'example': example} if example else {}))
        if ex:
            out.append(ex)
    return out


def _forms(lesson, rng):
    paragraphs = [p['t'] for p in lesson.get('story') or []]
    sentences = [s for p in paragraphs for s in _SENTENCE.split(p)]
    found = [(s, m) for s in sentences for m in [_MARK.findall(s)] if len(m) == 1]
    forms = sorted({_lower(m[0]) for _, m in found})
    if len(forms) < 3:
        return []
    step = max(1, len(found) // FORMS)
    out = []
    for s, (form,) in found[::step][:FORMS]:
        before, after = s.split(f'[{form}]', 1)
        others = [f for f in forms if _positive(f) != _positive(form) and f != _lower(form)]
        rng.shuffle(others)
        if not before.strip():  # the form starts the sentence
            others = [f[:1].upper() + f[1:] for f in others]
        ex = _choice('form', '', form, others, rng, fewest=1, before=_plain(before), after=_plain(after))
        if ex:
            out.append(ex)
    return out


def _replies(lesson, rng):
    phrases = [p for p in lesson.get('phrases') or [] if p.get('reply')]
    out = []
    for i, p in enumerate(phrases):
        line = ' '.join(_plain(x['t']) for x in p['lines'])
        others = [_plain(o['reply']['t']) for j, o in enumerate(phrases) if j != i]
        rng.shuffle(others)
        ex = _choice('reply', line, _plain(p['reply']['t']), others, rng)
        if ex:
            out.append(ex)
    return out


def _orders(lesson, rng):
    out = []
    for p in lesson.get('phrases') or []:
        for line in [part.strip() for x in p['lines'] for part in _plain(x['t']).split('·')]:
            words = line.split()
            if not ORDER_WORDS[0] <= len(words) <= ORDER_WORDS[1]:
                continue
            jumbled = words[:]
            while jumbled == words:
                rng.shuffle(jumbled)
            out.append({'type': 'order', 'kind': 'order', 'prompt': p.get('title', ''), 'words': jumbled,
                        'answer': line})
    return out


def lesson_exercises(level, lesson):
    """The exercises of one lesson of an exported level (export_app.export_level)."""
    rng = random.Random(f'{level["slug"]}/{lesson["lesson"]}')
    words = [(w['word'], w['meaning'], None) for w in lesson.get('words') or []]
    idioms = [(i['expr'], i['meaning'], i.get('example')) for i in lesson.get('idioms') or []]
    level_words = [w['meaning'] for les in level['lessons'] for w in les.get('words') or []]
    level_idioms = [i['meaning'] for les in level['lessons'] for i in les.get('idioms') or []]
    return [*_questions(lesson, rng), *_meanings('meaning', words, level_words, rng), *_forms(lesson, rng),
            *_meanings('idiom', idioms, level_idioms, rng), *_replies(lesson, rng), *_orders(lesson, rng)]


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('level', help='e.g. english/pre-intermediate-1')
    ap.add_argument('--lesson', type=int, help='one lesson (default: every lesson)')
    args = ap.parse_args()
    import export_app
    level = export_app.export_level(args.level)
    for lesson in level['lessons']:
        if args.lesson in (None, lesson['lesson']):
            print(json.dumps({'lesson': lesson['lesson'], 'title': lesson['title'],
                              'exercises': lesson_exercises(level, lesson)}, ensure_ascii=False, indent=1))


if __name__ == '__main__':
    main()
