# -*- coding: utf-8 -*-
"""4 个待确认区域: 房A东侧物体 / 第14列崖壁 / 东岸沙洲 / 桥东阴影"""
from PIL import Image, ImageDraw

SRC = r"E:\projects\taptap\ember_oath\tools\shots\raw_crop.png"
OUT = r"E:\projects\taptap\ember_oath\tools\shots"
TILE = 64
S = 2

jobs = [
    ("chk_house_a_e.png", (230, 0, 400, 150), [(4, 1), (5, 1), (4, 0)]),
    ("chk_col14.png", (848, 64, 960, 300), [(13, 1), (14, 1), (13, 2), (14, 2), (13, 3), (14, 3), (13, 4), (14, 4)]),
    ("chk_e_shore.png", (740, 300, 960, 470), [(12, 5), (13, 5), (14, 5), (12, 6), (13, 6), (14, 6)]),
    ("chk_bridge_e.png", (290, 280, 520, 420), [(5, 4), (6, 4), (7, 4), (5, 5), (6, 5), (7, 5)]),
]

img = Image.open(SRC).convert("RGB")
for name, box, marks in jobs:
    crop = img.crop(box)
    over = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    gx0 = -(box[0] % TILE)
    for x in range(gx0, crop.width + TILE, TILE):
        d.line([(x, 0), (x, crop.height)], fill=(255, 40, 40, 170), width=1)
    gy0 = -(box[1] % TILE)
    for y in range(gy0, crop.height + TILE, TILE):
        d.line([(0, y), (crop.width, y)], fill=(255, 40, 40, 170), width=1)
    for tx, ty in marks:
        x0 = tx * TILE - box[0]
        y0 = ty * TILE - box[1]
        if -TILE < x0 < crop.width and -TILE < y0 < crop.height:
            d.rectangle([x0, y0, x0 + TILE, y0 + TILE], outline=(255, 0, 255, 200), width=2)
            d.text((x0 + 3, y0 + 3), "(%d,%d)" % (tx, ty), fill=(255, 0, 255, 255))
    crop = Image.alpha_composite(crop.convert("RGBA"), over)
    crop = crop.resize((crop.width * S, crop.height * S), Image.NEAREST)
    crop.save(OUT + "\\" + name)
    print("saved", name, box)