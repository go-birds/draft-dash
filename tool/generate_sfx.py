#!/usr/bin/env python3
"""Synthesize Draft Dash SFX as WAV (stdlib only — self-made, license-free)."""
import math, os, random, struct, wave

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
os.makedirs(OUT, exist_ok=True)


def write(name, samples):
    # normalize
    peak = max(1e-6, max(abs(s) for s in samples))
    g = 0.92 / peak
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "w") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * g)) * 32767)) for s in samples))
    print("wrote", path, len(samples), "samples")


def env(i, n, attack=0.01, release=0.3):
    t = i / n
    a = min(1.0, (i / SR) / attack) if attack > 0 else 1.0
    r = min(1.0, ((n - i) / SR) / release) if release > 0 else 1.0
    return a * r


def tone(freq, dur, harmonics=(1,), amp=1.0, attack=0.01, release=0.2, vibrato=0.0, vrate=6):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = freq * (1 + vibrato * math.sin(2 * math.pi * vrate * t))
        s = 0.0
        for k, h in enumerate(harmonics, start=1):
            s += h * math.sin(2 * math.pi * f * k * t)
        out.append(s * amp * env(i, n, attack, release))
    return out


def noise(dur, release=0.12, lp=0.5):
    n = int(SR * dur)
    out = []
    prev = 0.0
    for i in range(n):
        x = random.uniform(-1, 1)
        prev = prev + lp * (x - prev)  # simple low-pass
        out.append(prev * env(i, n, 0.001, release))
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, s in enumerate(t):
            out[i] += s
    return out


# countdown beep — clean blip
write("beep", tone(880, 0.10, harmonics=(1, 0.2), attack=0.005, release=0.08))

# referee whistle — bright, trilled, a little breath
whistle = mix(
    tone(2300, 0.5, harmonics=(1, 0.35), amp=1.0, attack=0.02, release=0.18, vibrato=0.012, vrate=18),
    [s * 0.18 for s in noise(0.5, release=0.18, lp=0.85)],
)
write("whistle", whistle)

# air horn — fat detuned chord
horn = mix(
    tone(440, 0.8, harmonics=(1, 0.5, 0.33, 0.25, 0.2), amp=0.5, attack=0.03, release=0.25),
    tone(554, 0.8, harmonics=(1, 0.5, 0.33, 0.25, 0.2), amp=0.45, attack=0.03, release=0.25),
    tone(660, 0.8, harmonics=(1, 0.5, 0.33), amp=0.30, attack=0.04, release=0.25),
)
write("airhorn", horn)

# card flip — short "fwip" noise
write("card_flip", noise(0.13, release=0.11, lp=0.6))

# lottery ball — light "tok"
ball = mix(
    tone(320, 0.10, harmonics=(1, 0.4), amp=0.8, attack=0.002, release=0.09),
    [s * 0.3 for s in noise(0.06, release=0.05, lp=0.4)],
)
write("ball", ball)
