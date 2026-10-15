# -*- coding: utf-8 -*-
"""高台区大图 + 西北村庄区大图，带网格，确认崖面行位置"""
from PIL import Image, ImageDraw

SRC = r"E:\projects\taptap\ember_oath\tools\shots\raw_crop.png"
OUT = r"E:\projects\taptap\ember_oath\tools\shots"
TILE = 64
S = 2

jobs = [
    ("raw_highland_full.png", (688, 24, 960, 280), [(11, 1), (12, 1), (13, 1), (11, 2), (12, 2), (13, 2), (12, 3), (13, 3)]),
    ("raw_village_nw.png", (0, 0, 340, 280), [(1, 2), (2, 2), (3, 2), (3, 1), (1, 3)]),
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
            d.text((x0 + 4, y0 + 4), "(%d,%d)" % (tx, ty), fill=(255, 0, 255, 255))
    crop = Image.alpha_composite(crop.convert("RGBA"), over)
    crop = crop.resize((crop.width * S, crop.height * S), Image.NEAREST)
    crop.save(OUT + "\\" + name)
    print("saved", name, box)