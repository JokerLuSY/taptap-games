# -*- coding: utf-8 -*-
"""放大 raw_crop.png（补丁前底图），叠加 64px 红色网格 + 逻辑地标高亮，精确定位彩绘物"""
from PIL import Image, ImageDraw

SRC = r"E:\projects\taptap\ember_oath\tools\shots\raw_crop.png"
OUT = r"E:\projects\taptap\ember_oath\tools\shots"
TILE = 64
S = 2

# (label, box(x0,y0,x1,y1), [(tile_x,tile_y), ...高亮逻辑地标])
jobs = [
    ("raw_house_a.png", (144, 0, 320, 192), [(3, 1)]),
    ("raw_house_b.png", (512, 0, 704, 192), [(9, 1), (8, 1)]),
    ("raw_house_c.png", (0, 144, 192, 320), [(1, 3)]),
    ("raw_house_d.png", (704, 128, 896, 320), [(12, 3), (11, 1), (12, 1), (13, 1), (11, 2), (12, 2), (13, 2)]),
    ("raw_well.png", (440, 0, 600, 192), [(8, 1)]),
    ("raw_field.png", (64, 64, 320, 256), [(2, 2), (3, 2)]),
    ("raw_sand_w.png", (0, 192, 128, 384), [(0, 4)]),
    ("raw_sand_e.png", (832, 320, 960, 512), [(14, 6)]),
    ("raw_mount_w.png", (64, 384, 256, 576), [(2, 7)]),
    ("raw_mount_e.png", (576, 384, 768, 576), [(10, 7)]),
    ("raw_bridge.png", (320, 256, 640, 450), [(7, 5)]),
    ("raw_stray_well.png", (320, 176, 560, 320), [(6, 3), (7, 3), (6, 4), (7, 4)]),
    ("raw_south_full.png", (0, 448, 960, 640), [(2, 7), (10, 7)]),
]

img = Image.open(SRC).convert("RGB")
for name, box, marks in jobs:
    crop = img.crop(box)
    over = Image.new("RGBA", crop.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(over)
    # 64px 网格（对齐全图坐标）
    gx0 = -(box[0] % TILE)
    for x in range(gx0, crop.width + TILE, TILE):
        d.line([(x, 0), (x, crop.height)], fill=(255, 40, 40, 170), width=1)
    gy0 = -(box[1] % TILE)
    for y in range(gy0, crop.height + TILE, TILE):
        d.line([(0, y), (crop.width, y)], fill=(255, 40, 40, 170), width=1)
    # 逻辑地标半透明红框
    for tx, ty in marks:
        x0 = tx * TILE - box[0]
        y0 = ty * TILE - box[1]
        if -TILE < x0 < crop.width and -TILE < y0 < crop.height:
            d.rectangle([x0, y0, x0 + TILE, y0 + TILE], outline=(255, 0, 255, 220), width=3)
            d.text((x0 + 4, y0 + 4), "(%d,%d)" % (tx, ty), fill=(255, 0, 255, 255))
    crop = Image.alpha_composite(crop.convert("RGBA"), over)
    crop = crop.resize((crop.width * S, crop.height * S), Image.NEAREST)
    crop.save(OUT + "\\" + name)
    print("saved", name, box)