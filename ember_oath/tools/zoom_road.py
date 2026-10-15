# -*- coding: utf-8 -*-
"""道路带全景：确认彩绘道路/桥的真实列位置"""
from PIL import Image, ImageDraw

SRC = r"E:\projects\taptap\ember_oath\tools\shots\raw_crop.png"
OUT = r"E:\projects\taptap\ember_oath\tools\shots"
TILE = 64
S = 2

img = Image.open(SRC).convert("RGB")

# 道路带：列 4-9（x256-640），全高，带网格
box = (256, 0, 640, 640)
marks = [(5, 1), (5, 2), (5, 3), (5, 4), (5, 5), (5, 6),
         (7, 1), (7, 2), (7, 3), (7, 4), (7, 5), (7, 6), (7, 7)]
crop = img.crop(box)
over = Image.new("RGBA", crop.size, (0, 0, 0, 0))
d = ImageDraw.Draw(over)
gx0 = -(box[0] % TILE)
for x in range(gx0, crop.width + TILE, TILE):
    d.line([(x, 0), (x, crop.height)], fill=(255, 40, 40, 160), width=1)
for y in range(0, crop.height + TILE, TILE):
    d.line([(0, y), (crop.width, y)], fill=(255, 40, 40, 160), width=1)
for tx, ty in marks:
    x0 = tx * TILE - box[0]
    y0 = ty * TILE - box[1]
    d.rectangle([x0, y0, x0 + TILE, y0 + TILE], outline=(255, 0, 255, 190), width=2)
    d.text((x0 + 3, y0 + 3), "(%d,%d)" % (tx, ty), fill=(255, 0, 255, 255))
crop = Image.alpha_composite(crop.convert("RGBA"), over)
crop = crop.resize((crop.width * S // 2, crop.height * S // 2), Image.NEAREST)  # 1x 宽度防超限
crop.save(OUT + "\\raw_road_strip.png")
print("saved raw_road_strip.png", crop.size)