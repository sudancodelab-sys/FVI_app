#!/usr/bin/env python3
"""The voice sample with Gemini (docs/VOICES.md, step 1 of the plan).

Makes the clips of the sample from the app export, checks each one by
listening to it with another model (the words, a man or a woman, the
accent), and writes the clips and sample.json for the listening page.

    python3 curriculum/tools/export_app.py --out /tmp/export
    GEMINI_API_KEY=... python3 curriculum/tools/dev/voice_sample.py /tmp/export OUT

The free tier allows 3 requests a minute and 10 a day per model, so each
request speaks a whole group (a conversation, or two people) and the audio
is cut into one clip per line at the pauses. Answers are kept in OUT, so a
second run asks only for what is missing.

What the free tier showed (30 October 2026): 2.5 Flash sometimes leaves a
line out of a group (silence instead) or gives a speaker the wrong voice, so
every clip is checked; the listening model's "man or woman" and "accent" are
often wrong, so the pitch decides man or woman.
"""

import base64
import difflib
import hashlib
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import build  # noqa: E402  (plain() strips the markup of the books)

API = 'https://generativelanguage.googleapis.com/v1beta/models/'
# gemini-3.8-flash-tts reads any direction aloud and has no speed setting, so it
# gets the bare text, one line a request, and is slowed by stretching; 3.1
# follows directions but gave a British accent. 2.5 follows directions in words
# ("Say slowly: ...") without reading them, in American English.
TTS = 'gemini-2.5-flash-preview-tts'  # 2.5 Pro has no free tier
LITE = 'gemini-3.8-flash-lite-tts'
HEAR = ['gemini-3.5-flash', 'gemini-3-flash-preview', 'gemini-3.5-flash-lite', 'gemini-3.1-flash-lite',
        'gemini-3.6-flash', 'gemini-flash-latest']  # the next if one is busy or out
GAP = 21  # seconds between two requests to one model (3 a minute)
RATE = 24000

# The voices proposed for the sample (Gemini's prebuilt voices).
VOICE = {
    'narrator': 'Sulafat', 'teacher': 'Sulafat', 'question': 'Erinome', 'answer': 'Iapetus',
    'anchor': 'Charon', 'Sara': 'Leda', 'Huda': 'Aoede', 'Adam': 'Puck', 'Omar': 'Achird',
    'Mr. Ali': 'Sadaltager', 'Grandfather': 'Algenib', 'Clerk': 'Schedar',
}
FEMALE = {'Sulafat', 'Erinome', 'Leda', 'Aoede'}  # the others are men's voices

# The pace is asked for in words.
PACE = {
    0.80: 'a little more slowly than normal and very clearly, for beginners learning English',
    0.85: 'slightly more slowly than normal and clearly, for learners of English',
    1.0: 'at a natural, relaxed pace',
}

# One request each: (model, speed, [(section, audio id), ...]), at most two speakers.
GROUPS = [
    (TTS, 1.0, [('conversation', f'advanced-1/03/conversation.{i}') for i in range(10)]),
    (TTS, 0.80, [('story', 'pre-intermediate-1/01/story.1')]),
    (TTS, 1.0, [('story', 'pre-intermediate-1/01/story.1')]),  # read with Mr. Ali's line, which it left out
    (LITE, 0.85, [('questions', 'pre-intermediate-1/01/questions.3.q')]),  # with 2.5 the answer was a woman's
    (LITE, 0.85, [('questions', 'pre-intermediate-1/01/questions.3.a')]),
    (TTS, 1.0, [('word', 'advanced-1/01/words.3'), ('news', 'advanced-1/13/standfirst')]),
    (TTS, 1.0, [('cast', 'advanced-1/10/script.9'), ('cast', 'advanced-1/11/conversation.3')]),
    (TTS, 1.0, [('cast', 'advanced-1/05/conversation.7'), ('cast', 'advanced-1/06/pov.2')]),
    (LITE, 1.0, [('cast', 'advanced-1/09/pov.0')]),
]
# A second way to slow down: the natural clip stretched in time (pitch kept).
STRETCH = [('pre-intermediate-1/01/story.1', 0.80)]


class QuotaOver(Exception):
    pass


class Busy(Exception):
    pass


last_call = {}


def call(model, body, tries=8):
    """POST to the model, keeping to 3 a minute and retrying on 429 (per minute) and 503."""
    for attempt in range(tries):
        wait = GAP - (time.time() - last_call.get(model, 0))
        if wait > 0:
            time.sleep(wait)
        last_call[model] = time.time()
        req = urllib.request.Request(API + model + ':generateContent', json.dumps(body).encode(), {
            'x-goog-api-key': os.environ['GEMINI_API_KEY'], 'Content-Type': 'application/json'})
        try:
            with urllib.request.urlopen(req, timeout=90) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            err = json.load(e).get('error', {})
            quotas = [v.get('quotaId', '') for d in err.get('details', []) for v in d.get('violations', [])]
            if any('PerDay' in q for q in quotas):
                raise QuotaOver(model)
            if e.code in (429, 500, 503):
                delay = re.search(r'(\d+)s', json.dumps(err.get('details', '')))
                print(f'  {model} {e.code}, waiting', flush=True)
                time.sleep(int(delay.group(1)) + 2 if delay else 10 * (attempt + 1))
                continue
            raise RuntimeError(f'{model} {e.code}: {err.get("message")}')
        except (urllib.error.URLError, TimeoutError) as e:
            print(f'  {model} {e}, retrying', flush=True)
            time.sleep(15)
    raise Busy(f'{model}: no answer after {tries} tries')


def label(who):
    return re.sub(r'[^A-Za-z]', '', who.replace('Mr. ', '')).capitalize()


def speak(model, lines, speed):
    """One request for the lines [(who, voice, text)]: 16-bit PCM at 24 kHz."""
    names = list(dict.fromkeys(label(w) for w, _, _ in lines))
    if model.startswith('gemini-3.8'):
        prompt = lines[0][2]
        speech = {'voiceConfig': {'prebuiltVoiceConfig': {'voiceName': lines[0][1]}}}
    elif len(names) == 1:
        prompt = f'In a General American English accent, say {PACE[speed]}:\n{lines[0][2]}'
        speech = {'voiceConfig': {'prebuiltVoiceConfig': {'voiceName': lines[0][1]}}}
    else:
        prompt = (f'Read the lines below in General American English accents, {PACE[speed]}. '
                  'Leave a pause of about two seconds after each line.\n'
                  + '\n'.join(f'{label(w)}: {t}' for w, _, t in lines))
        voices = {label(w): v for w, v, _ in lines}
        speech = {'multiSpeakerVoiceConfig': {'speakerVoiceConfigs': [
            {'speaker': n, 'voiceConfig': {'prebuiltVoiceConfig': {'voiceName': voices[n]}}} for n in names]}}
    d = call(model, {'contents': [{'parts': [{'text': prompt}]}],
                   'generationConfig': {'responseModalities': ['AUDIO'], 'speechConfig': speech}})
    part = d['candidates'][0]['content']['parts'][0]['inlineData']
    audio = base64.b64decode(part['data'])
    if 'wav' in part['mimeType']:
        audio = pcm_of(audio, 'wav')
    return audio, prompt


def pcm_of(data, fmt):
    return subprocess.run(['ffmpeg', '-loglevel', 'error', '-f', fmt, '-i', '-', '-f', 's16le', '-ac', '1',
                           '-ar', str(RATE), '-'], input=data, capture_output=True, check=True).stdout


def pitch(x):
    """Median pitch in Hz of a stretch of speech (YIN), or 0 if it has no voiced sound."""
    f0, n, hi = [], RATE // 25, RATE // 60
    for i in range(0, len(x) - n - hi, n // 2):
        w = x[i:i + n]
        if np.sqrt(np.mean(w ** 2)) < 500:
            continue
        d = np.array([np.sum((w - x[i + tau:i + tau + n]) ** 2) for tau in range(1, hi)])
        cmnd = d * np.arange(1, hi) / np.maximum(np.cumsum(d), 1e-9)
        below = np.nonzero(cmnd[RATE // 400:] < 0.15)[0]
        if len(below):
            tau = RATE // 400 + below[0]
            while tau + 1 < len(cmnd) and cmnd[tau + 1] < cmnd[tau]:
                tau += 1
            f0.append(RATE / (tau + 1))
    return float(np.median(f0)) if f0 else 0


def cut(pcm, texts, voices):
    """Cut the audio of several lines at the pauses between them: one PCM per line."""
    x = np.frombuffer(pcm, dtype=np.int16).astype(float)
    if len(texts) == 1:
        return [pcm]
    hop = RATE // 100  # 10 ms frames
    db = np.array([20 * np.log10(np.sqrt(np.mean(x[i:i + hop] ** 2)) + 1) for i in range(0, len(x) - hop, hop)])
    quiet = db < db.max() - 35
    runs, i = [], 0  # (start frame, end frame) of each pause of 0.15 s or more
    while i < len(quiet):
        if quiet[i]:
            j = i
            while j < len(quiet) and quiet[j]:
                j += 1
            if j - i >= 15 and i > 0 and j < len(quiet):
                runs.append((i, j))
            i = j
        else:
            i += 1
    voiced = np.nonzero(~quiet)[0]
    first, last = voiced[0], voiced[-1]
    # The pauses between lines are no longer than those inside a line, so choose the
    # cuts that give every line the length its text should have (lines are read at
    # an even rate) and, where the speaker changes, a change of pitch (a man's voice
    # and a woman's). The length of a pause tells nothing.
    sizes = [len(t) for t in texts]
    edges = [0] + [(a + b) // 2 for a, b in runs] + [len(quiet)]
    tone = [pitch(x[edges[k] * hop:edges[k + 1] * hop]) for k in range(len(edges) - 1)]
    jump = []
    for j in range(len(runs)):
        left = next((t for t in reversed(tone[:j + 1]) if t), 0)
        right = next((t for t in tone[j + 1:] if t), 0)
        jump.append(abs(np.log(left / right)) if left and right else 0)
    expected = [(last - first) * n / sum(sizes) for n in sizes]
    mids = [(a + b) / 2 for a, b in runs]
    k_max, inf = len(texts) - 1, float('inf')
    # best[k][j]: the cost of lines 0..k with line k ending at pause j
    best = [[inf] * len(runs) for _ in range(k_max)]
    back = [[None] * len(runs) for _ in range(k_max)]

    def cost(k, a, b):
        return ((b - a - expected[k]) / expected[k]) ** 2

    def bonus(k, j):
        return 0.3 * (jump[j] if voices[k] != voices[k + 1] else -jump[j])

    for j in range(len(runs)):
        best[0][j] = cost(0, first, mids[j]) - bonus(0, j)
    for k in range(1, k_max):
        for j in range(len(runs)):
            for i in range(j):
                c = best[k - 1][i] + cost(k, mids[i], mids[j]) - bonus(k, j)
                if c < best[k][j]:
                    best[k][j], back[k][j] = c, i
    end = min(range(len(runs)), key=lambda j: best[k_max - 1][j] + cost(k_max, mids[j], last))
    chosen = [runs[end]]
    for k in range(k_max - 1, 0, -1):
        end = back[k][end]
        chosen.insert(0, runs[end])
    bounds = [0] + [(a + b) // 2 * hop for a, b in chosen] + [len(x)]
    return [x[bounds[k]:bounds[k + 1]].astype(np.int16).tobytes() for k in range(len(texts))]


def finish(pcm, wav, speed_stretch=None):
    """Trim the silence at both ends, keep 0.15 s on each side, write WAV and MP3."""
    trim = ('silenceremove=start_periods=1:start_threshold=-45dB,areverse,'
            'silenceremove=start_periods=1:start_threshold=-45dB,areverse,adelay=150,apad=pad_dur=0.15')
    if speed_stretch:
        trim = f'rubberband=tempo={speed_stretch}:pitchq=quality:formant=preserved,' + trim
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-f', 's16le', '-ar', str(RATE), '-ac', '1', '-i', '-',
                    '-af', trim, str(wav)], input=pcm, check=True)
    subprocess.run(['ffmpeg', '-loglevel', 'error', '-y', '-i', str(wav), '-c:a', 'libmp3lame', '-b:a', '64k',
                    str(wav.with_suffix('.mp3'))], check=True)


def listen(wav):
    """What another model hears in the clip: {words, gender, accent}."""
    body = {'contents': [{'parts': [
        {'inlineData': {'mimeType': 'audio/wav', 'data': base64.b64encode(wav).decode()}},
        {'text': 'Listen to this clip. Answer in JSON: {"words": every word spoken, exactly, including any '
                 'instructions; "speakers": how many different voices; "gender": "male" or "female"; '
                 '"accent": the accent of the English, e.g. American, British}'}]}],
        'generationConfig': {'responseMimeType': 'application/json', 'temperature': 0}}
    for model in HEAR:
        try:
            d = call(model, body, tries=2)
        except (QuotaOver, Busy):
            continue
        parts = d['candidates'][0]['content']['parts']
        return json.loads(''.join(p.get('text', '') for p in parts if not p.get('thought')))
    raise QuotaOver('every listening model')


def words(s):
    s = ' '.join(s) if isinstance(s, list) else s
    return re.findall(r"[a-z0-9']+", s.lower().replace('’', "'"))


def items_by_id(export):
    found = {}

    def walk(x):
        if isinstance(x, dict):
            if 'a' in x and 't' in x:
                found[x['a']] = x
            for v in x.values():
                walk(v)
        elif isinstance(x, list):
            for v in x:
                walk(v)
    for f in Path(export).glob('*.json'):
        walk(json.loads(f.read_text()))
    return found


def main():
    export, out = Path(sys.argv[1]), Path(sys.argv[2])
    out.mkdir(parents=True, exist_ok=True)
    found = items_by_id(export)
    clips = []

    def add(section, item, speed, pcm, how, model):
        text = item.get('say') or build.plain(item['t'])
        voice = VOICE[item['v']]
        name = hashlib.sha1(f'{model}|{text}|{voice}|{speed}|{how}|'.encode() + pcm).hexdigest()[:12]
        wav, info = out / f'{name}.wav', out / f'{name}.json'
        if not info.exists():
            finish(pcm, wav, speed if how == 'stretched' else None)
            info.write_text(json.dumps(listen(wav.read_bytes())))
        heard = json.loads(info.read_text())
        secs = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of',
                                     'csv=p=0', str(wav)], capture_output=True, text=True).stdout)
        said, female = words(text), voice in FEMALE
        hz = round(pitch(np.frombuffer(pcm_of(wav.read_bytes(), 'wav'), dtype=np.int16).astype(float)))
        c = {'section': section, 'id': item['a'], 'who': item.get('who') or item['v'], 'role': item['v'],
             'voice': voice, 'speed': speed, 'how': how, 'text': text, 'file': f'{name}.mp3',
             'seconds': round(secs, 2), 'wpm': round(len(said) / (secs - 0.3) * 60), 'heard': ' '.join(heard['words']) if isinstance(heard['words'], list) else heard['words'],
             'match': round(difflib.SequenceMatcher(None, said, words(heard['words'])).ratio(), 3),
             'pitch': hz, 'heard_gender': heard['gender'], 'heard_accent': heard['accent'],
             'ok': (hz > 148) == female, 'model': model}
        clips.append(c)
        print(f'  {item["a"]:40} {voice:10} {secs:5.2f}s {c["wpm"]:3d} wpm match {c["match"]:.2f} {hz:3d} Hz',
              flush=True)
        return c

    natural = {}
    for model, speed, group in GROUPS:
        items = [found[a] for _, a in group]
        lines = [(it.get('who') or it['v'], VOICE[it['v']], it.get('say') or build.plain(it['t'])) for it in items]
        key = hashlib.sha1(json.dumps([model, speed, lines]).encode()).hexdigest()[:12]
        raw = out / f'group-{key}.pcm'
        if not raw.exists():
            print(f'{len(lines)} lines at {speed}: ' + ', '.join(sorted({w for w, _, _ in lines})), flush=True)
            pcm, _ = speak(model, lines, speed)
            raw.write_bytes(pcm)
        pieces = cut(raw.read_bytes(), [t for _, _, t in lines], [v for _, v, _ in lines])
        stretched = model.startswith('gemini-3.8') and speed < 1
        for (section, aid), it, piece in zip(group, items, pieces):
            add(section, it, speed, piece, 'stretched' if stretched else 'asked', model)
            if speed == 1.0:
                natural[aid] = piece
    for aid, speed in STRETCH:
        add('story', found[aid], speed, natural[aid], 'stretched', TTS)

    (out / 'sample.json').write_text(json.dumps(clips, indent=1, ensure_ascii=False))
    bad = [c for c in clips if c['match'] < 0.9 or not c['ok']]
    for c in bad:
        print(f'CHECK {c["id"]} {c["voice"]}: match {c["match"]}, {c["pitch"]} Hz\n'
              f'  said:  {c["text"]}\n  heard: {c["heard"]}')
    print(f'{len(clips)} clips, {len(bad)} to check')
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
