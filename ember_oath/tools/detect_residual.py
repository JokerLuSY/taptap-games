# -*- coding: utf-8 -*-
"""扫描 v4 后的 ch1_bg.png, 精确定位残留物件 (屋顶/灰基座/黄灌木丛/棕黑水渍)"""
from PIL import Image
import sys

sys.stdout.reconfigure(encoding="utf-8")
SRC = r"E:\projects\taptap\ember_oath\art\maps\ch1_bg.png"
img = Image.open(SRC).convert("RGB")
W, H = img.size
px = img.load()


def spans(d, gap=10, thr=2):
    out = []
    s = None
    last = None
    for k in sorted(d):
        if d[k] < thr:
            continue
        if s is None:
            s = k
        elif k - last > gap:
            out.append((s, last))
            s = k
        last = k
    if s is not None:
        out.append((s, last))
    return out


def scan(name, box, mask, step=2):
    x0, y0, x1, y1 = box
    cols, rows, total = {}, {}, 0
    for y in range(y0, y1, step):
        for x in range(x0, x1, step):
            if mask(px[x, y]):
                cols[x] = cols.get(x, 0) + 1
                rows[y] = rows.get(y, 0) + 1
                total += 1
    if total < 12:
        print("%-26s 命中=%d (干净)" % (name, total))
        return
    print("%-26s 命中=%d" % (name, total))
    print("   x: %s" % spans(cols))
    print("   y: %s" % spans(rows))


def roof(c):
    r, g, b = c
    return r > 100 and r > g + 30 and r > b + 45 and g > b + 8 and r < 235


def greyring(c):
    r, g, b = c
    mx, mn = max(r, g, b), min(r, g, b)
    return mx - mn < 24 and 95 < mx < 185


def yellowbush(c):
    r, g, b = c
    return r > 165 and g > 120 and b < g - 62 and r < 245


def browndark(c):
    r, g, b = c
    return r > b + 12 and max(r, g, b) < 118


def woodwall(c):
    r, g, b = c
    return 140 < r < 210 and 100 < g < r - 25 and b < g - 25


print("=== 房D 残留 (x680-880, y180-280) ===")
scan("屋顶红棕", (680, 180, 880, 280), roof)
scan("木板墙", (680, 180, 880, 280), woodwall)
scan("灰石基座", (680, 180, 880, 280), greyring)
print("=== 井区 (x400-540, y60-210) ===")
scan("灰基座环", (400, 60, 540, 210), greyring)
scan("屋顶红棕", (400, 60, 540, 210), roof)
print("=== 麦田B残留 (x520-720, y150-270) ===")
scan("麦金黄", (520, 150, 720, 270), yellowbush)
print("=== 桥东水渍 (x370-480, y290-400) ===")
scan("棕黑渍", (370, 290, 480, 400), browndark)
print("=== 西南岩丘残留 (x0-300, y380-640) ===")
scan("灰岩", (0, 380, 300, 640), greyring)
scan("黄灌木", (0, 380, 300, 640), yellowbush)
print("=== 东南岩丘残留 (x680-960, y430-640) ===")
scan("灰岩", (680, 430, 960, 640), greyring)
print("=== 东金字塔残留 (x540-700, y400-560) ===")
scan("灰岩", (540, 400, 700, 560), greyring)
scan("深灰岩", (540, 400, 700, 560), lambda c: max(c) < 128 and max(c) - min(c) < 26)