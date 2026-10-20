"""战斗特写的分层背景（原创像素画）：雪地 / 城镇 / 城堡内 / 山岭 / 河岸。

和现有的 grass / forest / scorch 三套同规格：先画 320×180，再最近邻放大 4 倍到 1280×720。
每套四层，从远到近：
  sky_<set>.png           整幅不透明（天空或城堡内墙）
  mountains_<set>.png     远景，约占 y 39–108（原图坐标）
  mid_<set>.png           中景，约占 y 54–115
  ground_strip_<set>.png  地面带，y 108 以下；角色脚底在 y 130（放大后 520）

用法：python -P -E tools/pixelart/combat_bg.py art/combat/bg
"""
import math
import os
import random
import sys

from PIL import Image

W, H = 320, 180
SCALE = 4
HORIZON = 108          # 地面带顶边
FEET = 130             # 脚底


def new(opaque=False):
    return Image.new("RGBA", (W, H), (0, 0, 0, 255 if opaque else 0))


def put(img, x, y, c):
    if 0 <= x < W and 0 <= y < H:
        img.putpixel((x, y), c + (255,) if len(c) == 3 else c)


def rect(img, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(H, y1)):
        for x in range(max(0, x0), min(W, x1)):
            img.putpixel((x, y), c + (255,))


def shade(c, k):
    return tuple(max(0, min(255, int(v * k))) for v in c)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def speckle(img, rng, amount=0.06, k=(0.9, 1.1)):
    """像现有背景一样撒点明暗颗粒（只动不透明像素）"""
    px = img.load()
    for y in range(H):
        for x in range(W):
            r, g, b, a = px[x, y]
            if a == 0 or rng.random() > amount:
                continue
            f = k[0] if rng.random() < 0.5 else k[1]
            px[x, y] = (min(255, int(r * f)), min(255, int(g * f)), min(255, int(b * f)), a)


def ridge(rng, base, amp, step=4, smooth=0.5):
    """一条随机起伏的轮廓线：每列返回顶边 y"""
    ys = []
    y = base
    v = 0.0
    for x in range(W):
        if x % step == 0:
            v = v * smooth + rng.uniform(-amp, amp)
        y = max(base - amp * 6, min(base + amp * 3, y + v * 0.25))
        ys.append(int(y))
    return ys


def fill_below(img, ys, bottom, color_fn):
    for x in range(W):
        for y in range(max(0, ys[x]), min(H, bottom)):
            img.putpixel((x, y), color_fn(x, y) + (255,))


def sky_gradient(top, low, clouds=None, rng=None, cloud_c=None):
    img = new(True)
    for y in range(H):
        t = min(1.0, y / 110.0)
        c = lerp(top, low, t)
        for x in range(W):
            img.putpixel((x, y), c + (255,))
    if clouds and rng:
        for _ in range(clouds):
            cx, cy = rng.randint(0, W), rng.randint(6, 34)
            w, h = rng.randint(14, 28), rng.randint(3, 5)
            for y in range(cy - h, cy + h):
                for x in range(cx - w, cx + w):
                    if ((x - cx) / w) ** 2 + ((y - cy) / h) ** 2 <= 1.0:
                        put(img, x % W, y, cloud_c)
    return img


def save(img, out, name):
    big = img.resize((W * SCALE, H * SCALE), Image.NEAREST)
    big.save(os.path.join(out, name), optimize=True)


# ==================== 雪地 ====================

def snow(out):
    rng = random.Random(61)
    sky = sky_gradient((112, 128, 150), (196, 206, 220), clouds=7, rng=rng, cloud_c=(226, 230, 238))
    speckle(sky, rng, 0.05)
    save(sky, out, "sky_snow.png")

    mt = new()
    ys = ridge(rng, 70, 7, 5)
    fill_below(mt, ys, HORIZON, lambda x, y: (120, 132, 150) if (y - ys[x]) > 6 + (x * 7) % 5 else (232, 236, 244))
    ys2 = ridge(rng, 84, 5, 4)
    fill_below(mt, ys2, HORIZON, lambda x, y: (96, 108, 128) if (y - ys2[x]) > 4 else (214, 222, 234))
    speckle(mt, rng, 0.08)
    save(mt, out, "mountains_snow.png")

    mid = new()
    x = -4
    while x < W + 8:
        h = rng.randint(26, 44)
        base = HORIZON + rng.randint(0, 4)
        _pine(mid, x, base, h, (34, 62, 52), (238, 242, 248))
        x += rng.randint(9, 16)
    speckle(mid, rng, 0.05)
    save(mid, out, "mid_snow.png")

    gr = new()
    for y in range(HORIZON, H):
        for x in range(W):
            if y < FEET - 6:
                c = (226, 232, 242)
            elif y < FEET + 26:
                band = ((y - FEET) // 6) % 2
                c = (204, 214, 230) if band else (190, 202, 222)
            else:
                c = (232, 238, 246)
            put(gr, x, y, c)
    for _ in range(40):  # 脚印 / 车辙
        fx, fy = rng.randint(0, W - 3), rng.randint(FEET - 4, FEET + 24)
        rect(gr, fx, fy, fx + 2, fy + 1, (170, 182, 204))
    speckle(gr, rng, 0.07, (0.94, 1.04))
    save(gr, out, "ground_strip_snow.png")


def _pine(img, x, base, h, green, snow_c):
    for i in range(h):
        y = base - i
        half = int((h - i) * 0.32) + 1
        for dx in range(-half, half + 1):
            c = green
            # 每层枝上积雪
            if (i % 7) in (5, 6) and abs(dx) < half:
                c = snow_c
            if dx == -half or dx == half:
                c = shade(green, 0.7)
            put(img, x + dx, y, c)
    rect(img, x - 1, base, x + 2, base + 4, (70, 52, 40))


# ==================== 城镇 ====================

def town(out):
    rng = random.Random(71)
    sky = sky_gradient((96, 140, 196), (196, 214, 226), clouds=6, rng=rng, cloud_c=(236, 238, 240))
    speckle(sky, rng, 0.04)
    save(sky, out, "sky_town.png")

    mt = new()  # 远处城墙与塔楼
    ys = ridge(rng, 86, 3, 6)
    fill_below(mt, ys, HORIZON, lambda x, y: (150, 160, 170))
    for tx in range(10, W, 70):
        tw, th = 12, rng.randint(26, 34)
        rect(mt, tx, 86 - th, tx + tw, HORIZON, (136, 146, 158))
        for k in range(tx, tx + tw, 4):
            rect(mt, k, 86 - th - 3, k + 2, 86 - th, (136, 146, 158))
        rect(mt, tx + 4, 86 - th + 8, tx + 7, 86 - th + 13, (60, 64, 76))
    rect(mt, 0, 86, W, 88, (126, 136, 148))
    speckle(mt, rng, 0.06)
    save(mt, out, "mountains_town.png")

    mid = new()  # 一排民宅
    x = -6
    while x < W + 10:
        w = rng.randint(26, 40)
        hgt = rng.randint(22, 34)
        top = HORIZON - hgt
        wall = rng.choice([(214, 196, 160), (200, 186, 166), (222, 210, 186), (186, 168, 140)])
        roof = rng.choice([(150, 70, 52), (120, 64, 54), (96, 84, 110), (140, 96, 60)])
        rect(mid, x, top, x + w, HORIZON, wall)
        # 木梁
        rect(mid, x, top + 6, x + w, top + 7, shade(wall, 0.7))
        for bx in range(x, x + w, 9):
            rect(mid, bx, top, bx + 1, HORIZON, shade(wall, 0.72))
        # 窗与门
        for wx in range(x + 4, x + w - 6, 10):
            rect(mid, wx, top + 10, wx + 5, top + 16, (64, 72, 92))
            rect(mid, wx, top + 10, wx + 5, top + 11, (232, 214, 140))
        dx = x + w // 2 - 3
        rect(mid, dx, HORIZON - 10, dx + 6, HORIZON, (90, 60, 42))
        # 屋顶（三角）
        for i in range(12):
            rect(mid, x - 2 + i, top - 12 + i, x + w + 2 - i, top - 11 + i, roof if i % 3 else shade(roof, 0.8))
        if rng.random() < 0.6:
            cx = x + rng.randint(4, w - 6)
            rect(mid, cx, top - 16, cx + 3, top - 4, (110, 100, 96))
        x += w + rng.randint(2, 6)
    speckle(mid, rng, 0.05)
    save(mid, out, "mid_town.png")

    gr = new()  # 石板路
    for y in range(HORIZON, H):
        for x in range(W):
            row = (y - HORIZON) // 6
            off = 5 if row % 2 else 0
            edge = (y - HORIZON) % 6 == 0 or (x + off) % 11 == 0
            base = (150, 146, 140) if y < FEET + 26 else (126, 122, 118)
            put(gr, x, y, shade(base, 0.72) if edge else shade(base, 0.92 + 0.08 * ((x * 7 + y * 3) % 5) / 4))
    rect(gr, 0, HORIZON, W, HORIZON + 2, (112, 108, 104))
    speckle(gr, rng, 0.06)
    save(gr, out, "ground_strip_town.png")


# ==================== 城堡内 ====================

def castle(out):
    rng = random.Random(81)
    sky = new(True)  # 石墙
    for y in range(H):
        for x in range(W):
            row = y // 8
            off = 8 if row % 2 else 0
            edge = y % 8 == 0 or (x + off) % 16 == 0
            c = (72, 70, 82) if not edge else (52, 50, 60)
            put(sky, x, y, c)
    speckle(sky, rng, 0.08)
    save(sky, out, "sky_castle.png")

    mt = new()  # 拱窗 + 月光
    for ax in range(20, W, 80):
        rect(mt, ax, 44, ax + 30, 96, (40, 44, 70))
        for i in range(15):
            rect(mt, ax + 15 - i, 44 - int(math.sqrt(225 - i * i) * 0.6), ax + 15 + i, 44, (40, 44, 70))
        rect(mt, ax + 3, 50, ax + 27, 94, (88, 104, 150))
        rect(mt, ax + 14, 50, ax + 16, 94, (40, 44, 70))
        rect(mt, ax + 3, 70, ax + 27, 72, (40, 44, 70))
    speckle(mt, rng, 0.05)
    save(mt, out, "mountains_castle.png")

    mid = new()  # 石柱、旗帜、火把
    for cx in range(0, W + 40, 60):
        rect(mid, cx, 54, cx + 14, HORIZON, (116, 110, 120))
        rect(mid, cx + 2, 54, cx + 4, HORIZON, (148, 142, 150))
        rect(mid, cx - 3, 54, cx + 17, 58, (96, 90, 100))
        rect(mid, cx - 3, HORIZON - 4, cx + 17, HORIZON, (96, 90, 100))
    for bx in range(30, W, 120):
        rect(mid, bx, 58, bx + 18, 92, (150, 40, 44))
        for i in range(6):
            rect(mid, bx + i, 92 + i, bx + 18 - i, 93 + i, (150, 40, 44))
        rect(mid, bx + 6, 66, bx + 12, 74, (232, 196, 96))
    for tx in range(90, W, 120):
        rect(mid, tx, 74, tx + 3, 84, (80, 60, 44))
        rect(mid, tx - 1, 69, tx + 4, 74, (250, 170, 60))
        rect(mid, tx, 66, tx + 3, 69, (255, 226, 120))
    speckle(mid, rng, 0.04)
    save(mid, out, "mid_castle.png")

    gr = new()  # 方砖地 + 中间红毯
    for y in range(HORIZON, H):
        for x in range(W):
            edge = (y - HORIZON) % 10 == 0 or x % 20 == 0
            checker = ((x // 20) + ((y - HORIZON) // 10)) % 2
            c = (124, 118, 126) if checker else (108, 102, 112)
            if edge:
                c = (84, 80, 90)
            if FEET - 10 <= y < FEET + 12:
                c = (138, 36, 42) if not (y in (FEET - 10, FEET + 11)) else (212, 176, 90)
            put(gr, x, y, c)
    speckle(gr, rng, 0.05)
    save(gr, out, "ground_strip_castle.png")


# ==================== 山岭 ====================

def hills(out):
    rng = random.Random(91)
    sky = sky_gradient((90, 130, 186), (210, 214, 200), clouds=5, rng=rng, cloud_c=(240, 240, 236))
    speckle(sky, rng, 0.04)
    save(sky, out, "sky_hills.png")

    mt = new()
    ys = ridge(rng, 62, 9, 6, 0.7)
    fill_below(mt, ys, HORIZON, lambda x, y: (126, 116, 110) if (y - ys[x]) > 5 else (226, 226, 230))
    ys2 = ridge(rng, 80, 6, 4)
    fill_below(mt, ys2, HORIZON, lambda x, y: shade((112, 104, 96), 0.85 + 0.15 * ((x // 3 + y // 4) % 3) / 2))
    speckle(mt, rng, 0.08)
    save(mt, out, "mountains_hills.png")

    mid = new()  # 近处岩坡 + 灌木
    ys = ridge(rng, 92, 4, 3)
    fill_below(mid, ys, HORIZON, lambda x, y: (138, 120, 96) if (y - ys[x]) > 2 else (112, 132, 72))
    for _ in range(14):
        bx, by = rng.randint(0, W), rng.randint(92, 104)
        r = rng.randint(4, 8)
        for y in range(by - r, by + 1):
            for x in range(bx - r, bx + r):
                if (x - bx) ** 2 + (y - by) ** 2 <= r * r:
                    put(mid, x, y, (150, 142, 132) if y < by - r // 2 else (110, 102, 94))
    for _ in range(18):
        sx, sy = rng.randint(0, W), rng.randint(96, 106)
        rect(mid, sx, sy, sx + 5, sy + 3, (74, 104, 52))
    speckle(mid, rng, 0.06)
    save(mid, out, "mid_hills.png")

    gr = new()  # 碎石土路
    for y in range(HORIZON, H):
        for x in range(W):
            if y < FEET - 6:
                c = (120, 132, 74)
            elif y < FEET + 26:
                band = ((y - FEET) // 6) % 2
                c = (150, 128, 98) if band else (134, 114, 88)
            else:
                c = (110, 120, 70)
            put(gr, x, y, c)
    for _ in range(90):
        px, py = rng.randint(0, W - 2), rng.randint(FEET - 4, FEET + 24)
        rect(gr, px, py, px + 2, py + 1, (172, 160, 142))
    speckle(gr, rng, 0.08)
    save(gr, out, "ground_strip_hills.png")


# ==================== 河岸 ====================

def river(out):
    rng = random.Random(101)
    sky = sky_gradient((104, 150, 204), (220, 226, 214), clouds=7, rng=rng, cloud_c=(244, 244, 240))
    speckle(sky, rng, 0.04)
    save(sky, out, "sky_river.png")

    mt = new()  # 对岸远山与树线
    ys = ridge(rng, 78, 5, 6)
    fill_below(mt, ys, 96, lambda x, y: (118, 140, 128))
    ys2 = ridge(rng, 90, 3, 3)
    fill_below(mt, ys2, 98, lambda x, y: (70, 104, 70))
    speckle(mt, rng, 0.07)
    save(mt, out, "mountains_river.png")

    mid = new()  # 河面
    for y in range(96, HORIZON + 4):
        for x in range(W):
            c = (70, 122, 170) if y < 102 else (84, 140, 184)
            put(mid, x, y, c)
    for _ in range(60):
        wx, wy = rng.randint(0, W - 6), rng.randint(97, HORIZON + 2)
        rect(mid, wx, wy, wx + rng.randint(3, 7), wy + 1, (190, 220, 236))
    for _ in range(26):  # 芦苇
        rx = rng.randint(0, W)
        for k in range(rng.randint(5, 10)):
            put(mid, rx, HORIZON + 2 - k, (96, 124, 60))
            if k > 4:
                put(mid, rx, HORIZON + 2 - k, (120, 90, 60))
    speckle(mid, rng, 0.04)
    save(mid, out, "mid_river.png")

    gr = new()  # 沙岸
    for y in range(HORIZON, H):
        for x in range(W):
            if y < HORIZON + 3:
                c = (176, 200, 210)
            elif y < FEET + 26:
                band = ((y - FEET) // 6) % 2
                c = (214, 196, 150) if band else (200, 182, 138)
            else:
                c = (188, 170, 128)
            put(gr, x, y, c)
    for _ in range(70):
        px, py = rng.randint(0, W - 2), rng.randint(FEET - 4, FEET + 30)
        rect(gr, px, py, px + 2, py + 1, rng.choice([(150, 140, 126), (232, 222, 196)]))
    speckle(gr, rng, 0.07)
    save(gr, out, "ground_strip_river.png")


def main():
    out = sys.argv[1] if len(sys.argv) > 1 else "art/combat/bg"
    os.makedirs(out, exist_ok=True)
    for fn in (snow, town, castle, hills, river):
        fn(out)
        print("ok", fn.__name__)


if __name__ == "__main__":
    main()
