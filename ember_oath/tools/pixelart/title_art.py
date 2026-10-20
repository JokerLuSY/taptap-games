"""标题画面主视觉（原创像素画，替换早期的 AI 插画）：140×180 逐像素绘制。

夜空（深蓝 → 紫 → 地平线上的火光）、残月和星星、远山、右边山丘上的圣都剪影、
燃烧的灰岩村（屋子剪影 + 火苗 + 烟）、飘起的火星；前景是缇娅（直接取战斗特写的待机帧，脚踩在焦土上）。
最后取缇娅周围 94×120 一块 ×3 放大（282×360，标题框 280×360 居中裁掉 1px）。
用法：python -P -E title_art.py <ember_oath 目录>   → art/title/key_art.png
"""
import math
import os
import random
import sys
from PIL import Image, ImageDraw

W, H = 140, 180
SKY = [(14, 12, 30), (22, 18, 44), (36, 24, 58), (58, 30, 64), (92, 38, 58), (140, 54, 46), (186, 82, 44)]
FIRE = [(255, 244, 196), (255, 214, 96), (255, 156, 48), (226, 86, 36), (150, 40, 30)]


def build(root):
    rnd = random.Random(7)
    img = Image.new("RGBA", (W, H), SKY[0] + (255,))
    px = img.load()
    # 天空：分档 + 档边棋盘抖动
    horizon = 128
    for y in range(H):
        t = y / horizon
        f = min(len(SKY) - 1.001, max(0.0, t * t * (len(SKY) - 1)))
        k = int(f)
        frac = f - k
        for x in range(W):
            kk = k + (1 if frac > 0.5 and (x + y) % 2 == 0 and k + 1 < len(SKY) else 0)
            px[x, y] = SKY[kk] + (255,)
    # 星星
    for _ in range(40):
        x, y = rnd.randrange(20, 120), rnd.randrange(58, 100)
        px[x, y] = (230, 226, 255, 255) if rnd.random() < 0.3 else (150, 146, 190, 255)
    # 残月
    for y in range(H):
        for x in range(W):
            if (x - 46) ** 2 + (y - 74) ** 2 <= 8 ** 2 and (x - 42) ** 2 + (y - 71) ** 2 > 7 ** 2:
                px[x, y] = ((250, 240, 214) if x > 49 else (226, 214, 186)) + (255,)
    d = ImageDraw.Draw(img)
    # 远山（两层）
    ridge = []
    for x in range(-2, W + 3, 3):
        ridge.append((x, 104 - 10 * math.sin(x / 13.0) - 6 * math.sin(x / 5.3 + 1)))
    d.polygon(ridge + [(W + 2, H), (-2, H)], fill=(44, 26, 52))
    ridge2 = [(x, 118 - 6 * math.sin(x / 9.0 + 2) - 3 * math.sin(x / 3.1)) for x in range(-2, W + 3, 2)]
    d.polygon(ridge2 + [(W + 2, H), (-2, H)], fill=(34, 20, 38))
    # 圣都剪影（右侧山丘上：城墙 + 尖塔）
    sil = (24, 14, 28)
    d.polygon([(92, 122), (100, 108), (140, 104), (140, 130), (92, 130)], fill=sil)
    for x0, h, w in ((104, 26, 4), (112, 36, 5), (121, 30, 4), (129, 22, 4)):
        d.rectangle((x0, 108 - h + 6, x0 + w, 112), fill=sil)
        d.polygon([(x0 - 1, 108 - h + 6), (x0 + w / 2, 108 - h - 2), (x0 + w + 1, 108 - h + 6)], fill=sil)
    for x0, y0 in ((113, 86), (122, 92)):
        px[x0, y0] = (255, 214, 120, 255)
    # 燃烧的村子：屋子剪影 + 火 + 烟
    ground_y = 150
    houses = [(4, 22, 16), (24, 18, 12), (40, 26, 18), (62, 20, 14), (78, 24, 16)]
    for hx, hw, hh in houses:
        top = ground_y - hh
        d.rectangle((hx, top, hx + hw, ground_y), fill=(30, 16, 20))
        d.polygon([(hx - 2, top + 1), (hx + hw / 2, top - 8), (hx + hw + 2, top + 1)], fill=(30, 16, 20))
        # 窗里透火光
        d.rectangle((hx + 4, top + 5, hx + 6, top + 7), fill=FIRE[2])
        # 火苗
        for i in range(5):
            fx = hx + rnd.randrange(hw)
            fh = rnd.randrange(6, 16)
            for y in range(fh):
                w = max(0, int((fh - y) / 4))
                c = FIRE[min(4, y * 5 // fh)] if y < fh - 2 else FIRE[0]
                for dx in range(-w, w + 1):
                    xx, yy = fx + dx, top - 6 - y + rnd.randrange(0, 2)
                    if 0 <= xx < W and 0 <= yy < H:
                        px[xx, yy] = FIRE[min(4, 1 + y * 4 // fh)] + (255,) if dx else c + (255,)
        # 烟
        for i in range(10):
            sx = hx + hw // 2 + rnd.randrange(-4, 5) + i // 2
            sy = top - 20 - i * 3
            r = 2 + i // 3
            d.ellipse((sx - r, sy - r, sx + r, sy + r), fill=(60, 44, 56) if i % 2 else (52, 38, 50))
    # 焦土地面
    d.rectangle((0, ground_y, W, H), fill=(40, 22, 22))
    for x in range(W):
        for y in range(ground_y, H):
            if (x * 7 + y * 13) % 11 == 0:
                px[x, y] = (58, 32, 28, 255)
            if y == ground_y:
                px[x, y] = (96, 48, 34, 255)
    # 缇娅：战斗特写待机第一帧，脚踩地面
    here = os.path.dirname(os.path.abspath(__file__))
    strip = Image.open(os.path.join(root, "art", "combat", "fe", "tia", "idle.png")).convert("RGBA")
    fr = strip.crop((0, 0, 120, 148))
    bb = fr.getbbox()
    tia = fr.crop(bb)
    # 脚底 = 帧里 feet.y（120）
    feet_in_crop = 120 - bb[1]
    ox = W // 2 - tia.width // 2 + 4
    oy = 172 - feet_in_crop
    # 脚下的影子和身后的火光晕
    d.ellipse((ox + 4, 168, ox + tia.width - 4, 176), fill=(24, 12, 14))
    img.alpha_composite(tia, (ox, oy))
    # 火星
    for _ in range(36):
        x, y = rnd.randrange(W), rnd.randrange(40, 160)
        px[x, y] = FIRE[rnd.randrange(0, 3)] + (255,)
    # 取缇娅周围 94×120 一块，×3 放大（像素大小统一，人物占画面四成）
    crop = img.crop((23, 58, 117, 178))
    out = crop.resize((crop.width * 3, crop.height * 3), Image.NEAREST)
    os.makedirs(os.path.join(root, "art", "title"), exist_ok=True)
    out.save(os.path.join(root, "art", "title", "key_art.png"))
    print("ok", tia.size, (ox, oy))


if __name__ == "__main__":
    build(sys.argv[1])
