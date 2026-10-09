# -*- coding: utf-8 -*-
"""程序生成 UI 音效与氛围底噪 (WAV, 无第三方素材)"""
import math
import os
import random
import struct
import wave

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "missing_neighbor", "audio")
SR = 22050
random.seed(7)


def write_wav(name, samples):
    os.makedirs(ROOT, exist_ok=True)
    path = os.path.join(ROOT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))
    print("audio:", name)


def tone(freq, dur, vol=0.4, decay=8.0, shape="sine"):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t)
        if shape == "sine":
            v = math.sin(2 * math.pi * freq * t)
        else:
            v = 1.0 if math.sin(2 * math.pi * freq * t) > 0 else -1.0
        out.append(v * env * vol)
    return out


def mix(a, b, offset=0.0):
    n = max(len(a), len(b) + int(SR * offset))
    out = [0.0] * n
    for i, v in enumerate(a):
        out[i] += v
    off = int(SR * offset)
    for i, v in enumerate(b):
        out[off + i] += v
    return out


def click():
    write_wav("click.wav", tone(880, 0.07, 0.35, 40.0))


def success():
    s = mix(tone(660, 0.35, 0.35, 6.0), tone(990, 0.5, 0.35, 5.0), 0.12)
    write_wav("success.wav", s)


def fail():
    s = mix(tone(160, 0.3, 0.4, 7.0, "square"), tone(150, 0.3, 0.3, 7.0), 0.02)
    write_wav("fail.wav", s)


def ambience():
    """24 秒夜间氛围: 低通棕噪 + 低频 pad, 首尾淡化可循环"""
    dur = 24.0
    n = int(SR * dur)
    out = []
    brown = 0.0
    for i in range(n):
        t = i / SR
        brown += (random.random() * 2 - 1) * 0.02
        brown *= 0.998
        pad = 0.05 * math.sin(2 * math.pi * 55 * t) + 0.03 * math.sin(2 * math.pi * 82.5 * t + 0.7)
        v = brown * 1.6 + pad
        edge = min(1.0, t / 2.0, (dur - t) / 2.0)
        out.append(v * 0.5 * edge)
    write_wav("ambience.wav", out)


if __name__ == "__main__":
    click(); success(); fail(); ambience()
    print("DONE")
