# -*- coding: utf-8 -*-
"""AI 白底精灵 → 透明 PNG (v2: 二值抠白 + 1px 腐蚀 + 底部裁切)
旧版的 alpha=白度差×5 会把精灵自带的浅灰软阴影变成半透明白晕(白台/白圈), 全部改掉:
  - 二值抠白: min(RGB) >= 232 才透明, 其余全不透明 → 灰阴影保持实体(看起来是正常阴影)
  - 1px alpha 腐蚀: 杀掉轮廓上的白边
  - bottom_cut: 裁掉底部残留的台座/阴影
  - alpha 通道 bbox 裁剪
"""
import os

from PIL import Image

SRC = r"C:\Users\lushe\.cursor\projects\e-projects-taptap\assets"
DST = r"E:\projects\taptap\ember_oath\art\sprites"
os.makedirs(DST, exist_ok=True)

# (源文件, 输出名, 目标宽 px, 底部裁切比例)
JOBS = [
    ("spr_house2.jpg", "house.png", 78, 0.03),
    ("spr_trees.jpg", "trees.png", 70, 0.0),
    ("spr_pine.jpg", "pine.png", 58, 0.0),
    ("spr_well_v2.jpg", "well.png", 54, 0.02),
    ("spr_mountain2.jpg", "mountain.png", 66, 0.02),
]

WHITE = 232


def key_white(img):
    img = img.convert("RGB")
    out = Image.new("RGBA", img.size)
    px, po = img.load(), out.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = px[x, y]
            if min(r, g, b) >= WHITE:
                po[x, y] = (0, 0, 0, 0)
            elif min(r, g, b) >= 205 and max(r, g, b) - min(r, g, b) < 22:
                # 近白中性色 = 画在白底上的浅灰软阴影/底座晕, 一并抠掉(运行时有落地阴影)
                po[x, y] = (0, 0, 0, 0)
            else:
                po[x, y] = (r, g, b, 255)
    return out


def erode_edge(img):
    """1px alpha 腐蚀: 去掉贴边白 fringe"""
    w, h = img.size
    px = img.load()
    solid = [[px[x, y][3] > 0 for x in range(w)] for y in range(h)]
    for y in range(h):
        for x in range(w):
            if solid[y][x]:
                beside_trans = (
                    x == 0 or y == 0 or x == w - 1 or y == h - 1
                    or not solid[y][x - 1] or not solid[y][x + 1]
                    or not solid[y - 1][x] or not solid[y + 1][x]
                )
                if beside_trans:
                    px[x, y] = (0, 0, 0, 0)
    return img


def clean_fringe(img):
    """缩放后净化: 半透明白边→全透; 较实边缘→固化(像素艺术硬边); 最外暗色重采样残→全透"""
    px = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if 0 < a < 255:
                if min(r, g, b) > 185 or a < 140:
                    px[x, y] = (0, 0, 0, 0)
                else:
                    px[x, y] = (r, g, b, 255)
    return img


def contact_shade(img, rows_n=2, factor=0.55):
    """底部接触暗边: 最底 rows_n 行不透明像素压暗, 消除贴地亮线并增加落地感"""
    px = img.load()
    for y in range(img.height - rows_n, img.height):
        for x in range(img.width):
            r, g, b, a = px[x, y]
            if a > 0:
                px[x, y] = (int(r * factor), int(g * factor), int(b * factor), a)
    return img


for src_name, out_name, target_w, bottom_cut in JOBS:
    img = Image.open(os.path.join(SRC, src_name))
    img = key_white(img)
    img = erode_edge(img)
    if bottom_cut > 0:
        w, h = img.size
        img = img.crop((0, 0, w, int(h * (1 - bottom_cut))))
    bbox = img.split()[3].getbbox()
    if bbox:
        img = img.crop(bbox)
    ratio = target_w / img.width
    img = img.resize((target_w, max(1, int(img.height * ratio))), Image.LANCZOS)
    img = clean_fringe(img)
    img = contact_shade(img)
    img.save(os.path.join(DST, out_name), optimize=True)
    print("saved", out_name, img.size)
print("DONE")