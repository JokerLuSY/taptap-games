"""炎烬之誓：原创 GBA 火纹风像素对话立绘（64×64 半身像，游戏里 ×2 显示）。

部件拼装：后发 → 衣服 → 脖子 → 脸 → 五官 → 前发 / 头饰 → 饰品。每个部件是一块蒙版，按左上来光自动分三阶明暗，
部件边缘描一圈同色系深色（GBA 的选择性描边）。角色只在 CAST 里挑部件、配颜色。
用法：python -P -E fe_portraits.py <输出目录> [预览.png]
"""
import os
import sys
from PIL import Image

S = 64
HEAD = (32, 29)          # 脸中心
FACE_RX, FACE_RY = 13, 15


def C(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def mix(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def ramp(base):
    """一个底色派生出 亮 / 中 / 暗 / 描边"""
    light = mix(base, (255, 250, 235), 0.32)
    shade = mix(base, (30, 20, 45), 0.36)
    line = mix(base, (12, 8, 20), 0.72)
    return {"l": light, "m": base, "d": shade, "k": line}


class Canvas:
    def __init__(self):
        self.px = [[None] * S for _ in range(S)]

    def stamp(self, mask, base, outline=True, cx=None, cy=None, flat=False, light_edge=0.45, shade_edge=0.28):
        """把蒙版里的格子按左上来光上色，边缘描深色"""
        if not mask:
            return
        r = ramp(base)
        xs = [p[0] for p in mask]
        ys = [p[1] for p in mask]
        x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
        cx = (x0 + x1) / 2 if cx is None else cx
        cy = (y0 + y1) / 2 if cy is None else cy
        rx = max(1, (x1 - x0) / 2)
        ry = max(1, (y1 - y0) / 2)
        ms = set(mask)
        for (x, y) in mask:
            if not (0 <= x < S and 0 <= y < S):
                continue
            c = r["m"]
            if not flat:
                d = (x - cx) / rx * 0.65 + (y - cy) / ry * 0.45
                if d > shade_edge:
                    c = r["d"]
                elif d < -light_edge:
                    c = r["l"]
            if outline and any((x + dx, y + dy) not in ms for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                c = r["k"]
            self.px[y][x] = c

    def put(self, x, y, c):
        if 0 <= x < S and 0 <= y < S and c is not None:
            self.px[y][x] = c

    def image(self, scale=1):
        img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        for y in range(S):
            for x in range(S):
                if self.px[y][x] is not None:
                    img.putpixel((x, y), self.px[y][x] + (255,))
        return img.resize((S * scale, S * scale), Image.NEAREST) if scale != 1 else img


def ellipse(cx, cy, rx, ry, clip=None):
    out = []
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2 <= 1.0 and (clip is None or clip(x, y)):
                out.append((x, y))
    return out


def poly(pts):
    """扫描线填多边形"""
    out = []
    ys = [p[1] for p in pts]
    for y in range(int(min(ys)), int(max(ys)) + 1):
        xs = []
        n = len(pts)
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if (y0 <= y + 0.5 < y1) or (y1 <= y + 0.5 < y0):
                xs.append(x0 + (y + 0.5 - y0) / (y1 - y0) * (x1 - x0))
        xs.sort()
        for a, b in zip(xs[0::2], xs[1::2]):
            for x in range(int(round(a)), int(round(b))):
                out.append((x, y))
    return out


def rect(x0, y0, x1, y1):
    return [(x, y) for y in range(y0, y1 + 1) for x in range(x0, x1 + 1)]


# ======================= 部件 =======================

def back_hair(cv, d):
    hx, hy = HEAD
    hc = C(d["hair"])
    style = d.get("hair_style", "short")
    m = ellipse(hx, hy - 3, 14, 14)
    if style in ("long", "braid", "swept_long"):
        m += poly([(hx - 15, hy - 4), (hx + 15, hy - 4), (hx + 16, hy + 26), (hx - 16, hy + 26)])
    if style == "ponytail":
        m += poly([(hx + 9, hy - 14), (hx + 16, hy - 12), (hx + 24, hy + 4), (hx + 22, hy + 24), (hx + 16, hy + 30), (hx + 14, hy + 8)])
    if style == "bun":
        m += ellipse(hx, hy - 16, 6, 5)
    if style in ("bald", "helmet_only"):
        return
    cv.stamp(m, hc, cx=hx - 2, cy=hy - 8)


def body(cv, d):
    kind = d.get("body", "tunic")
    cl = C(d["cloth"])
    ac = C(d.get("cloth2", d["cloth"]))
    hx = HEAD[0]
    torso = poly([(hx - 10, 44), (hx + 10, 44), (hx + 24, 52), (hx + 27, 64), (hx - 27, 64), (hx - 24, 52)])
    cv.stamp(torso, cl, cx=hx - 4, cy=50)
    if kind in ("plate", "armor_dark", "knight"):
        for sx in (-1, 1):
            cv.stamp(ellipse(hx + sx * 19, 52, 9, 6), ac)
        cv.stamp(poly([(hx - 8, 46), (hx + 8, 46), (hx + 10, 64), (hx - 10, 64)]), ac, cx=hx - 3)
    if kind == "leather":
        cv.stamp(poly([(hx - 9, 47), (hx + 9, 47), (hx + 11, 64), (hx - 11, 64)]), ac, cx=hx - 3)
        cv.stamp(rect(hx - 12, 56, hx + 12, 58), C(d.get("belt", "#6b4a30")), outline=False, flat=True)
    if kind == "robe":
        cv.stamp(poly([(hx - 3, 45), (hx + 3, 45), (hx + 4, 64), (hx - 4, 64)]), ac, flat=True)
    if kind == "coat":
        cv.stamp(poly([(hx - 7, 45), (hx + 7, 45), (hx + 2, 64), (hx - 2, 64)]), ac, cx=hx - 2)
    if kind == "cloak":
        cv.stamp(poly([(hx - 14, 45), (hx + 14, 45), (hx + 27, 64), (hx - 27, 64)]), cl, cx=hx - 5, cy=52)
        cv.stamp(poly([(hx - 6, 46), (hx + 6, 46), (hx + 8, 64), (hx - 8, 64)]), ac, cx=hx - 2)
    if d.get("scarf"):
        sc = C(d["scarf"])
        cv.stamp(ellipse(hx, 45, 11, 4), sc)
        if d.get("scarf_tail"):
            cv.stamp(poly([(hx + 4, 46), (hx + 10, 47), (hx + 8, 62), (hx + 3, 60)]), sc, cx=hx + 5)
    if d.get("collar"):
        cv.stamp(poly([(hx - 9, 43), (hx, 50), (hx + 9, 43), (hx + 11, 46), (hx, 54), (hx - 11, 46)]), C(d["collar"]), cx=hx - 3)
    if d.get("fur"):
        cv.stamp(ellipse(hx, 46, 15, 5), C(d["fur"]))
    if d.get("trim"):
        tc = C(d["trim"])
        for x in range(hx - 26, hx + 27):
            cv.put(x, 63, ramp(tc)["m"])


def neck_face(cv, d):
    hx, hy = HEAD
    sk = C(d.get("skin", "#f6d2ac"))
    neck = rect(hx - 4, hy + 9, hx + 4, hy + 18)
    cv.stamp(neck, sk, flat=True)
    for x in range(hx - 3, hx + 4):
        for y in range(hy + 12, hy + 15):
            cv.put(x, y, ramp(sk)["d"])
    ry = FACE_RY - (1 if d.get("young") else 0)
    jaw = d.get("jaw", 0)
    face = ellipse(hx, hy, FACE_RX + jaw * 0.5, ry)
    face += poly([(hx - 8 - jaw, hy + 4), (hx + 8 + jaw, hy + 4), (hx + 3 + jaw, hy + ry + 1), (hx - 3 - jaw, hy + ry + 1)])
    for sx in (-1, 1):
        cv.stamp(ellipse(hx + sx * (FACE_RX + 1), hy + 2, 2, 3), sk, flat=True, outline=False)
    cv.stamp(face, sk, flat=True)
    r = ramp(sk)
    fs = set(face)
    for (x, y) in face:
        edge = any((x + dx, y + dy) not in fs for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if not edge and (x - hx) / FACE_RX > 0.62:
            cv.put(x, y, r["d"])
        elif not edge and y > hy + 9 and abs(x - hx) > 6:
            cv.put(x, y, mix(r["m"], r["d"], 0.5))


def eyes(cv, d):
    hx, hy = HEAD
    ec = ramp(C(d.get("eyes", "#5a4030")))
    lash = ramp(C(d["hair"]))["k"] if not d.get("lash") else C(d["lash"])
    white = (250, 248, 240)
    y0 = hy - 1
    style = d.get("eye_style", "normal")
    for sx, ex in ((-1, hx - 8), (1, hx + 3)):
        h = 5 if style != "narrow" else 4
        w = 5
        for x in range(ex, ex + w):
            cv.put(x, y0, lash)
        for y in range(y0 + 1, y0 + h):
            for x in range(ex, ex + w):
                inner = ex + 1 <= x <= ex + 3
                cv.put(x, y, (ec["d"] if y <= y0 + 1 else ec["m"]) if inner else white)
        for x in range(ex + 1, ex + 4):
            cv.put(x, y0 + h - 1, ec["l"])
        cv.put(ex - 1 if sx < 0 else ex + w, y0, lash)
        cv.put(ex - 1 if sx < 0 else ex + w, y0 + 1, lash)
        if style != "blank":
            cv.put(ex + 2, y0 + 2, white)
        else:
            for y in range(y0 + 1, y0 + h):
                cv.put(ex + 1, y, ec["d"])
                cv.put(ex + 2, y, ec["d"])
        # 眉毛
        by = y0 - 3 if style != "stern" else y0 - 2
        brow = ramp(C(d.get("brow", d["hair"])))["d"]
        for x in range(ex - (1 if sx < 0 else 0), ex + w + (0 if sx < 0 else 1)):
            tilt = 0
            if style in ("stern", "fierce"):
                tilt = (1 if (x - ex) * -sx > 1 else 0) if sx < 0 else (1 if x - ex < 2 else 0)
            cv.put(x, by + tilt, brow)
            if (x - ex) in (1, 2):
                cv.put(x, by + tilt - 1, brow)
    sk = ramp(C(d.get("skin", "#f6d2ac")))
    cv.put(hx + 1, hy + 5, sk["d"])
    cv.put(hx + 1, hy + 6, sk["d"])
    mouth = d.get("mouth", "flat")
    my = hy + 9
    lip = mix(sk["d"], (150, 60, 60), 0.4)
    if mouth == "smile":
        cv.put(hx - 2, my, lip)
        for x in range(hx - 1, hx + 2):
            cv.put(x, my + 1, lip)
        cv.put(hx + 2, my, lip)
    elif mouth == "frown":
        for x in range(hx - 1, hx + 2):
            cv.put(x, my, lip)
        cv.put(hx - 2, my + 1, lip)
        cv.put(hx + 2, my + 1, lip)
    else:
        for x in range(hx - 1, hx + 2):
            cv.put(x, my, lip)
    if d.get("blush"):
        for x in (hx - 8, hx - 7, hx + 6, hx + 7):
            cv.put(x, hy + 5, mix(sk["m"], (240, 120, 120), 0.45))


def facial_hair(cv, d):
    hx, hy = HEAD
    if d.get("beard"):
        bc = C(d["beard"])
        m = poly([(hx - 10, hy + 3), (hx + 10, hy + 3), (hx + 8, hy + 12), (hx + 3, hy + 17), (hx - 3, hy + 17), (hx - 8, hy + 12)])
        m = [p for p in m if not (abs(p[0] - hx) <= 2 and hy + 7 <= p[1] <= hy + 9)]
        cv.stamp(m, bc, cx=hx - 3)
    if d.get("mustache"):
        mc = ramp(C(d["mustache"]))
        for x in range(hx - 4, hx + 5):
            cv.put(x, hy + 6, mc["m"])
        cv.put(hx - 5, hy + 7, mc["d"])
        cv.put(hx + 5, hy + 7, mc["d"])
    if d.get("scar"):
        for i in range(6):
            cv.put(hx + 3 + i // 2, hy - 4 + i, (150, 70, 70))


def front_hair(cv, d):
    hx, hy = HEAD
    hc = C(d["hair"])
    style = d.get("hair_style", "short")
    top = d.get("fringe", "bangs")
    if style in ("bald", "helmet_only"):
        return
    cap = ellipse(hx, hy - 6, 13, 9, clip=lambda x, y: y <= hy - 6)
    if top == "bangs":
        spikes = [(hx - 12, hy - 4), (hx - 9, hy + 1), (hx - 7, hy - 3), (hx - 4, hy + 1), (hx - 1, hy - 4), (hx + 2, hy + 1),
                  (hx + 5, hy - 3), (hx + 8, hy + 1), (hx + 10, hy - 3), (hx + 13, hy + 2), (hx + 13, hy - 7), (hx - 13, hy - 7)]
        cap += poly(spikes)
    elif top == "swept":
        cap += poly([(hx - 13, hy - 7), (hx + 13, hy - 7), (hx + 14, hy + 1), (hx + 6, hy - 4), (hx - 4, hy - 4), (hx - 12, hy)])
    elif top == "spiky":
        for sx in range(-12, 13, 5):
            cap += poly([(hx + sx - 3, hy - 12), (hx + sx + 1, hy - 21), (hx + sx + 4, hy - 12)])
        cap += poly([(hx - 12, hy - 7), (hx + 12, hy - 7), (hx + 10, hy - 2), (hx + 4, hy - 4), (hx - 3, hy - 2), (hx - 10, hy - 4)])
    elif top == "short":
        cap += poly([(hx - 12, hy - 7), (hx + 12, hy - 7), (hx + 12, hy - 3), (hx - 12, hy - 3)])
    elif top == "messy":
        cap += poly([(hx - 13, hy - 6), (hx + 13, hy - 6), (hx + 14, hy + 2), (hx + 9, hy - 2), (hx + 6, hy + 2), (hx + 2, hy - 3),
                     (hx - 2, hy + 1), (hx - 6, hy - 3), (hx - 10, hy + 2)])
        cap += poly([(hx - 6, hy - 14), (hx - 2, hy - 20), (hx + 1, hy - 14)])
        cap += poly([(hx + 4, hy - 14), (hx + 9, hy - 19), (hx + 9, hy - 12)])
    elif top == "buzz":
        cap = ellipse(hx, hy - 6, 12, 8, clip=lambda x, y: y <= hy - 7)
    # 鬓角
    if style in ("long", "braid", "ponytail", "swept_long"):
        cap += poly([(hx - 13, hy - 6), (hx - 10, hy - 6), (hx - 10, hy + 10), (hx - 13, hy + 8)])
        cap += poly([(hx + 10, hy - 6), (hx + 13, hy - 6), (hx + 13, hy + 8), (hx + 10, hy + 10)])
    cv.stamp(cap, hc, cx=hx - 4, cy=hy - 10)
    r = ramp(hc)
    cs = set(cap)
    for x in range(hx - 9, hx + 6):
        y = hy - 13 + int(((x - hx + 2) / 9.0) ** 2 * 3)
        if (x, y) in cs and (x + y) % 5 != 0:
            cv.put(x, y, r["l"])
    if top in ("bangs", "messy", "swept"):
        for x in range(hx - 9, hx + 11, 4):
            for y in range(hy - 6, hy - 1):
                if (x, y) in cs and (x, y + 1) in cs:
                    cv.put(x, y, r["d"])
    if style == "braid":
        for i in range(4):
            cv.stamp(ellipse(hx - 13, hy + 12 + i * 5, 3, 3), hc)


def headwear(cv, d):
    hx, hy = HEAD
    hw = d.get("headwear")
    if not hw:
        return
    col = C(d.get("hw_color", "#c0c0c8"))
    if hw == "hood":
        m = ellipse(hx, hy - 2, 16, 17)
        hole = set(ellipse(hx, hy + 1, 11, 13))
        m = [p for p in m if p not in hole or p[1] < hy - 9]
        cv.stamp(m, col, cx=hx - 4, cy=hy - 8)
    elif hw == "veil":
        m = ellipse(hx, hy - 4, 15, 13) + poly([(hx - 16, hy), (hx + 16, hy), (hx + 18, hy + 22), (hx - 18, hy + 22)])
        hole = set(ellipse(hx, hy + 2, 10, 12))
        m = [p for p in m if p not in hole or p[1] < hy - 8]
        cv.stamp(m, col, cx=hx - 4, cy=hy - 6)
        cv.stamp(rect(hx - 11, hy - 10, hx + 11, hy - 8), C(d.get("hw_color2", "#d8b04a")), flat=True)
    elif hw in ("helmet", "helmet_plume"):
        m = ellipse(hx, hy - 5, 14, 12, clip=lambda x, y: y <= hy + 1)
        m += poly([(hx - 14, hy - 4), (hx - 10, hy - 4), (hx - 10, hy + 10), (hx - 14, hy + 8)])
        m += poly([(hx + 10, hy - 4), (hx + 14, hy - 4), (hx + 14, hy + 8), (hx + 10, hy + 10)])
        hole = set(rect(hx - 9, hy - 4, hx + 9, hy + 14))
        m = [p for p in m if p not in hole]
        cv.stamp(m, col, cx=hx - 4, cy=hy - 8)
        cv.stamp(rect(hx - 10, hy - 5, hx + 10, hy - 4), ramp(col)["d"], flat=True, outline=False)
        if hw == "helmet_plume":
            cv.stamp(poly([(hx - 2, hy - 16), (hx + 2, hy - 16), (hx + 12, hy - 26), (hx + 4, hy - 24)]), C(d.get("hw_color2", "#c03030")))
    elif hw == "bandana":
        cv.stamp(rect(hx - 13, hy - 9, hx + 13, hy - 6), col, cx=hx - 4)
        cv.stamp(poly([(hx + 12, hy - 8), (hx + 20, hy - 10), (hx + 22, hy - 4), (hx + 14, hy - 5)]), col)
    elif hw == "headband":
        cv.stamp(rect(hx - 13, hy - 8, hx + 13, hy - 6), col, cx=hx - 4)
        cv.stamp(poly([(hx + 12, hy - 7), (hx + 17, hy - 4), (hx + 19, hy + 8), (hx + 15, hy + 6)]), col)
    elif hw == "circlet":
        for x in range(hx - 11, hx + 12):
            cv.put(x, hy - 7, ramp(col)["m"] if (x + hy) % 4 else ramp(col)["l"])
        cv.put(hx, hy - 8, (120, 200, 255))
    elif hw == "mitre":
        cv.stamp(poly([(hx - 11, hy - 8), (hx + 11, hy - 8), (hx + 8, hy - 26), (hx, hy - 31), (hx - 8, hy - 26)]), col, cx=hx - 3, cy=hy - 18)
        cv.stamp(rect(hx - 1, hy - 28, hx + 1, hy - 9), C(d.get("hw_color2", "#d8b04a")), flat=True)
        cv.stamp(rect(hx - 6, hy - 20, hx + 6, hy - 18), C(d.get("hw_color2", "#d8b04a")), flat=True)


def render(d):
    cv = Canvas()
    back_hair(cv, d)
    body(cv, d)
    neck_face(cv, d)
    eyes(cv, d)
    facial_hair(cv, d)
    if d.get("headwear") not in ("helmet", "helmet_plume", "hood", "veil"):
        front_hair(cv, d)
    else:
        if d.get("headwear") in ("hood", "veil") and d.get("fringe"):
            front_hair(cv, {**d, "hair_style": "short"})
    headwear(cv, d)
    if d.get("earring"):
        cv.put(HEAD[0] - FACE_RX - 1, HEAD[1] + 5, C(d["earring"]))
    return cv.image()


# ======================= 角色 =======================

CAST = {
    # 我方
    "tia": dict(hair="#d8402e", hair_style="ponytail", fringe="bangs", eyes="#c8701e", cloth="#a8784a", cloth2="#c83a30", body="leather", belt="#5a3a22", mouth="smile", blush=True, young=True),
    "balto": dict(hair="#b8bcc4", hair_style="short", fringe="swept", eyes="#3e5878", cloth="#a8b4c8", cloth2="#6a84b0", body="plate", beard="#c8ccd0", mustache="#d0d4d8", eye_style="stern", jaw=2, skin="#e8c49c"),
    "harlo": dict(hair="#8a5a30", hair_style="short", fringe="spiky", eyes="#5a4030", cloth="#7a8a4a", cloth2="#a08a5a", body="tunic", mouth="smile", young=True, blush=True),
    "toby": dict(hair="#4a3424", hair_style="short", fringe="messy", eyes="#4a3a2a", cloth="#a08460", cloth2="#7a6040", body="leather", headwear="headband", hw_color="#b04030", young=True),
    "nina": dict(hair="#7a5a34", hair_style="braid", fringe="swept", eyes="#4a8a4a", cloth="#4a7a44", cloth2="#8a6a40", body="cloak", mouth="flat", young=True),
    "kain": dict(hair="#3a3048", hair_style="short", fringe="messy", eyes="#7a6aa0", cloth="#4a4450", cloth2="#2a2630", body="armor_dark", headwear="headband", hw_color="#a03040", eye_style="stern"),
    "edric": dict(hair="#3a5aa8", hair_style="short", fringe="swept", eyes="#3a6ab8", cloth="#3a5aa0", cloth2="#d8c070", body="cloak", headwear="circlet", hw_color="#e0c060", collar="#e8e0d0"),
    "noya": dict(hair="#e0c070", hair_style="short", fringe="bangs", eyes="#5a8ac0", cloth="#f0ece0", cloth2="#d8b04a", body="robe", headwear="veil", hw_color="#f4f0e6", hw_color2="#d8b04a", blush=True, mouth="smile", young=True),
    "cyril": dict(hair="#4a5878", hair_style="short", fringe="messy", eyes="#d07830", cloth="#80603e", cloth2="#5a4230", body="coat", scarf="#e8802e", scarf_tail=True, mouth="smile"),
    "sparrow": dict(hair="#a8643a", hair_style="short", fringe="messy", eyes="#7a5a2a", cloth="#4c9470", cloth2="#ccb27e", body="tunic", headwear="bandana", hw_color="#ecc848", young=True, blush=True, mouth="smile"),
    # 敌方 / 剧情
    "silas": dict(hair="#e8e0c0", hair_style="swept_long", fringe="swept", eyes="#8098b8", cloth="#f0ecf4", cloth2="#d8b04a", body="robe", eye_style="narrow", collar="#d8b04a", mouth="flat"),
    "morgan": dict(hair="#e8e8f0", hair_style="long", fringe="swept", eyes="#a060c0", cloth="#5a2a70", cloth2="#d8b04a", body="robe", headwear="mitre", hw_color="#f0e8f8", hw_color2="#d8b04a", eye_style="narrow", skin="#ecd8cc", mouth="smile"),
    "vera": dict(hair="#a8a8b0", hair_style="long", fringe="swept", eyes="#c05040", cloth="#3a3438", cloth2="#5a2a28", body="armor_dark", fur="#8a8078", scar=True, eye_style="stern"),
    "gray": dict(hair="#3a3a3a", hair_style="short", fringe="buzz", eyes="#5a5050", cloth="#3a3a40", cloth2="#2a2a2e", body="armor_dark", scar=True, eye_style="fierce", jaw=2, mouth="frown", beard="#3a3a3a"),
    "hawk": dict(hair="#1e1a1a", hair_style="short", fringe="spiky", eyes="#a03030", cloth="#3a2a2c", cloth2="#5a2a2a", body="armor_dark", scar=True, eye_style="fierce", jaw=1, mouth="frown"),
    "brock": dict(hair="#2a2020", hair_style="bald", eyes="#6a3020", cloth="#6a4a30", cloth2="#4a3020", body="leather", beard="#2a2020", scar=True, eye_style="fierce", jaw=3, skin="#d8a880", mouth="frown"),
    "marco": dict(hair="#2a1a14", hair_style="short", fringe="spiky", eyes="#6a3020", cloth="#6a3a28", cloth2="#4a2a1c", body="leather", scar=True, eye_style="fierce", jaw=2, skin="#d8a880", mouth="smile", mustache="#2a1a14"),
    "barrett": dict(hair="#4a4038", hair_style="helmet_only", eyes="#5a4a40", cloth="#9a968e", cloth2="#7a7670", body="knight", headwear="helmet", hw_color="#a8a4a0", eye_style="stern", jaw=3, beard="#4a4038"),
    "august": dict(hair="#5a4a38", hair_style="helmet_only", eyes="#5a4a40", cloth="#d8d4c8", cloth2="#d8b04a", body="knight", headwear="helmet", hw_color="#e8e4dc", eye_style="stern", jaw=2, mustache="#5a4a38"),
    "lorenz": dict(hair="#b89a5a", hair_style="helmet_only", eyes="#4a6a8a", cloth="#c8ccd8", cloth2="#9aa4b8", body="knight", headwear="helmet_plume", hw_color="#d0d4e0", hw_color2="#c03030", eye_style="stern"),
    "seven": dict(hair="#a8a4a8", hair_style="short", fringe="bangs", eyes="#7a7880", cloth="#2a2830", cloth2="#4a4450", body="tunic", eye_style="blank", skin="#e8dcd8", collar="#1a181e", young=True),
    "edmund": dict(hair="#5a6a90", hair_style="short", fringe="swept", eyes="#3a5a90", cloth="#2a4a88", cloth2="#d8c070", body="cloak", mustache="#8a8a98", beard="#8a8a98", jaw=2, eye_style="stern", skin="#ecc8a4"),
    "lance": dict(hair="#7a5a3a", hair_style="short", fringe="short", eyes="#4a6a3a", cloth="#5a7a50", cloth2="#9aa088", body="plate", mouth="flat"),
    # 杂兵 / 路人
    "bandit": dict(hair="#3a2a1c", hair_style="short", fringe="spiky", eyes="#5a3a2a", cloth="#8a6a48", cloth2="#5a4028", body="leather", headwear="headband", hw_color="#7a3a28", eye_style="fierce", skin="#d8a880", mouth="smile"),
    "merc": dict(hair="#2a2830", hair_style="short", fringe="short", eyes="#5a5060", cloth="#3a3840", cloth2="#2a282e", body="armor_dark", eye_style="stern", mouth="frown"),
    "church": dict(hair="#6a5a40", hair_style="helmet_only", eyes="#5a5a6a", cloth="#e0dcd0", cloth2="#c8a850", body="knight", headwear="helmet", hw_color="#e8e4dc", eye_style="stern"),
    "knight": dict(hair="#8a7050", hair_style="helmet_only", eyes="#4a5a7a", cloth="#c8c8d4", cloth2="#9a9ab0", body="knight", headwear="helmet_plume", hw_color="#d0d0dc", hw_color2="#d8d4c8", eye_style="stern"),
    "archer": dict(hair="#6a5030", hair_style="short", fringe="short", eyes="#4a6a3a", cloth="#5a7a4a", cloth2="#7a6a40", body="cloak", headwear="hood", hw_color="#5a7a4a"),
    "mage": dict(hair="#c0a070", hair_style="short", fringe="bangs", eyes="#7a5aa0", cloth="#e8e2d0", cloth2="#b03838", body="robe", headwear="hood", hw_color="#ece6d6", fringe2=True),
    "scout": dict(hair="#3a3830", hair_style="short", fringe="short", eyes="#5a5a40", cloth="#5a5a4a", cloth2="#3a3a30", body="cloak", headwear="hood", hw_color="#4a4a3e", eye_style="narrow"),
    "villager": dict(hair="#7a5030", hair_style="short", fringe="short", eyes="#5a4030", cloth="#9a8058", cloth2="#7a6040", body="tunic", mouth="flat"),
    "villager_w": dict(hair="#8a5a30", hair_style="bun", fringe="swept", eyes="#5a4030", cloth="#a86a5a", cloth2="#e0d0b0", body="tunic", mouth="smile", blush=True),
    "elder": dict(hair="#c8c4bc", hair_style="short", fringe="swept", eyes="#5a5048", cloth="#7a6a58", cloth2="#5a4a3a", body="cloak", beard="#d0ccc4", mustache="#d8d4cc", skin="#e0b894", eye_style="narrow"),
    "granny": dict(hair="#d8d4cc", hair_style="bun", fringe="swept", eyes="#5a5048", cloth="#6a5a70", cloth2="#9a8aa0", body="cloak", skin="#e0b894", eye_style="narrow", mouth="smile"),
    "smith": dict(hair="#3a2a20", hair_style="bald", eyes="#4a3a2a", cloth="#6a5040", cloth2="#4a3a2a", body="leather", beard="#3a2a20", jaw=3, skin="#d09870", mouth="smile"),
}


def preview(path, imgs, scale=3):
    names = list(imgs)
    cols = 9
    rows = (len(names) + cols - 1) // cols
    W = cols * (S * scale + 8)
    H = rows * (S * scale + 8)
    out = Image.new("RGBA", (W, H), (28, 34, 54, 255))
    for i, n in enumerate(names):
        x = (i % cols) * (S * scale + 8)
        y = (i // cols) * (S * scale + 8)
        out.alpha_composite(imgs[n].resize((S * scale, S * scale), Image.NEAREST), (x, y))
    out.save(path)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    imgs = {}
    for key, d in CAST.items():
        imgs[key] = render(d)
        imgs[key].save(os.path.join(out_dir, key + ".png"))
    if len(sys.argv) > 2:
        preview(sys.argv[2], imgs)
