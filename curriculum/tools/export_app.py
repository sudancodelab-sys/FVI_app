#!/usr/bin/env python3
"""Export the approved levels for the student app.

Each level becomes one JSON file. The lessons keep the text and markup of
the books ([grammar], ((idioms)), c[a]t, mak{e}); every text that gets
audio becomes an item {t, a, v}:

    t  the text as shown in the app
    a  the audio id, fixed by its place in the lesson,
       e.g. pre-intermediate-1/04/story.2
    v  who says it: a member of the cast, or a role (narrator, teacher,
       question, answer, anchor)

The voice generator reads the same files, so a clip can only ever be made
for, and played next to, the text it belongs to.

    python3 curriculum/tools/export_app.py [english/<level> ...] [--out DIR]
"""

import argparse
import json
import sys
from pathlib import Path

import yaml

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import build  # noqa: E402  (the checks and loaders of the books)
import exercises  # noqa: E402  (the exercises of a lesson, decision #44)

ROOT = build.ROOT
FORMAT = 1

# Who reads the parts that are not dialogue, by kind of lesson.
_READER = {'story': 'narrator', 'topic': 'narrator', 'science': 'narrator',
           'news': 'anchor', 'podcast': 'narrator', 'conversation': 'narrator'}


class Ids:
    """Hands out audio ids and refuses to hand out the same one twice."""

    def __init__(self, prefix):
        self.prefix = prefix
        self.seen = set()

    def item(self, path, text, voice, say=None):
        aid = f'{self.prefix}/{path}'
        if aid in self.seen:
            raise SystemExit(f'duplicate audio id {aid}')
        self.seen.add(aid)
        out = {'t': text, 'a': aid, 'v': voice}
        if say is not None and say != build.plain(text):
            out['say'] = say
        return out


def _qa(ids, path, pair):
    q, a = pair
    return {'question': ids.item(f'{path}.q', q, 'question'), 'answer': ids.item(f'{path}.a', a, 'answer')}


def _sentence(text):
    return text[:1].upper() + text[1:] + ('' if text.endswith(('.', '!', '?')) else '.')


def _words(ids, words):
    return [dict(w, **ids.item(f'words.{i}', w['word'], 'teacher',
                               say=f'{w["word"]}. {_sentence(w["meaning"])}'))
            for i, w in enumerate(words)]


def _phrases(ids, phrases, voice='teacher'):
    out = []
    for i, ph in enumerate(phrases):
        box = {'title': ph['title'],
               'lines': [ids.item(f'phrases.{i}.{j}', line, voice) for j, line in enumerate(ph['lines'])]}
        if ph.get('reply'):
            box['reply'] = ids.item(f'phrases.{i}.reply', ph['reply'], voice)
        out.append(box)
    return out


def export_lesson(slug, lesson):
    """A lesson of the levels after Starter."""
    kind = lesson['kind']
    ids = Ids(f'{slug}/{lesson["lesson"]:02d}')
    reader = lesson.get('reader', _READER[kind])
    out = {k: lesson[k] for k in ('lesson', 'unit', 'kind', 'title', 'subtitle', 'icon', 'goals')}
    if kind == 'story':
        out['story'] = [ids.item(f'story.{i}', p, reader) for i, p in enumerate(lesson['story'])]
        pov = lesson['pov']
        out['pov'] = {'intro': pov['intro'], 'speaker': pov['speaker'],
                      'text': [ids.item(f'pov.{i}', p, pov['speaker']) for i, p in enumerate(pov['text'])]}
        learn = dict(lesson['learn'])
        learn['ask'] = _qa(ids, 'ask', learn['ask'])
        out['learn'] = learn
    elif kind in ('topic', 'science', 'news'):
        if kind == 'news':
            for k in ('paper', 'date', 'byline'):
                out[k] = lesson[k]
            out['headline'] = ids.item('headline', lesson['headline'], reader)
            out['standfirst'] = ids.item('standfirst', lesson['standfirst'], reader)
            if lesson.get('quote'):
                out['quote'] = lesson['quote']
        out['text'] = [ids.item(f'text.{i}', p, reader) for i, p in enumerate(lesson['text'])]
        out['facts'] = lesson.get('facts', [])
        if lesson.get('did_you_know'):
            out['did_you_know'] = ids.item('did_you_know', lesson['did_you_know'], reader)
    elif kind == 'podcast':
        for k in ('show', 'episode', 'scene'):
            out[k] = lesson[k]
        out['before'] = [ids.item(f'before.{i}', q, reader) for i, q in enumerate(lesson['before'])]
        out['script'] = [dict(ids.item(f'script.{i}', text, who), time=time, who=who)
                         for i, (time, who, text) in enumerate(lesson['script'])]
    elif kind == 'conversation':
        out['scene'] = lesson['scene']
        out['conversation'] = [dict(ids.item(f'conversation.{i}', text, who), who=who)
                               for i, (who, text) in enumerate(lesson['conversation'])]
        out['phrases'] = _phrases(ids, lesson['phrases'])
    if 'questions' in lesson:
        out['questions'] = [_qa(ids, f'questions.{i}', pair) for i, pair in enumerate(lesson['questions'])]
    if lesson.get('idioms'):
        # Said as the plan has it: the expression, its meaning, then the example.
        out['idioms'] = [dict(e, **ids.item(f'idioms.{i}', e['expr'], 'teacher',
                                            say=f'{_sentence(e["expr"])} {_sentence(e["meaning"])} {e["example"]}'))
                         for i, e in enumerate(lesson['idioms'])]
    out['words'] = _words(ids, lesson['words'])
    return out


def _examples(ids, path, value):
    """Starter: every example word gets its own clip, read by the teacher."""
    if isinstance(value, dict):
        out = {}
        for k, v in value.items():
            if k in ('examples', 'note_examples') and isinstance(v, list):
                out[k] = [ids.item(f'{path}{k}.{i}', w, 'teacher') for i, w in enumerate(v)]
            elif k == 'word' and isinstance(v, str):
                out[k] = ids.item(f'{path}word', v, 'teacher')
            else:
                out[k] = _examples(ids, f'{path}{k}.', v)
        return out
    if isinstance(value, list):
        return [_examples(ids, f'{path}{i}.', v) for i, v in enumerate(value)]
    return value


def export_phonics(slug, lesson):
    ids = Ids(f'{slug}/p{lesson["lesson"]:02d}')
    # build.normalize() copies a one-letter lesson's sounds, rules, silent
    # and teams into parts[0]; the app reads parts only.
    lesson = {k: v for k, v in lesson.items()
              if 'parts' not in lesson or k not in ('sounds', 'rules', 'silent', 'teams')}
    return _examples(ids, '', lesson)


def export_speaking(slug, lesson):
    ids = Ids(f'{slug}/s{lesson["lesson"]:02d}')
    out = {k: lesson[k] for k in ('lesson', 'title', 'subtitle', 'icon', 'goals', 'scene')}
    out['kind'] = 'speaking'
    out['conversation'] = [dict(ids.item(f'conversation.{i}', text, who), who=who)
                           for i, (who, text) in enumerate(lesson['conversation'])]
    out['phrases'] = _phrases(ids, lesson['phrases'])
    out['words'] = _words(ids, lesson['words'])
    return out


def export_level(level_path):
    """Checks a level as the books do, then returns its app file."""
    level_dir = ROOT / level_path
    slug = level_dir.name
    wordlists = yaml.safe_load((ROOT / 'wordlists.yaml').read_text(encoding='utf-8'))
    course = yaml.safe_load((level_dir.parent / 'course.yaml').read_text(encoding='utf-8'))
    staged = (level_dir / 'lessons').is_dir()
    report = build.Report()
    if staged:
        level = yaml.safe_load((level_dir / 'level.yaml').read_text(encoding='utf-8'))
        lessons = build.load_lessons(level_dir)
        if [l['lesson'] for l in lessons] != list(range(1, len(lessons) + 1)):
            report.error('level', 'lessons do not run 1..n without gaps')
        build.check_lessons(level, lessons, wordlists, report)
        build.check_no_arabic(lessons, report)
    else:
        level, phonics, speaking = build.load(level_dir)
        report = build.check_level(level, phonics, wordlists)
        build.check_speaking(level, speaking, wordlists, report)
        build.check_no_arabic(phonics + speaking, report)
    if report.errors:
        for e in report.errors:
            print('ERROR:', e)
        raise SystemExit(f'{level_path}: {len(report.errors)} error(s); nothing was exported.')

    order = [name for st in course['stages'] for name in st['levels']]
    out = {
        'format': FORMAT,
        'id': f'languages/english/{slug}',
        'slug': slug,
        'order': order.index(level['name']) + 1,
        'stage': level['stage'],
        **{k: level[k] for k in ('name', 'chip', 'cefr', 'tagline', 'subtitle') if k in level},
        'cast': level.get('cast', {}),
    }
    if staged:
        out['units'] = [{'unit': n, 'title': t} for n, t in sorted(level['units'].items())]
        out['lessons'] = [export_lesson(slug, l) for l in lessons]
        for lesson in out['lessons']:
            lesson['exercises'] = exercises.lesson_exercises(out, lesson)
    else:
        out['letter_order'] = level['letter_order']
        out['phonics'] = [export_phonics(slug, l) for l in phonics]
        out['speaking'] = [export_speaking(slug, l) for l in speaking]
    return out


def audio_items(value):
    """Every {t, a, v} item in an exported level, in reading order."""
    if isinstance(value, dict):
        if 'a' in value and 'v' in value and ('t' in value):
            yield value
        for v in value.values():
            if isinstance(v, (dict, list)):
                yield from audio_items(v)
    elif isinstance(value, list):
        for v in value:
            yield from audio_items(v)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('levels', nargs='*', help='e.g. english/pre-intermediate-1 (default: every level)')
    ap.add_argument('--out', default=str(ROOT.parent / 'build' / 'content'),
                    help='output folder (default: build/content at the repository root)')
    args = ap.parse_args()
    course = yaml.safe_load((ROOT / 'english' / 'course.yaml').read_text(encoding='utf-8'))
    slugs = {name: name.lower().replace(' ', '-') for st in course['stages'] for name in st['levels']}
    levels = args.levels or [f'english/{s}' for s in slugs.values()]
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    index = []
    for lv in levels:
        data = export_level(lv)
        path = out_dir / f'{data["slug"]}.json'
        path.write_text(json.dumps(data, ensure_ascii=False, indent=1), encoding='utf-8')
        index.append({k: data[k] for k in ('slug', 'id', 'order', 'name', 'cefr', 'stage')}
                     | {'lessons': len(data.get('lessons', [])) or len(data['phonics']) + len(data['speaking'])})
        items = list(audio_items(data))
        drills = sum(len(lesson['exercises']) for lesson in data.get('lessons', []))
        print(f'{path.relative_to(out_dir.parent.parent) if out_dir.is_relative_to(ROOT.parent) else path}: '
              f'{len(data.get("lessons", data.get("phonics", [])))} lessons, {drills} exercises, {len(items)} audio items')
    if not args.levels:
        index.sort(key=lambda l: l['order'])
        (out_dir / 'index.json').write_text(json.dumps(index, ensure_ascii=False, indent=1), encoding='utf-8')


if __name__ == '__main__':
    main()
