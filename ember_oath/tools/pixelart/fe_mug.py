"""火纹 GBA 式立绘引擎 v3：96×80 画布，3/4 侧脸朝右。

和 v2（正脸模板）的区别：
  - 脸型由一组轮廓点决定（少女 / 少年 / 成年 / 粗汉 / 老人 / 瘦长），每人可再微调，不再千人一面；
  - 近侧眼大、远侧眼窄，鼻尖和下巴朝脸的方向，耳朵在近侧；
  - 上色按「沿光线探到边缘的距离」分档（边缘光 / 背光边），每一簇头发单独上色，簇与簇之间压暗线，
    外轮廓背光侧用最深色、受光侧用次深色（选择性描边）。
角色数据在 fe_mugs.py。
"""
import math
from PIL import Image
from fe_faces import hx, mix, ramp, poly, ellipse, border

W, H = 96, 80
LIGHT = (0.7, -0.72)            # 光从右上方（脸朝的方向）来


class Canvas:
    def __init__(self):
        self.px = [[None] * W for _ in range(H)]
        self.tag = [[None] * W for _ in range(H)]

    def get(self, x, y):
        if 0 <= x < W and 0 <= y < H:
            return self.px[y][x]
        return None

    def tag_at(self, x, y):
        if 0 <= x < W and 0 <= y < H:
            return self.tag[y][x]
        return None

    def put(self, x, y, c, tag=None):
        x, y = int(x), int(y)
        if 0 <= x < W and 0 <= y < H and c is not None:
            self.px[y][x] = c
            if tag is not None:
                self.tag[y][x] = tag

    def image(self, scale=1):
        img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
        for y in range(H):
            for x in range(W):
                if self.px[y][x] is not None:
                    img.putpixel((x, y), self.px[y][x] + (255,))
        return img.resize((W * scale, H * scale), Image.NEAREST) if scale != 1 else img


# ======================= 几何 =======================

def bez(p0, p1, p2, n=10):
    return [((1 - t) ** 2 * p0[0] + 2 * (1 - t) * t * p1[0] + t * t * p2[0],
             (1 - t) ** 2 * p0[1] + 2 * (1 - t) * t * p1[1] + t * t * p2[1]) for t in [i / n for i in range(n + 1)]]


def lock(a, b, tip, bend=0.0, bend2=None):
    """一绺头发：根部 a→b，尖端 tip；bend 让两侧曲线朝同一方向弯（正 = 往前进方向的左侧）"""
    if bend2 is None:
        bend2 = bend

    def ctrl(p, q, k):
        mx, my = (p[0] + q[0]) / 2, (p[1] + q[1]) / 2
        dx, dy = q[0] - p[0], q[1] - p[1]
        L = math.hypot(dx, dy) or 1
        return (mx - dy / L * k, my + dx / L * k)
    side1 = bez(a, ctrl(a, tip, bend), tip)
    side2 = bez(tip, ctrl(tip, b, -bend2), b)
    return poly(side1 + side2[1:])


def blob(pts):
    """平滑闭合轮廓：把折线点当控制点，用二次贝塞尔连接各边中点"""
    out = []
    n = len(pts)
    for i in range(n):
        p0 = ((pts[i - 1][0] + pts[i][0]) / 2, (pts[i - 1][1] + pts[i][1]) / 2)
        p2 = ((pts[i][0] + pts[(i + 1) % n][0]) / 2, (pts[i][1] + pts[(i + 1) % n][1]) / 2)
        out += bez(p0, pts[i], p2, 6)[:-1]
    return poly(out)


def line(a, b):
    (x0, y0), (x1, y1) = a, b
    n = int(round(max(abs(x1 - x0), abs(y1 - y0), 1)))
    return [(int(round(x0 + (x1 - x0) * t / n)), int(round(y0 + (y1 - y0) * t / n))) for t in range(n + 1)]


def path(pts):
    out = []
    for a, b in zip(pts, pts[1:]):
        out += line(a, b)
    return out


def thick(pts, w=1):
    return {(x + dx, y + dy) for (x, y) in pts for dx in range(-w, w + 1) for dy in range(-w, w + 1) if abs(dx) + abs(dy) <= w}


# ======================= 上色 =======================

def _probe(mask, x, y, d, cap):
    for n in range(1, cap + 1):
        if (int(round(x + d[0] * n)), int(round(y + d[1] * n))) not in mask:
            return n
    return cap + 1


def shade(cv, mask, rp, tag=None, sh=(2, 4), lt=(1, 3), outline=True, keep=None, light=LIGHT):
    """rp = ramp()；sh = (最深档宽, 暗档宽)，lt = (最亮档宽, 亮档宽)：按到背光边 / 受光边的距离分档"""
    if not mask:
        return
    dark_dir = (-light[0], -light[1])
    edge = border(mask) if outline else set()
    for (x, y) in mask:
        if keep is not None and (x, y) not in keep:
            continue
        if (x, y) in edge:
            # 选择性描边：受光侧用次深色
            lit_side = (int(round(x + light[0] * 1.5)), int(round(y + light[1] * 1.5))) not in mask
            cv.put(x, y, rp[4] if lit_side else rp[5], tag)
            continue
        ns = _probe(mask, x, y, dark_dir, 8)
        nl = _probe(mask, x, y, light, 8)
        if ns <= sh[0]:
            k = 4 if ns <= max(1, sh[0] - 1) and sh[0] > 1 else 3
            k = 3 if sh[0] <= 1 else k
        elif ns <= sh[1]:
            k = 3
            if ns == sh[1] and (x + y) % 2:
                k = 2
        elif nl <= lt[0]:
            k = 0
        elif nl <= lt[1]:
            k = 1
            if nl == lt[1] and (x + y) % 2:
                k = 2
        else:
            k = 2
        cv.put(x, y, rp[k], tag)


def clumps(cv, polys, rp, tag="hair", sh=(1, 3), lt=(1, 3), shine=(), inner=4):
    """一组发簇：每簇单独按边缘上色，簇的分界线压暗，最后整体外轮廓描边；shine = 高光像素列表"""
    union = set()
    for m in polys:
        union |= m
    for m in polys:
        shade(cv, m, rp, tag, sh=sh, lt=lt, outline=False)
        for p in border(m):
            if p in union:
                cv.put(p[0], p[1], rp[inner], tag)
    for p in shine:
        if p in union and p not in border(union):
            cv.put(p[0], p[1], rp[0], tag)
    for (x, y) in border(union):
        lit_side = (int(round(x + LIGHT[0] * 1.5)), int(round(y + LIGHT[1] * 1.5))) not in union
        cv.put(x, y, rp[4] if lit_side and False else rp[5], tag)
    return union


def arc(cx, cy, rx, ry, a0, a1, step=4, gap=()):
    """高光弧：角度单位度，0 = 右，90 = 下"""
    out = []
    a = a0
    i = 0
    while (a <= a1) if a1 >= a0 else (a >= a1):
        if i % step not in gap:
            out.append((int(round(cx + rx * math.cos(math.radians(a)))), int(round(cy + ry * math.sin(math.radians(a))))))
        a += 2 if a1 >= a0 else -2
        i += 1
    return out


# ======================= 脸 =======================

# 脸型（朝右 3/4 侧脸，远侧是侧面轮廓：眉骨 → 眼窝 → 鼻尖 → 人中 → 嘴唇 → 下巴）
#   tl/cl/jl  近侧太阳穴 / 颊 / 下颌角      ch = (下巴底中点 x, y, 平宽)
#   fx 远侧眼窝的 x；ey 眼睛上沿 y；ny 鼻尖 y；my 嘴 y；nl 鼻尖伸出量；cf 下巴前伸量
SHAPES = {
    "girl":  dict(tl=(31, 20), cl=(30, 38), jl=(34, 52), ch=(51, 56, 1), fx=60, ey=31, ny=41, my=46, nl=2, cf=0),
    "boy":   dict(tl=(30, 20), cl=(29, 39), jl=(33, 55), ch=(52, 59, 2), fx=60, ey=32, ny=43, my=49, nl=3, cf=0),
    "man":   dict(sq=1, tl=(30, 19), cl=(29, 39), jl=(33, 53), ch=(52, 61, 4), fx=61, ey=32, ny=44, my=51, nl=3, cf=1),
    "brute": dict(sq=1, tl=(28, 19), cl=(27, 40), jl=(31, 55), ch=(51, 62, 6), fx=62, ey=33, ny=45, my=52, nl=3, cf=2),
    "old":   dict(tl=(31, 19), cl=(30, 41), jl=(34, 59), ch=(51, 63, 2), fx=60, ey=33, ny=45, my=52, nl=4, cf=0),
    "slim":  dict(tl=(31, 19), cl=(30, 40), jl=(35, 57), ch=(52, 61, 1), fx=60, ey=32, ny=44, my=51, nl=3, cf=0),
}

# 眼睛（左 = 近侧大眼，右 = 远侧窄眼；都往右看）：L 眼线  I 虹膜暗  i 虹膜  j 虹膜亮  h 高光  w 眼白  s 眼皮阴影
EYES = {
    "girl": ([
        "...LLLLLL",
        "LLLLIIIIL",
        "..wIIIhIL",
        "..wIiiiIw",
        "...jiiij.",
        "....jjj..",
    ], [
        "LLLLL.",
        "IIIILL",
        "IIhIw.",
        "iiij..",
        "jjj...",
    ]),
    "boy": ([
        ".LLLLLL.",
        "LLIIIIL.",
        ".wIIhIw.",
        "..jiij..",
    ], [
        "LLLL.",
        "IIIL.",
        "Ihiw.",
        "jj...",
    ]),
    "man": ([
        "LLLLLLL.",
        ".wIIhIL.",
        "..jjj...",
    ], [
        "LLLL",
        "IhiL",
        "jj..",
    ]),
    "narrow": ([
        ".LLLLLL.",
        "LLIIhiLL",
        "...jjj..",
    ], [
        "LLLL",
        "IhLL",
        "j...",
    ]),
    "old": ([
        ".ssssss.",
        "LLLLLLL.",
        ".wIhiL..",
        ".sjjjs..",
    ], [
        "ssss",
        "LLLL",
        "IhL.",
        "js..",
    ]),
    "blank": ([
        ".LLLLLL.",
        "LLjjjjL.",
        ".wjjjjw.",
        "..jjjj..",
    ], [
        "LLLL",
        "jjjL",
        "jjw.",
        "j...",
    ]),
}


def face(cv, shape="girl", skin="#f4c8a0", eye="#c06a2a", brow="#5a3a22", eyes=None, brows=None, mouth="smile",
         blush=False, wrinkles=False, scar=False, tweak=None, ear=True, lash=None):
    """画脖子 + 耳朵 + 脸 + 五官；返回关键位置（供胡子、伤疤等）"""
    sp = dict(SHAPES[shape])
    if tweak:
        sp.update(tweak)
    sk = ramp(skin)
    sk[5] = mix(sk[4], (60, 20, 20), 0.45)
    jl, (chx, chy, chw) = sp["jl"], sp["ch"]
    fx, ey, ny, my, nl, cf = sp["fx"], sp["ey"], sp["ny"], sp["my"], sp["nl"], sp["cf"]
    # 脖子：窄、短，下巴底下一道阴影
    neck = poly([(jl[0] + 6, jl[1] - 3), (chx + chw + 3, chy - 4), (chx + chw + 2, 72), (jl[0] + 5, 72)])
    shade(cv, neck, sk, "skin", sh=(1, 3), lt=(1, 2))
    for (x, y) in neck:
        if y <= chy + 2 and (x, y) not in border(neck):
            cv.put(x, y, sk[4] if y <= chy else sk[3], "skin")
    # 耳朵
    cl = sp["cl"]
    if ear:
        e = blob([(cl[0] - 3, cl[1] - 9), (cl[0] + 3, cl[1] - 9), (cl[0] + 3, cl[1] + 2), (cl[0] - 1, cl[1] + 3), (cl[0] - 4, cl[1] - 3)])
        shade(cv, e, sk, "skin", sh=(1, 3), lt=(1, 1))
        for p in line((cl[0] - 1, cl[1] - 6), (cl[0], cl[1] - 1)):
            cv.put(p[0], p[1], sk[4], "skin")
    # 脸轮廓
    tl = sp["tl"]
    if sp.get("sq"):      # 方下颌：下颌角是个角
        jaw = [((cl[0] + jl[0]) / 2 - 0.3, (cl[1] + jl[1]) / 2), jl, (chx - chw - 2, chy - 1.2), (chx - chw, chy)]
    else:                 # 圆下颌：颊 → 下巴一条弧
        jaw = bez(cl, jl, (chx - chw, chy), 10)[1:]
    pts = [tl, ((tl[0] + cl[0]) / 2 - 0.8, (tl[1] + cl[1]) / 2), cl] + jaw + [(chx + chw, chy),
           (fx - 3 + cf, chy - 2), (fx - 2 + cf, my + 4), (fx - 1, my + 2), (fx, my), (fx - 1, my - 1), (fx - 1, ny + 2),
           (fx + nl, ny), (fx + 1, ny - 5), (fx, ey + 3), (fx + 1, ey - 2), (fx + 1, ey - 6), (fx - 1, tl[1] - 1), (46, tl[1] - 5)]
    m = poly(pts)
    shade(cv, m, sk, "skin", sh=(2, 6), lt=(1, 3))
    # 眼
    kind = eyes or {"girl": "girl", "boy": "boy", "slim": "boy"}.get(shape, "man")
    near, far = EYES[kind]
    ir = ramp(eye)
    lc = lash or mix(hx(brow), (20, 10, 20), 0.6)
    pal = {"L": lc, "I": ir[4], "i": ir[2], "j": ir[1], "h": (255, 255, 250), "w": (236, 236, 244), "s": sk[3], "l": ir[3]}
    nx = fx - 22
    fex = fx - len(far[0]) - 1
    for rows, ox in ((near, nx), (far, fex)):
        for dy, row in enumerate(rows):
            for dx, ch in enumerate(row):
                if ch != ".":
                    cv.put(ox + dx, ey + dy, pal[ch], "eye")
    # 眼窝：两眼之间（鼻梁根）一点阴影
    cv.put(nx + 9, ey + 1, sk[3], "skin")
    # 眉
    bc = ramp(brow)
    bk = brows or ("soft" if kind == "girl" else "firm")
    by = ey - 3
    W_ = {"soft": 0, "firm": 1, "angry": 1, "worried": 0, "thick": 2}[bk]
    nb = {"soft": [(nx, by + 1), (nx + 3, by - 1), (nx + 8, by)],
          "firm": [(nx - 1, by + 1), (nx + 3, by), (nx + 8, by)],
          "angry": [(nx - 1, by - 1), (nx + 4, by), (nx + 8, by + 2)],
          "worried": [(nx, by + 1), (nx + 5, by), (nx + 8, by - 2)],
          "thick": [(nx - 1, by), (nx + 4, by - 1), (nx + 8, by)]}[bk]
    fb_ = {"angry": [(fex, by + 2), (fx, by - 1)], "worried": [(fex, by - 1), (fx, by + 1)]}.get(bk, [(fex, by), (fx, by - 1)])
    for pts_, ww in ((nb, W_), (fb_, max(0, W_ - 1))):
        for p in path(pts_):
            cv.put(p[0], p[1], bc[4], "brow")
            if ww >= 1:
                cv.put(p[0], p[1] + 1, bc[3] if ww == 1 else bc[4], "brow")
            if ww >= 2:
                cv.put(p[0], p[1] - 1, bc[3], "brow")
    # 鼻：近侧鼻翼一道阴影 + 鼻孔
    for p in line((fx - 3, ny - 4), (fx - 3, ny - 1)):
        cv.put(p[0], p[1], sk[3], "skin")
    cv.put(fx - 2, ny + 1, sk[4], "skin")
    cv.put(fx - 3, ny, sk[3], "skin")
    # 嘴（贴着远侧轮廓）
    mx = fx - 7
    lip = mix(sk[3], (210, 70, 80), 0.4)
    if mouth == "smile":
        for p in [(mx, my - 1), (mx + 1, my), (mx + 2, my), (mx + 3, my), (mx + 4, my), (mx + 5, my)]:
            cv.put(p[0], p[1], sk[5], "mouth")
        cv.put(mx + 3, my + 1, lip, "mouth")
        cv.put(mx + 4, my + 1, lip, "mouth")
    elif mouth == "grin":
        for x in range(mx, mx + 6):
            cv.put(x, my, sk[5], "mouth")
            cv.put(x, my + 1, (250, 248, 240) if mx < x else sk[5], "mouth")
        for x in range(mx + 1, mx + 6):
            cv.put(x, my + 2, sk[5], "mouth")
        cv.put(mx - 1, my - 1, sk[5], "mouth")
    elif mouth == "open":
        for x in range(mx + 1, mx + 6):
            cv.put(x, my, sk[5], "mouth")
            cv.put(x, my + 1, (120, 40, 50), "mouth")
        for x in range(mx + 2, mx + 5):
            cv.put(x, my + 2, sk[5], "mouth")
    elif mouth == "frown":
        for p in [(mx, my + 1), (mx + 1, my), (mx + 2, my), (mx + 3, my), (mx + 4, my), (mx + 5, my)]:
            cv.put(p[0], p[1], sk[5], "mouth")
        cv.put(mx + 3, my + 2, sk[3], "mouth")
    elif mouth == "smirk":
        for p in [(mx, my), (mx + 1, my), (mx + 2, my), (mx + 3, my), (mx + 4, my - 1), (mx + 5, my - 1)]:
            cv.put(p[0], p[1], sk[5], "mouth")
    else:  # neutral
        for x in range(mx + 1, mx + 6):
            cv.put(x, my, sk[5], "mouth")
        cv.put(mx + 3, my + 1, sk[3], "mouth")
    # 下唇下面一点阴影
    cv.put(mx + 3, my + 3, sk[3], "skin")
    if blush:
        rc = mix(sk[1], (240, 110, 110), 0.5)
        for (x, y) in ((nx + 1, ey + 7), (nx + 3, ey + 7), (nx + 5, ey + 7), (nx + 2, ey + 8), (nx + 4, ey + 8), (fex + 1, ey + 7), (fex + 3, ey + 7)):
            cv.put(x, y, rc, "skin")
    if wrinkles:
        for p in line((fx - 6, ny + 1), (mx - 1, my + 2)):
            cv.put(p[0], p[1], sk[3], "skin")
        cv.put(nx - 1, ey + 3, sk[3], "skin")
        cv.put(nx - 2, ey + 4, sk[3], "skin")
        for x in range(nx + 1, nx + 7):
            cv.put(x, by - 3, sk[3], "skin")
        for p in line((nx + 2, ey + 5), (nx + 6, ey + 6)):
            cv.put(p[0], p[1], sk[3], "skin")
    if scar:
        for p in line((nx + 2, ey - 4), (nx + 6, ey + 10)):
            cv.put(p[0], p[1], (176, 70, 70), "skin")
    return dict(mask=m, sp=sp, sk=sk, eye_y=ey, nx=nx, fx=fx, mouth=(mx, my), nose=(fx + nl, ny))


def hair_shadow(cv, sk, depth=2):
    """头发在额头上投下的阴影：皮肤像素正上方 depth 格内有头发 → 压暗"""
    for y in range(H - 1, -1, -1):
        for x in range(W):
            if cv.tag_at(x, y) == "skin" and any(cv.tag_at(x - 1, y - k) == "hair" or cv.tag_at(x, y - k) == "hair" for k in range(1, depth + 1)):
                cv.put(x, y, sk[3], "skin_s")


# ======================= 身体 =======================

def torso(top=64, near=(4, 80), far=(90, 80), neck=(40, 56)):
    """3/4 身体：近侧（左）肩膀宽且低，远侧（右）肩膀窄"""
    return poly([(neck[0] - 2, top), (neck[1] + 2, top), (neck[1] + 14, top + 2), (far[0] - 6, top + 8), far,
                 near, (near[0] + 4, top + 8), (neck[0] - 16, top + 2)])


def preview(imgs, path_, scale=3, cols=6):
    keys = list(imgs)
    rows = (len(keys) + cols - 1) // cols
    sheet = Image.new("RGBA", (cols * (W * scale + 8) + 8, rows * (H * scale + 8) + 8), (28, 30, 52, 255))
    for i, k in enumerate(keys):
        x = 8 + (i % cols) * (W * scale + 8)
        y = 8 + (i // cols) * (H * scale + 8)
        sheet.alpha_composite(imgs[k].resize((W * scale, H * scale), Image.NEAREST), (x, y))
    sheet.save(path_)


# ======================= 手绘工具 =======================

def stamp(cv, ox, oy, rows, pal, tag=None):
    """字符网格按调色板贴到画布；'.' 和空格跳过"""
    for dy, row in enumerate(rows):
        for dx, ch in enumerate(row):
            if ch not in ". ":
                cv.put(ox + dx, oy + dy, pal[ch], tag)


def skin_rows(cv, ox, oy, table, sk, shadow=None, lit=None, tag="skin"):
    """按手写的逐行轮廓表上皮肤：table = {行: (左列, 右列)}；左侧（背光）几列压暗，右侧（受光）一列提亮；
    shadow / lit = {行: 宽度} 覆盖默认宽度"""
    rows = sorted(table)
    for r in rows:
        L, R = table[r]
        for c in range(L, R + 1):
            k = 2
            sw = (shadow or {}).get(r, 1 if r < rows[0] + 14 else 2)
            lw = (lit or {}).get(r, 1)
            if c == L or c == R:
                k = 5
            elif c <= L + sw:
                k = 3
            elif c >= R - lw:
                k = 1
            cv.put(ox + c, oy + r, sk[k], tag)
    # 下颌底边：每列最低的皮肤像素上一格压暗
    for r in rows:
        L, R = table[r]
        for c in range(L + 1, R):
            below = table.get(r + 1)
            if below is None or not (below[0] < c < below[1]):
                if r - 1 in table:
                    cv.put(ox + c, oy + r - 1, sk[3], tag)
                cv.put(ox + c, oy + r, sk[5], tag)
