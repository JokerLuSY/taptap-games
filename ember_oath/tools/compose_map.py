# -*- coding: utf-8 -*-
"""把 AI 生成的地图 (4:3) 裁剪对齐到 960x640 (v4.2)

原则（网格向手绘对齐 + 物件全交给运行时精灵）:
- 保留手绘: 道路(第5列)/木桥(5,5)/河流两岸/高地麦田与崖壁/森林带/北缘石墙/沙滩
- 抹除彩绘物件(运行时会画精灵): 4座房/2口井/木平台/房旁麦田/灰金字塔/南部岩丘/桥墩深影
- 补丁一律"整块连贯复制"(源=同横带干净草地), 避免小样块平铺的方块接缝;
  源区人工核实过干净, 或取自更早补丁已清好的区域
用法: python ember_oath/tools/compose_map.py
"""
import os

from PIL import Image, ImageDraw, ImageFilter

SRC = r"C:\Users\lushe\.cursor\projects\e-projects-taptap\assets\ch1_map_b.jpg"
DST_DIR = r"E:\projects\taptap\ember_oath\art\maps"
os.makedirs(DST_DIR, exist_ok=True)

TARGET_W, TARGET_H = 960, 640
RIVER_TARGET_TOP = 320

img = Image.open(SRC).convert("RGB")
img = img.resize((960, 720), Image.LANCZOS)


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
crop = img.crop((0, off_y, TARGET_W, off_y + TARGET_H))
print("river_center:", cy, "crop offset:", off_y)


def _feather_mask(w, h, feather):
    mask = Image.new("L", (w, h), 0)
    md = ImageDraw.Draw(mask)
    md.rectangle([feather, feather, w - feather, h - feather], fill=255)
    return mask.filter(ImageFilter.GaussianBlur(feather / 2))


def block(dst, box, src_box, feather=12):
    """整块连贯复制: src_box(与 box 同尺寸) -> box, 边界羽化"""
    x0, y0, x1, y1 = box
    sx0, sy0, sx1, sy1 = src_box
    patch = dst.crop(src_box)
    assert (x1 - x0, y1 - y0) == (sx1 - sx0, sy1 - sy0), "size mismatch %s vs %s" % (box, src_box)
    dst.paste(patch, (x0, y0), _feather_mask(x1 - x0, y1 - y0, feather))


def shift(dst, box, dx, feather=10):
    """同横带平移复制 (保手绘明暗走向)"""
    x0, y0, x1, y1 = box
    block(dst, box, (x0 + dx, y0, x1 + dx, y1), feather)


def tile(dst, box, samples, feather=12, step=56, seed=42):
    """多样块平铺 (仅用于森林冠层等高方差纹理)"""
    import random
    x0, y0, x1, y1 = box
    w, h = x1 - x0, y1 - y0
    layer = Image.new("RGB", (w, h))
    rnd = random.Random(seed)
    yy = 0
    while yy < h:
        xx = 0
        while xx < w:
            layer.paste(rnd.choice(samples), (xx, yy))
            xx += step
        yy += step
    dst.paste(layer, (x0, y0), _feather_mask(w, h, feather))


# ---- 采样 (打补丁前取; 均为人工核实过的干净区域) ----
forest_s = [
    crop.crop((0, 0, 64, 64)),
    crop.crop((300, 0, 364, 64)),
    crop.crop((364, 0, 428, 64)),
    crop.crop((700, 0, 764, 64)),
    crop.crop((764, 0, 828, 64)),
]
# 高地麦田: 取地块内部 (石梯田墙在 x776-792 与 x826-853, 房D y130 起, 均避开)
wheat_s = [
    crop.crop((700, 64, 764, 128)),   # 地块A内部
    crop.crop((796, 64, 824, 128)),   # 地块B内部(窄)
    crop.crop((706, 64, 758, 128)),   # 地块A内部2
]

# =========== 1. 北部物件 (源=南部干净草地整块) ===========
# 房A+木平台 (房A x160-260 y2-128, 平台 x62-282 y50-188)
block(crop, (56, 0, 292, 196), (386, 426, 622, 622))
# 房B+房旁麦田 (房 x540-696 y4-128, 麦 x550-688 y70-240)
block(crop, (524, 0, 712, 258), (388, 382, 576, 640))
# 房C (x20-168 y140-258) —— 源取同邻域干净草地(花色/明暗一致, 无接缝)
block(crop, (12, 132, 176, 266), (152, 196, 316, 330))
# 路东井 (7,1)-(7,2) 锥顶+支架+灰台 (x394-536 y56-206, 含西侧框腿与南侧影)
block(crop, (394, 50, 540, 210), (386, 460, 532, 620))
# 孤儿井 (6,3) (x384-448 y192-256, 含左侧影) —— 源取自刚补好的房B区
block(crop, (384, 176, 464, 270), (576, 176, 656, 270), 10)
# 中北散树丛 (x576-670 y208-288)
block(crop, (576, 206, 672, 290), (386, 470, 482, 554), 10)
# 高台脚散树 (x734-816 y232-292)
block(crop, (732, 230, 818, 294), (392, 470, 478, 534), 10)

# =========== 2. 房D (x700-798 y104-262, 根在(11,3), 顶戳进(11,2)麦田) ===========
# 石梯田墙 (x776-792 / x826-853) 是合法景观, 保留; 只清房子本体
tile(crop, (693, 104, 800, 130), wheat_s, 6, 48)                # (11,1) 底条
tile(crop, (693, 130, 800, 196), wheat_s, 6, 48)                # (11,2) 麦田
block(crop, (693, 196, 810, 268), (386, 462, 503, 534), 10)     # (11,3) 主体+基座 -> 草

# =========== 3. 南部大清理 (岩丘/金字塔/散树, 全在可行走草地) ===========
block(crop, (40, 426, 160, 640), (386, 426, 506, 640))         # 西 1/2
block(crop, (160, 426, 276, 640), (446, 426, 562, 640))         # 西 2/2
block(crop, (566, 420, 692, 552), (386, 420, 512, 552))         # 东灰金字塔
block(crop, (688, 424, 892, 452), (386, 424, 590, 452), 8)     # 东南过渡条(护住(14,6)沙滩)
block(crop, (688, 452, 820, 640), (386, 452, 518, 640))         # 东南 1/2
block(crop, (820, 452, 960, 640), (428, 452, 568, 640))         # 东南 2/2

# =========== 4. 河面清理 (桥(5,5)东的深色桥墩残影) ===========
block(crop, (382, 318, 470, 384), (470, 318, 558, 384), 4)      # 桥东水域 (窄羽化防灰环)
block(crop, (902, 356, 956, 388), (838, 356, 892, 388), 5)      # 东南角水面条

# =========== 5. 森林带 / 越界收边 ===========
# 北缘森林: 物件抹除后铺回森林(整块连贯复制, 避免平铺接缝); 干净林带源: x292-400 / x700-916
block(crop, (56, 0, 164, 64), (292, 0, 400, 64), 6)
block(crop, (164, 0, 272, 64), (700, 0, 808, 64), 6)
block(crop, (272, 0, 292, 64), (808, 0, 828, 64), 6)
block(crop, (394, 50, 496, 64), (292, 50, 394, 64), 5)          # 井框腿留下的缝
block(crop, (496, 50, 540, 64), (700, 50, 744, 64), 5)
block(crop, (524, 0, 632, 64), (292, 0, 400, 64), 6)            # 房B顶
block(crop, (632, 0, 712, 64), (700, 0, 780, 64), 6)
block(crop, (0, 138, 80, 244), (386, 460, 466, 566), 10)         # 西缘越界森林
block(crop, (894, 126, 960, 182), (386, 470, 452, 526), 10)     # 东北越界森林
shift(crop, (0, 226, 66, 262), 240)                             # 西缘河水侵入

crop.save(os.path.join(DST_DIR, "ch1_bg.png"), optimize=True)
print("saved ch1_bg.png", crop.size)