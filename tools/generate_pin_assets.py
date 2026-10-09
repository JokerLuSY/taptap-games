# -*- coding: utf-8 -*-
"""《见缝插针》资源生成: 音效(8 档音高 tick + fail + win) + 应用图标"""
import math
import os
import struct
import wave
from PIL import Image, ImageDraw

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "pin_circle")
SR = 22050


def write_wav(name, samples):
    out_dir = os.path.join(ROOT, "audio")
    os.makedirs(out_dir, exist_ok=True)
    with wave.open(os.path.join(out_dir, name), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))
    print("audio:", name)


def tone(freq, dur, vol=0.4, decay=30.0, shape="sine", sweep_to=None):
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        f = freq + (sweep_to - freq) * (i / n) if sweep_to else freq
        env = math.exp(-decay * t)
        ph = 2 * math.pi * f * t
        v = math.sin(ph) if shape == "sine" else (1.0 if math.sin(ph) > 0 else -1.0)
        out.append(v * env * vol)
    return out


def mix_at(base, add, offset):
    n = max(len(base), len(add) + int(SR * offset))
    out = list(base) + [0.0] * (n - len(base))
    off = int(SR * offset)
    for i, v in enumerate(add):
        out[off + i] += v
    return out


def gen_audio():
    # 8 档音高, 连插有音阶上行感
    scale = [1.0, 1.125, 1.25, 1.333, 1.5, 1.667, 1.875, 2.0]
    for i, ratio in enumerate(scale):
        write_wav("tick_%d.wav" % i, tone(880 * ratio, 0.09, 0.42, 34.0))
    write_wav("fail.wav", tone(240, 0.4, 0.45, 6.0, "square", sweep_to=70))
    win = tone(660, 0.3, 0.35, 8.0)
    win = mix_at(win, tone(880, 0.3, 0.35, 8.0), 0.1)
    win = mix_at(win, tone(1320, 0.45, 0.35, 7.0), 0.2)
    write_wav("win.wav", win)


def gen_icon():
    img = Image.new("RGB", (512, 512), (10, 14, 28))
    d = ImageDraw.Draw(img)
    cx, cy, r = 256, 226, 150
    d.ellipse([cx - r - 18, cy - r - 18, cx + r + 18, cy + r + 18], outline=(40, 120, 150), width=10)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], outline=(60, 220, 255), width=16)
    for deg in [30, 110, 190, 310]:
        a = math.radians(deg)
        x0, y0 = cx + math.cos(a) * (r - 12), cy + math.sin(a) * (r - 12)
        x1, y1 = cx + math.cos(a) * (r + 74), cy + math.sin(a) * (r + 74)
        d.line([(x0, y0), (x1, y1)], fill=(255, 184, 77), width=12)
        d.ellipse([x1 - 20, y1 - 20, x1 + 20, y1 + 20], fill=(255, 184, 77))
    d.line([(256, 500), (256, 420)], fill=(255, 184, 77), width=12)
    d.ellipse([236, 396, 276, 436], fill=(255, 184, 77))
    d.text((196, 200), "aa", fill=(10, 14, 28))
    img.save(os.path.join(ROOT, "icon.png"))
    print("icon: icon.png")


if __name__ == "__main__":
    gen_audio()
    gen_icon()
    print("DONE")
