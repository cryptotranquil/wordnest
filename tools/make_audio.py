#!/usr/bin/env python3
"""Synthesises WordNest's sound effects and chapter music (all original, no samples).

  python tools/make_audio.py            # writes assets/audio/sfx/*.mp3 and assets/audio/music/*.mp3
Needs: numpy, scipy, ffmpeg on PATH.  Tweak the numbers below and re-run to change the sound.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np
from scipy import signal

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
rng = np.random.default_rng(7)


def mtof(m):
    return 440.0 * 2 ** ((m - 69) / 12.0)


def write_mp3(path, left, right=None, sr=44100, kbps=96):
    right = left if right is None else right
    data = np.stack([left, right], axis=1)
    data = np.clip(data, -1, 1)
    pcm = (data * 32767).astype("<i2")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        wav_path = tmp.name
    with wave.open(wav_path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(sr)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", wav_path, "-codec:a", "libmp3lame",
                    "-b:a", f"{kbps}k", path], check=True)
    os.remove(wav_path)


# ------------------------------------------------------------------ sound effects
SR = 44100


def t_axis(dur):
    return np.arange(int(SR * dur)) / SR


def fade_edges(x, a=0.004, r=0.02):
    n = len(x)
    na, nr = int(SR * a), int(SR * r)
    x = x.copy()
    if na:
        x[:na] *= np.linspace(0, 1, na)
    if nr:
        x[-nr:] *= np.linspace(1, 0, nr)
    return x


def bell(freq, dur=0.6, decay=5.0, partials=((1, 1.0, 1.0), (2.76, 0.30, 1.6), (5.4, 0.10, 2.4)), vol=1.0):
    t = t_axis(dur)
    x = np.zeros_like(t)
    for ratio, amp, d in partials:
        x += amp * np.sin(2 * np.pi * freq * ratio * t) * np.exp(-t * decay * d)
    return fade_edges(x * vol, 0.003, 0.03)


def soft_chime(freq, dur=0.5, vol=1.0):
    return bell(freq, dur, decay=6.5, partials=((1, 1.0, 1.0), (2.0, 0.22, 1.5), (3.0, 0.08, 2.0)), vol=vol)


def noise_band(dur, lo, hi):
    n = int(SR * dur)
    x = rng.standard_normal(n)
    sos = signal.butter(2, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def mix(parts, total):
    out = np.zeros(int(SR * total))
    for start, sig in parts:
        i = int(SR * start)
        out[i:i + len(sig)] += sig[: len(out) - i]
    return out


def small_reverb(x, wet=0.18, tail=0.5):
    n = int(SR * tail)
    ir = rng.standard_normal(n) * np.exp(-np.arange(n) / (SR * tail / 4))
    ir[0] = 0
    y = signal.fftconvolve(x, ir)[: len(x) + n]
    out = np.zeros(len(y))
    out[: len(x)] += x
    out += wet * y / (np.max(np.abs(y)) + 1e-9) * np.max(np.abs(x))
    return out


def finish(x, peak=0.6):
    x = x / (np.max(np.abs(x)) + 1e-9) * peak
    return fade_edges(x, 0.002, 0.04)


def make_sfx():
    d = os.path.join(OUT, "sfx")
    sfx = {}

    # UI
    tap = noise_band(0.06, 900, 2500) * np.exp(-t_axis(0.06) * 70) + 0.8 * np.sin(2 * np.pi * 330 * t_axis(0.06)) * np.exp(-t_axis(0.06) * 60)
    sfx["ui_tap"] = finish(tap, 0.45)
    sfx["toggle"] = finish(mix([(0, bell(1500, 0.08, 40, ((1, 1, 1),))), (0, 0.4 * bell(2250, 0.06, 50, ((1, 1, 1),)))], 0.1), 0.35)

    # letters: D major pentatonic climbing, one per letter selected
    for i, m in enumerate([74, 76, 78, 81, 83, 86, 88], start=1):
        sfx[f"letter_{i}"] = finish(soft_chime(mtof(m), 0.38), 0.5)

    # word feedback
    arp = mix([(k * 0.085, bell(mtof(m), 0.9, 4.5, vol=1 - 0.1 * k)) for k, m in enumerate([74, 78, 81, 86])], 1.2)
    sfx["word_correct"] = finish(small_reverb(arp, 0.2), 0.6)
    sp = [(k * 0.045, bell(f, 0.7, 6.0, ((1, 1, 1), (2.0, 0.3, 1.5)), vol=0.8)) for k, f in
          enumerate(rng.choice([1568, 1760, 2093, 2349, 2637, 3136], 7))]
    sfx["word_bonus"] = finish(small_reverb(mix(sp, 1.0), 0.25), 0.55)
    t = t_axis(0.32)
    f = 190 - 70 * t / 0.32
    sfx["word_wrong"] = finish(np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * 11) + 0.15 * noise_band(0.32, 120, 600) * np.exp(-t * 20), 0.4)
    sfx["word_repeat"] = finish(mix([(0, bell(520, 0.12, 30, ((1, 1, 1),))), (0.1, bell(520, 0.12, 30, ((1, 1, 1),)))], 0.3), 0.35)

    # shuffle: airy swirl
    dur = 0.6
    t = t_axis(dur)
    bands = [(200, 500), (500, 1200), (1200, 2600), (2600, 5000)]
    sw = np.zeros_like(t)
    for k, (lo, hi) in enumerate(bands):
        centre = (k + 0.5) / len(bands) * dur
        env = np.exp(-((t - centre) / 0.11) ** 2)
        sw += noise_band(dur, lo, hi) * env
    sw *= np.sin(np.pi * t / dur) ** 1.5
    glide = np.sin(2 * np.pi * np.cumsum(260 + 700 * t / dur) / SR) * 0.15 * np.sin(np.pi * t / dur)
    sfx["shuffle"] = finish(sw / np.max(np.abs(sw)) * 0.8 + glide, 0.5)

    # boosters
    sfx["hint"] = finish(small_reverb(mix([(0, bell(880, 0.9, 4, vol=1)), (0.09, bell(1175, 0.8, 5, vol=0.7)),
                                           (0.18, bell(1568, 0.8, 5, vol=0.6))], 1.2), 0.2), 0.55)
    ping = bell(1000, 1.4, 3.5, ((1, 1, 1), (2.0, 0.15, 2.0)))
    sfx["target"] = finish(mix([(0, ping), (0.28, 0.45 * ping), (0.56, 0.2 * ping)], 1.9), 0.5)

    # rewards
    sfx["coin"] = finish(mix([(0, bell(1318, 0.5, 9, ((1, 1, 1), (3.0, 0.2, 2.0)))), (0.07, bell(1760, 0.6, 8, ((1, 1, 1), (3.0, 0.2, 2.0))))], 0.8), 0.5)
    arp = mix([(k * 0.16, bell(mtof(m), 1.6, 3.0, vol=1 - 0.05 * k)) for k, m in enumerate([62, 69, 74, 78, 81, 88])], 3.0)
    t = t_axis(3.0)
    pad = sum(np.sin(2 * np.pi * mtof(m) * t) for m in (50, 57, 62, 66, 69)) * np.minimum(t / 0.8, 1) * np.exp(-np.maximum(t - 1.2, 0) * 1.4) * 0.12
    sfx["level_complete"] = finish(small_reverb(arp + pad, 0.3, 0.8), 0.6)
    sp = [(k * 0.06, bell(mtof(m), 1.2, 4.0, vol=0.9)) for k, m in enumerate([81, 84, 88, 91, 93, 96])]
    sfx["reward_claim"] = finish(small_reverb(mix(sp + [(0.4, bell(mtof(69), 1.4, 3.0)), (0.4, bell(mtof(76), 1.4, 3.0, vol=0.8))], 2.0), 0.28, 0.7), 0.55)
    t = t_axis(3.2)
    swell = sum(np.sin(2 * np.pi * mtof(m) * t) for m in (57, 64, 69, 73, 76)) * np.sin(np.pi * np.minimum(t / 3.2, 1)) ** 2 * 0.15
    shimmer = mix([(0.5 + k * 0.28, bell(mtof(m), 1.4, 3.5, vol=0.7)) for k, m in enumerate([88, 92, 93, 95, 100])], 3.2)
    sfx["chapter_unlock"] = finish(small_reverb(swell + shimmer, 0.3, 0.9), 0.55)
    sfx["mission_claim"] = finish(small_reverb(mix([(0, bell(mtof(81), 0.9, 4.5)), (0.1, bell(mtof(86), 0.9, 4.5)), (0.2, bell(mtof(90), 1.0, 4.0))], 1.3), 0.2), 0.55)

    for name, x in sfx.items():
        write_mp3(os.path.join(d, name + ".mp3"), x, sr=SR, kbps=80)
    print(f"sfx: wrote {len(sfx)} files")


# ------------------------------------------------------------------ music (seamless 48 s loops)
MSR = 32000
LOOP = 48.0
N = int(MSR * LOOP)
CH = 8.0  # seconds per chord


def add_wrap(buf, sig, start):
    start %= len(buf)
    first = min(len(sig), len(buf) - start)
    buf[start:start + first] += sig[:first]
    rest = len(sig) - first
    if rest > 0:
        buf[:rest] += sig[first:first + rest]


def pad_voice(midi, dur, detune=0.0, vib=0.0):
    t = np.arange(int(MSR * dur)) / MSR
    f = mtof(midi) * 2 ** (detune / 1200.0)
    ph = 2 * np.pi * f * t + vib * np.sin(2 * np.pi * 0.23 * t)
    x = np.sin(ph) + 0.30 * np.sin(2 * ph) + 0.10 * np.sin(3 * ph)
    att, rel = 2.6, 3.2
    env = np.ones_like(t)
    na, nr = int(MSR * att), int(MSR * rel)
    env[:na] = 0.5 - 0.5 * np.cos(np.linspace(0, np.pi, na))
    env[-nr:] = np.minimum(env[-nr:], 0.5 + 0.5 * np.cos(np.linspace(0, np.pi, nr)))
    return x * env


def pluck_note(midi, decay=2.4, vol=1.0):
    t = np.arange(int(MSR * 3.5)) / MSR
    f = mtof(midi)
    x = (np.sin(2 * np.pi * f * t) * np.exp(-t * decay)
         + 0.25 * np.sin(2 * np.pi * f * 2.0 * t) * np.exp(-t * decay * 1.8)
         + 0.08 * np.sin(2 * np.pi * f * 4.2 * t) * np.exp(-t * decay * 3.0))
    x[: int(MSR * 0.004)] *= np.linspace(0, 1, int(MSR * 0.004))
    return x * vol


def circular_filter(x, lo=None, hi=None):
    X = np.fft.rfft(x)
    f = np.fft.rfftfreq(len(x), 1 / MSR)
    m = np.ones_like(f)
    if lo:
        m *= 1 / (1 + (lo / np.maximum(f, 1e-3)) ** 4)
    if hi:
        m *= 1 / (1 + (f / hi) ** 4)
    return np.fft.irfft(X * m, len(x))


def circular_reverb(x, seconds=3.2, seed=0):
    r = np.random.default_rng(seed)
    n = int(MSR * seconds)
    ir = r.standard_normal(n) * np.exp(-np.arange(n) / (MSR * seconds / 4.2))
    ir = circular_filter(np.pad(ir, (0, len(x) - n)), 150, 5500)[:n] if len(x) > n else ir
    ir[: int(MSR * 0.02)] *= np.linspace(0, 1, int(MSR * 0.02))
    IR = np.fft.rfft(ir, len(x))
    return np.fft.irfft(np.fft.rfft(x) * IR, len(x))


THEMES = {
    # name: chords [(pad midi notes, bass midi)], pluck pool (midi), step seconds, play prob, extras
    "forest": dict(
        chords=[([62, 66, 69, 73], 38), ([59, 62, 66, 69], 35 + 12), ([55, 59, 62, 66], 43),
                ([57, 61, 64, 66, 69], 45), ([54, 57, 61, 64], 42 + 12), ([52, 55, 59, 62, 66], 40 + 12)],
        pool=[74, 76, 78, 81, 83, 86, 88, 90], step=1.0, prob=0.62, decay=2.6, wind=0.020, wave=0.0),
    "ocean": dict(
        chords=[([53, 57, 60, 64], 41), ([50, 53, 57, 60, 64], 38 + 12), ([46 + 12, 53, 57, 62], 46),
                ([55, 58, 62, 65], 43), ([48, 55, 60, 62, 64], 48), ([57, 60, 64, 67], 45)],
        pool=[72, 74, 77, 79, 81, 84, 86, 89], step=0.75, prob=0.7, decay=2.0, wind=0.0, wave=0.10),
    "cosmos": dict(
        chords=[([57, 60, 64, 67, 71], 45), ([53, 57, 60, 64], 41), ([48, 55, 59, 64], 48),
                ([52, 59, 62, 67], 40 + 12), ([50, 57, 60, 64], 38 + 12), ([53, 57, 60, 64], 41)],
        pool=[81, 84, 86, 88, 91, 93, 96], step=2.0, prob=0.38, decay=1.0, wind=0.0, wave=0.0),
}


def render_theme(name):
    th = THEMES[name]
    r = np.random.default_rng({"forest": 1, "ocean": 2, "cosmos": 3}[name])
    L = np.zeros(N)
    R = np.zeros(N)
    for ci, (notes, bass) in enumerate(th["chords"]):
        start = int(MSR * ci * CH)
        dur = CH + 3.2
        for k, m in enumerate(notes):
            lv = 0.16 / np.sqrt(len(notes))
            add_wrap(L, lv * pad_voice(m, dur, detune=-4 + k, vib=0.15), start)
            add_wrap(R, lv * pad_voice(m, dur, detune=+4 - k, vib=0.15), start)
        b = 0.20 * pad_voice(bass - 12 if bass > 45 else bass, dur)
        add_wrap(L, b, start)
        add_wrap(R, b, start)

    # plucks (kalimba / harp / star bells)
    idx = len(th["pool"]) // 2
    t = 0.0
    while t < LOOP - 1e-6:
        if r.random() < th["prob"]:
            idx = int(np.clip(idx + r.integers(-2, 3), 0, len(th["pool"]) - 1))
            note = pluck_note(th["pool"][idx], th["decay"], vol=0.07 * r.uniform(0.6, 1.0))
            pan = r.uniform(0.15, 0.85)
            s = int(MSR * (t + r.uniform(-0.02, 0.02)))
            add_wrap(L, note * np.cos(pan * np.pi / 2), s)
            add_wrap(R, note * np.sin(pan * np.pi / 2), s)
        t += th["step"]

    tt = np.arange(N) / MSR
    if th["wave"]:  # sea swell, 8 s period divides the loop exactly
        for ch, seed in ((L, 11), (R, 12)):
            nz = circular_filter(np.random.default_rng(seed).standard_normal(N), 80, 900)
            lfo = (0.5 + 0.5 * np.sin(2 * np.pi * tt / 8.0 + (0.0 if seed == 11 else 1.2))) ** 2
            ch += th["wave"] * nz / np.std(nz) * lfo * 0.25
    if th["wind"]:  # forest air
        for ch, seed in ((L, 21), (R, 22)):
            nz = circular_filter(np.random.default_rng(seed).standard_normal(N), 250, 1400)
            lfo = 0.6 + 0.4 * np.sin(2 * np.pi * tt / 12.0 + seed)
            ch += th["wind"] * nz / np.std(nz) * lfo * 0.25
    if name == "cosmos":  # faint shimmer drone
        for k, m in enumerate([93, 96, 100]):
            sh = np.sin(2 * np.pi * mtof(m) * tt + 0.3 * np.sin(2 * np.pi * (0.17 + 0.04 * k) * tt)) * (0.5 + 0.5 * np.sin(2 * np.pi * tt / 16.0 + k * 2.1))
            sh *= 0.012
            L += sh * (1 - 0.3 * k / 2)
            R += sh * (0.7 + 0.3 * k / 2)

    wl = circular_reverb(L, 3.2, 1)
    wr = circular_reverb(R, 3.2, 2)
    L = 0.7 * L + 0.55 * wl / (np.std(wl) + 1e-9) * np.std(L) * 0.9
    R = 0.7 * R + 0.55 * wr / (np.std(wr) + 1e-9) * np.std(R) * 0.9

    rms = np.sqrt(np.mean(np.stack([L, R]) ** 2))
    g = 0.085 / rms  # quiet background level; the app volume slider scales it
    L, R = np.tanh(L * g * 1.4) / 1.4, np.tanh(R * g * 1.4) / 1.4
    peak = max(np.max(np.abs(L)), np.max(np.abs(R)))
    seam = max(abs(L[0] - L[-1]), abs(R[0] - R[-1]))
    return L, R, peak, seam


def make_music():
    d = os.path.join(OUT, "music")
    for name in THEMES:
        L, R, peak, seam = render_theme(name)
        write_mp3(os.path.join(d, f"chapter_{name}.mp3"), L, R, sr=MSR, kbps=96)
        step = np.max(np.abs(np.diff(L)))
        print(f"music {name}: peak {peak:.2f}, loop-seam jump {seam:.4f} (max normal step {step:.4f})")


if __name__ == "__main__":
    make_sfx()
    make_music()
