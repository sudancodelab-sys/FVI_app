#!/usr/bin/env python3
"""The exercise samples for the institute (decision #44: exercises in place of audio).

Writes one page with the exercises of a few lessons, made by
curriculum/tools/exercises.py exactly as the app has them, to try as a
student or to review with their answers:

    python3 curriculum/tools/dev/exercise_sample.py [--starter] [--out build/exercise-sample]

The page without --starter is the approved sample, "FVI Exercise Sample";
with it, "FVI Starter Exercises".
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

# (level, part of the level, lesson number)
LESSONS = [('pre-intermediate-1', 'lessons', 1), ('pre-intermediate-1', 'lessons', 2),
           ('pre-intermediate-1', 'lessons', 3), ('advanced-2', 'lessons', 1)]
STARTER = [('starter', 'phonics', 3), ('starter', 'phonics', 10), ('starter', 'phonics', 12),
           ('starter', 'speaking', 1)]
LEVELS = ['pre-intermediate-1', 'pre-intermediate-2', 'pre-intermediate-3', 'pre-intermediate-4',
          'intermediate-1', 'intermediate-2', 'advanced-1', 'advanced-2', 'advanced-3']

# The note to the institute at the top of the page (Arabic: it is not part of the app).
INTRO = '''  <section class="intro" dir="rtl" lang="ar">
    <div>
      <div class="eyebrow">معهد الرؤية المستقبلية · تطبيق الطالب</div>
      <h1>عيّنة التمارين<span>كلها مأخوذة من نصوص الكتب المعتمدة، بلا نص جديد</span></h1>
    </div>
    <ul class="facts"><!--FACTS--></ul>
    <ol class="ask">
      <li><b>1</b><span>هل أنواع التمارين مناسبة: أسئلة الفهم، ومعاني الكلمات والتعابير، وإكمال الجملة كما في القصة، والرد المناسب، وترتيب الكلمات؟</span></li>
      <li><b>2</b><span>لغة التطبيق الإنجليزية، ولا تظهر العربية إلا إذا اختارها الطالب لغةً للتطبيق. جرّبوا زر <bdi>English | العربية</bdi> أسفل هذه البطاقة.</span></li>
    </ol>
    <p class="note">هذه البطاقة رسالة إليكم وليست من التطبيق. في التطبيق يكون زر التمارين في آخر كل درس، والإجابات هنا لا تُحفظ.</p>
  </section>
'''
INTRO_STARTER = '''  <section class="intro" dir="rtl" lang="ar">
    <div>
      <div class="eyebrow">معهد الرؤية المستقبلية · تطبيق الطالب</div>
      <h1>عيّنة تمارين <bdi>Starter</bdi><span>من دروس الصوتيات والمخاطبة في الكتاب المعتمد، بلا نص جديد</span></h1>
    </div>
    <ul class="facts"><!--FACTS--></ul>
    <ol class="ask">
      <li><b>1</b><span>تمرينان جديدان لدروس الصوتيات: «أكمل الكلمة» بالحروف التي تصنع الصوت المكتوب فوقها، و«أيّ حرف لا يُنطق؟». هل هما مناسبان؟</span></li>
      <li><b>2</b><span>دروس المخاطبة الستة فيها التمارين التي اعتمدتموها: معاني الكلمات، والرد المناسب، وترتيب الكلمات.</span></li>
    </ol>
    <p class="note">التطبيق بلا صوت، فالصوت مكتوب برمزه كما في الكتاب (مثل <bdi>/e/ · Short E</bdi>)، ولا يُعرض بين الاختيارات حرف يصنع الصوت نفسه في الكتاب. الدرس الأول (الحروف الإنجليزية) بلا تمارين. هذه البطاقة رسالة إليكم وليست من التطبيق.</p>
  </section>
'''


def _count(n, few, many):
    """An Arabic count: 3 to 10 take the plural, 11 to 99 the singular."""
    return f'{n} {few if 3 <= n % 100 <= 10 else many}'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--starter', action='store_true', help='the Starter sample')
    ap.add_argument('--out', default=str(REPO / 'build' / 'exercise-sample'))
    args = ap.parse_args()
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    levels = {slug: export_app.export_level(f'english/{slug}') for slug in (['starter'] if args.starter else LEVELS)}
    sample = []
    for slug, part, number in STARTER if args.starter else LESSONS:
        level = levels[slug]
        lesson = next(les for les in level[part] if les['lesson'] == number)
        sample.append({'level': level['name'], 'number': number, 'kind': lesson.get('kind', 'phonics'),
                       'title': lesson['title'], 'exercises': exercises.lesson_exercises(level, lesson)})

    total = collections.Counter(e['kind'] for level in levels.values()
                                for part in ('lessons', 'phonics', 'speaking') for les in level.get(part, [])
                                for e in exercises.lesson_exercises(level, les))
    shown = sum(len(s['exercises']) for s in sample)
    facts = [_count(len(sample), 'دروس', 'درساً'), f'{shown} تمريناً في العيّنة',
             f'{sum(total.values()):,} تمريناً في '.replace(',', '٬')
             + ('مستوى <bdi>Starter</bdi>' if args.starter else 'المستويات التسعة')]
    title, intro, name = (('FVI Starter Exercises', INTRO_STARTER, 'starter-exercise-sample.html') if args.starter
                          else ('FVI Exercise Sample', INTRO, 'exercise-sample.html'))
    page = PAGE.read_text(encoding='utf-8')
    page = page.replace('<!--TITLE-->', title).replace('<!--INTRO-->\n', intro)
    page = page.replace('<!--FACTS-->', ''.join(f'<li>{f}</li>' for f in facts))
    page = page.replace('/*DATA*/[]', json.dumps(sample, ensure_ascii=False).replace('</', '<\\/'))
    (out / name).write_text(page, encoding='utf-8')
    print(f'{out / name}: {shown} exercises in {len(sample)} lessons; all: {dict(total)}')


if __name__ == '__main__':
    main()
