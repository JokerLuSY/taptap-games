# -*- coding: utf-8 -*-
"""按已知窗口扫描色块密度, 输出每 8px 行列命中数, 精确定 bbox"""
from PIL import Image
import sys

sys.stdout.reconfigure(encoding="utf-8")
SRC = r"E:\projects\taptap\ember_oath\tools\shots\raw_crop.png"
img = Image.open(SRC).convert("RGB")
W, H = img.size
px = img.load()


def scan(name, box, mask, step=2):
    x0, y0, x1, y1 = box
    cols = {}
    rows = {}
    total = 0
    for y in range(y0, y1, step):
        for x in range(x0, x1, step):
            if mask(px[x, y]):
                cols[x] = cols.get(x, 0) + 1
                rows[y] = rows.get(y, 0) + 1
                total += 1
    if total < 10:
        print("%-22s 总命中=%d (太少, 跳过)" % (name, total))
        return
    # 找连续命中区 (容忍 6px 空洞)
    def spans(d, lo, hi, gap=8):
        out = []
        s = None
        last = None
        for k in sorted(d):
            if d[k] < 2:
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
    xs = spans(cols, x0, x1)
    ys = spans(rows, y0, y1)
    print("%-22s 命中=%d" % (name, total))
    print("   x spans: %s" % xs)
    print("   y spans: %s" % ys)


# 房子屋顶: 饱和暖棕红
def roof(c):
    r, g, b = c
    return r > 100 and r > g + 30 and r > b + 45 and g > b + 8 and r < 230


# 井橙锥顶: 更亮更橙
def cone(c):
    r, g, b = c
    return r > 150 and r > g + 45 and r > b + 70 and g > b + 15


# 麦田金黄
def wheat(c):
    r, g, b = c
    return r > 140 and g > 105 and b < g - 55 and g < r + 15 and r < 240


# 木板: 水平棕色条
def wood(c):
    r, g, b = c
    return r > 125 and g > 78 and b < g - 28 and r < 215 and r > g + 25


# 暗蓝水残留
def darkwater(c):
    r, g, b = c
    return b > 40 and max(r, g) < 78 and b < 130 and b > r + 14


# 石基座: 浅灰白
def stone(c):
    r, g, b = c
    mx, mn = max(r, g, b), min(r, g, b)
    return mx - mn < 22 and mx > 130 and mx < 215


scan("房A屋顶(160,0,330,130)", (160, 0, 330, 130), roof)
scan("房B屋顶(540,0,700,130)", (540, 0, 700, 130), roof)
scan("房C屋顶(20,140,170,260)", (20, 140, 170, 260), roof)
scan("房D屋顶(660,110,800,270)", (660, 110, 800, 270), roof)
scan("井锥顶-路东(430,60,540,180)", (430, 60, 540, 180), cone)
scan("井锥顶-路西(370,180,470,300)", (370, 180, 470, 300), cone)
scan("井石基座A(420,80,540,190)", (420, 80, 540, 190), stone)
scan("井石基座B(360,180,470,290)", (360, 180, 470, 290), stone)
scan("木平台(50,50,300,190)", (50, 50, 300, 190), wood)
scan("麦田B(550,70,690,210)", (550, 70, 690, 210), wheat)
scan("河黑残留(300,300,560,400)", (300, 300, 560, 400), darkwater)
scan("西山台基(100,420,240,560)", (100, 420, 240, 560), stone)
scan("东山台基(550,420,700,550)", (550, 420, 700, 550), stone)