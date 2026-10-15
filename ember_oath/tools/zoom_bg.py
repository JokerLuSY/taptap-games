# -*- coding: utf-8 -*-
"""放大 ch1_bg.png 关键地标区域，检查 AI 手绘背景残留问题"""
from PIL import Image

SRC = r"E:\projects\taptap\ember_oath\art\maps\ch1_bg.png"
OUT = r"E:\projects\taptap\ember_oath\tools\shots"

TILE = 64
# (tile_x, tile_y, label) —— 逻辑地标位置
jobs = [
    (3, 1, "bg_house_a.png"),    # 房 A (3,1)
    (9, 1, "bg_house_b.png"),    # 房 B (9,1)
    (1, 3, "bg_house_c.png"),    # 房 C (1,3)
    (12, 3, "bg_house_d.png"),   # 房 D (12,3)
    (8, 1, "bg_well.png"),       # 井 (8,1)
    (2, 2, "bg_field.png"),      # 农田 (2,2)(3,2) 两格横跨
    (0, 4, "bg_sand_w.png"),     # 西沙滩 (0,4)
    (14, 6, "bg_sand_e.png"),    # 东沙滩 (14,6)
    (2, 7, "bg_mount_w.png"),    # 西山 (2,7)
    (10, 7, "bg_mount_e.png"),   # 东山 (10,7)
    (7, 5, "bg_bridge.png"),     # 桥 (7,5) 含上下游河带
    (7, 4, "bg_road_bridge_n.png"),  # 桥北路口
]

img = Image.open(SRC)
S = 2  # 放大倍数
# 每格向四周外扩 0.75 格，看融入情况
PAD = 48
for tx, ty, name in jobs:
    x0, y0 = tx * TILE, ty * TILE
    box = (max(0, x0 - PAD), max(0, y0 - PAD),
           min(img.width, x0 + TILE + PAD), min(img.height, y0 + TILE + PAD))
    crop = img.crop(box)
    # 桥特例: 拉宽到整条河带上下
    if name == "bg_bridge.png":
        box = (max(0, x0 - PAD), 250, min(img.width, x0 + TILE + PAD), 450)
        crop = img.crop(box)
    crop = crop.resize((crop.width * S, crop.height * S), Image.NEAREST)
    crop.save(OUT + "\\" + name)
    print("saved", name, box)