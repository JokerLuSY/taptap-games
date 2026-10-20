"""像素立绘引擎：画布、色阶、脸部底稿（手工逐像素）、发丝、服装形状。角色数据在 fe_portraits.py。

画布 64×64（游戏里 ×2 显示在 128 的立绘框里）。脸部底稿是手画的字符网格：
  .  空    k  皮肤描边   1 2 3 4  皮肤 亮 / 中 / 暗 / 深
  p  睫毛 / 眼线      w  眼白      E  虹膜暗   e  虹膜亮   h  高光
  n  眉毛（取头发最暗色）   o  鼻影   m  嘴线   M  嘴唇   r  腮红
"""
from PIL import Image

S = 64
FACE_X, FACE_Y = 18, 12          # 脸部网格左上角在画布上的位置


def hx(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


def mix(a, b, t):
    return tuple(int(round(a[i] + (b[i] - a[i]) * t)) for i in range(3))


def ramp(base, shift=True):
    """GBA 火纹式色阶：亮部偏暖、暗部偏冷偏紫；返回 [最亮, 亮, 中, 暗, 深, 描边]"""
    b = hx(base) if isinstance(base, str) else base
    warm = (255, 244, 214)
    cool = (40, 26, 70) if shift else (20, 20, 24)
    return [mix(b, warm, 0.55), mix(b, warm, 0.28), b, mix(b, cool, 0.32), mix(b, cool, 0.55), mix(b, (16, 10, 26), 0.78)]


# ======================= 脸部底稿 =======================

def _row(c0, c1, ch="2", w=28):
    s = ["."] * w
    for c in range(c0, c1 + 1):
        s[c] = ch
    s[c0] = "k"
    s[c1] = "k"
    return s


def _face_shape(kind):
    """脸型：每行皮肤的左右列（网格 28 宽）"""
    if kind == "female":
        ext = [(4, 23), (3, 24), (2, 25)] + [(1, 26)] * 14 + [(1, 26), (2, 25), (2, 25), (3, 24), (4, 23), (5, 22), (6, 21), (8, 19), (10, 17)]
    elif kind == "boy":
        ext = [(4, 23), (3, 24), (2, 25)] + [(1, 26)] * 15 + [(2, 25), (2, 25), (3, 24), (4, 23), (5, 22), (6, 21), (8, 19), (10, 17)]
    else:  # male / old：下颌更方
        ext = [(4, 23), (3, 24), (2, 25)] + [(1, 26)] * 16 + [(1, 26), (2, 25), (3, 24), (4, 23), (5, 22), (7, 20), (9, 18)]
    return ext


EYES = {
    # (左眼, 右眼)，7 宽；光从左上来，高光都在虹膜左上
    "female": (["pppppp.", "pwhEEEp", ".wEEEEw", ".wEeeEw", "..eeee.", "......."],
               [".pppppp", "phEEEwp", "wEEEEw.", "wEeeEw.", ".eeee..", "......."]),
    "boy": (["pppppp.", "pwhEEEp", ".wEEEEw", "..eeee.", "......."],
            [".pppppp", "phEEEwp", "wEEEEw.", ".eeee..", "......."]),
    "male": (["pppppp.", "pwhEEw.", ".wEeEw.", "..333.."],
             [".pppppp", ".whEEwp", ".wEeEw.", "..333.."]),
    "stern": (["ppppppp", "pwhEEwp", ".wEeEw.", "..333.."],
              ["ppppppp", "pwhEEwp", ".wEeEw.", "..333.."]),
    "old": (["pppppp.", "3whEw3.", ".3333.."],
            [".pppppp", ".3whEw3", "..3333."]),
    "blank": (["pppppp.", "pwEEEEp", ".wEEEEw", ".wEEEEw", "..EEEE.", "......."],
              [".pppppp", "pEEEEwp", "wEEEEw.", "wEEEEw.", ".EEEE..", "......."]),
    "narrow": (["ppppppp", ".whEEw.", "..333.."],
               ["ppppppp", ".whEEw.", "..333.."]),
}

BROWS = {
    "soft": (["..nnnnn", ".nn...."], ["nnnnn..", "....nn."]),
    "firm": (["nnnnnnn", ".......".replace(".", ".")], ["nnnnnnn", "......."]),
    "angry": (["nnn....", "..nnnnn"], ["....nnn", "nnnnn.."]),
    "worried": (["....nnn", "nnnn..."], ["nnn....", "...nnnn"]),
    "thick": (["nnnnnn.", "nnnnnnn"], [".nnnnnn", "nnnnnnn"]),
}

MOUTHS = {
    # 4 宽，画在第 12 列起（脸中线两侧）
    "smile": ["m..m", ".mm."],
    "neutral": [".mm."],
    "smirk": ["...m", ".mm."],
    "frown": [".mm.", "m..m"],
    "open": [".mm.", "mMMm", ".mm."],
    "grin": ["mmmm", ".MM."],
}


def face_grid(kind="female", eyes=None, brows="soft", mouth="smile", blush=False, wrinkles=False, scar=False):
    ext = _face_shape("female" if kind == "female" else ("boy" if kind == "boy" else "male"))
    rows = [_row(a, b) for a, b in ext]
    # 脖子（在下巴后面）
    while len(rows) < 32:
        rows.append(["."] * 28)
    for r in range(20, 32):
        for c in range(10, 18):
            if rows[r][c] == ".":
                rows[r][c] = "k" if c in (10, 17) else ("3" if r < len(ext) + 2 or c >= 15 else "2")
    # 耳朵
    for r in range(10, 16):
        rows[r][0] = "k" if r in (10, 15) else ("2" if r < 13 else "3")
        rows[r][27] = "k" if r in (10, 15) else "3"
    # 明暗：右侧三列暗、下颌暗、左颊高光、额头被刘海压暗
    for r, (a, b) in enumerate(ext):
        for c in range(a + 1, b):
            if c >= b - 3:
                rows[r][c] = "3"
            if c >= b - 1 and r > 4:
                rows[r][c] = "4"
            if r >= len(ext) - 3 and c >= 16 and rows[r][c] == "2":
                rows[r][c] = "3"
            if r <= 3:
                rows[r][c] = "3"
    for r in range(16, 20):
        for c in (3, 4):
            if rows[r][c] == "2":
                rows[r][c] = "1"
    # 眼睛
    ek = eyes or ("female" if kind == "female" else ("boy" if kind == "boy" else "male"))
    le, re = EYES[ek]
    top = 11 if len(le) >= 5 else 12
    for i, line in enumerate(le):
        for j, ch in enumerate(line):
            if ch != ".":
                rows[top + i][4 + j] = ch
    for i, line in enumerate(re):
        for j, ch in enumerate(line):
            if ch != ".":
                rows[top + i][17 + j] = ch
    # 眉毛
    lb, rb = BROWS[brows]
    by = top - 3
    for i, line in enumerate(lb):
        for j, ch in enumerate(line):
            if ch != ".":
                rows[by + i][3 + j] = ch
    for i, line in enumerate(rb):
        for j, ch in enumerate(line):
            if ch != ".":
                rows[by + i][18 + j] = ch
    # 鼻子
    rows[top + 6][14] = "o"
    rows[top + 7][14] = "o"
    rows[top + 7][13] = "1" if rows[top + 7][13] == "2" else rows[top + 7][13]
    # 嘴
    my = top + 10
    for i, line in enumerate(MOUTHS[mouth]):
        for j, ch in enumerate(line):
            if ch != ".":
                rows[my + i][12 + j] = ch
    if blush:
        for c in (3, 4, 5, 21, 22, 23):
            if rows[top + 7][c] in "23":
                rows[top + 7][c] = "r"
    if wrinkles:
        for c in (4, 5, 21, 22):
            rows[top + 8][c] = "3"
        rows[my - 1][9] = "3"
        rows[my - 1][18] = "3"
        rows[my][9] = "3"
        rows[my][18] = "3"
    if scar:
        for i in range(6):
            rows[top - 2 + i][19 + i // 2] = "s"
    return ["".join(r) for r in rows]


# ======================= 画布 =======================

class Canvas:
    def __init__(self):
        self.px = [[None] * S for _ in range(S)]

    def get(self, x, y):
        if 0 <= x < S and 0 <= y < S:
            return self.px[y][x]
        return None

    def put(self, x, y, c):
        if 0 <= x < S and 0 <= y < S and c is not None:
            self.px[y][x] = c

    def grid(self, rows, pal, ox=0, oy=0, keep=""):
        """按调色板把字符网格画上去；keep 里的字符不覆盖已有像素（只画在空处）"""
        for y, line in enumerate(rows):
            for x, ch in enumerate(line):
                if ch == "." or ch == " ":
                    continue
                if ch in keep and self.get(ox + x, oy + y) is not None:
                    continue
                if ch not in pal:
                    raise KeyError("调色板缺字符 %r" % ch)
                self.put(ox + x, oy + y, pal[ch])

    def image(self, scale=1):
        img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        for y in range(S):
            for x in range(S):
                if self.px[y][x] is not None:
                    img.putpixel((x, y), self.px[y][x] + (255,))
        return img.resize((S * scale, S * scale), Image.NEAREST) if scale != 1 else img


# ======================= 形状工具 =======================

def poly(pts):
    out = set()
    ys = [p[1] for p in pts]
    for y in range(int(min(ys)), int(max(ys)) + 1):
        xs = []
        n = len(pts)
        for i in range(n):
            (x0, y0), (x1, y1) = pts[i], pts[(i + 1) % n]
            if (y0 <= y + 0.5 < y1) or (y1 <= y + 0.5 < y0):
                xs.append(x0 + (y + 0.5 - y0) / (y1 - y0) * (x1 - x0))
        xs.sort()
        for a, b in zip(xs[0::2], xs[1::2]):
            for x in range(int(round(a)), int(round(b))):
                out.add((x, y))
    return out


def ellipse(cx, cy, rx, ry):
    out = set()
    for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
        for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
            if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                out.add((x, y))
    return out


def border(mask):
    return {p for p in mask if any((p[0] + dx, p[1] + dy) not in mask for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))}


def fill(cv, mask, rp, light=(-1.0, -0.8), band=(0.30, -0.25, -0.65), outline=True, line_idx=5, dither=True):
    """按光向给蒙版上色：rp 是 ramp()；band = (暗阈, 亮阈, 最亮阈)；沿光方向投影分档，档边做棋盘抖动"""
    if not mask:
        return
    xs = [p[0] for p in mask]
    ys = [p[1] for p in mask]
    cx, cy = (min(xs) + max(xs)) / 2, (min(ys) + max(ys)) / 2
    rx, ry = max(1, (max(xs) - min(xs)) / 2), max(1, (max(ys) - min(ys)) / 2)
    edge = border(mask) if outline else set()
    for (x, y) in mask:
        if (x, y) in edge:
            cv.put(x, y, rp[line_idx])
            continue
        t = -((x - cx) / rx * light[0] + (y - cy) / ry * light[1]) / 1.8
        dark, lit, top = band
        k = 2
        if t > dark:
            k = 3
            if t > dark + 0.35:
                k = 4
        elif t < top:
            k = 0
        elif t < lit:
            k = 1
        if dither and abs(t - dark) < 0.05 and (x + y) % 2 == 0:
            k = 2 if k == 3 else 3
        cv.put(x, y, rp[k])


def strand(root, tip, w0, w1=0.6, bend=0.0):
    """一缕头发：从 root 到 tip 的锥形带，bend 让中段往侧面弯"""
    (x0, y0), (x1, y1) = root, tip
    pts_l, pts_r = [], []
    n = 12
    import math
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1
    nx, ny = -dy / L, dx / L
    for i in range(n + 1):
        t = i / n
        w = w0 + (w1 - w0) * t
        bx = bend * math.sin(math.pi * t)
        cx = x0 + dx * t + nx * bx
        cy = y0 + dy * t + ny * bx
        pts_l.append((cx + nx * w, cy + ny * w))
        pts_r.append((cx - nx * w, cy - ny * w))
    return poly(pts_l + pts_r[::-1])
