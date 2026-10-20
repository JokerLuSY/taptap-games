"""角色立绘数据（v3，3/4 侧脸）。用法：python fe_mugs.py <输出目录> [预览.png] [只画的key,逗号分隔]"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fe_mug import (Canvas, ramp, mix, hx, poly, ellipse, border, blob, lock, line, path, thick, shade, clumps, arc, face,
                    hair_shadow, torso, preview, stamp, skin_rows, bez)


def tia(cv):
    OX, OY = 18, 4                       # 头部网格原点（下面坐标都是网格坐标）

    def g(pts):
        return [(x + OX, y + OY) for (x, y) in pts]

    def gl(a, b, tip, bend=0.0):
        return lock((a[0] + OX, a[1] + OY), (b[0] + OX, b[1] + OY), (tip[0] + OX, tip[1] + OY), bend)

    hair = ramp("#d8402e")
    sk = ramp("#f8d4b0")
    sk[5] = (150, 74, 60)
    # —— 马尾 + 后脑（最底层）——
    tail = gl((-4, 2), (14, 14), (-8, 66), -12)
    clumps(cv, [tail, gl((-6, 8), (6, 20), (-13, 56), -8)], hair, inner=3,
           shine=g(arc(-4, 34, 9, 24, 180, 205) + arc(-3, 34, 9, 24, 180, 205)))
    for pts in ([(2, 10), (-2, 24), (-6, 40), (-8, 56)], [(7, 12), (3, 28), (-1, 44)]):
        for p_ in path(g(pts)):
            if p_ in tail and cv.get(*p_) != hair[5]:
                cv.put(p_[0], p_[1], hair[3], "hair")
    clumps(cv, [blob(g([(2, 30), (1, 10), (8, 1), (20, -3), (32, -3), (42, 2), (48, 12), (48, 24), (40, 20), (8, 34)]))], hair)
    # —— 身体 ——
    shirt = ramp("#c83a2e")
    shade(cv, poly([(36, 58), (52, 58), (66, 62), (80, 68), (90, 80), (2, 80), (8, 70), (22, 62)]), shirt, "cloth", sh=(2, 5), lt=(1, 3))
    vest = ramp("#8a5a34")
    shade(cv, poly([(2, 80), (8, 70), (20, 63), (34, 62), (40, 80)]), vest, "cloth", sh=(1, 3), lt=(1, 2))
    shade(cv, poly([(56, 62), (70, 64), (82, 70), (88, 80), (58, 80)]), vest, "cloth", sh=(1, 3), lt=(1, 2))
    shade(cv, thick(line((22, 63), (56, 80)), 1), ramp("#5a3a24"), "cloth", sh=(1, 1), lt=(0, 0))
    # 脖子
    neck = {r: (20, 31) for r in range(44, 60)}
    skin_rows(cv, OX, OY, neck, sk, shadow={r: 3 for r in range(44, 60)})
    for r in range(44, 52):
        for c in range(21, 31):
            cv.put(OX + c, OY + r, sk[4] if r <= 49 else sk[3], "skin")
    # 白衣领
    shade(cv, poly(g([(17, 55), (34, 55), (31, 61), (26, 64), (21, 61)])), ramp("#f0eadc"), "cloth", sh=(1, 2), lt=(1, 1))
    steel = ramp("#b8c0cc")
    plate = poly(bez((0, 66), (12, 56), (32, 60), 10) + [(33, 64), (28, 70)] + bez((22, 74), (10, 72), (0, 78), 8))
    shade(cv, plate, steel, "metal", sh=(2, 4), lt=(1, 3))
    for p_ in bez((3, 66), (13, 58), (30, 62), 12):
        cv.put(int(p_[0]), int(p_[1]) + 1, steel[0], "metal")
    for p_ in bez((2, 72), (12, 66), (28, 68), 12):
        cv.put(int(p_[0]), int(p_[1]), steel[4], "metal")
    for x_ in (8, 16, 24):
        cv.put(x_, 70 - (x_ // 8), steel[0], "metal")
    # —— 脸：逐行轮廓（行: 左列, 右列）——
    T = {16: (10, 39), 17: (9, 40), 18: (9, 40), 19: (8, 40), 20: (8, 40), 21: (8, 40), 22: (8, 40), 23: (8, 40), 24: (8, 40),
         25: (8, 40), 26: (8, 39), 27: (8, 39), 28: (8, 39), 29: (8, 39), 30: (8, 40), 31: (8, 40), 32: (9, 41), 33: (9, 41),
         34: (9, 42), 35: (10, 42), 36: (10, 41), 37: (11, 39), 38: (11, 39), 39: (12, 40), 40: (13, 39), 41: (14, 39),
         42: (15, 38), 43: (17, 38), 44: (18, 37), 45: (20, 36), 46: (22, 35), 47: (25, 33), 48: (28, 31)}
    skin_rows(cv, OX, OY, T, sk, lit={r: 2 for r in range(16, 34)})
    P = {"L": (58, 22, 30), "I": ramp("#c86a20")[4], "i": ramp("#c86a20")[2], "j": ramp("#e8a040")[1], "W": (255, 255, 250),
         "w": (240, 238, 246), "n": ramp("#a83222")[4], "s": sk[3], "S": sk[4], "f": sk[0], "M": (150, 70, 60),
         "m": (226, 136, 130), "B": (246, 170, 160), "K": sk[5]}
    # 近眼 / 远眼
    stamp(cv, OX + 16, OY + 27, [
        "...LLLLLL",
        "LLLLIIIIL",
        "..wIIIWIL",
        "..wIiiiIw",
        "...jiiij.",
        "....jjj..",
    ], P, "eye")
    stamp(cv, OX + 31, OY + 27, [
        "LLLLL.",
        "IIIILL",
        "IIWIw.",
        "iiij..",
        "jjj...",
    ], P, "eye")
    # 眉（多半被刘海盖住）
    stamp(cv, OX + 16, OY + 23, ["..nnnnn..", ".n.....nn"], P, "brow")
    stamp(cv, OX + 31, OY + 23, ["nnnnn.", ".....n"], P, "brow")
    # 鼻：鼻梁暗线、鼻尖高光、鼻孔
    stamp(cv, OX + 37, OY + 30, ["s....", "s....", ".s...", ".s..f", "..S.."], P)
    # 嘴：小，微笑
    stamp(cv, OX + 32, OY + 39, ["M.....", ".MMMM.", "..mm.."], P, "mouth")
    # 腮红
    stamp(cv, OX + 17, OY + 34, ["B.B.B", ".B.B."], P)
    stamp(cv, OX + 32, OY + 34, ["B.B", ".B."], P)
    f = dict(sk=sk)
    # —— 前发：头顶 + 刘海几绺 + 近侧鬓发 ——
    front = [
        blob(g([(3, 22), (2, 10), (8, 1), (20, -3), (32, -3), (42, 2), (48, 12), (48, 21), (42, 15), (30, 10), (14, 11)])),
        gl((1, 14), (11, 16), (6, 48), -1.5),
        gl((6, 11), (18, 9), (12, 31), -1),
        gl((16, 9), (29, 7), (24, 28), 1.5),
        gl((27, 7), (39, 9), (35, 26), 2.5),
        gl((37, 9), (48, 15), (44, 27), 2),
    ]
    clumps(cv, front, hair, inner=3,
           shine=g(arc(25, 22, 19, 19, 250, 320) + arc(25, 23, 19, 19, 252, 318) + arc(25, 24, 19, 19, 258, 310)))
    for pts in ([(14, 2), (10, 8), (9, 14)], [(24, 0), (21, 6), (20, 10)], [(34, 1), (35, 6), (33, 9)], [(42, 5), (44, 11)]):
        for p_ in path(g(pts)):
            cv.put(p_[0], p_[1], hair[3], "hair")
    hair_shadow(cv, sk)
    shade(cv, ellipse(OX + 4, OY + 5, 2.6, 2.6), ramp("#e8b83a"), "acc", sh=(1, 1), lt=(1, 1))


CAST = {"tia": tia}


def render(fn):
    cv = Canvas()
    fn(cv)
    return cv.image()


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    only = sys.argv[3].split(",") if len(sys.argv) > 3 else list(CAST)
    imgs = {}
    for k in only:
        imgs[k] = render(CAST[k])
        imgs[k].save(os.path.join(out, k + ".png"))
    if len(sys.argv) > 2:
        preview(imgs, sys.argv[2], scale=4 if len(imgs) <= 3 else 3, cols=min(len(imgs), 6))
    print("ok", len(imgs))
