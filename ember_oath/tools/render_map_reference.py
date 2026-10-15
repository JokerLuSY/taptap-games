# -*- coding: utf-8 -*-
"""从 chapter1.gd 的 MAP/LEVELS 渲染布局参考图 (960x640 + 上下 40px 补边 = 960x720)
供 AI 图像生成作为 reference_image 使用, 保证手绘地图与格子逻辑对齐"""
import re

from PIL import Image, ImageDraw

TILE = 64
PAD = 40  # 上下各补 40px, 凑 4:3
SRC = r"E:\projects\taptap\ember_oath\scripts\chapter1.gd"
DST = r"E:\projects\taptap\ember_oath\tools\map_reference.png"


def read_block(text, name):
    m = re.search(name + r"\s*:=\s*\[(.*?)\]", text, re.S)
    return re.findall(r'"([^"]+)"', m.group(1))


text = open(SRC, encoding="utf-8").read()
MAP = read_block(text, "MAP")
LEVELS = read_block(text, "LEVELS")
W, H = len(MAP[0]), len(MAP)

img = Image.new("RGB", (W * TILE, H * TILE + PAD * 2))
d = ImageDraw.Draw(img)

COLORS = {
    ".": (122, 168, 92), "g": (178, 172, 96), "F": (56, 100, 54),
    "H": (168, 140, 105), "R": (190, 168, 128), "~": (58, 108, 170),
    "B": (140, 100, 60), "M": (130, 126, 120), "f": (150, 116, 72),
    "W": (110, 110, 110), "s": (214, 192, 142),
}

# 补边: 顶部森林, 底部草地
d.rectangle([0, 0, W * TILE, PAD], fill=COLORS["F"])
d.rectangle([0, H * TILE + PAD, W * TILE, H * TILE + PAD * 2], fill=COLORS["."])

for y in range(H):
    for x in range(W):
        t = MAP[y][x]
        lv = int(LEVELS[y][x])
        c = COLORS[t]
        x0, y0 = x * TILE, y * TILE + PAD
        d.rectangle([x0, y0, x0 + TILE, y0 + TILE], fill=c)
        cx, cy = x0 + TILE // 2, y0 + TILE // 2
        if t == "F":
            d.ellipse([cx - 18, cy - 20, cx + 18, cy + 14], fill=(36, 74, 38))
            d.rectangle([cx - 3, cy + 8, cx + 3, cy + 20], fill=(70, 50, 30))
        elif t == "H":
            d.rectangle([x0 + 12, y0 + 24, x0 + 52, y0 + 54], fill=(196, 172, 130))
            d.polygon([(x0 + 8, y0 + 26), (cx, y0 + 6), (x0 + 56, y0 + 26)], fill=(170, 70, 50))
        elif t == "M":
            d.polygon([(x0 + 10, y0 + 50), (cx, y0 + 12), (x0 + 54, y0 + 50)], fill=(105, 100, 95))
        elif t == "f":
            for i in range(3):
                d.line([x0, y0 + 14 + i * 18, x0 + TILE, y0 + 14 + i * 18], fill=(110, 84, 50), width=3)
        elif t == "W":
            d.ellipse([cx - 12, cy - 4, cx + 12, cy + 12], fill=(90, 90, 90))
            d.polygon([(cx - 14, cy - 4), (cx, cy - 18), (cx + 14, cy - 4)], fill=(170, 70, 50))
        elif t == "B":
            d.rectangle([x0, y0 + 6, x0 + TILE, y0 + TILE - 6], fill=(150, 108, 64))
            d.rectangle([x0, y0 + 2, x0 + TILE, y0 + 8], fill=(110, 78, 44))
            d.rectangle([x0, y0 + TILE - 8, x0 + TILE, y0 + TILE - 2], fill=(110, 78, 44))
        # 高度差悬崖提示线 (告诉 AI 这里有台地边缘)
        for dx, dy in ((0, 1), (-1, 0), (1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < W and 0 <= ny < H and int(LEVELS[ny][nx]) < lv and MAP[ny][nx] != "B":
                if dy == 1:
                    d.rectangle([x0, y0 + TILE - 8, x0 + TILE, y0 + TILE], fill=(150, 112, 72))
                elif dx == -1:
                    d.rectangle([x0, y0, x0 + 6, y0 + TILE], fill=(150, 112, 72))
                else:
                    d.rectangle([x0 + TILE - 6, y0, x0 + TILE, y0 + TILE], fill=(150, 112, 72))

img.save(DST)
print("saved", DST, img.size)
