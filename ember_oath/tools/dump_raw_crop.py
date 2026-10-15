# -*- coding: utf-8 -*-
"""复现 compose_map 的裁剪（不做任何补丁），输出原始裁剪图供定位彩绘物边界"""
from PIL import Image

SRC = r"C:\Users\lushe\.cursor\projects\e-projects-taptap\assets\ch1_map_b.jpg"
OUT = r"E:\projects\taptap\ember_oath\tools\shots\raw_crop.png"

img = Image.open(SRC).convert("RGB")
img = img.resize((960, 720), Image.LANCZOS)

RIVER_TARGET_TOP = 320


def river_center(im):
    best_y, best_score = 0, -1
    for y in range(200, 560):
        score = 0
        for x in (100, 180, 260):
            r, g, b = im.getpixel((x, y))
            score += b - (r + g) / 2
        if score > best_score:
            best_score, best_y = score, y
    return best_y


cy = river_center(img)
off_y = max(0, min(80, cy - (RIVER_TARGET_TOP + 32)))
crop = img.crop((0, off_y, 960, off_y + 640))
crop.save(OUT, optimize=True)
print("river_center:", cy, "offset:", off_y, "-> raw_crop.png 960x640")