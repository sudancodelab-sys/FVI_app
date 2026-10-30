# FVI — تطبيق معهد الرؤية المستقبلية

تطبيق مذاكرة ومراجعة لطلاب **معهد الرؤية المستقبلية للحاسوب واللغات** (Future Vision Institute). يعمل دون إنترنت، ولا يعمل إلا بعد تفعيل يصدر من تطبيق الإدارة.

- [وثيقة المتطلبات](docs/REQUIREMENTS.md): كل ما اتفقنا عليه، والتصميم الأمني، والتقنيات وأسباب اختيارها.
- [تصاميم الشاشات](docs/design/screens): تطبيق الطالب وتطبيق الإدارة.

## هيكل المستودع

| المجلد | المحتوى |
|---|---|
| `packages/fvi_core` | الأساس الأمني المشترك: شجرة مفاتيح المحتوى، وطلب التفعيل، وكود التفعيل، وتشفير المحتوى، وحماية الساعة |
| `curriculum` | منهج اللغة الإنجليزية: دليل المنهج، ومحتوى المستويات (YAML)، وأداة تفحص المحتوى وتُخرجه PDF |
| `docs` | الوثائق والتصاميم |

## التشغيل محلياً

يحتاج Flutter 3.47 أو أحدث، أو Dart 3.13 أو أحدث.

```bash
dart pub get
cd packages/fvi_core && dart test
```

الحالة:
- الخطوة 1 من خطة العمل (الأساس المشترك) مكتملة ومختبرة.
- مستوى Starter من منهج الإنجليزية معتمد من المعهد: 20 درس صوتيات و6 دروس مخاطبة، في كتاب من 36 صفحة.
- مستوى Pre-Intermediate 1 معتمد من المعهد: 12 درساً في 4 وحدات، في كتاب من 21 صفحة.
- مستوى Pre-Intermediate 2 معتمد من المعهد: 12 درساً في 4 وحدات، في كتاب من 22 صفحة.
- مستوى Pre-Intermediate 3 معتمد من المعهد: 12 درساً في 4 وحدات، في كتاب من 23 صفحة.
- مستوى Pre-Intermediate 4 معتمد من المعهد: 12 درساً في 4 وحدات، في كتاب من 23 صفحة. وبه تكتمل مرحلة ما قبل المتوسط.
- مستوى Intermediate 1 معتمد من المعهد: 13 درساً في 5 وحدات، منها درسان علميان، في كتاب من 28 صفحة.
- مستوى Intermediate 2 معتمد من المعهد: 13 درساً في 5 وحدات، في كتاب من 29 صفحة. وبه تكتمل المرحلة المتوسطة.
- مستوى Advanced 1 معتمد من المعهد: 13 درساً في 5 وحدات، منها خبر صحفي وبودكاست، في كتاب من 31 صفحة.
- مستوى Advanced 2 معتمد من المعهد: 13 درساً في 5 وحدات، و31 تعبيراً ومثلاً، في كتاب من 36 صفحة.
- مستوى Advanced 3 معتمد من المعهد: 13 درساً في 5 وحدات، و31 تعبيراً ومثلاً، في كتاب من 37 صفحة. وبه تكتمل كتب المنهج العشرة.
- تطبيق الطالب (`apps/student`): شاشات المستويات والدروس معتمدة، والشرح العربي لقواعد Pre-Intermediate 1 إلى 4 مكتوب. الأصوات هي الخطوة التالية (`docs/VOICES.md`).

لبناء كتاب المستوى (يحتاج Python مع PyYAML وJinja2 وcmudict، وNode مع Playwright):

```bash
python3 curriculum/tools/build.py english/starter --book --out starter-book
python3 curriculum/tools/build.py english/pre-intermediate-1 --book --out pi1-book
python3 curriculum/tools/build.py english/pre-intermediate-2 --book --out pi2-book
python3 curriculum/tools/build.py english/pre-intermediate-3 --book --out pi3-book
python3 curriculum/tools/build.py english/pre-intermediate-4 --book --out pi4-book
python3 curriculum/tools/build.py english/intermediate-1 --book --out int1-book
python3 curriculum/tools/build.py english/intermediate-2 --book --out int2-book
python3 curriculum/tools/build.py english/advanced-1 --book --out adv1-book
python3 curriculum/tools/build.py english/advanced-2 --book --out adv2-book
python3 curriculum/tools/build.py english/advanced-3 --book --out adv3-book
```
