#!/usr/bin/env python3
"""Make the voices of the student app (docs/VOICES.md).

Every text with audio in the export (export_app.py) gets one clip, spoken by
Kokoro at the speed of its level, in the voice curriculum/voices.yaml gives
its speaker. Then every clip is checked, because no clip may be in the wrong
place:

    1. every item has a clip, and every clip has an item;
    2. every clip is about as long as its words, at its speed;
    3. speech recognition (Whisper) hears the words of the text.

The clips go to apps/student/assets/audio as Ogg Opus, named by a hash of
what they say, in which voice and at which speed, so a clip is only made
again when one of those changes. manifest.json ties every audio id to its
clip; it is written only when every check passes. The report of the checks
is build/voices-report.json.

Kokoro needs Python 3.12 and its own packages (docs/VOICES.md):

    python3.12 -m venv ~/.venvs/voices
    ~/.venvs/voices/bin/pip install -r curriculum/tools/voices-requirements.txt
    ~/.venvs/voices/bin/python curriculum/tools/voices.py --setup      # the models, once
    ~/.venvs/voices/bin/python curriculum/tools/voices.py [english/<level> ...] [--only ID-PREFIX ...]
"""

import argparse
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import time
from difflib import SequenceMatcher
from pathlib import Path

import numpy as np
import yaml
from num2words import num2words

TOOLS = Path(__file__).resolve().parent
sys.path.insert(0, str(TOOLS))
import build  # noqa: E402
import export_app  # noqa: E402

ROOT = build.ROOT  # curriculum/
REPO = ROOT.parent
CONFIG = ROOT / 'voices.yaml'
OUT = REPO / 'apps' / 'student' / 'assets' / 'audio'
REPORT = REPO / 'build' / 'voices-report.json'
CACHE = Path(os.environ.get('FVI_VOICES_CACHE', Path.home() / '.cache' / 'fvi-voices'))

RATE = 24000          # Kokoro's sample rate
HEAD, TAIL = 50, 100  # ms of silence around every clip, so no player cuts a sound
# Part of every clip's name: another engine makes new clips.
ENGINE = 'kokoro-v1.0 misaki-0.9.4 lead-in'

# Hugging Face is closed to the build environment; the same files are on GitHub.
_GH = 'https://github.com'
MODELS = {
    'kokoro-v1.0.onnx': (f'{_GH}/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx',
                         '7d5df8ecf7d4b1878015a32686053fd0eebe2bc377234608764cc0ef3636a6c5'),
    'voices-v1.0.bin': (f'{_GH}/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin',
                        'bca610b8308e8d99f32e6fe4197e7ec01679264efed0cac9140fe9c29f1fbf7d'),
}
WHISPER_URL = f'{_GH}/k2-fsa/sherpa-onnx/releases/download/asr-models/sherpa-onnx-whisper-small.en.tar.bz2'
WHISPER = {
    'small.en-encoder.int8.onnx': '8bdac288f369aa94ee2194059238c465ed82ea9d47ee8fa4a8c0a891873e462f',
    'small.en-decoder.int8.onnx': '710ccf890e10f3faa15f51ec346081a2723c9f3adb6e4da81c6573a5a6f877fb',
    'small.en-tokens.txt': '306cd27f03c1a714eca7108e03d66b7dc042abe8c258b44c199a7ed9838dd930',
}


# ---------------------------------------------------------------- models

def _sha256(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for block in iter(lambda: f.read(1 << 20), b''):
            h.update(block)
    return h.hexdigest()


def setup():
    """Downloads the models into CACHE and checks them."""
    CACHE.mkdir(parents=True, exist_ok=True)
    for name, (url, sha) in MODELS.items():
        path = CACHE / name
        if not path.exists() or _sha256(path) != sha:
            print('downloading', url)
            subprocess.run(['curl', '-fsSL', '--retry', '3', '-o', str(path), url], check=True)
        if _sha256(path) != sha:
            raise SystemExit(f'{path}: not the file expected')
    asr = CACHE / 'whisper'
    if not all((asr / n).exists() and _sha256(asr / n) == s for n, s in WHISPER.items()):
        asr.mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory() as tmp:
            print('downloading', WHISPER_URL)
            archive = Path(tmp) / 'whisper.tar.bz2'
            subprocess.run(['curl', '-fsSL', '--retry', '3', '-o', str(archive), WHISPER_URL], check=True)
            members = [f'sherpa-onnx-whisper-small.en/{n}' for n in WHISPER]
            subprocess.run(['tar', 'xjf', str(archive), '-C', tmp, *members], check=True)
            for n in WHISPER:
                os.replace(Path(tmp) / 'sherpa-onnx-whisper-small.en' / n, asr / n)
    for n, s in WHISPER.items():
        if _sha256(asr / n) != s:
            raise SystemExit(f'{asr / n}: not the file expected')
    _timed()
    print('models ready in', CACHE)


def _timed():
    """Kokoro, also giving the length of every sound it says.

    The model works the lengths out (its duration predictor) but does not
    give them; this copy gives them as the output "duration", in frames of
    600 samples. kokoro-onnx then knows when each sound is said.
    """
    path = CACHE / 'kokoro-v1.0-timed.onnx'
    if path.exists():
        return path
    import onnx
    model = onnx.load(str(CACHE / 'kokoro-v1.0.onnx'))
    model.graph.node.append(onnx.helper.make_node('Identity', ['/encoder/Clip_output_0'], ['duration']))
    model.graph.output.append(onnx.helper.make_tensor_value_info('duration', onnx.TensorProto.FLOAT, None))
    onnx.save(model, str(path.with_suffix('.tmp')))
    os.replace(path.with_suffix('.tmp'), path)
    return path


# ---------------------------------------------------------------- what is said

_MONTHS = ('January', 'February', 'March', 'April', 'May', 'June', 'July', 'August',
           'September', 'October', 'November', 'December')
_CLOCK = re.compile(r'\b(\d{1,2}):(\d\d)\b')
_DATE = re.compile(rf'\b({"|".join(_MONTHS)}) (\d{{1,2}})\b(?!:)')
_SLASH = re.compile(r'\s+/\s+')


def _clock(m):
    """7:50 -> seven fifty, 8:00 -> eight o'clock, 9:05 -> nine oh five"""
    hour, minute = num2words(int(m.group(1))), int(m.group(2))
    if minute == 0:
        return f"{hour} o'clock"
    return f'{hour} {"oh " if minute < 10 else ""}{num2words(minute)}'


def spoken(item, cfg):
    """The words a clip says: the text without its markup, read as a person would."""
    text = item.get('say') or build.plain(item['t'])
    for written, said in cfg.get('say_as', {}).items():
        text = text.replace(written, said)
    text = _CLOCK.sub(_clock, text)
    text = _DATE.sub(lambda m: f'{m.group(1)} {num2words(int(m.group(2)), to="ordinal")}', text)
    # "Yes, I am.  /  No, I'm not." is two answers, not a slash.
    text = _SLASH.sub(' ', text)
    return ' '.join(text.split())


def _possessive(ipa):
    if ipa[-1] in 'szʃʒʧʤ':
        return ipa + 'ᵻz'
    return ipa + ('s' if ipa[-1] in 'ptkfθ' else 'z')


class Voice:
    """Kokoro, with misaki's American English G2P and the fixes of voices.yaml.

    Kokoro says the first sound of a text badly: a word on its own often
    comes out with a sound in front ("Zomar" for Omar). So every text is
    said after a lead-in sentence, which is cut off at the pause between
    them, where the model's own sound lengths put it.
    """

    LEAD_IN = 'Here it is.'

    def __init__(self, cfg):
        from kokoro_onnx import Kokoro
        from kokoro_onnx.trim import trim
        from misaki import en, espeak
        self.g2p = en.G2P(trf=False, british=False, fallback=espeak.EspeakFallback(british=False))
        self.kokoro = Kokoro(str(_timed()), str(CACHE / 'voices-v1.0.bin'))
        self.trim = trim
        pron = cfg.get('pronounce', {})
        self.fixes = [(re.compile(rf"\b{re.escape(w)}('s)?\b"), ipa) for w, ipa in pron.items()]
        self.lead_in = self.g2p(self.LEAD_IN)[0] + ' '

    def phonemes(self, text):
        for pattern, ipa in self.fixes:
            text = pattern.sub(lambda m: f'[{m.group(0)}](/{_possessive(ipa) if m.group(1) else ipa}/)', text)
        return self.g2p(text)[0]

    def speak(self, phonemes, voice, speed):
        # Slower levels pause a little longer between sentences, too.
        audio, rate, sounds = self.kokoro.create_timed(self.lead_in + phonemes, voice=voice, speed=speed,
                                                       is_phonemes=True, sentence_pause=0.25 / speed,
                                                       clause_pause=0.1 / speed)
        assert rate == RATE
        gap = sounds[len(self.kokoro.tokenizer.known(self.lead_in)) - 1]  # the space after the lead-in
        audio, _ = self.trim(audio[int((gap.start + gap.end) / 2 * RATE):])
        return audio.astype(np.float32)


# ---------------------------------------------------------------- who says it

def lesson_of(audio_id):
    """advanced-1/03/conversation.4 -> advanced-1/03"""
    return audio_id.rsplit('/', 1)[0]


def voices_of(slug, items, cfg):
    """The voice of every speaker of one lesson.

    The cast and the roles keep their voice everywhere; everyone else takes
    the first voice of their gender that nobody else in the lesson speaks with.
    """
    speakers = list(dict.fromkeys(i['v'] for i in items))
    fixed = {s: cfg['cast'].get(s) or cfg['roles'].get(s) for s in speakers}
    used = {v for v in fixed.values() if v}
    out = {}
    for s in speakers:
        if fixed[s]:
            out[s] = fixed[s]
            continue
        gender = cfg['gender'].get(slug, {}).get(s)
        if gender is None:
            raise SystemExit(f'{slug}: {s!r} has no voice and no gender in voices.yaml')
        free = [v for v in cfg['pool'][gender] if v not in used]
        if not free:
            raise SystemExit(f'{lesson_of(items[0]["a"])}: no {gender} voice left for {s}')
        out[s] = free[0]
        used.add(free[0])
    return out


def _seconds(mmss):
    m, s = mmss.split(':')
    return int(m) * 60 + int(s)


class Clip:
    def __init__(self, aid, text, voice, speed, slot=None):
        self.id, self.text, self.voice, self.speed = aid, text, voice, speed
        self.slot = slot  # podcast lines: ms until the next line starts
        self.phonemes = None
        self.ms = self.speech_ms = None

    @property
    def file(self):
        key = '\0'.join([ENGINE, self.voice, f'{self.speed:.2f}', self.phonemes, str(self.slot or '')])
        return hashlib.sha1(key.encode('utf-8')).hexdigest()[:16] + '.ogg'


def plan(levels, cfg, only=()):
    """Every clip of the levels, in reading order: (clips, items by id)."""
    clips, items = [], {}
    for level in levels:
        data = export_app.export_level(level)
        slug = data['slug']
        speed = cfg['speed'][slug]
        by_lesson = {}
        for it in export_app.audio_items(data):
            by_lesson.setdefault(lesson_of(it['a']), []).append(it)
        for lesson_items in by_lesson.values():
            voice = voices_of(slug, lesson_items, cfg)
            times = [_seconds(it['time']) for it in lesson_items if 'time' in it]
            for it in lesson_items:
                items[it['a']] = it
                if only and not it['a'].startswith(tuple(only)):
                    continue
                slot = None
                if 'time' in it:
                    k = times.index(_seconds(it['time']))
                    if k + 1 < len(times):
                        slot = (times[k + 1] - times[k]) * 1000
                clips.append(Clip(it['a'], spoken(it, cfg), voice[it['v']], speed, slot))
    if only:
        items = {k: v for k, v in items.items() if k.startswith(tuple(only))}
    return clips, items


# ---------------------------------------------------------------- making the clips

def _encode(audio, path):
    """Mono Ogg Opus at 24 kb/s, the same bytes every time for the same audio."""
    tmp = path.with_suffix('.tmp')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'f32le', '-ar', str(RATE), '-ac', '1', '-i', 'pipe:',
                    '-c:a', 'libopus', '-b:a', '24k', '-map_metadata', '-1',
                    '-fflags', '+bitexact', '-flags:a', '+bitexact', '-f', 'ogg', str(tmp)],
                   input=audio.astype('<f4').tobytes(), check=True)
    os.replace(tmp, path)


def _decode(path, rate):
    out = subprocess.run(['ffmpeg', '-v', 'error', '-i', str(path), '-f', 'f32le', '-ac', '1', '-ar', str(rate), 'pipe:'],
                         capture_output=True, check=True).stdout
    return np.frombuffer(out, dtype='<f4')


def make(clips, voice, out, log=print):
    """Writes the clips that are not in OUT yet; sets every clip's length."""
    out.mkdir(parents=True, exist_ok=True)
    for c in clips:
        c.phonemes = voice.phonemes(c.text)
    todo = {c.file: c for c in clips if not (out / c.file).exists()}
    start = time.time()
    for n, c in enumerate(todo.values(), 1):
        audio = voice.speak(c.phonemes, c.voice, c.speed)
        pad = np.zeros(RATE * HEAD // 1000, np.float32), np.zeros(RATE * TAIL // 1000, np.float32)
        audio = np.concatenate([pad[0], audio, pad[1]])
        if c.slot:
            # Silence until the next line's time; a line too long for it is
            # left as it is, and check 2 reports it.
            spare = RATE * c.slot // 1000 - len(audio)
            audio = np.concatenate([audio, np.zeros(max(0, spare), np.float32)])
        _encode(audio, out / c.file)
        if n % 25 == 0 or n == len(todo):
            log(f'  {n}/{len(todo)} clips made ({time.time() - start:.0f} s)')
    lengths = {}
    for c in clips:
        if c.file not in lengths:
            samples = _decode(out / c.file, 8000)
            lengths[c.file] = len(samples) // 8, _speech_ms(samples)
        c.ms, c.speech_ms = lengths[c.file]


# ---------------------------------------------------------------- the checks

_STRESS = re.compile(r'[ˈˌ\s.,!?;:…—–\-"“”()]')


def check_items(clips, items, problems):
    """Check 1: an item with no clip, or a clip with no item."""
    ids = [c.id for c in clips]
    for aid in items:
        if aid not in ids:
            problems.append({'id': aid, 'check': 'missing', 'detail': 'no clip for this item'})
    for aid in set(ids) - set(items):
        problems.append({'id': aid, 'check': 'extra', 'detail': 'a clip for no item'})
    if len(ids) != len(set(ids)):
        problems.append({'id': '', 'check': 'extra', 'detail': 'an audio id has two clips'})


def _speech_ms(samples, rate=8000):
    """How long a clip speaks, from its first sound to its last."""
    frame = rate // 100
    n = len(samples) // frame
    loud = np.sqrt((samples[:n * frame].reshape(n, frame) ** 2).mean(1))
    on = np.flatnonzero(loud > loud.max() * 10 ** (-40 / 20)) if n else []
    return int((on[-1] - on[0] + 1) * 10) if len(on) else 0


def check_lengths(clips, problems, low=0.5, high=2.0):
    """Check 2: every clip about as long as its sounds and pauses, at its speed.

    At speed 1, Kokoro speaks about 60 ms a sound, plus 165 ms for each end of
    a sentence or comma, plus 135 ms (measured on three lessons: all within
    0.7 to 1.45 of that). A clip far shorter lost words; far longer, it has a
    long silence or a noise.
    """
    for c in clips:
        sounds = len(_STRESS.sub('', c.phonemes))
        pauses = len(re.findall(r'[.!?…,;:—]', c.phonemes))
        expected = (60 * sounds + 165 * pauses + 135) / c.speed
        ratio = c.speech_ms / expected
        if not low <= ratio <= high:
            problems.append({'id': c.id, 'check': 'length', 'text': c.text,
                             'detail': f'{c.speech_ms} ms of speech: {ratio:.2f} times what its sounds take'})
        if c.slot and c.ms > c.slot:
            problems.append({'id': c.id, 'check': 'podcast', 'text': c.text,
                             'detail': f'{c.ms} ms, longer than its {c.slot} ms before the next line'})


_ABBR = {'mr': 'mister', 'mrs': 'missus', 'ms': 'miz', 'dr': 'doctor', 'ok': 'okay', 'tv': 'tv'}


def words(text):
    """Text as comparable words: lower case, numbers and times in words."""
    text = _CLOCK.sub(_clock, text).replace('%', ' percent').replace('&', ' and ')
    text = re.sub(r'(\d),(\d{3})', r'\1\2', text)
    text = re.sub(r'\b(\d+)(st|nd|rd|th)\b', lambda m: num2words(int(m.group(1)), to='ordinal'), text)
    text = re.sub(r'\b(1[1-9]|20)(\d\d)\b', lambda m: num2words(int(m.group(0)), to='year'), text)
    text = re.sub(r'\d+', lambda m: num2words(int(m.group(0))), text)
    text = text.lower().replace('’', "'")
    out = []
    for w in re.findall(r"[a-z']+", re.sub(r'[-–—]', ' ', text)):
        w = w.strip("'")
        if w.endswith("'s") and w[:-2] in _ABBR:
            w = w[:-2]
        out.extend(_ABBR.get(w, w).split())
    return out


def errors(ref, heard, names):
    """Word edits from what was written to what was heard; names compare loosely."""
    def same(a, b):
        if a == b:
            return True
        return a in names and SequenceMatcher(None, a, b).ratio() >= 0.5
    prev = list(range(len(heard) + 1))
    for i, a in enumerate(ref, 1):
        cur = [i]
        for j, b in enumerate(heard, 1):
            cur.append(min(prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (0 if same(a, b) else 1)))
        prev = cur
    return prev[-1]


def allowed(n):
    """Edits allowed in a text of n words: none under 10 words, then 1 in 10."""
    return n // 10


class Ear:
    """Whisper small.en, through sherpa-onnx."""

    def __init__(self, threads):
        import sherpa_onnx
        d = CACHE / 'whisper'
        self.rec = sherpa_onnx.OfflineRecognizer.from_whisper(
            encoder=str(d / 'small.en-encoder.int8.onnx'), decoder=str(d / 'small.en-decoder.int8.onnx'),
            tokens=str(d / 'small.en-tokens.txt'), language='en', task='transcribe', num_threads=threads)

    def hear(self, path):
        audio = _decode(path, 16000)
        # A second of silence on each side: Whisper hears short clips better.
        quiet = np.zeros(16000, np.float32)
        stream = self.rec.create_stream()
        stream.accept_waveform(16000, np.concatenate([quiet, audio, quiet]))
        self.rec.decode_stream(stream)
        return stream.result.text.strip()


def check_heard(clips, out, cfg, problems, threads, cache, log=print):
    """Check 3: Whisper hears the text. cache: what was heard before, by file."""
    names = {w.lower() for n in [*cfg.get('listen_for', []), *cfg['cast'], *cfg.get('pronounce', {}),
                                 *[s for g in cfg['gender'].values() for s in g]] for w in n.split()}
    ear = None
    heard = {}
    start = time.time()
    todo = [c for c in clips if c.file not in cache]
    for n, c in enumerate(clips):
        if c.file not in heard:
            if c.file in cache:
                heard[c.file] = cache[c.file]
            else:
                ear = ear or Ear(threads)
                heard[c.file] = ear.hear(out / c.file)
                done = len(heard) - sum(1 for f in heard if f in cache)
                if done % 25 == 0 or done == len(todo):
                    log(f'  {done}/{len(todo)} clips heard ({time.time() - start:.0f} s)')
        ref, got = words(c.text), words(heard[c.file])
        e = errors(ref, got, names)
        c.heard, c.errors = heard[c.file], e
        if e > allowed(len(ref)):
            problems.append({'id': c.id, 'check': 'heard', 'text': c.text, 'heard': heard[c.file],
                             'detail': f'{e} of {len(ref)} words differ'})
    return heard


# ---------------------------------------------------------------- main

def run(clips, items, out, cfg, listen=True, threads=4, log=print):
    """Makes and checks the clips; returns the report."""
    problems = []
    check_items(clips, items, problems)
    make(clips, Voice(cfg), out, log)
    check_lengths(clips, problems)
    old = json.loads(REPORT.read_text(encoding='utf-8')) if REPORT.exists() else {}
    cache = old.get('heard', {})
    heard = check_heard(clips, out, cfg, problems, threads, cache, log) if listen else {}
    files = {c.file for c in clips}
    report = {
        'summary': {'items': len(items), 'clips': len(clips), 'files': len(files),
                    'minutes': round(sum(c.ms for c in {c.file: c for c in clips}.values()) / 60000, 1),
                    'megabytes': round(sum((out / f).stat().st_size for f in files) / 1e6, 1),
                    'listened': listen, 'problems': len(problems)},
        'problems': problems,
        'heard': {**cache, **heard},
    }
    return report


def manifest(clips):
    return {'format': 1, 'clips': {c.id: {'file': c.file, 'ms': c.ms, 'text': c.text, 'voice': c.voice,
                                          'speed': c.speed, **({'slot': c.slot} if c.slot else {})}
                                   for c in clips}}


def main():
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    ap.add_argument('levels', nargs='*', help='e.g. english/advanced-1 (default: every level)')
    ap.add_argument('--setup', action='store_true', help='download the models, then stop')
    ap.add_argument('--only', nargs='+', default=(), metavar='ID', help='only the clips whose id starts so')
    ap.add_argument('--out', default=str(OUT), help=f'clips folder (default: {OUT.relative_to(REPO)})')
    ap.add_argument('--no-listen', action='store_true', help='skip check 3 (speech recognition)')
    ap.add_argument('--threads', type=int, default=os.cpu_count() or 4)
    args = ap.parse_args()
    if args.setup:
        return setup()
    cfg = yaml.safe_load(CONFIG.read_text(encoding='utf-8'))
    course = yaml.safe_load((ROOT / 'english' / 'course.yaml').read_text(encoding='utf-8'))
    levels = args.levels or [f'english/{n.lower().replace(" ", "-")}'
                             for st in course['stages'] for n in st['levels']]
    out = Path(args.out)
    clips, items = plan(levels, cfg, args.only)
    print(f'{len(clips)} clips for {len(items)} items')
    report = run(clips, items, out, cfg, listen=not args.no_listen, threads=args.threads)
    REPORT.parent.mkdir(parents=True, exist_ok=True)
    REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=1), encoding='utf-8')
    s = report['summary']
    print(f'{s["clips"]} clips, {s["files"]} files, {s["minutes"]} min, {s["megabytes"]} MB; '
          f'{s["problems"]} problem(s). Report: {REPORT.relative_to(REPO)}')
    for p in report['problems'][:40]:
        print(f'  {p["check"]:8} {p["id"]}: {p["detail"]}' + (f'\n           heard: {p["heard"]}' if 'heard' in p else ''))
    if report['problems']:
        raise SystemExit('Not finished: manifest.json was not written.')
    (out / 'manifest.json').write_text(json.dumps(manifest(clips), ensure_ascii=False, indent=1), encoding='utf-8')
    if not args.only and not args.levels:
        keep = {c.file for c in clips} | {'manifest.json'}
        for f in out.iterdir():
            if f.name not in keep:
                f.unlink()
    print('manifest written:', out / 'manifest.json')


if __name__ == '__main__':
    main()
