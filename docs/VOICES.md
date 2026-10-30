# Voices: what to build next

The plan the institute approved is `docs/APP-PLAN.md` (Arabic). This is the
technical side, written so a new session can start at once. The voices
themselves are in `curriculum/voices.yaml`.

## Status (30 October 2026)

- Not started: the voice generator and the voice sample.
- **Blocked by the network:** `huggingface.co`, where Kokoro's model and voices are, was refused
  (403) in the session that wrote this, although the institute had allowed it in the
  environment settings. Check first:

      curl -sS -o /dev/null -w "%{http_code}\n" https://huggingface.co/api/models/hexgrad/Kokoro-82M

  Downloads also go through `cdn-lfs.hf.co` / `cas-bridge.xethub.hf.co` (allow `*.hf.co`).
  `pypi.org` is open; `github.com` and `download.pytorch.org` were closed.
- **Checked again (30 October 2026, later):** `huggingface.co` still 403. The Gemini API
  (`generativelanguage.googleapis.com`) is open, but `ai.google.dev` (its docs) is not.
- **Gemini, proposed by the institute's question (not approved: it changes the engine named in
  `APP-PLAN.md`):** Google's TTS models (`gemini-3.8-flash-tts` in Google's docs in October 2026;
  older previews retire in November 2026, so check the id) speak two voices in one request, so a
  conversation's man and woman come in one call; podcasts (three people) go in pairs. Pace is set
  by the instruction, not a number, so measure each clip's words per minute against `speed`. The
  speech check can be Gemini too (transcribe each clip), since faster-whisper is on Hugging Face.
  Needs a key in the environment settings as `GEMINI_API_KEY` (never in the repo). Then the voice
  sample below, with Gemini's voices in place of Kokoro's.
- **Python:** the `kokoro` package needs Python < 3.13, and the session had 3.13. Either install
  Python 3.12, or use `kokoro-onnx` (runs on 3.13) with the ONNX model
  `onnx-community/Kokoro-82M-v1.0-ONNX` (one `voices/<name>.bin` per voice; build the
  `voices.bin` dict kokoro-onnx expects from them). Prefer the official `kokoro` +
  `misaki` G2P if it installs: its English pronunciation is better than espeak's.

## First deliverable: the voice sample (step 1 of the plan)

Before generating anything else, send the institute, on a private Artifact page with
players and the text beside each clip:

1. A conversation with a man and a woman (e.g. advanced-1 lesson 3, Sara and the Clerk).
2. One story paragraph at Starter speed (0.80) and the same at Advanced speed (1.0).
3. Ideally the question and answer voices, and the narrator.

Ask them to approve the voices (or pick others) before the full run.

## Generator: `curriculum/tools/voices.py` (to write)

Input: the export, `python3 curriculum/tools/export_app.py --out apps/student/assets/content`.
Every text with audio is an item `{t, a, v, say?}`:

- `a` is the clip id, fixed by its place: `pre-intermediate-1/04/story.2`,
  `.../questions.3.q`, `.../conversation.4`, `starter/p02/parts.0.sounds.1.examples.2`.
- `v` is the speaker: a cast name, or a role (narrator, teacher, anchor, question, answer).
- The text to speak is `say` if present (new words: "word. Meaning."; idioms: expression then
  example), else `t` without its markup (`curriculum/tools/build.py` `plain()` strips
  `[...]`, `((...))`, `{...}`).

Voice per item: `voices.yaml` `cast`, then `roles`, then the speaker's gender in `gender`
for that level with a voice from `pool` that no other speaker of the same lesson uses.
Speed: `voices.yaml` `speed` for the level.

Output, in `apps/student/assets/audio/` (add `- assets/audio/` to the app's pubspec):

- One mono Ogg Opus file per distinct (text, voice, speed): `ffmpeg -c:a libopus -b:a 24k`
  from Kokoro's 24 kHz output. Name it by a hash of the three, so identical clips are shared.
- `manifest.json`, read by `apps/student/lib/src/audio/speaker.dart`:

      {"format": 1, "clips": {"<id>": {"file": "<name>.ogg", "ms": 1830,
                                        "text": "<spoken text>", "voice": "af_heart", "speed": 0.85}}}

## Checks (the institute asked that no clip be in the wrong place)

The generator must refuse to finish, with a report, if:

1. an item in the export has no clip, or the manifest has a clip for no item;
2. a clip's length is not plausible for its words at its speed;
3. speech recognition (`faster-whisper`, model `base.en` or `small.en`, also on Hugging Face)
   hears words that differ from the text beyond a small threshold. Names and places (see
   `listen_for`) are compared loosely; fix a wrong pronunciation with Kokoro's `[word](/IPA/)`.

Keep the report (`build/voices-report.json`) and give its summary to the institute.

## Podcasts

The books print a time for every podcast line (00:05, 00:08, …). Pad each line's clip with
silence so the next line starts at its printed time, and play podcast lines with no extra gap
(the app's `Speaker.gap` is 450 ms between other clips). If a line is longer than its slot,
report it rather than squeezing it.

## Size

About 40,000 words, roughly 5 hours. At 24 kb/s Opus that is about 50 MB. Later the content
builder encrypts each level's text and audio with its key (docs/REQUIREMENTS.md 5.4); the
`Speaker` will then read clips from the decrypted pack instead of plain assets.
