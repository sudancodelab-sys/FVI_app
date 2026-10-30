#!/usr/bin/env python3
"""The exercise sample for the institute (decision #44: exercises in place of audio).

Writes one page with the exercises of a few lessons, made by
curriculum/tools/exercises.py exactly as the app will have them, to try as a
student or to review with their answers:

    python3 curriculum/tools/dev/exercise_sample.py [--out build/exercise-sample]
"""

import argparse
import collections
import json
import sys
from pathlib import Path

DEV = Path(__file__).resolve().parent
sys.path.insert(0, str(DEV.parent))
import exercises  # noqa: E402
import export_app  # noqa: E402

PAGE = DEV / 'exercise-sample.html'
REPO = DEV.parents[2]

# The first unit of Pre-Intermediate 1 (a story, a topic, a conversation), and
# a story of Advanced 2 for the idioms.
LESSONS = [('pre-intermediate-1', 1), ('pre-intermediate-1', 2), ('pre-intermediate-1', 3), ('advanced-2', 1)]
LEVELS = ['pre-intermediate-1', 'pre-intermediate-2', 'pre-intermediate-3', 'pre-intermediate-4',
          'intermediate-1', 'intermediate-2', 'advanced-1', 'advanced-2', 'advanced-3']


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default=str(REPO / 'build' / 'exercise-sample'))
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    levels = {slug: export_app.export_level(f'english/{slug}') for slug in LEVELS}
    sample = []
    for slug, number in LESSONS:
        level = levels[slug]
        lesson = next(les for les in level['lessons'] if les['lesson'] == number)
        sample.append({'level': level['name'], 'number': number, 'kind': lesson['kind'], 'title': lesson['title'],
                       'exercises': exercises.lesson_exercises(level, lesson)})

    total = collections.Counter(e['kind'] for level in levels.values() for les in level['lessons']
                                for e in exercises.lesson_exercises(level, les))
    shown = sum(len(s['exercises']) for s in sample)
    facts = [f'{len(sample)} دروس', f'{shown} تمريناً في العيّنة',
             f'{sum(total.values()):,} تمريناً في المستويات التسعة'.replace(',', '٬')]
    page = PAGE.read_text(encoding='utf-8')
    page = page.replace('<!--FACTS-->', ''.join(f'<li>{f}</li>' for f in facts))
    page = page.replace('/*DATA*/[]', json.dumps(sample, ensure_ascii=False).replace('</', '<\\/'))
    (out / 'exercise-sample.html').write_text(page, encoding='utf-8')
    print(f'{out / "exercise-sample.html"}: {shown} exercises in {len(sample)} lessons; '
          f'all levels: {dict(total)}')


if __name__ == '__main__':
    main()
