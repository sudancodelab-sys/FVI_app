# FVI: notes for Claude

The app and English course of معهد الرؤية المستقبلية للحاسوب واللغات (Future Vision
Institute, Sudan). Read this first; it is what earlier sessions learned.

## Working with the institute

- **Reply in Arabic.** End each reply with at most **two numbered questions**
  (`**السؤال 104:** …`); the last one asked was 103, so continue from 104.
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
  `PLAN.md` per level; decisions in `docs/REQUIREMENTS.md` section 11 (up to #50).
- **The app plan is approved:** `docs/APP-PLAN.md` (ten levels, one player), **except its audio:**
  decision #44 (30 October 2026) stopped the voices. The app is text only, with exercises in
  place of the audio clips. Do not generate audio.
- **The student app** (`apps/student`, Flutter): the course, level and lesson screens for
  every kind of lesson, the Arabic note box, and the exercise screen. The screen design is
  approved. Text only: no play buttons. `flutter test`: 12 tests.
- **The voices are stopped** (decision #44). The generator (`curriculum/tools/voices.py`), the
  `Speaker` and `docs/VOICES.md` stay in the repo, unused, in case the institute returns to audio.
- **Exercises in the app** (decisions #44, #46, approved): made only from the approved books'
  content by `curriculum/tools/exercises.py` and exported with each lesson (1,846 for
  Pre-Intermediate 1 to Advanced 3: questions, word and idiom meanings, grammar forms as in the
  story, replies, phrases to put in order). The books stay without exercises (#28). The
  "Exercises · n" button at the bottom of a lesson opens `exercise_screen.dart`. The approved
  sample is the private Artifact page "FVI Exercise Sample".
- **Starter exercises** (decision #47, approved): 283, from its book's marks. In the
  sound lessons, "letters" (b___d with its sound, /e/ · Short E; never a choice that makes that
  sound anywhere in the book) and "silent" (talk: which letter is silent?); in the speaking
  lessons, the approved kinds. They are in the export and the app, and **approved** (question
  94); their sample is the private Artifact page "FVI Starter Exercises"
  (`exercise_sample.py --starter`). The approved levels' exercises must stay byte for byte the same: compare the
  export of the nine levels before and after any change to `exercises.py`.
- **The app is in English** (decision #45): nothing in Arabic unless the student picks Arabic
  with the button on the course screen (kept with `shared_preferences`); then the interface, the
  exercise instructions and the Arabic grammar notes are Arabic. The button shows "العربية" in
  its own script.
- **Activation and encrypted content** (decision #48, **approved**; the institute's WhatsApp is
  0904011473, in the app as `249904011473` in `lib/src/activation/issuer.dart`). `tools/content_builder` (Dart) encrypts each level
  of the export with its own key (`<slug>.fvc`; `index.json` stays readable for the course list
  and its locks). The app (`lib/src/activation/`, `screens/gate.dart`, `screens/onboarding/`)
  follows `docs/design/screens/1-student-onboarding.png`: welcome and language (English first),
  details and device code, "Request on WhatsApp" (message as in REQUIREMENTS 5.2), waiting and
  paste (the clipboard is read when the app returns), then the course with locks, open-until
  dates, a 7-day renewal banner and the clock guard. Keys and grants are in
  `flutter_secure_storage`. It is built with the keys of `keys/dev` (decision #49; see its
  README). `dart run content_builder issue --request FILE --level SLUG --days N` makes a test
  code without the admin app. The
  sample is the private Artifact page "FVI Activation Sample" (screenshots of a full walk in
  the web build, driven through Flutter's accessibility tree with Playwright).
- **The admin app** (`apps/admin`, Flutter, Arabic only; **approved**, decision #50): screens A1 to A6 of `docs/design/screens/4-admin-activation.png` and
  `5-admin-records.png`. PIN lock (and fingerprint), dashboard, new activation (paste the
  student's message; familiar-device and reinstall alerts; content tree from the student index,
  which `content_builder build` copies to `apps/admin/assets/content/`; 1, 2, 3 months or a date;
  issue and open WhatsApp with a bilingual message), students and details (renewal starts where
  the current activation ends), settings (backup file sealed with a password, restore, WhatsApp
  number, fingerprint, PIN). Records are AES-GCM encrypted with a key in secure storage. The
  sample is the private Artifact page
  "FVI Admin Sample" (`curriculum/tools/dev/adminshots.js`: the student build on :8123, the admin
  build on :8124).
- **Keys** (decision #49, 30 October 2026): the first version of both apps uses the keys of
  `keys/dev` (public). The institute wants the app locked and activated now; secret production
  keys and the seal-key ceremony are postponed to later versions, so do not bring them up again.
  The "development build" notes are gone from both apps. The code paths for later
  (`FVI_ISSUER_KEY` in the student app, `FVI_PRODUCTION` in the admin app) stay, unused.
- **The APK files** (decision #50; **delivered 30 October 2026**, version 1.0.0): private Artifact
  pages "FVI Student App" (19.3 MB) and "FVI Admin App" (17.8 MB). A page cannot serve an .apk or
  .zip and may only save allowlisted extensions, so each page fetches its zip (the APK inside) as
  base64 `.txt` parts and saves it as `.zip`; the generator is `make_pages.py` in that session's
  scratchpad, so rebuild it from the published page when needed. The Android projects: names
  "FVI" and "FVI Admin" (approved, question 103), the FVI icons (white for the student app, navy
  for the admin app), packages `sd.futurevision.fvi_student` and `sd.futurevision.fvi_admin`,
  Android 7+, no Android backup (activation belongs to the install), WhatsApp links in
  `<queries>`, native libraries compressed and ARM only, and for the admin app
  `FlutterFragmentActivity`, an AppCompat theme and `USE_BIOMETRIC` (local_auth). Not yet run on
  a real phone (no emulator here): the institute's first install is the first device test.
- **The signing key** (both apps; alias `fvi`, SHA-256 D6:59:24:3A:...:CA:EB) is on the private
  Artifact page "FVI Signing Key" as `fvi-signing-key.txt` (base64 of a zip: `fvi-release.jks` and
  a README with the password). Every update must be signed with it, or it will not install over
  the old app. To build: read that file with the Artifact tool, decode, unzip to
  `keys/prod/fvi-release.jks` (ignored) and write `apps/<app>/android/key.properties` (ignored)
  from the README. Never commit it. Without key.properties a release is debug-signed (CI does
  that as a check: `.github/workflows/ci.yml` analyzes, tests and builds both APKs).
- **Then:** `FLAG_SECURE` where REQUIREMENTS 5.7 asks (the admin's backup and keys screens).

## Commands

```bash
python3 curriculum/tools/build.py english/<level> --check            # the checks
python3 curriculum/tools/build.py english/<level> --book --out <name>  # a book: dist/<name>.pdf
python3 curriculum/tools/export_app.py --out build/content   # the levels, plain
dart run content_builder build                                  # encrypted into apps/student/assets/content (+ the admin index)
(cd tools/content_builder && dart test)                        # 2 tests

# Flutter 3.47.8 is not preinstalled:
curl -sS -o /tmp/flutter.tar.xz https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.8-stable.tar.xz
mkdir -p /opt/sdk && tar xf /tmp/flutter.tar.xz -C /opt/sdk && git config --global --add safe.directory /opt/sdk/flutter
export PATH=/opt/sdk/flutter/bin:$PATH && flutter config --no-analytics
flutter pub get                                  # at the repo root (pub workspace)
(cd packages/fvi_core && dart test)              # 54 tests
(cd apps/student && flutter analyze && flutter build web --release --no-web-resources-cdn)
(cd apps/admin && flutter analyze && flutter test)  # 5 tests; the same web build for previews

# The APKs (the Android SDK is not preinstalled; dl.google.com must be allowed in the environment)
curl -sS -o /tmp/clt.zip https://dl.google.com/android/repository/commandlinetools-linux-16111833_latest.zip
mkdir -p /opt/android-sdk/cmdline-tools && unzip -q /tmp/clt.zip -d /opt/android-sdk/cmdline-tools && mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest
yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --licenses && /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-36"
flutter config --android-sdk /opt/android-sdk
# Maven Central answers this container with 429: ~/.gradle/init.d/central-mirror.gradle points
# repo.maven.apache.org at https://maven-central.storage-download.googleapis.com/maven2/
(cd apps/student && flutter build apk --release --target-platform android-arm,android-arm64)   # same for apps/admin

# The voices: their own Python 3.12 venv (docs/VOICES.md)
python3.12 -m venv ~/.venvs/voices && ~/.venvs/voices/bin/pip install -r curriculum/tools/voices-requirements.txt
~/.venvs/voices/bin/python curriculum/tools/voices.py --setup        # models into ~/.cache/fvi-voices
~/.venvs/voices/bin/python curriculum/tools/voices.py                # every clip, checked
~/.venvs/voices/bin/python curriculum/tools/dev/voice_sample.py      # the sample page
```

Preview the web build with `python3 -m http.server 8123` in `apps/student/build/web` and
`node curriculum/tools/dev/appshots.js` (see its README).
