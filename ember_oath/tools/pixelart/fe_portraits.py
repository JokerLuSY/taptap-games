"""炎烬之誓：原创 GBA 火纹风像素对话立绘（64×64 半身像，游戏里 ×2 显示）。

每个有名字的角色单独画：发型轮廓、一缕缕发丝、服装（领口、护甲、皮带、褶皱）都按角色手工摆放；
脸部用 fe_faces 里手工逐像素画好的底稿（女 / 少年 / 男 / 老），再换眼型、眉形、嘴型、伤疤。
用法：python -P -E fe_portraits.py <输出目录> [预览.png] [只画哪些，逗号分隔]
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fe_faces import (S, FACE_X, FACE_Y, Canvas, ramp, mix, hx, face_grid, poly, ellipse, border, fill, strand)  # noqa: E402
from PIL import Image  # noqa: E402


# ======================= 公共小工具 =======================

def face_pal(skin="#f4c8a0", eye="#c06a2a", brow=None, lip="#d88078"):
    sk = ramp(skin)
    ey = ramp(eye)
    return {"k": sk[5], "1": sk[1], "2": sk[2], "3": sk[3], "4": sk[4], "o": sk[3],
            "p": (36, 18, 28), "w": (250, 248, 240), "E": ey[3], "e": ey[1], "h": (255, 255, 255),
            "n": hx(brow) if brow else (90, 40, 30), "m": mix(sk[4], (120, 40, 40), 0.4), "M": hx(lip),
            "r": mix(sk[2], (240, 120, 120), 0.45), "s": (176, 84, 76)}


def draw_face(cv, kind, skin, eye, brow, **kw):
    cv.grid(face_grid(kind, **kw), face_pal(skin, eye, brow), FACE_X, FACE_Y)


def hair_mass(cv, masks, rp, lines=True, shine=None, band=(0.18, -0.2, -0.6)):
    """头发：几块蒙版合起来整体上色（左上来光），每缕之间描一条暗线；shine = 高光像素"""
    union = set()
    for m in masks:
        union |= m
    fill(cv, union, rp, band=band)
    ub = border(union)
    if lines:
        seen = set()
        for m in masks:
            for (x, y) in border(m):
                if (x, y) in seen and (x, y) not in ub:
                    cv.put(x, y, rp[4])
            seen |= m
    if shine:
        for (x, y) in shine:
            if (x, y) in union and (x, y) not in ub:
                cv.put(x, y, rp[0])
    return union


def shine_arc(cx, cy, r, a0, a1, gaps=(3,)):
    import math
    out = []
    n = int(abs(a1 - a0) / 180 * math.pi * r) + 1
    for i in range(n):
        if i % 7 in gaps:
            continue
        a = math.radians(a0 + (a1 - a0) * i / max(1, n - 1))
        x, y = int(round(cx + r * math.cos(a))), int(round(cy - r * math.sin(a)))
        out += [(x, y), (x, y + 1)]
    return out


def shoulders(top=46, neck=(27, 36), wide=(2, 61)):
    """肩膀轮廓：从脖根往两侧斜下到画布底"""
    l, r = neck
    return poly([(l, top), (r + 1, top), (r + 9, top + 3), (wide[1], top + 11), (wide[1] + 2, 65), (wide[0] - 2, 65), (wide[0], top + 11), (l - 9, top + 3)])


def seg(a, b):
    (x0, y0), (x1, y1) = a, b
    n = int(round(max(abs(x1 - x0), abs(y1 - y0), 1)))
    return [(int(round(x0 + (x1 - x0) * t / n)), int(round(y0 + (y1 - y0) * t / n))) for t in range(n + 1)]


def thick(pts, w=1):
    out = set()
    for (x, y) in pts:
        for d in range(-w, w + 1):
            out.add((x, y + d))
    return out


def clip_y(mask, y0=None, y1=None):
    return {p for p in mask if (y0 is None or p[1] >= y0) and (y1 is None or p[1] <= y1)}


def px(cv, pts, c):
    for p in pts:
        cv.put(p[0], p[1], c)


# ======================= 角色 =======================

def hair_poly(cv, outline_pts, rp, strands=(), shine=None, band=(0.18, -0.2, -0.6)):
    """头发：手画的整体轮廓（多边形）+ 里面的发丝暗线 + 高光；轮廓外描边"""
    mask = poly(outline_pts)
    fill(cv, mask, rp, band=band)
    edge = border(mask)
    for line in strands:
        for a, b in zip(line, line[1:]):
            for p in seg(a, b):
                if p in mask and p not in edge:
                    cv.put(p[0], p[1], rp[4])
    if shine:
        for p in shine:
            if p in mask and p not in edge:
                cv.put(p[0], p[1], rp[0])
    return mask


def pauldron(cv, cx, cy, rp, rx=9, ry=6, rivets=True):
    """圆顶肩甲：上片 + 下片，边上一道亮线和铆钉"""
    lower = ellipse(cx, cy + ry * 0.7, rx * 0.9, ry * 0.7)
    fill(cv, lower, rp)
    upper = ellipse(cx, cy, rx, ry)
    fill(cv, upper, rp, band=(0.25, -0.15, -0.55))
    ub = border(upper)
    for dx in range(-rx + 3, rx - 2):
        y = cy - int(ry * 0.55 * max(0.0, 1 - (dx / rx) ** 2) ** 0.5)
        if (cx + dx, y) in upper and (cx + dx, y) not in ub:
            cv.put(cx + dx, y, rp[0])
    if rivets:
        for dx in (-rx // 2, 0, rx // 2):
            cv.put(cx + dx, cy + ry - 2, rp[0])


def chest_plate(cv, rp, x0=20, x1=43, top=45):
    """胸甲：中间一道棱线，左亮右暗"""
    m = poly([(x0, top), (x1 + 1, top), (x1 + 3, 65), (x0 - 2, 65)])
    fill(cv, m, rp, band=(0.15, -0.25, -0.6))
    mid = (x0 + x1) // 2
    for y in range(top + 2, 64):
        cv.put(mid, y, rp[0])
        cv.put(mid + 1, y, rp[3])
    return m


def cape(cv, rp, top=43):
    m = poly([(6, top + 2), (57, top + 2), (64, 65), (-1, 65)])
    fill(cv, m, rp)
    return m


def band_over(cv, rp, y0, y1, x0=13, x1=50):
    """头带 / 发箍：横跨头顶的一条带子，只画在头发范围里"""
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if cv.get(x, y) is not None:
                cv.put(x, y, rp[1] if y == y0 else (rp[2] if y < y1 else rp[4]))


def tia(cv):
    hair = ramp("#d8402e")
    # 后发 + 高马尾（从发绳往右后方甩下来）
    hair_poly(cv, [(14, 27), (13, 17), (16, 9), (23, 4), (40, 4), (47, 8), (49, 16), (48, 28), (44, 31), (19, 31)], hair)
    hair_poly(cv, [(43, 10), (47, 6), (52, 8), (56, 14), (59, 24), (59, 34), (56, 43), (52, 51), (50, 45), (53, 36), (53, 26), (50, 18), (46, 14)], hair,
              strands=[[(48, 9), (53, 18), (55, 30), (53, 42)], [(46, 11), (50, 20), (51, 32)]],
              shine=[(54, 17), (55, 19), (56, 21), (56, 23), (55, 26)])
    fill(cv, ellipse(45.5, 9, 2.4, 2.4), ramp("#e8b440"))
    # 衣服：红衫 + 皮马甲 + 斜挎皮带 + 左肩护甲
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#c8382e"))
    leather = ramp("#9a6a40")
    fill(cv, poly([(2, 54), (14, 46), (26, 44), (29, 65), (0, 65)]), leather)
    fill(cv, poly([(37, 44), (49, 46), (62, 54), (64, 65), (35, 65)]), leather)
    fill(cv, thick(seg((13, 47), (47, 64))), ramp("#5a3a24"), dither=False)
    for x in (22, 23):
        cv.put(x, 51, hx("#f0c050"))
    pauldron(cv, 11, 48, ramp("#b8c0cc"), rx=10, ry=6)
    draw_face(cv, "female", "#f6d0aa", "#d07024", "#8a2a20", blush=True, mouth="smile")
    fill(cv, poly([(26, 41), (37, 41), (36, 45), (31.5, 48), (27, 45)]), ramp("#f0e8dc"))
    # 前发：头顶 + 侧分刘海（往右扫）+ 两侧鬓发
    hair_poly(cv, [(15, 25), (15, 17), (17, 11), (21, 7), (26, 4), (32, 3), (38, 4), (43, 7), (46, 11), (48, 17), (48, 25), (47, 31), (46, 36),
                   (44, 29), (43, 24), (42, 20), (40, 23), (38, 18), (36, 22), (34, 17), (32, 21), (30, 16), (28, 21), (26, 16), (24, 20), (22, 17),
                   (21, 23), (20, 28), (18, 36), (17, 30), (16, 27)], hair,
              strands=[[(27, 5), (27, 11), (26, 16)], [(31, 4), (31, 11), (30, 16)], [(35, 5), (35, 12), (34, 17)], [(39, 6), (39, 13), (38, 18)],
                       [(43, 9), (45, 17), (45, 28)], [(21, 8), (19, 16), (19, 26)], [(24, 7), (23, 13), (22, 17)]],
              shine=shine_arc(31.5, 16, 11, 150, 50))


def balto(cv):
    hair = ramp("#b4b8c0")
    hair_poly(cv, [(15, 26), (14, 16), (18, 8), (26, 4), (38, 4), (45, 8), (49, 16), (48, 26), (44, 30), (19, 30)], hair)
    cape(cv, ramp("#3a5aa0"), top=40)
    steel = ramp("#a8b4c8")
    fill(cv, shoulders(top=42, neck=(26, 37)), steel)
    chest_plate(cv, steel, 21, 42, top=44)
    fill(cv, poly([(23, 40), (40, 40), (42, 46), (21, 46)]), ramp("#8a96ac"))
    pauldron(cv, 9, 47, steel, rx=10, ry=7)
    pauldron(cv, 54, 47, steel, rx=10, ry=7)
    draw_face(cv, "male", "#e8c098", "#3e5a88", "#9a9ea8", eyes="old", brows="thick", mouth="neutral", wrinkles=True)
    beard = ramp("#c8ccd2")
    m = poly([(19, 28), (21, 34), (24, 38), (28, 41), (35, 41), (39, 38), (42, 34), (44, 28), (43, 33), (39, 36), (35, 35), (28, 35), (24, 36), (20, 33)])
    fill(cv, m, beard)
    for x in range(27, 37):
        cv.put(x, 33, beard[3])
    for x in (26, 27, 36, 37):
        cv.put(x, 34, beard[3])
    hair_poly(cv, [(16, 22), (16, 14), (20, 8), (27, 5), (36, 5), (43, 8), (47, 13), (47, 22), (45, 18), (41, 14), (36, 13), (31, 14), (26, 13),
                   (22, 15), (19, 18)], hair,
              strands=[[(22, 8), (21, 14)], [(28, 6), (27, 13)], [(34, 6), (35, 13)], [(40, 8), (42, 15)]],
              shine=shine_arc(31.5, 15, 10, 150, 60))


def harlo(cv):
    hair = ramp("#9a6232")
    hair_poly(cv, [(16, 26), (15, 16), (19, 8), (28, 4), (38, 5), (45, 9), (48, 17), (47, 26), (43, 29), (20, 29)], hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#7a8c48"))
    vest = ramp("#a88458")
    fill(cv, poly([(4, 54), (15, 46), (26, 44), (28, 65), (1, 65)]), vest)
    fill(cv, poly([(37, 44), (48, 46), (60, 54), (63, 65), (35, 65)]), vest)
    fill(cv, thick(seg((44, 64), (60, 34)), 1), ramp("#8a5a30"), dither=False)
    fill(cv, poly([(56, 30), (63, 28), (63, 40), (58, 38)]), ramp("#b8bcc4"))
    draw_face(cv, "boy", "#f2c49c", "#6a4a2a", "#5a3418", mouth="grin", blush=True)
    fill(cv, poly([(27, 41), (36, 41), (35, 45), (28, 45)]), ramp("#e8dcc0"))
    hair_poly(cv, [(15, 25), (14, 17), (16, 9), (19, 4), (22, 8), (25, 1), (29, 6), (33, 0), (36, 6), (41, 2), (42, 8), (47, 5), (47, 12),
                   (49, 18), (48, 25), (46, 21), (44, 23), (42, 18), (39, 21), (36, 16), (33, 20), (30, 16), (27, 20), (24, 16), (21, 21),
                   (19, 17), (17, 22)], hair,
              strands=[[(25, 5), (25, 12), (24, 16)], [(32, 4), (32, 12), (30, 16)], [(39, 6), (38, 13), (36, 16)], [(44, 9), (45, 16)]],
              shine=shine_arc(31.5, 15, 10, 150, 60))


def toby(cv):
    hair = ramp("#4e3a2a")
    hair_poly(cv, [(15, 27), (14, 16), (18, 7), (27, 3), (38, 3), (46, 8), (49, 17), (48, 27), (44, 30), (19, 30)], hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#8a8a90"))
    vest = ramp("#b09060")
    fill(cv, poly([(3, 55), (15, 46), (27, 44), (27, 65), (0, 65)]), vest)
    fill(cv, poly([(36, 44), (48, 46), (61, 55), (64, 65), (36, 65)]), vest)
    for (x, y) in ((8, 56), (9, 57), (10, 56), (52, 58), (53, 57)):
        cv.put(x, y, vest[4])
    draw_face(cv, "boy", "#ecc098", "#5a4632", "#3a2618", brows="worried", mouth="neutral")
    hair_poly(cv, [(15, 26), (14, 17), (16, 10), (21, 6), (27, 3), (33, 4), (39, 3), (44, 7), (48, 12), (49, 20), (47, 26), (45, 20), (43, 23),
                   (41, 17), (38, 22), (35, 17), (32, 21), (29, 16), (26, 21), (23, 17), (20, 23), (18, 19), (17, 25)], hair,
              strands=[[(24, 5), (23, 12), (23, 17)], [(31, 4), (30, 12), (29, 16)], [(38, 5), (37, 12), (35, 17)], [(44, 9), (44, 18)]])
    band = ramp("#b8402e")
    band_over(cv, band, 14, 16, 14, 49)
    hair_poly(cv, [(48, 14), (55, 12), (58, 18), (54, 26), (51, 24), (53, 19), (49, 17)], band)


def nina(cv):
    hair = ramp("#8a5a36")
    hair_poly(cv, [(15, 30), (14, 17), (18, 8), (27, 4), (37, 4), (45, 8), (49, 17), (48, 30), (44, 33), (19, 33)], hair)
    fill(cv, shoulders(top=42, neck=(26, 37)), ramp("#4e7a44"))
    fill(cv, poly([(25, 45), (39, 45), (37, 65), (27, 65)]), ramp("#9a7a4c"))
    fill(cv, poly([(14, 42), (22, 39), (42, 39), (50, 42), (46, 48), (31.5, 52), (18, 48)]), ramp("#5e8a50"))
    fill(cv, thick(seg((42, 47), (22, 64))), ramp("#6a4a2c"), dither=False)
    draw_face(cv, "female", "#f4cca6", "#4a8a4a", "#5a3a22", mouth="neutral")
    for i in range(6):
        fill(cv, ellipse(17 - i * 0.4, 33 + i * 4.5, 3.2, 2.8), hair)
    fill(cv, ellipse(15, 59, 2, 2), ramp("#c8a050"))
    hair_poly(cv, [(15, 28), (14, 17), (17, 10), (22, 6), (29, 3), (36, 4), (42, 7), (46, 12), (48, 19), (48, 27), (46, 23), (44, 19),
                   (40, 16), (35, 15), (31, 17), (27, 15), (23, 17), (20, 21), (18, 26)], hair,
              strands=[[(24, 6), (22, 12), (20, 20)], [(31, 4), (30, 10), (28, 15)], [(38, 5), (40, 10), (42, 16)], [(44, 10), (46, 18)]],
              shine=shine_arc(31.5, 16, 11, 150, 50))


def kain(cv):
    hair = ramp("#3e3450")
    hair_poly(cv, [(14, 30), (13, 17), (17, 8), (26, 3), (38, 3), (46, 8), (50, 17), (50, 30), (45, 34), (19, 34)], hair)
    dark = ramp("#4a4652")
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#2e2a34"))
    chest_plate(cv, dark, 21, 42, top=45)
    pauldron(cv, 9, 48, dark, rx=9, ry=6)
    pauldron(cv, 54, 48, dark, rx=9, ry=6)
    fill(cv, ellipse(26, 53, 2.5, 2.5), ramp("#c84a2e"))
    draw_face(cv, "boy", "#eec49c", "#7a6aa8", "#2a2236", brows="firm", mouth="neutral")
    hair_poly(cv, [(14, 28), (14, 17), (17, 10), (23, 5), (30, 2), (37, 3), (44, 7), (48, 13), (50, 21), (50, 30), (47, 26), (45, 21),
                   (43, 24), (40, 18), (37, 23), (34, 17), (31, 22), (28, 16), (25, 21), (22, 17), (20, 25), (17, 31), (16, 26)], hair,
              strands=[[(22, 7), (20, 15), (18, 25)], [(29, 4), (28, 12), (28, 16)], [(36, 4), (35, 12), (34, 17)], [(42, 6), (42, 14), (40, 18)]],
              shine=shine_arc(31.5, 15, 10, 150, 60))
    band = ramp("#a83440")
    band_over(cv, band, 13, 15, 14, 50)
    hair_poly(cv, [(49, 13), (54, 14), (57, 26), (56, 34), (53, 30), (54, 22), (50, 16)], band)


def edric(cv):
    hair = ramp("#3a5ab0")
    hair_poly(cv, [(16, 27), (15, 16), (19, 8), (27, 4), (37, 4), (45, 8), (48, 16), (48, 27), (44, 30), (20, 30)], hair)
    cape(cv, ramp("#2e4a90"), top=41)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#e8e4dc"))
    fill(cv, poly([(28, 44), (35, 44), (37, 65), (26, 65)]), ramp("#3a5ab0"))
    gold = ramp("#d8b04a")
    for y in range(46, 64):
        cv.put(27, y, gold[1])
        cv.put(36, y, gold[1])
    pauldron(cv, 10, 48, ramp("#c0c8d8"), rx=9, ry=6)
    pauldron(cv, 53, 48, ramp("#c0c8d8"), rx=9, ry=6)
    draw_face(cv, "boy", "#f4cca6", "#3a6ac0", "#2a3a78", brows="firm", mouth="smile")
    fill(cv, poly([(25, 40), (38, 40), (37, 44), (26, 44)]), gold)
    hair_poly(cv, [(15, 26), (15, 16), (18, 10), (24, 5), (31, 3), (38, 4), (44, 7), (47, 12), (48, 20), (48, 26), (46, 22), (44, 18),
                   (41, 15), (37, 17), (33, 14), (29, 18), (26, 15), (23, 19), (20, 23), (18, 27)], hair,
              strands=[[(25, 6), (23, 12), (21, 20)], [(31, 4), (31, 10), (29, 17)], [(37, 5), (38, 11), (37, 16)], [(43, 8), (45, 16)]],
              shine=shine_arc(31.5, 16, 11, 150, 50))
    for x in range(16, 48):
        y = 13 if 21 <= x <= 42 else 14
        if cv.get(x, y) is not None:
            cv.put(x, y, gold[1] if x % 3 else gold[0])
    cv.put(31, 12, (110, 200, 255))
    cv.put(32, 12, (110, 200, 255))


def noya(cv):
    veil = ramp("#e8e6f0")
    hair = ramp("#e8c860")
    gold = ramp("#d8b04a")
    fill(cv, poly([(13, 30), (12, 16), (17, 7), (26, 2), (38, 2), (47, 7), (52, 16), (51, 30), (56, 47), (7, 47)]), veil)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#f0eee8"))
    fill(cv, poly([(22, 44), (26, 44), (27, 65), (22, 65)]), gold)
    fill(cv, poly([(37, 44), (41, 44), (41, 65), (36, 65)]), gold)
    draw_face(cv, "female", "#f8d8bc", "#4a7ad0", "#b0903a", brows="worried", mouth="neutral", blush=True)
    hair_poly(cv, [(19, 24), (20, 15), (25, 11), (32, 10), (39, 11), (44, 15), (45, 24), (43, 19), (40, 21), (37, 16), (34, 20), (31, 16),
                   (28, 20), (25, 16), (22, 21)], hair,
              strands=[[(26, 12), (25, 16)], [(32, 11), (31, 16)], [(38, 12), (37, 16)]])
    hair_poly(cv, [(11, 46), (11, 18), (15, 9), (23, 4), (32, 3), (41, 4), (49, 9), (53, 18), (53, 46), (46, 46), (46, 26), (45, 16),
                   (39, 11), (32, 10), (25, 11), (19, 16), (18, 26), (18, 46)], veil,
              strands=[[(15, 20), (14, 30), (15, 42)], [(49, 20), (50, 30), (49, 42)]],
              shine=shine_arc(31.5, 14, 13, 160, 40))
    band_over(cv, gold, 7, 8, 14, 50)
    cv.put(31, 8, (90, 150, 240))
    cv.put(32, 8, (90, 150, 240))
    fill(cv, ellipse(31.5, 47, 2, 2), ramp("#4a7ad0"))


def cyril(cv):
    hair = ramp("#5a6a8a")
    hair_poly(cv, [(15, 28), (14, 16), (18, 7), (27, 3), (38, 3), (46, 8), (50, 17), (49, 28), (45, 32), (19, 32)], hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#7a5a3e"))
    fill(cv, poly([(26, 46), (37, 46), (39, 65), (24, 65)]), ramp("#4a4a52"))
    draw_face(cv, "boy", "#eec49c", "#d8a030", "#3a4460", brows="firm", mouth="smirk")
    scarf = ramp("#d8782e")
    fill(cv, poly([(36, 46), (42, 46), (45, 60), (39, 62)]), scarf)
    fill(cv, poly([(21, 40), (42, 40), (45, 46), (38, 50), (26, 50), (18, 46)]), scarf)
    for x in range(23, 41, 4):
        cv.put(x, 45, scarf[3])
    hair_poly(cv, [(14, 27), (13, 18), (15, 10), (20, 5), (26, 2), (31, 4), (36, 1), (41, 4), (46, 6), (49, 13), (51, 22), (49, 28), (47, 22),
                   (45, 25), (43, 18), (40, 23), (37, 16), (34, 22), (31, 15), (28, 21), (25, 16), (22, 23), (20, 18), (17, 26)], hair,
              strands=[[(22, 6), (21, 14), (22, 23)], [(29, 4), (29, 12), (28, 20)], [(36, 3), (35, 12), (34, 21)], [(43, 6), (44, 14), (45, 24)]],
              shine=shine_arc(31.5, 15, 10, 150, 60))


def sparrow(cv):
    hair = ramp("#7a5030")
    hair_poly(cv, [(16, 26), (15, 16), (19, 8), (27, 4), (37, 4), (45, 8), (48, 16), (48, 26), (44, 29), (20, 29)], hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#e0d4b8"))
    vest = ramp("#5a8a40")
    fill(cv, poly([(3, 55), (15, 46), (26, 44), (27, 65), (0, 65)]), vest)
    fill(cv, poly([(37, 44), (48, 46), (61, 55), (64, 65), (37, 65)]), vest)
    draw_face(cv, "boy", "#f0c09a", "#5a8a40", "#4a2e18", brows="soft", mouth="grin")
    for (x, y) in ((22, 30), (24, 31), (26, 30), (37, 30), (39, 31), (41, 30)):
        cv.put(x, y, (204, 132, 96))
    hair_poly(cv, [(15, 25), (15, 17), (19, 13), (45, 13), (49, 17), (48, 25), (46, 21), (43, 23), (41, 18), (37, 21), (34, 17), (31, 21),
                   (28, 17), (25, 21), (22, 18), (19, 22), (17, 20)], hair,
              strands=[[(24, 14), (25, 20)], [(32, 14), (31, 20)], [(40, 14), (41, 19)]])
    band = ramp("#e0b030")
    hair_poly(cv, [(14, 17), (16, 9), (22, 4), (32, 2), (42, 4), (48, 9), (50, 17), (44, 14), (32, 13), (20, 14)], band,
              strands=[[(24, 5), (22, 13)], [(40, 5), (42, 13)]], shine=shine_arc(31.5, 12, 9, 150, 60))
    for (x, y) in ((22, 8), (30, 6), (37, 9), (43, 7), (27, 11)):
        cv.put(x, y, (250, 240, 200))
    hair_poly(cv, [(48, 12), (54, 9), (58, 13), (55, 16), (59, 21), (54, 22), (50, 16)], band)


def silas(cv):
    hair = ramp("#e0dcd0")
    hair_poly(cv, [(15, 30), (13, 17), (18, 7), (27, 3), (37, 3), (46, 7), (51, 17), (50, 30), (52, 50), (44, 52), (20, 52), (12, 50)], hair,
              strands=[[(16, 30), (15, 48)], [(48, 30), (49, 48)]])
    robe = ramp("#e8e4dc")
    gold = ramp("#d8b04a")
    fill(cv, shoulders(top=44, wide=(3, 60)), robe)
    fill(cv, poly([(29, 46), (34, 46), (35, 65), (28, 65)]), gold)
    fill(cv, poly([(20, 47), (23, 35), (28, 39), (35, 39), (40, 35), (43, 47), (36, 44), (28, 44)]), robe)
    for (a, b) in (((23, 35), (20, 47)), ((40, 35), (43, 47))):
        for p in seg(a, b):
            cv.put(p[0], p[1], gold[1])
    draw_face(cv, "male", "#f0d4bc", "#6a8aa8", "#b8b4a8", eyes="narrow", brows="firm", mouth="neutral")
    hair_poly(cv, [(14, 44), (13, 18), (17, 9), (24, 4), (32, 3), (40, 4), (47, 9), (51, 18), (51, 44), (47, 38), (45, 26), (44, 18), (39, 13),
                   (33, 12), (31.5, 15), (30, 12), (24, 13), (20, 18), (19, 26), (17, 38)], hair,
              strands=[[(26, 5), (21, 13), (18, 26), (16, 40)], [(31, 4), (28, 9)], [(37, 5), (42, 13), (46, 26), (48, 40)]],
              shine=shine_arc(31.5, 16, 12, 160, 40))


def morgan(cv):
    hair = ramp("#ecece8")
    hair_poly(cv, [(15, 30), (14, 18), (48, 18), (49, 30), (51, 52), (13, 52)], hair,
              strands=[[(16, 32), (15, 50)], [(47, 32), (49, 50)]])
    robe = ramp("#6a4a8a")
    gold = ramp("#d8b04a")
    fill(cv, shoulders(top=43, neck=(27, 36), wide=(2, 61)), robe)
    fill(cv, poly([(8, 46), (24, 42), (31.5, 54), (39, 42), (55, 46), (57, 52), (31.5, 60), (6, 52)]), ramp("#e8e4dc"))
    for p in seg((24, 42), (31.5, 54)) + seg((39, 42), (31.5, 54)):
        cv.put(p[0], p[1], gold[1])
    fill(cv, poly([(30, 55), (33, 55), (33, 65), (30, 65)]), gold)
    fill(cv, poly([(27, 58), (36, 58), (36, 60), (27, 60)]), gold)
    draw_face(cv, "male", "#ecd0b8", "#9a6ad0", "#c8c8c4", eyes="narrow", brows="soft", mouth="smirk", wrinkles=True)
    hair_poly(cv, [(14, 44), (14, 20), (18, 15), (45, 15), (49, 20), (49, 44), (46, 36), (44, 22), (40, 17), (31.5, 16), (23, 17), (19, 22),
                   (17, 36)], hair, strands=[[(17, 20), (16, 40)], [(46, 20), (48, 40)]])
    mitre = ramp("#f0eee6")
    hair_poly(cv, [(19, 17), (20, 7), (26, 2), (31.5, -1), (37, 2), (43, 7), (44, 17), (31.5, 15)], mitre,
              shine=shine_arc(31.5, 12, 8, 160, 100))
    for y in range(1, 16):
        cv.put(31, y, gold[1])
        cv.put(32, y, gold[2])
    band_over(cv, gold, 14, 16, 18, 45)
    fill(cv, ellipse(31.5, 7, 1.6, 1.6), ramp("#b03a4a"))


def vera(cv):
    hair = ramp("#c8ccd8")
    hair_poly(cv, [(15, 30), (13, 17), (18, 7), (27, 3), (37, 3), (46, 7), (51, 17), (50, 30), (54, 54), (10, 54)], hair,
              strands=[[(14, 32), (12, 52)], [(50, 32), (52, 52)]])
    dark = ramp("#3e3a48")
    fill(cv, shoulders(top=44, neck=(27, 36)), ramp("#2a2632"))
    chest_plate(cv, dark, 21, 42, top=46)
    pauldron(cv, 9, 50, dark, rx=9, ry=6)
    pauldron(cv, 54, 50, dark, rx=9, ry=6)
    fur = ramp("#9a8a76")
    fill(cv, poly([(12, 46), (18, 41), (24, 43), (31.5, 47), (39, 43), (45, 41), (51, 46), (46, 50), (31.5, 51), (17, 50)]), fur)
    for x in range(14, 50, 3):
        cv.put(x, 49 + (x % 2), fur[3])
    draw_face(cv, "female", "#f2d2c0", "#c8303a", "#8a8ea0", brows="firm", mouth="neutral", scar=True)
    hair_poly(cv, [(14, 46), (13, 18), (17, 9), (24, 4), (32, 3), (40, 4), (47, 9), (51, 18), (51, 46), (47, 38), (45, 24), (42, 17), (38, 21),
                   (35, 15), (31, 19), (28, 14), (24, 18), (20, 24), (18, 36)], hair,
              strands=[[(24, 5), (20, 14), (17, 30), (16, 44)], [(32, 4), (30, 12)], [(40, 5), (44, 14), (47, 30), (49, 44)]],
              shine=shine_arc(31.5, 16, 12, 160, 40))


def gray(cv):
    hair = ramp("#5a5a5e")
    blk = ramp("#34323a")
    fill(cv, shoulders(top=43, neck=(26, 37), wide=(0, 63)), ramp("#222028"))
    chest_plate(cv, blk, 20, 43, top=46)
    pauldron(cv, 8, 48, blk, rx=10, ry=7)
    pauldron(cv, 55, 48, blk, rx=10, ry=7)
    draw_face(cv, "male", "#d8a882", "#5a5a60", "#3a3a3e", eyes="stern", brows="angry", mouth="frown", scar=True)
    for y in range(31, 39):
        for x in range(20, 44):
            if (x + y) % 2 == 0 and cv.get(x, y) is not None and not (27 <= x <= 36 and 32 <= y <= 34):
                if y >= 35 or x <= 23 or x >= 40:
                    cv.put(x, y, (150, 112, 92))
    hair_poly(cv, [(17, 22), (17, 13), (21, 7), (28, 4), (36, 4), (43, 7), (47, 13), (47, 22), (45, 17), (40, 13), (32, 12), (24, 13), (19, 17)], hair,
              shine=shine_arc(31.5, 14, 9, 150, 60))
    for (x, y) in ((22, 9), (26, 7), (30, 8), (34, 6), (38, 8), (42, 10), (24, 11), (36, 10), (44, 14), (20, 14)):
        cv.put(x, y, hair[3])


def hawk(cv):
    hair = ramp("#2a2630")
    red = ramp("#7a2a2a")
    hair_poly(cv, [(15, 28), (14, 16), (18, 7), (27, 3), (38, 3), (46, 8), (50, 17), (49, 28), (45, 31), (19, 31)], hair)
    fill(cv, shoulders(top=43, neck=(26, 37)), ramp("#3a2228"))
    chest_plate(cv, red, 20, 43, top=46)
    pauldron(cv, 9, 48, red, rx=10, ry=7)
    pauldron(cv, 54, 48, red, rx=10, ry=7)
    for (cx, cy) in ((4, 44), (59, 44)):
        fill(cv, poly([(cx - 2, cy + 2), (cx, cy - 5), (cx + 2, cy + 2)]), ramp("#b8bcc4"))
    draw_face(cv, "male", "#e0b08a", "#c83030", "#1e1a22", eyes="stern", brows="angry", mouth="grin", scar=True)
    hair_poly(cv, [(14, 26), (12, 16), (8, 10), (15, 10), (14, 3), (21, 6), (24, -1), (29, 4), (34, -1), (37, 4), (43, 0), (44, 6), (51, 3),
                   (49, 11), (56, 12), (50, 18), (50, 26), (47, 21), (44, 24), (42, 17), (38, 22), (35, 16), (32, 21), (29, 16), (26, 21), (23, 16),
                   (20, 22), (17, 19)], hair,
              strands=[[(19, 7), (21, 14), (20, 20)], [(28, 3), (29, 12), (29, 16)], [(37, 3), (36, 12), (35, 16)], [(46, 5), (44, 14), (44, 22)]],
              shine=shine_arc(31.5, 14, 10, 150, 60))


def seven(cv):
    hair = ramp("#9a9a9e")
    hair_poly(cv, [(15, 34), (14, 17), (18, 8), (27, 4), (37, 4), (46, 8), (50, 17), (49, 34), (45, 36), (19, 36)], hair)
    blk = ramp("#26242c")
    fill(cv, shoulders(top=43, neck=(27, 36)), blk)
    fill(cv, poly([(21, 46), (24, 33), (28, 36), (35, 36), (39, 33), (42, 46), (36, 44), (27, 44)]), ramp("#34323c"))
    for p in seg((31.5, 44), (31.5, 64)):
        cv.put(p[0], p[1], blk[0])
    fill(cv, ellipse(31.5, 52, 1.6, 1.6), ramp("#8a2a3a"))
    draw_face(cv, "boy", "#f0dcd0", "#8a9aa8", "#6a6a70", eyes="blank", brows="soft", mouth="neutral")
    hair_poly(cv, [(14, 36), (13, 18), (17, 9), (24, 4), (32, 3), (40, 4), (47, 9), (51, 18), (50, 36), (46, 36), (45, 26), (43, 20), (40, 24),
                   (38, 17), (35, 23), (32, 17), (29, 24), (26, 18), (23, 22), (20, 20), (19, 28), (19, 36)], hair,
              strands=[[(22, 6), (18, 16), (16, 34)], [(30, 4), (29, 14), (29, 22)], [(38, 5), (40, 14), (41, 22)], [(44, 8), (48, 18), (48, 34)]],
              shine=shine_arc(31.5, 16, 12, 160, 40))


def _beard(cv, rp, full=True, mustache=True):
    """胡子：full=络腮胡（下巴一圈），mustache=上唇八字胡"""
    if full:
        fill(cv, poly([(19, 28), (21, 34), (24, 38), (28, 41), (35, 41), (39, 38), (42, 34), (44, 28), (43, 33), (39, 36), (35, 35), (28, 35),
                       (24, 36), (20, 33)]), rp)
    if mustache:
        for x in range(27, 37):
            cv.put(x, 32, rp[2] if 29 <= x <= 34 else rp[3])
        for x in (25, 26, 27, 36, 37, 38):
            cv.put(x, 33, rp[3])


def _helm(cv, rp, top=3, cheeks=34):
    """敞面头盔：盖住头顶和两颊，留出脸"""
    m = poly([(13, cheeks), (13, 16), (18, top + 4), (26, top), (38, top), (46, top + 4), (51, 16), (51, cheeks), (46, cheeks + 3), (45, 20),
              (43, 16), (32, 15), (21, 16), (19, 20), (18, cheeks + 3)])
    fill(cv, m, rp, band=(0.2, -0.2, -0.5))
    for x in range(19, 45):
        if (x, 15) in m or (x, 16) in m:
            cv.put(x, 16, rp[3])
    for x in range(20, 44):
        cv.put(x, 14, rp[0])
    for y in range(top + 2, 14):
        cv.put(31, y, rp[0])
        cv.put(32, y, rp[3])
    return m


def edmund(cv):
    hair = ramp("#5a6a90")
    hair_poly(cv, [(15, 28), (14, 16), (18, 7), (27, 3), (38, 3), (46, 7), (50, 16), (49, 28), (45, 31), (19, 31)], hair)
    fill(cv, shoulders(top=43, neck=(27, 36), wide=(1, 62)), ramp("#2e4a8a"))
    fur = ramp("#ece6d8")
    fill(cv, poly([(4, 52), (12, 44), (24, 41), (31.5, 52), (39, 41), (51, 44), (59, 52), (52, 56), (31.5, 58), (11, 56)]), fur)
    for (x, y) in ((10, 50), (17, 47), (24, 51), (40, 51), (47, 47), (54, 50), (14, 54), (50, 54)):
        cv.put(x, y, (30, 28, 34))
        cv.put(x, y + 1, (30, 28, 34))
    gold = ramp("#d8b04a")
    for i, p in enumerate(seg((16, 50), (31.5, 60)) + seg((31.5, 60), (47, 50))):
        cv.put(p[0], p[1], gold[0] if i % 2 else gold[2])
    fill(cv, ellipse(31.5, 61, 2.2, 2.2), ramp("#3a6ac0"))
    draw_face(cv, "male", "#ecc8a6", "#3a5a98", "#8a90a0", eyes="old", brows="thick", mouth="neutral", wrinkles=True)
    _beard(cv, ramp("#8a8e9c"))
    hair_poly(cv, [(16, 24), (16, 15), (20, 8), (27, 4), (36, 4), (43, 7), (48, 13), (48, 24), (46, 19), (42, 14), (36, 12), (30, 13), (25, 12),
                   (21, 15), (18, 19)], hair,
              strands=[[(23, 7), (21, 15)], [(30, 5), (28, 12)], [(37, 5), (40, 12)], [(43, 9), (46, 18)]],
              shine=shine_arc(31.5, 14, 10, 150, 60))
    for (x, y) in ((22, 10), (25, 8), (40, 9), (44, 13), (19, 17), (46, 20)):
        cv.put(x, y, (200, 204, 212))


def lance(cv):
    hair = ramp("#6a4a2e")
    hair_poly(cv, [(15, 27), (14, 16), (18, 7), (27, 3), (38, 3), (46, 8), (49, 16), (48, 27), (44, 30), (19, 30)], hair)
    grn = ramp("#4a7a4a")
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#3a5438"))
    chest_plate(cv, grn, 21, 42, top=45)
    pauldron(cv, 9, 48, grn, rx=9, ry=6)
    pauldron(cv, 54, 48, grn, rx=9, ry=6)
    fill(cv, poly([(25, 41), (38, 41), (37, 45), (26, 45)]), ramp("#b8c0cc"))
    draw_face(cv, "boy", "#eec49c", "#4a6a3a", "#3e2a18", brows="firm", mouth="neutral")
    hair_poly(cv, [(15, 25), (15, 16), (19, 9), (26, 4), (33, 3), (40, 5), (46, 10), (49, 18), (48, 25), (46, 20), (43, 22), (41, 16), (37, 19),
                   (34, 14), (30, 18), (26, 15), (23, 20), (20, 18), (18, 24)], hair,
              strands=[[(24, 6), (22, 13), (20, 18)], [(31, 4), (30, 11), (30, 17)], [(38, 5), (38, 12), (37, 18)], [(44, 9), (46, 18)]],
              shine=shine_arc(31.5, 15, 10, 150, 60))


def brock(cv):
    skin = "#d8a07a"
    fill(cv, shoulders(top=42, neck=(25, 38), wide=(0, 63)), ramp("#5a4a3e"))
    fur = ramp("#8a6a4a")
    fill(cv, poly([(2, 52), (10, 44), (22, 41), (26, 44), (26, 65), (0, 65)]), fur)
    fill(cv, poly([(37, 44), (41, 41), (53, 44), (61, 52), (63, 65), (37, 65)]), fur)
    for x in range(3, 62, 3):
        if not 26 <= x <= 37:
            cv.put(x, 45 + (x * 7) % 5, fur[3])
    fill(cv, ellipse(31.5, 16, 15.5, 12), ramp(skin), band=(0.2, -0.2, -0.5))
    draw_face(cv, "male", skin, "#4a3a2a", "#2a1e18", eyes="stern", brows="angry", mouth="frown", scar=True)
    _beard(cv, ramp("#2e2622"))
    for x in range(23, 41):
        cv.put(x, 38, ramp("#2e2622")[4])
    for (x, y) in ((24, 7), (25, 6), (26, 6)):
        cv.put(x, y, ramp(skin)[0])


def marco(cv):
    hair = ramp("#26222a")
    hair_poly(cv, [(15, 27), (14, 16), (18, 7), (27, 3), (38, 3), (46, 8), (49, 16), (48, 27), (44, 30), (19, 30)], hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#6a5a4a"))
    lea = ramp("#7a4a2e")
    fill(cv, poly([(3, 55), (15, 46), (27, 44), (28, 65), (0, 65)]), lea)
    fill(cv, poly([(36, 44), (48, 46), (61, 55), (64, 65), (35, 65)]), lea)
    fill(cv, thick(seg((14, 46), (40, 64))), ramp("#3a2a20"), dither=False)
    draw_face(cv, "male", "#dcae88", "#6a4a2a", "#1e1a1e", eyes="stern", brows="angry", mouth="smirk", scar=True)
    _beard(cv, ramp("#2a2428"), full=False)
    hair_poly(cv, [(14, 25), (13, 16), (10, 10), (16, 9), (17, 3), (23, 5), (27, -1), (31, 4), (36, 0), (39, 5), (45, 3), (45, 8), (52, 9),
                   (49, 16), (49, 25), (46, 20), (43, 23), (41, 16), (37, 21), (34, 15), (31, 20), (28, 15), (25, 20), (22, 15), (19, 21), (16, 18)],
              hair, strands=[[(20, 6), (21, 14)], [(29, 3), (29, 14)], [(38, 3), (37, 14)], [(46, 7), (45, 18)]],
              shine=shine_arc(31.5, 14, 10, 150, 60))


def barrett(cv):
    steel = ramp("#8a94a4")
    fill(cv, shoulders(top=43, neck=(26, 37), wide=(0, 63)), ramp("#4a4e58"))
    chest_plate(cv, steel, 20, 43, top=46)
    pauldron(cv, 8, 48, steel, rx=10, ry=7)
    pauldron(cv, 55, 48, steel, rx=10, ry=7)
    fill(cv, poly([(22, 40), (41, 40), (43, 47), (20, 47)]), ramp("#6a7484"))
    draw_face(cv, "male", "#d8a882", "#4a4a5a", "#5a3a2a", eyes="stern", brows="thick", mouth="neutral")
    _beard(cv, ramp("#7a4a2e"))
    _helm(cv, steel)


def august(cv):
    wht = ramp("#e8e4dc")
    gold = ramp("#d8b04a")
    cape(cv, ramp("#a83440"), top=41)
    fill(cv, shoulders(top=43, neck=(26, 37), wide=(1, 62)), ramp("#c8c4bc"))
    chest_plate(cv, wht, 20, 43, top=46)
    pauldron(cv, 9, 48, gold, rx=10, ry=7)
    pauldron(cv, 54, 48, gold, rx=10, ry=7)
    fill(cv, poly([(22, 40), (41, 40), (43, 47), (20, 47)]), gold)
    draw_face(cv, "male", "#e4b892", "#5a4a3a", "#8a7a6a", eyes="stern", brows="thick", mouth="neutral", wrinkles=True)
    _beard(cv, ramp("#a8a094"), full=False)
    _helm(cv, wht, top=2)
    for x in range(14, 51):
        for y in (16, 17):
            if cv.get(x, y) is not None and (x <= 19 or x >= 44):
                cv.put(x, y, gold[1])
    fill(cv, poly([(29, 3), (31.5, -1), (34, 3), (31.5, 7)]), gold)


def lorenz(cv):
    silver = ramp("#c0c8d8")
    hair = ramp("#e8c868")
    hair_poly(cv, [(13, 36), (13, 24), (51, 24), (51, 36), (47, 40), (17, 40)], hair)
    cape(cv, ramp("#3a5ab0"), top=41)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#8a92a4"))
    chest_plate(cv, silver, 21, 42, top=45)
    pauldron(cv, 9, 48, silver, rx=9, ry=6)
    pauldron(cv, 54, 48, silver, rx=9, ry=6)
    draw_face(cv, "boy", "#f2cca8", "#3a6ac0", "#a88a3a", brows="firm", mouth="smile")
    hair_poly(cv, [(19, 24), (20, 16), (44, 16), (45, 24), (42, 20), (39, 23), (36, 18), (33, 22), (30, 18), (27, 22), (24, 18), (21, 22)], hair)
    _helm(cv, silver, cheeks=26)
    plume = ramp("#c83a3a")
    hair_poly(cv, [(30, 4), (36, -1), (46, -1), (55, 3), (60, 10), (57, 18), (53, 12), (46, 7), (38, 6)], plume,
              strands=[[(40, 1), (52, 6), (57, 14)], [(36, 3), (48, 4)]])


def _short_hair(cv, rp, spiky=False):
    hair_poly(cv, [(15, 27), (14, 16), (18, 7), (27, 3), (38, 3), (46, 8), (49, 16), (48, 27), (44, 30), (19, 30)], rp)


def _bangs(cv, rp, shine=True):
    hair_poly(cv, [(15, 25), (15, 16), (19, 9), (26, 4), (33, 3), (40, 5), (46, 10), (49, 18), (48, 25), (46, 20), (43, 22), (41, 16), (37, 19),
                   (34, 14), (30, 18), (26, 15), (23, 20), (20, 18), (18, 24)], rp,
              strands=[[(24, 6), (22, 13), (20, 18)], [(31, 4), (30, 11), (30, 17)], [(38, 5), (38, 12), (37, 18)], [(44, 9), (46, 18)]],
              shine=shine_arc(31.5, 15, 10, 150, 60) if shine else None)


def _hood(cv, rp, face_top=15):
    hair_poly(cv, [(10, 48), (11, 18), (15, 8), (23, 2), (32, 1), (41, 2), (49, 8), (53, 18), (54, 48), (46, 46), (46, 26), (44, 18), (39, 14),
                   (32, face_top - 2), (25, 14), (20, 18), (18, 26), (18, 46)], rp,
              strands=[[(15, 20), (14, 32), (15, 44)], [(49, 20), (50, 32), (49, 44)], [(24, 4), (19, 12)], [(40, 4), (45, 12)]],
              shine=shine_arc(31.5, 14, 13, 160, 40))


def _vest_body(cv, shirt, vest):
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp(shirt))
    v = ramp(vest)
    fill(cv, poly([(3, 55), (15, 46), (26, 44), (27, 65), (0, 65)]), v)
    fill(cv, poly([(37, 44), (48, 46), (61, 55), (64, 65), (37, 65)]), v)


def bandit(cv):
    _short_hair(cv, ramp("#3a2a22"))
    _vest_body(cv, "#7a6a5a", "#6a4a32")
    fill(cv, thick(seg((48, 46), (22, 64))), ramp("#3a2a20"), dither=False)
    draw_face(cv, "male", "#d8a882", "#5a3a2a", "#2a1e18", eyes="stern", brows="angry", mouth="grin")
    for y in range(33, 39):
        for x in range(20, 44):
            if (x + y) % 2 == 0 and cv.get(x, y) is not None and (y >= 36 or x <= 24 or x >= 39):
                cv.put(x, y, (150, 108, 86))
    band = ramp("#8a2e2a")
    hair_poly(cv, [(14, 18), (16, 9), (22, 4), (32, 2), (42, 4), (48, 9), (50, 18), (44, 15), (32, 14), (20, 15)], band,
              strands=[[(24, 5), (22, 14)], [(40, 5), (42, 14)]], shine=shine_arc(31.5, 12, 9, 150, 60))
    hair_poly(cv, [(48, 13), (55, 10), (58, 15), (54, 18), (57, 24), (52, 23), (50, 17)], band)


def merc(cv):
    hair = ramp("#7a5a3a")
    _short_hair(cv, hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#5a4a3a"))
    lea = ramp("#8a6a48")
    chest_plate(cv, lea, 21, 42, top=45)
    pauldron(cv, 9, 48, ramp("#9aa2b0"), rx=9, ry=6)
    fill(cv, thick(seg((50, 38), (60, 64)), 1), ramp("#5a3a24"), dither=False)
    draw_face(cv, "male", "#e0b48e", "#5a4a3a", "#4a321e", eyes="stern", brows="firm", mouth="neutral", scar=True)
    _bangs(cv, hair)


def church(cv):
    wht = ramp("#e4e0d8")
    gold = ramp("#d8b04a")
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#c8c4bc"))
    chest_plate(cv, wht, 21, 42, top=45)
    fill(cv, poly([(29, 49), (34, 49), (34, 63), (29, 63)]), gold)
    fill(cv, poly([(25, 53), (38, 53), (38, 56), (25, 56)]), gold)
    pauldron(cv, 9, 48, wht, rx=9, ry=6)
    pauldron(cv, 54, 48, wht, rx=9, ry=6)
    draw_face(cv, "male", "#e8c4a0", "#5a6a7a", "#5a4a3a", eyes="stern", brows="firm", mouth="neutral")
    _helm(cv, wht)
    for x in range(14, 51):
        if cv.get(x, 17) is not None and (x <= 19 or x >= 44):
            cv.put(x, 17, gold[1])
    fill(cv, poly([(30, 5), (33, 5), (33, 12), (30, 12)]), gold)
    fill(cv, poly([(28, 7), (35, 7), (35, 9), (28, 9)]), gold)


def archer(cv):
    hair = ramp("#5a3e2a")
    _short_hair(cv, hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#5a7a44"))
    fill(cv, poly([(25, 45), (39, 45), (37, 65), (27, 65)]), ramp("#9a7a4c"))
    fill(cv, thick(seg((44, 46), (22, 64))), ramp("#6a4a2c"), dither=False)
    for i, x in enumerate((50, 53, 56)):
        fill(cv, thick(seg((x, 34 + i), (x - 3, 50)), 0), ramp("#8a6a44"), dither=False)
        fill(cv, poly([(x - 1, 30 + i), (x + 2, 30 + i), (x + 1, 35 + i)]), ramp("#e8e4dc"), dither=False)
    draw_face(cv, "boy", "#eec49c", "#4a6a3a", "#3e2a18", brows="firm", mouth="neutral")
    _hood(cv, ramp("#4e7040"))


def mage(cv):
    robe = ramp("#4a4a8a")
    fill(cv, shoulders(top=43, neck=(27, 36)), robe)
    gold = ramp("#d8b04a")
    for p in seg((22, 44), (28, 64)) + seg((41, 44), (35, 64)):
        cv.put(p[0], p[1], gold[1])
    fill(cv, ellipse(31.5, 46, 2, 2), ramp("#c84a2e"))
    draw_face(cv, "boy", "#f0cca8", "#6a5aa8", "#4a3a2a", eyes="narrow", brows="soft", mouth="neutral")
    hair_poly(cv, [(19, 24), (20, 16), (44, 16), (45, 24), (42, 20), (39, 23), (36, 18), (33, 22), (30, 18), (27, 22), (24, 18), (21, 22)],
              ramp("#5a4a3a"))
    _hood(cv, robe)
    for p in seg((19, 18), (32, 13)) + seg((32, 13), (45, 18)):
        cv.put(p[0], p[1], gold[1])


def scout(cv):
    hair = ramp("#8a6a3a")
    _short_hair(cv, hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#6a5a44"))
    scarf = ramp("#5a7a9a")
    fill(cv, poly([(21, 40), (42, 40), (45, 46), (38, 50), (26, 50), (18, 46)]), scarf)
    fill(cv, poly([(20, 46), (26, 47), (24, 60), (18, 58)]), scarf)
    draw_face(cv, "boy", "#ecc098", "#5a6a3a", "#4a3418", brows="soft", mouth="smirk")
    _bangs(cv, hair)


def villager(cv):
    hair = ramp("#6a4a2a")
    _short_hair(cv, hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#a89070"))
    fill(cv, poly([(27, 43), (36, 43), (31.5, 50)]), ramp("#e8dcc0"))
    draw_face(cv, "boy", "#eec49c", "#5a4632", "#3a2618", brows="soft", mouth="smile")
    _bangs(cv, hair)


def villager_w(cv):
    hair = ramp("#7a4a2a")
    hair_poly(cv, [(15, 32), (14, 17), (18, 8), (27, 4), (37, 4), (45, 8), (49, 17), (48, 32), (44, 35), (19, 35)], hair)
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#8a6a9a"))
    fill(cv, poly([(18, 44), (27, 41), (31.5, 48), (36, 41), (45, 44), (40, 50), (31.5, 52), (23, 50)]), ramp("#e8dcc0"))
    draw_face(cv, "female", "#f2cca6", "#6a4a2a", "#5a321e", mouth="smile", blush=True)
    hair_poly(cv, [(15, 30), (14, 17), (17, 10), (22, 6), (29, 3), (36, 4), (42, 7), (46, 12), (48, 19), (48, 30), (46, 24), (44, 19), (40, 16),
                   (35, 15), (31, 17), (27, 15), (23, 17), (20, 22), (18, 28)], hair,
              strands=[[(24, 6), (22, 12), (20, 20)], [(38, 5), (40, 10), (42, 16)]], shine=shine_arc(31.5, 16, 11, 150, 50))
    kerchief = ramp("#c8503a")
    hair_poly(cv, [(14, 18), (16, 9), (22, 4), (32, 2), (42, 4), (48, 9), (50, 18), (44, 14), (32, 12), (20, 14)], kerchief,
              shine=shine_arc(31.5, 12, 9, 150, 60))
    for (x, y) in ((22, 8), (28, 6), (35, 6), (41, 8), (25, 11), (38, 11)):
        cv.put(x, y, (250, 236, 210))


def granny(cv):
    gry = ramp("#c4c0bc")
    fill(cv, ellipse(31.5, 5, 6, 4.5), gry)
    hair_poly(cv, [(15, 26), (14, 16), (18, 8), (27, 5), (37, 5), (45, 8), (49, 16), (48, 26), (44, 29), (20, 29)], gry)
    shawl = ramp("#7a4a5a")
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#5a5a6a"))
    fill(cv, poly([(4, 52), (14, 44), (26, 41), (31.5, 52), (37, 41), (49, 44), (59, 52), (52, 60), (31.5, 62), (11, 60)]), shawl)
    for x in range(10, 54, 4):
        cv.put(x, 58 + (x % 3) - 1, shawl[0])
    draw_face(cv, "female", "#ecc6a6", "#6a5a4a", "#a8a49c", eyes="old", brows="soft", mouth="smile", wrinkles=True)
    hair_poly(cv, [(16, 22), (16, 15), (20, 9), (27, 6), (36, 6), (43, 9), (47, 14), (47, 22), (45, 17), (40, 13), (32, 12), (24, 13), (19, 17)],
              gry, strands=[[(24, 8), (21, 15)], [(32, 7), (32, 12)], [(40, 8), (43, 15)]], shine=shine_arc(31.5, 14, 9, 150, 60))


def knight(cv):
    steel = ramp("#9aa4b4")
    fill(cv, shoulders(top=43, neck=(26, 37), wide=(0, 63)), ramp("#5a6070"))
    chest_plate(cv, steel, 20, 43, top=46)
    pauldron(cv, 8, 48, steel, rx=10, ry=7)
    pauldron(cv, 55, 48, steel, rx=10, ry=7)
    fill(cv, poly([(22, 40), (41, 40), (43, 47), (20, 47)]), ramp("#7a8494"))
    draw_face(cv, "male", "#e0b48e", "#4a4a5a", "#4a3a2a", eyes="stern", brows="thick", mouth="frown")
    _helm(cv, steel, cheeks=36)
    fill(cv, poly([(18, 13), (46, 13), (45, 18), (19, 18)]), steel, band=(0.2, -0.2, -0.5))
    for x in range(21, 43, 3):
        cv.put(x, 16, (24, 22, 30))


def elder(cv):
    fill(cv, shoulders(top=43, neck=(27, 36)), ramp("#7a6a54"))
    fill(cv, poly([(4, 54), (16, 45), (26, 43), (27, 65), (0, 65)]), ramp("#8a7a5a"))
    fill(cv, poly([(37, 43), (47, 45), (60, 54), (64, 65), (37, 65)]), ramp("#8a7a5a"))
    skin = "#e4b894"
    wh = ramp("#e4e2dc")
    hair_poly(cv, [(14, 31), (13, 22), (16, 14), (47, 14), (50, 22), (50, 31), (46, 33), (18, 33)], wh,
              strands=[[(15, 22), (16, 30)], [(48, 22), (47, 30)]])
    fill(cv, ellipse(31.5, 16, 14.5, 11), ramp(skin), band=(0.2, -0.2, -0.5))
    draw_face(cv, "male", skin, "#5a4a3a", "#c8c4bc", eyes="old", brows="thick", mouth="neutral", wrinkles=True)
    fill(cv, poly([(20, 30), (23, 35), (26, 39), (29, 46), (31.5, 49), (34, 46), (37, 39), (40, 35), (43, 30), (42, 34), (38, 36), (35, 35),
                   (28, 35), (25, 36), (21, 34)]), wh)
    _beard(cv, wh, full=False)
    for (x, y) in ((24, 8), (25, 7), (26, 7)):
        cv.put(x, y, ramp(skin)[0])


def smith(cv):
    hair = ramp("#4a3020")
    _short_hair(cv, hair)
    fill(cv, shoulders(top=42, neck=(25, 38), wide=(0, 63)), ramp("#c08a62"))
    apron = ramp("#5a4232")
    fill(cv, poly([(18, 48), (45, 48), (47, 65), (16, 65)]), apron)
    for p in seg((18, 48), (24, 41)) + seg((45, 48), (39, 41)):
        cv.put(p[0], p[1], apron[3])
    draw_face(cv, "male", "#d8a07a", "#4a3a2a", "#3a2a1e", eyes="stern", brows="thick", mouth="grin")
    _beard(cv, ramp("#5a3a24"))
    band = ramp("#3a5a7a")
    hair_poly(cv, [(14, 17), (16, 9), (22, 4), (32, 2), (42, 4), (48, 9), (50, 17), (44, 14), (32, 13), (20, 14)], band,
              shine=shine_arc(31.5, 12, 9, 150, 60))


CAST = {
    "tia": tia, "balto": balto, "harlo": harlo, "toby": toby, "nina": nina, "kain": kain, "edric": edric,
    "noya": noya,
    "cyril": cyril,
    "sparrow": sparrow,
    "silas": silas,
    "morgan": morgan,
    "vera": vera,
    "gray": gray,
    "hawk": hawk,
    "seven": seven,
    "edmund": edmund,
    "lance": lance,
    "brock": brock,
    "marco": marco,
    "barrett": barrett,
    "august": august,
    "lorenz": lorenz,
    "bandit": bandit,
    "merc": merc,
    "church": church,
    "knight": knight,
    "archer": archer,
    "mage": mage,
    "scout": scout,
    "villager": villager,
    "villager_w": villager_w,
    "elder": elder,
    "granny": granny,
    "smith": smith,
}


def render(fn):
    cv = Canvas()
    fn(cv)
    return cv.image()


def preview(path, imgs, scale=4):
    names = list(imgs)
    cols = min(6, len(names))
    rows = (len(names) + cols - 1) // cols
    W = cols * (S * scale + 10)
    H = rows * (S * scale + 10)
    out = Image.new("RGBA", (W, H), (26, 32, 54, 255))
    for i, n in enumerate(names):
        x = (i % cols) * (S * scale + 10)
        y = (i // cols) * (S * scale + 10)
        out.alpha_composite(imgs[n].resize((S * scale, S * scale), Image.NEAREST), (x, y))
    out.save(path)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    only = sys.argv[3].split(",") if len(sys.argv) > 3 else None
    os.makedirs(out_dir, exist_ok=True)
    imgs = {}
    for key, fn in CAST.items():
        if only and key not in only:
            continue
        imgs[key] = render(fn)
        imgs[key].save(os.path.join(out_dir, key + ".png"))
    if len(sys.argv) > 2:
        preview(sys.argv[2], imgs, 6 if len(imgs) <= 2 else 4)
