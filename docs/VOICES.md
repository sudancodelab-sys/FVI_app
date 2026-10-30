# Voices: what to build next

The plan the institute approved is `docs/APP-PLAN.md` (Arabic). This is the
technical side, written so a new session can start at once. The voices
themselves are in `curriculum/voices.yaml`.

## Status (30 October 2026)

- Not started: the voice generator and the voice sample.
- **Gemini works** (checked 30 October, the institute added `GEMINI_API_KEY` to the
  environment; never write the key in the repo). `generativelanguage.googleapis.com` is open,
  `huggingface.co` and `ai.google.dev` (Google's docs) are still refused. What was tried:
  - Text to speech: `gemini-3.8-flash-tts` (newest; once 503 "high demand", then fine; answers
    `audio/wav`, 24 kHz mono), `gemini-3.8-flash-lite-tts`, `gemini-3.1-flash-tts-preview` and
    `gemini-2.5-flash-preview-tts` (answer raw `audio/L16` PCM, 24 kHz). Voices are Gemini's
    (Kore, Charon, ...), not Kokoro's, so `voices.yaml` needs Gemini names if it is chosen.
    There is no speed setting: the pace is asked for in the prompt.
  - Two speakers in one request: the 2.5 and 3.1 models take `Sara: ...` lines and
    `multiSpeakerVoiceConfig`; 3.8 refuses that (400) and needs one text part per line with
    `"speechMetadata": {"speaker": "Sara"}`.
  - Speech recognition for the checks: `gemini-3.5-transcribe` (about 2 s a clip; the text is in
    `parts[].audioTranscription.text`). It heard all five test clips word for word, Khartoum,
    Omdurman and Port Sudan included. `gemini-2.5-flash` is closed to new users.
  - The key is on the **free tier**: 3 requests a minute per model (the 429 names
    `generate_content_free_tier_requests`, limit 3). The daily limit is not known. Audio costs
    25 tokens a second.
- **Size of the run:** the export has 4,077 clips (3,987 distinct) and 42,165 words. At one
  request a clip and 3 a minute, that is about 22 hours of speech requests and 22 more of
  checks, before any daily limit; the full run needs a paid tier (or grouped requests).
- **The voice sample is made** (30 October, waiting for the institute to listen): the private
  Artifact "Gemini Voice Sample", 22 clips, made by `curriculum/tools/dev/voice_sample.py` (its
  voices and groups are at the top) and `docs/voice-sample/build_page.py`. What it taught:
  - Free tier per model: **10 requests a day** for each TTS model (`gemini-2.5-pro-preview-tts`
    has 0: paid only), about 20 a day for `gemini-3.5-transcribe`, 3 a minute for all. The
    4,077 clips cannot be made on the free tier.
  - `gemini-3.8-flash-tts` and `-lite` **read any direction aloud** ("Read this aloud in ...")
    and refuse a system instruction (400), so they get the bare text, and a slower level is
    made by stretching with ffmpeg `rubberband` (pitch kept). `gemini-2.5-flash-preview-tts`
    follows "Say ... slowly:" without reading it, but "slowly" gave 83 words a minute for a
    paragraph read at 155 naturally (0.54, not 0.80); stretching gives the speed exactly (124).
    `gemini-3.1-flash-tts-preview` gave a British accent.
  - One request for a whole conversation (2 speakers) works on 2.5, but the pauses between
    lines are no longer than those inside a line, so the audio is cut where every line gets
    the length of its text, plus the change of pitch between a man and a woman. 2.5 also
    **left a line out** once (silence instead) and once gave the answer voice (Iapetus, a man)
    a woman's pitch (195 Hz); both were caught by the checks and remade on 3.8 Lite.
  - Checks: the words are compared with what another model hears (whole clips; it can leave
    out spoken directions, so the length check matters too). The listening model's "man or
    woman" and "accent" were often wrong; the pitch (YIN) was right: men 98-147 Hz, women
    152-217 Hz here.
  - Proposed voices (Gemini's): narrator and teacher Sulafat, question Erinome, answer Iapetus,
    anchor Charon, Sara Leda, Huda Aoede, Adam Puck, Omar Achird, Mr. Ali Sadaltager,
    Grandfather Algenib, Clerk Schedar. Not in `voices.yaml` until approved.
- **Blocked by the network:** `huggingface.co`, where Kokoro's model and voices are, was refused
  (403) in the session that wrote this, although the institute had allowed it in the
  environment settings. Check first:

      curl -sS -o /dev/null -w "%{http_code}\n" https://huggingface.co/api/models/hexgrad/Kokoro-82M

  Downloads also go through `cdn-lfs.hf.co` / `cas-bridge.xethub.hf.co` (allow `*.hf.co`).
  `pypi.org` is open; `github.com` and `download.pytorch.org` were closed.
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
