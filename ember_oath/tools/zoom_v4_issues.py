# -*- coding: utf-8 -*-
"""v4 后复查: 桥(第5列)真实位置 / 房D残留 / 房B井区 / 西南岩丘羽化痕"""
from PIL import Image, ImageDraw

SRC = r"E:\projects\taptap\ember_oath\art\maps\ch1_bg.png"
OUT = r"E:\projects\taptap\ember_oath\tools\shots"
TILE = 64
S = 2

jobs = [
    ("v4_bridge.png", (280, 270, 500, 430), [(5, 4), (5, 5), (6, 5), (5, 6)]),
    ("v4_house_d.png", (660, 84, 900, 330), [(11, 1), (11, 2), (12, 2), (11, 3), (12, 3), (13, 3)]),
    ("v4_well_zone.png", (400, 40, 620, 240), [(7, 1), (8, 1), (8, 2), (7, 2), (9, 1)]),
    ("v4_sw_grass.png", (0, 400, 340, 640), [(2, 7), (3, 8)]),
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