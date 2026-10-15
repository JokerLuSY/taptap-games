# -*- coding: utf-8 -*-
"""《余烬之誓》程序生成音效与 BGM (WAV, 无第三方素材)
用法: python ember_oath/tools/generate_audio.py
"""
import math
import os
import random
import struct
import wave

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "audio")
SR = 22050
random.seed(2026)


# ---------------- 基础工具 ----------------

def write_wav(name, samples):
    os.makedirs(ROOT, exist_ok=True)
    # 限制器: 防止爆音
    peak = max(0.001, max(abs(s) for s in samples))
    if peak > 0.95:
        samples = [s * 0.95 / peak for s in samples]
    path = os.path.join(ROOT, name)
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(b"".join(struct.pack("<h", max(-32767, min(32767, int(s * 32767)))) for s in samples))
    print("audio:", name)


def tone(freq, dur, vol=0.4, decay=8.0, shape="sine", offset_samples=0):
    n = int(SR * dur)
    out = [0.0] * offset_samples
    for i in range(n):
        t = i / SR
        env = math.exp(-decay * t)
        ph = math.sin(2 * math.pi * freq * t)
        if shape == "sine":
            v = ph
        elif shape == "tri":
            v = 4 * abs((freq * t) % 1.0 - 0.5) - 1
        else:  # square
            v = (0.6 if ph > 0 else -0.6)
        out.append(v * env * vol)
    return out


def sweep(f1, f2, dur, vol=0.4, decay=8.0, offset_samples=0):
    n = int(SR * dur)
    out = [0.0] * offset_samples
    phase = 0.0
    for i in range(n):
        t = i / SR
        f = f1 + (f2 - f1) * t / dur
        phase += 2 * math.pi * f / SR
        env = math.exp(-decay * t)
        out.append(math.sin(phase) * env * vol)
    return out


def noise(dur, vol=0.4, decay=8.0, smooth=4, offset_samples=0):
    """简易低通白噪"""
    n = int(SR * dur)
    out = [0.0] * offset_samples
    last = 0.0
    for i in range(n):
        t = i / SR
        w = random.random() * 2 - 1
        last += (w - last) / smooth
        out.append(last * math.exp(-decay * t) * vol)
    return out


def whoosh(dur, vol=0.4, smooth=6):
    """起-落包络的风声"""
    n = int(SR * dur)
    out = []
    last = 0.0
    for i in range(n):
        t = i / SR
        w = random.random() * 2 - 1
        last += (w - last) / smooth
        env = math.sin(math.pi * t / dur) ** 1.5
        out.append(last * env * vol)
    return out


def mix(*tracks):
    n = max(len(t) for t in tracks)
    out = [0.0] * n
    for t in tracks:
        for i, v in enumerate(t):
            out[i] += v
    return out


def off(samples, sec):
    return [0.0] * int(SR * sec) + samples


NOTE = lambda m: 440.0 * 2 ** ((m - 69) / 12)


def seq_note(midi, dur, vol=0.3, shape="square", attack=0.008, release=0.06):
    freq = NOTE(midi)
    n = int(SR * dur)
    out = []
    for i in range(n):
        t = i / SR
        env = min(1.0, t / attack, (dur - t) / release)
        if env < 0:
            env = 0.0
        ph = math.sin(2 * math.pi * freq * t)
        if shape == "square":
            v = 0.55 if ph > 0 else -0.55
        elif shape == "tri":
            v = 4 * abs((freq * t) % 1.0 - 0.5) - 1
        else:
            v = ph
        out.append(v * env * vol)
    return out


def sequence(notes, vol=0.3, shape="square", gap=0.0):
    """notes: [(midi, dur), ...] 依次排布, midi=None 为休止"""
    out = []
    for midi, dur in notes:
        if midi is None:
            out += [0.0] * int(SR * dur)
        else:
            out += seq_note(midi, dur - gap, vol, shape) + [0.0] * int(SR * gap)
    return out


# ---------------- 音效 ----------------

def sfx():
    write_wav("cursor.wav", tone(1250, 0.03, 0.22, 60))
    write_wav("select.wav", mix(tone(880, 0.05, 0.30, 40), off(tone(1318, 0.07, 0.22, 40), 0.035)))
    write_wav("cancel.wav", mix(tone(523, 0.05, 0.30, 40), off(tone(392, 0.08, 0.28, 40), 0.04)))
    write_wav("move.wav", whoosh(0.22, 0.30, 5))
    write_wav("sword.wav", mix(noise(0.10, 0.45, 25, 2), off(tone(2093, 0.12, 0.18, 18), 0.02)))
    write_wav("lance.wav", mix(sweep(500, 1500, 0.09, 0.30, 10), off(noise(0.06, 0.30, 30, 2), 0.07)))
    write_wav("axe.wav", mix(tone(130, 0.22, 0.50, 10, "square"), off(noise(0.15, 0.40, 20, 3), 0.01)))
    write_wav("bow.wav", mix(sweep(700, 250, 0.10, 0.35, 25), off(whoosh(0.14, 0.30, 6), 0.08)))
    write_wav("miss.wav", whoosh(0.20, 0.35, 7))
    # 暴击: 低频重击 + 噪声碎裂 + 高频金属鸣
    write_wav("crit.wav", mix(tone(95, 0.25, 0.50, 10, "square"), noise(0.12, 0.45, 22, 2), off(tone(2637, 0.20, 0.22, 16), 0.03)))
    write_wav("heal.wav", mix(tone(1318.5, 0.10, 0.22, 8), off(tone(1568, 0.25, 0.20, 6), 0.08)))
    write_wav("coin.wav", mix(tone(987.77, 0.05, 0.28, 30), off(tone(1318.5, 0.18, 0.24, 14), 0.05)))
    write_wav("phase.wav", mix(tone(659.25, 0.10, 0.25, 12), off(tone(987.77, 0.14, 0.20, 12), 0.06)))
    write_wav("talk.wav", tone(950, 0.025, 0.15, 55))
    write_wav("reinforce.wav", mix(tone(110, 0.35, 0.30, 8, "square"), off(tone(164.8, 0.35, 0.22, 8), 0.06)))
    # 升级: 上行琶音
    lv = []
    for m in [72, 76, 79, 84]:
        lv = mix(lv, off(seq_note(m, 0.30, 0.28, "square"), 0))
        lv += [0.0] * int(SR * 0.09) if False else []
    arp = []
    t = 0.0
    for m in [72, 76, 79, 84]:
        arp = mix(arp, off(seq_note(m, 0.28, 0.26, "square"), t))
        t += 0.09
    write_wav("levelup.wav", arp)
    # 胜利小号角
    vic = []
    t = 0.0
    for m, d in [(74, 0.11), (78, 0.11), (81, 0.11), (86, 0.22), (81, 0.10), (83, 0.10), (86, 0.45)]:
        vic = mix(vic, off(seq_note(m, d, 0.26, "square"), t))
        t += d + 0.01
    write_wav("victory.wav", vic)
    # 战败下行音
    dft = []
    t = 0.0
    for m in [69, 65, 62, 57]:
        dft = mix(dft, off(seq_note(m, 0.30, 0.32, "sine"), t))
        t += 0.26
    write_wav("defeat.wav", dft)


# ---------------- BGM ----------------

def bgm_map():
    """村庄晨光: D 大调, 100bpm, 8 小节, 9.6s 循环"""
    e = 0.3  # 八分音符
    lead = [
        (74, e), (78, e), (81, 2 * e),
        (79, e), (78, e), (76, 2 * e),
        (74, e), (76, e), (78, 2 * e),
        (76, 3 * e),
        (78, e), (81, e), (83, 2 * e),
        (81, e), (79, e), (78, 2 * e),
        (79, e), (78, e), (76, 2 * e),
        (74, 4 * e),
    ]
    bass_roots = [50, 45, 47, 43, 50, 45, 52, 45]  # D A Bm G D A Em A
    bass = []
    for root in bass_roots:
        bass += [(root, 0.55), (root, 0.55), (None, 0.1)]
    lead_track = sequence(lead, 0.20, "square", 0.01)
    bass_track = sequence(bass, 0.26, "tri", 0.01)
    write_wav("bgm_map.wav", mix(lead_track, bass_track))


def bgm_combat():
    """战斗: d 小调, 132bpm 紧张短循环"""
    e = 0.227
    lead = [
        (74, e), (74, e), (77, e), (79, e),
        (81, e), (82, e), (81, e), (79, e),
        (77, e), (79, e), (81, e), (77, e),
        (79, 2 * e), (81, e), (86, 3 * e),
        (82, e), (81, e), (79, e), (77, e),
        (76, e), (74, 3 * e),
    ]
    n_eighths = 24
    bass = []
    for i in range(n_eighths):
        root = 45 if i >= 20 else 50  # 结尾 A2 回转
        bass.append((root, e * 0.9))
    lead_track = sequence(lead, 0.21, "square", 0.008)
    bass_track = sequence(bass, 0.28, "tri", 0.006)
    write_wav("bgm_combat.wav", mix(lead_track, bass_track))


if __name__ == "__main__":
    sfx()
    bgm_map()
    bgm_combat()
    print("DONE")
