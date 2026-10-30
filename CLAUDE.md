# FVI: notes for Claude

The app and English course of معهد الرؤية المستقبلية للحاسوب واللغات (Future Vision
Institute, Sudan). Read this first; it is what earlier sessions learned.

## Working with the institute

- **Reply in Arabic.** End each reply with at most **two numbered questions**
  (`**السؤال 85:** …`); the last one asked was 84, so continue from 85.
- **Plan and sample first.** For every new piece of work (a level, a design, the voices),
  send a plan and a sample, and go on only after the institute approves both.
- **Never change what is approved** unless asked. New behavior goes behind an option (a
  level setting such as `split_boxes`, `idioms`, `arabic_notes`), and after any change to
  shared code, rebuild the approved books and compare: `cmp` the new `dist/*.html` with the
  committed one, or `curriculum/tools/dev/pagetext.js` page by page.
- **Files to download go on a private Artifact page,** not a GitHub link: the institute asked
  for "a complete downloadable file not from GitHub". Template: `docs/download-page/`. Each
  book's page is an Artifact titled "<Level> Book" (find them with the Artifact list).
- Commit and push to the session's branch with the session's commit trailer. The repo is
  public: never commit production keys.

## Curriculum rules (curriculum/GUIDELINES.md has the full list)

- American spelling and pronunciation. **No Arabic on the sheets** (the books).
- No exercises, and no half-empty pages (lessons run on; `curriculum/tools/dev/fill.js`).
- Pre-Intermediate levels: 4 stories, 4 topics, 4 conversations. Intermediate: 5 stories,
  4 topics (2 everyday, 2 science), 4 conversations. Advanced: 5 stories, 4 topics (news,
  podcast, science, everyday), 4 conversations including an interview.
- From Advanced 2 on, every lesson teaches idioms, proverbs and phrases (`idioms: true`):
  3 in a story (one proverb), 2 elsewhere, marked `((like this))` in the text.
- **Arabic grammar notes**: in the app only, for Pre-Intermediate 1 to 4
  (`arabic_notes: true`), in `learn.ar` of each grammar lesson: a summary and points of
  `[Arabic, English example]`. Never attach an English word to an Arabic letter (و + you):
  it shows in the wrong order. All 16 are written and approved.
- YAML traps: quote any value with a comma (`meaning: "a long, narrow room"` or the text after
  the comma is lost), `?`, `:`, a leading `[`, and words such as yes, no, on, true.
  `build.py --check` catches these.

## Where things are (30 October 2026)

- **All ten books are approved:** Starter 36 pages, Pre-Intermediate 1-4 21/22/23/23,
  Intermediate 1-2 28/29, Advanced 1-3 31/36/37. Source in `curriculum/english/<level>/`;
  `PLAN.md` per level; decisions in `docs/REQUIREMENTS.md` section 11 (up to #42).
- **The app plan is approved:** `docs/APP-PLAN.md` (ten levels, natural voices with a man and a
  woman in conversations, a speed per level, every clip tied to its text, one player).
- **The student app** (`apps/student`, Flutter): the course, level and lesson screens for
  every kind of lesson, the Arabic note box, the play buttons and the one `Speaker`. The
  screen design is approved. No audio yet.
- **Next: the voices.** Everything is in `docs/VOICES.md` and `curriculum/voices.yaml`. It
  was blocked by the network (`huggingface.co`); check it first.
- **After the voices**, the rest of the original plan (`docs/REQUIREMENTS.md` section 9): a
  content builder that encrypts each level (and its audio) with `packages/fvi_core`, the
  activation screens (`docs/design/screens/1-student-onboarding.png`), the admin app, the APK
  build on GitHub Actions, and tests for the `Speaker`.

## Commands

```bash
python3 curriculum/tools/build.py english/<level> --check            # the checks
python3 curriculum/tools/build.py english/<level> --book --out <name>  # a book: dist/<name>.pdf
python3 curriculum/tools/export_app.py --out apps/student/assets/content  # the app's content

# Flutter 3.47.8 is not preinstalled:
curl -sS -o /tmp/flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.8-stable.tar.xz
mkdir -p /opt/sdk && tar xf /tmp/flutter.tar.xz -C /opt/sdk && git config --global --add safe.directory /opt/sdk/flutter
export PATH=/opt/sdk/flutter/bin:$PATH && flutter config --no-analytics
flutter pub get                                  # at the repo root (pub workspace)
(cd packages/fvi_core && dart test)              # 54 tests
(cd apps/student && flutter analyze && flutter build web --release --no-web-resources-cdn)
```

Preview the web build with `python3 -m http.server 8123` in `apps/student/build/web` and
`node curriculum/tools/dev/appshots.js` (see its README).
