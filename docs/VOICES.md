# Voices: what to build next

The plan the institute approved is `docs/APP-PLAN.md` (Arabic). This is the
technical side, written so a new session can start at once. The voices
themselves are in `curriculum/voices.yaml`.

## Status (30 October 2026, third session)

- **Stopped.** The institute decided there is no audio in the app (decision #44 in
  `docs/REQUIREMENTS.md`): the app is text only, with exercises instead. Nothing below is to be
  run unless the institute asks for audio again. No clip was committed.

- **The institute approved the voices**, the speeds and the names (the sample, the private Artifact
  page "FVI Voice Sample"). Questions 85 and 86 are answered.
- **The first full run** (3975 files, 83 minutes to make) was stopped while being heard: about 1
  clip in 20 had lost the start of its first word (see "What was learned"). The generator now cuts
  in the quiet before the first word and makes other takes of a clip heard wrong. **Next:** the full
  run again, then commit `apps/student/assets/audio/` (clips and `manifest.json`) once every check
  passes. Open: the four podcast lines longer than their printed time (question 87).
- **Hugging Face is still closed** (403 from the proxy). The generator does not need it any more:
  the same Kokoro v1.0 files are GitHub release assets (kokoro-onnx `model-files-v1.0`), and
  Whisper small.en comes from sherpa-onnx's GitHub releases. `--setup` downloads and checks them
  (sha256) into `~/.cache/fvi-voices`.
- **Python:** Kokoro runs through `kokoro-onnx` (no PyTorch) with the official `misaki` G2P, in a
  Python 3.12 venv (`/usr/bin/python3.12` is in the image):

      python3.12 -m venv ~/.venvs/voices
      ~/.venvs/voices/bin/pip install -r curriculum/tools/voices-requirements.txt
      ~/.venvs/voices/bin/python curriculum/tools/voices.py --setup
      ~/.venvs/voices/bin/python curriculum/tools/voices.py                  # every level
      ~/.venvs/voices/bin/python curriculum/tools/voices.py english/starter --only starter/p02/ --out build/x

  Do not install `misaki[en]`: its extra pulls in PyTorch (gigabytes) for nothing.

### What was learned

- **Kokoro mangles the first sound of a text.** A word alone came out as "Zomar" for Omar,
  "Lappin'" for up. Punctuation in front or another style vector did not help. What works: say a
  lead-in ("Here it is.") first and cut it off. `--setup` makes a copy of the model that also
  outputs the length of every sound (the duration predictor, `/encoder/Clip_output_0`, as output
  `duration`, in frames of 600 samples); kokoro-onnx then gives timings.
- **But the timings run late, and the cut must not trust them.** The sounds come out 30 to 100 ms
  before their times, and many voices (am_onyx, am_puck, am_eric, am_liam, and often am_michael)
  run the lead-in straight into the text with no pause at all. The first full run cut in the
  middle of the timed pause and lost the start of the first word in about 1 clip in 20: "time is
  it?" for "What time is it?", "tab" for "cab", "prised" for "Surprised". kokoro-onnx's own pause
  lengthening made it worse: it lengthens the quiet nearest a mark, which can be the stop of the
  next word (the k of "OK"). Now the generator synthesizes with no added pauses, cuts at the
  quietest 10 ms between the lead-in's last sound and the text's first (by the timings, which
  only say where to look), and lengthens a pause only in quiet that starts before the next
  word's first sound. On 230 flagged clips this fixed 67 and broke none of 80 good ones.
- **Takes.** "Here it is." ends in z, which can run into an s or sh ("or anything else" for "Sure.
  Anything else?"). A clip Whisper hears wrong is made again: after "Here you are.", then cut
  where the hiss of its first sound starts, until one take is heard right (`Voice.TAKES`).
- **Whisper on one word** hears its vowel a step lower: sit as set, set as sat, bed as bad
  (8 of 38 Starter words right, even words said right). After "The word is" in the same voice it
  hears 32 of 38, so a one-word clip is heard after that carrier. It also adds articles ("A cat.")
  and hears names as words ("cartoon" for Khartoum): names and words it does not know compare
  loosely (`listen_for`, `cast`, `pronounce`, the people of `gender`), and the comparison accepts
  what is said the same (two/too, café/cafe, 830 for eight thirty, £1,500 for fifteen hundred
  pounds).
- **Clip length:** at speed 1, about 60 ms a sound, 165 ms for each sentence end or comma, plus
  135 ms. The check allows 0.5 to 2 times that (the three test lessons were within 0.7 to 1.45).
- **Speed:** about 3.5 times faster than real time to make, 2.5 times to hear, on 4 cores: the
  full run (about 5 hours of audio) takes about 3.5 hours; clips already made are kept (named by
  hash), and what Whisper heard is kept in the report, so a second run only does what changed.
- **Podcasts:** a line a little long for its printed time gives up its own end silence. Four
  lines are still longer than their time (measured with the cut above): advanced-1/10/script.11
  (+0.14 s), advanced-2/08/script.0 (+0.44 s), advanced-3/08/script.0 (+0.06 s) and
  advanced-3/08/script.1 (+0.52 s). The institute decides (question 87): let the next line start
  that much late, or a later time in the book, or a shorter line.

## Generator: `curriculum/tools/voices.py`

Input: the export, `python3 curriculum/tools/export_app.py --out apps/student/assets/content`.
Every text with audio is an item `{t, a, v, say?}`:

- `a` is the clip id, fixed by its place: `pre-intermediate-1/04/story.2`,
  `.../questions.3.q`, `.../conversation.4`, `starter/p02/parts.0.sounds.1.examples.2`.
- `v` is the speaker: a cast name, or a role (narrator, teacher, anchor, question, answer).
- The text to speak is `say` if present (new words: "word. Meaning."; idioms: expression, meaning,
  then example, as the plan has it), else `t` without its markup (`curriculum/tools/build.py`
  `plain()` strips `[...]`, `((...))`, `{...}`). Then `voices.yaml` `say_as`, times (7:50 →
  seven fifty), dates (March 12 → March twelfth), and " / " between two answers becomes a pause.
  Names in `pronounce` get their phonemes (`[Huda](/hˈudə/)`, and Huda's with its s).

Voice per item: `voices.yaml` `cast`, then `roles`, then the speaker's gender in `gender`
for that level with a voice from `pool` that no other speaker of the same lesson uses.
Speed: `voices.yaml` `speed` for the level.

Output, in `apps/student/assets/audio/` (still to do with the full run: add `- assets/audio/` to the
app's pubspec, decide whether the 50 MB of clips go in the repository or are built in CI):

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

The books print a time for every podcast line (00:05, 00:08, …). The generator pads each line's
clip with silence so the next line starts at its printed time (the manifest gives such clips a
`slot`), and reports a line longer than its slot rather than squeezing it. Still to do in the
app: play clips that have a `slot` with no extra gap (the `Speaker.gap` is 450 ms between other
clips).

## Size

About 40,000 words, roughly 5 hours. At 24 kb/s Opus that is about 50 MB. Later the content
builder encrypts each level's text and audio with its key (docs/REQUIREMENTS.md 5.4); the
`Speaker` will then read clips from the decrypted pack instead of plain assets.
