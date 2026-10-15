# -*- coding: utf-8 -*-
"""把 AI 生成的地形纹理处理成游戏可用的 64px 图块 + 旋转变体 + 调色衍生品"""
import os

from PIL import Image, ImageOps

SRC = r"C:\Users\lushe\.cursor\projects\e-projects-taptap\assets"
DST = r"E:\projects\taptap\ember_oath\art\terrain"
os.makedirs(DST, exist_ok=True)


def load(name):
    return Image.open(os.path.join(SRC, name)).convert("RGB").resize((64, 64), Image.LANCZOS)


def tint(img, rm, gm, bm):
    r, g, b = img.split()
    r = r.point(lambda v: min(255, int(v * rm)))
    g = g.point(lambda v: min(255, int(v * gm)))
    b = b.point(lambda v: min(255, int(v * bm)))
    return Image.merge("RGB", (r, g, b))


def save_variants(img, base):
    rots = [img, img.transpose(Image.ROTATE_90), img.transpose(Image.ROTATE_180), img.transpose(Image.ROTATE_270)]
    for i, im in enumerate(rots):
        im.save(os.path.join(DST, "%s_%d.png" % (base, i)), optimize=True)
    print("saved", base, "x4")


save_variants(load("tex_grass.jpg"), "grass")
save_variants(tint(load("tex_grass.jpg"), 1.14, 1.02, 0.66), "hill")     # 高地: 偏黄干草
save_variants(load("tex_water.jpg"), "water")
save_variants(load("tex_sand.jpg"), "sand")
save_variants(load("tex_dirt.jpg"), "dirt")
save_variants(load("tex_forest.jpg"), "forest")
save_variants(load("tex_cliff.jpg"), "rock")
save_variants(tint(ImageOps.grayscale(load("tex_cliff.jpg")).convert("RGB"), 1.0, 0.98, 0.95), "mount")
print("DONE")
