# -*- coding: utf-8 -*-
"""用颜色聚类检测 raw_crop.png 中彩绘物件的精确 bbox
- 红棕屋顶(房子): 高饱和暖色
- 灰石基座+橙锥顶(井): 灰色方块 / 橙色小锥
- 深灰金字塔(山): 暗灰
- 木平台: 棕色横条纹
- 麦田: 高饱和金黄
输出: 按区域聚类的 bbox 列表 (绝对坐标)
"""
from PIL import Image
import sys

sys.stdout.reconfigure(encoding="utf-8")
SRC = r"E:\projects\taptap\ember_oath\tools\shots\raw_crop.png"
img = Image.open(SRC).convert("RGB")
W, H = img.size
px = img.load()


def cluster(mask_fn, label, min_count=40):
    """扫描全部像素, mask 命中后做连通 bbox 聚类 (网格分块法: 32px 块级聚合)"""
    hits = {}
    for y in range(0, H, 2):
        for x in range(0, W, 2):
            if mask_fn(px[x, y]):
                bx, by = x // 48, y // 48
                hits[(bx, by)] = hits.get((bx, by), 0) + 1
    # 合并相邻块
    blocks = sorted([k for k, v in hits.items() if v >= 3])
    groups = []
    for b in blocks:
        placed = False
        for g in groups:
            if abs(g[-1][0] - b[0]) <= 1 and abs(g[-1][1] - b[1]) <= 1:
                g.append(b)
                placed = True
                break
        if not placed:
            groups.append([b])
    # 再做一轮传递合并
    merged = True
    while merged:
        merged = False
        for i in range(len(groups)):
            for j in range(i + 1, len(groups)):
                gi, gj = set(groups[i]), set(groups[j])
                if any(abs(a[0] - b[0]) <= 1 and abs(a[1] - b[1]) <= 1 for a in gi for b in gj):
                    groups[i] = groups[i] + groups[j]
                    groups.pop(j)
                    merged = True
                    break
            if merged:
                break
    print("== %s ==" % label)
    for g in groups:
        xs = [b[0] for b in g]
        ys = [b[1] for b in g]
        x0, x1 = min(xs) * 48, (max(xs) + 1) * 48
        y0, y1 = min(ys) * 48, (max(ys) + 1) * 48
        cnt = sum(hits.get(b, 0) for b in g)
        if cnt >= min_count:
            print("  bbox=(%d,%d,%d,%d) blocks=%d hits=%d  tiles=(%.1f,%.1f)-(%.1f,%.1f)" % (
                x0, y0, x1, y1, len(g), cnt, x0 / 64, y0 / 64, x1 / 64, y1 / 64))


# 1) 红棕屋顶: r 明显大于 g/b, 中等亮度
def roof(c):
    r, g, b = c
    return r > 95 and r > g + 28 and r > b + 38 and g > b


# 2) 金黄麦田: r,g 高, b 低
def wheat(c):
    r, g, b = c
    return r > 130 and g > 100 and r < 235 and b < g - 45 and g < r + 20


# 3) 深灰岩(金字塔/崖壁): 低饱和暗灰
def darkrock(c):
    r, g, b = c
    mx, mn = max(r, g, b), min(r, g, b)
    return mx - mn < 26 and 52 < mx < 128


# 4) 木板平台: 棕色 (r>g>b, 中亮)
def wood(c):
    r, g, b = c
    return r > 120 and 70 < g < r - 25 and b < g - 22 and r < 210


# 5) 近黑水域残留: 很暗的蓝黑
def blackish(c):
    r, g, b = c
    return max(r, g, b) < 62


cluster(roof, "红棕屋顶(房子/井顶)")
cluster(wheat, "金黄麦田")
cluster(darkrock, "深灰岩(金字塔)")
cluster(wood, "棕木(平台/桥)")
cluster(blackish, "近黑残留")