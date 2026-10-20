"""《炎烬之誓》APP 图标（原创像素画）：64×64 逐像素生成，最近邻放大。

方案：
  A 炎刃纹章：深蓝圆角底，金边盾形纹章，一柄剑尖朝下的剑，剑身裹着往上窜的火焰
  B 誓火：中央一团大火焰（三层：白芯 / 金 / 橙红），下方两柄交叉的剑，四周飘火星
  C 缇娅：地图小人缇娅（游戏里的像素小人 ×3）站在火焰光环前，脚下一块草地
用法：python -P -E app_icon.py <输出目录>   → icon_A.png / icon_B.png / icon_C.png（512×512）+ preview.png
定稿（方案 A）：python -P -E app_icon.py --final <ember_oath 目录>
  → icon.png（512，项目 / 窗口图标）、art/icon/icon_192.png（安卓传统启动图标）、
    art/icon/icon_fg_432.png / icon_bg_432.png / icon_mono_432.png（安卓自适应图标前景 / 背景 / 单色）
"""
import math
import os
import sys
from PIL import Image, ImageDraw

N = 64
OUT = (12, 10, 22)

NAVY = [(22, 26, 52), (30, 36, 72), (40, 50, 96)]
FIRE = [(255, 250, 214), (255, 226, 112), (255, 170, 52), (236, 96, 36), (176, 44, 32), (96, 20, 24)]
GOLD = [(255, 236, 150), (236, 192, 80), (184, 132, 44), (110, 72, 24)]
STEEL = [(248, 250, 255), (200, 210, 228), (138, 150, 176), (78, 86, 112)]


def canvas():
    return Image.new("RGBA", (N, N), (0, 0, 0, 0))


def rounded_bg(img, inner=NAVY, r=12):
    """圆角方底 + 由中心往外变暗"""
    px = img.load()
    for y in range(N):
        for x in range(N):
            dx = max(r - x, 0, x - (N - 1 - r))
            dy = max(r - y, 0, y - (N - 1 - r))
            if dx * dx + dy * dy > r * r:
                continue
            d = math.hypot(x - 31.5, y - 28) / 40
            c = inner[2] if d < 0.45 else (inner[1] if d < 0.8 else inner[0])
            px[x, y] = c + (255,)
    return img


def mask_poly(pts):
    m = Image.new("L", (N, N), 0)
    ImageDraw.Draw(m).polygon(pts, fill=255)
    return m


def fill_mask(img, m, ramp, light=(-0.6, -0.8), outline=OUT):
    """在蒙版范围内按光向分档上色，外缘描边"""
    mp = m.load()
    px = img.load()
    pts = [(x, y) for y in range(N) for x in range(N) if mp[x, y]]
    if not pts:
        return
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    rx, ry = max(1, (max(xs) - min(xs)) / 2), max(1, (max(ys) - min(ys)) / 2)
    for x, y in pts:
        edge = any(not (0 <= x + dx < N and 0 <= y + dy < N and mp[x + dx, y + dy]) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if edge and outline is not None:
            px[x, y] = outline + (255,)
            continue
        t = ((x - cx) / rx * light[0] + (y - cy) / ry * light[1]) / 1.6
        k = 0 if t > 0.55 else (1 if t > 0.1 else (2 if t > -0.4 else 3))
        k = min(k, len(ramp) - 1)
        px[x, y] = ramp[k] + (255,)


def flame_mask(cx, base, w, h, wobble=0.0, tongues=3):
    """火焰形：底部圆、往上收成几条火舌"""
    pts = []
    steps = 40
    for i in range(steps + 1):
        t = i / steps
        a = math.pi * t
        # 下半圆
        pts.append((cx - w * math.cos(a), base - w * 0.55 * math.sin(a) * 0 + w * 0.5 * math.sin(a)))
    pts = [(cx + w * math.cos(math.pi + math.pi * i / steps), base + w * 0.55 * math.sin(math.pi * i / steps)) for i in range(steps + 1)]
    pts = pts[::-1]
    top = []
    for i in range(tongues * 2 + 1):
        u = i / (tongues * 2)
        x = cx - w + 2 * w * u
        if i % 2 == 1:
            # 火舌尖：中间最高
            hh = h * (1.0 - 0.45 * abs(u - 0.5) * 2) + wobble * math.sin(i * 1.7)
            top.append((x + (u - 0.5) * 3, base - hh))
        else:
            hh = h * (0.45 - 0.25 * abs(u - 0.5) * 2)
            top.append((x, base - hh))
    return mask_poly(pts + top[::-1])


def sparks(img, pts, colors=(FIRE[1], FIRE[2])):
    px = img.load()
    for i, (x, y) in enumerate(pts):
        if 0 <= x < N and 0 <= y < N:
            px[x, y] = colors[i % len(colors)] + (255,)


def sword(img, cx, tip_y, hilt_y, blade_w=2, steel=STEEL, gold=GOLD, pommel=True, angle=0.0, pivot=None):
    """剑：先按剑尖朝下（tip_y > hilt_y）画，再绕 pivot（默认护手中心）转 angle 弧度"""
    px_, py_ = pivot if pivot else (cx, hilt_y)

    def rot(p):
        x, y = p[0] - px_, p[1] - py_
        ca, sa = math.cos(angle), math.sin(angle)
        return (px_ + x * ca - y * sa, py_ + x * sa + y * ca)
    blade = [(cx - blade_w, hilt_y + 2), (cx + blade_w + 1, hilt_y + 2), (cx + blade_w + 1, tip_y - 4), (cx + 0.5, tip_y), (cx - blade_w, tip_y - 4)]
    fill_mask(img, mask_poly([rot(p) for p in blade]), steel, light=(-1, 0))
    guard = [(cx - 8, hilt_y - 1), (cx + 9, hilt_y - 1), (cx + 9, hilt_y + 2), (cx - 8, hilt_y + 2)]
    fill_mask(img, mask_poly([rot(p) for p in guard]), gold)
    grip = [(cx - 1, hilt_y - 9), (cx + 2, hilt_y - 9), (cx + 2, hilt_y - 1), (cx - 1, hilt_y - 1)]
    fill_mask(img, mask_poly([rot(p) for p in grip]), [(150, 70, 52), (120, 52, 40), (90, 38, 30), (60, 26, 22)])
    if pommel:
        p = rot((cx + 0.5, hilt_y - 11))
        m = Image.new("L", (N, N), 0)
        ImageDraw.Draw(m).ellipse((p[0] - 2.5, p[1] - 2.5, p[0] + 2.5, p[1] + 2.5), fill=255)
        fill_mask(img, m, gold)


def concept_a(with_bg=True):
    img = rounded_bg(canvas()) if with_bg else canvas()
    # 火焰（在纹章后面往上窜）
    fill_mask(img, flame_mask(31.5, 40, 17, 34, tongues=3), FIRE[2:], outline=FIRE[5])
    fill_mask(img, flame_mask(31.5, 40, 11, 24, tongues=2), FIRE[1:4], outline=None)
    # 盾形纹章
    shield = [(18, 22), (45, 22), (45, 38), (39, 49), (31.5, 54), (24, 49), (18, 38)]
    fill_mask(img, mask_poly(shield), [(176, 40, 40), (148, 30, 34), (116, 22, 30), (84, 16, 24)])
    rim = Image.new("L", (N, N), 0)
    d = ImageDraw.Draw(rim)
    d.polygon(shield, outline=255)
    inner = [(20, 24), (43, 24), (43, 37), (38, 47), (31.5, 51), (25, 47), (20, 37)]
    d.polygon(inner, outline=255)
    px = img.load()
    rp = rim.load()
    for y in range(N):
        for x in range(N):
            if rp[x, y]:
                px[x, y] = (GOLD[1] if (x + y) % 5 else GOLD[0]) + (255,)
    # 剑：剑尖朝下贯穿纹章
    sword(img, 31, 58, 17, blade_w=2)
    sparks(img, [(12, 20), (50, 14), (54, 26), (9, 32), (47, 8), (16, 10)])
    return img


def concept_b():
    img = rounded_bg(canvas())
    # 两柄交叉的剑（剑尖朝上）
    # 剑尖朝上、斜着交叉在火焰后面：先画剑尖朝下的剑，再绕画面中心转 180°±35°
    for ang in (0.62, -0.62):
        sword(img, 31.5, 58, 14, blade_w=1, angle=math.pi + ang, pivot=(31.5, 34))
    # 大火焰
    fill_mask(img, flame_mask(31.5, 44, 15, 36, tongues=3, wobble=1.5), FIRE[2:], outline=FIRE[5])
    fill_mask(img, flame_mask(31.5, 44, 10, 26, tongues=2), FIRE[1:4], outline=None)
    fill_mask(img, flame_mask(31.5, 44, 5, 14, tongues=1), FIRE[0:2], outline=None)
    sparks(img, [(14, 18), (49, 12), (52, 30), (10, 36), (44, 6), (20, 8), (56, 44), (7, 48)])
    return img


def concept_c():
    img = rounded_bg(canvas(), inner=[(26, 20, 40), (40, 28, 52), (64, 38, 60)])
    # 火焰光环
    px = img.load()
    for y in range(N):
        for x in range(N):
            d = math.hypot(x - 31.5, y - 27)
            if 19 <= d <= 23 and px[x, y][3]:
                ang = math.atan2(y - 27, x - 31.5)
                k = 1 if (int(ang * 10) % 3) else 2
                px[x, y] = FIRE[k + (1 if d > 21.5 else 0)] + (255,)
            elif 23 < d <= 24.5 and px[x, y][3]:
                px[x, y] = FIRE[4] + (255,)
    fill_mask(img, flame_mask(31.5, 50, 20, 30, tongues=4, wobble=2), FIRE[3:], outline=None)
    # 草地
    for y in range(50, 58):
        for x in range(10, 54):
            if px[x, y][3] and (x - 31.5) ** 2 / 22 ** 2 + (y - 52) ** 2 / 5 ** 2 <= 1:
                px[x, y] = ((112, 168, 72) if y < 52 else (84, 136, 60)) + (255,)
    # 缇娅地图小人（待机第一帧，16×16，×3）
    here = os.path.dirname(os.path.abspath(__file__))
    sheet = Image.open(os.path.join(here, "..", "..", "art", "units", "fe", "tia_blue.png")).convert("RGBA")  # 下面换成红色板
    fw = sheet.width // 4
    fh = sheet.height // 4
    tia = sheet.crop((0, 0, fw, fh)).resize((fw * 3, fh * 3), Image.NEAREST)
    # 我方蓝色板看不出缇娅的红发：换成游戏里的红色板（阵营色阶 1–5）
    sys.path.insert(0, here)
    from fe_units import RAMPS
    blue = {v: k for k, v in RAMPS["blue"].items()}
    tp = tia.load()
    for y in range(tia.height):
        for x in range(tia.width):
            c = tp[x, y]
            if c[3] and c[:3] in blue:
                tp[x, y] = RAMPS["red"][blue[c[:3]]] + (255,)
    img.alpha_composite(tia, (32 - fw * 3 // 2, 54 - fh * 3))
    sparks(img, [(12, 14), (50, 10), (54, 24), (8, 30), (46, 4), (18, 6)])
    return img


CONCEPTS = {"A": concept_a, "B": concept_b, "C": concept_c}


def big(img, size=512):
    return img.resize((size, size), Image.NEAREST)


def export_final(root):
    """定稿方案 A：项目图标 + 安卓启动图标（传统 192 + 自适应前景 / 背景 / 单色，各 432）"""
    d = os.path.join(root, "art", "icon")
    os.makedirs(d, exist_ok=True)
    full = concept_a()
    big(full, 512).save(os.path.join(root, "icon.png"))
    big(full, 192).save(os.path.join(d, "icon_192.png"))
    # 自适应图标：432 画布，中间 288（2/3）是安全区，各家桌面会裁成圆 / 方 / 水滴。
    # 纹章本体（裁到实际内容）×5 约 270 高，放在中间，不会被裁掉
    art = concept_a(with_bg=False)
    art = art.crop(art.getbbox())
    art = art.resize((art.width * 5, art.height * 5), Image.NEAREST)
    fg = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    fg.alpha_composite(art, ((432 - art.width) // 2, (432 - art.height) // 2))
    fg.save(os.path.join(d, "icon_fg_432.png"))
    # 背景：深蓝，从中心往外三档变暗（108 格 ×4 保持像素感）
    bg = Image.new("RGBA", (108, 108), NAVY[0] + (255,))
    bp = bg.load()
    for y in range(108):
        for x in range(108):
            r = math.hypot(x - 53.5, y - 50) / 70
            bp[x, y] = (NAVY[2] if r < 0.45 else (NAVY[1] if r < 0.8 else NAVY[0])) + (255,)
    bg.resize((432, 432), Image.NEAREST).save(os.path.join(d, "icon_bg_432.png"))
    # 单色（安卓 13 主题图标）：前景剪影，白色
    mono = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
    a = fg.getchannel("A")
    mono.paste((255, 255, 255, 255), (0, 0), a)
    mono.save(os.path.join(d, "icon_mono_432.png"))
    print("final ok")


if __name__ == "__main__":
    if sys.argv[1] == "--final":
        export_final(sys.argv[2])
        sys.exit(0)
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    imgs = {}
    for k, fn in CONCEPTS.items():
        imgs[k] = big(fn())
        imgs[k].save(os.path.join(out, "icon_%s.png" % k))
    pv = Image.new("RGBA", (3 * 512 + 4 * 32, 512 + 64 + 3 * 96), (240, 240, 244, 255))
    for i, k in enumerate(CONCEPTS):
        pv.alpha_composite(imgs[k], (32 + i * 544, 32))
        # 手机桌面大小（96px）
        pv.alpha_composite(imgs[k].resize((96, 96), Image.LANCZOS), (32 + i * 544 + 208, 576))
    pv.save(os.path.join(out, "preview.png"))
    print("ok")
