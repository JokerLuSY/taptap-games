"""战斗特写角色（原创，GBA 火纹风，纸娃娃拼帧）。

头、躯干（以及马身）是逐像素手画的字符小图；四肢、马腿和武器每帧按「骨架姿势」重新栅格化：
带描边、明暗两色的粗像素线段，关节处圆头，所以不会有旋转糊边。角色一律朝右画，左侧出场时由游戏翻转。
角色数据在 fe_combat_art.py。
用法：python -P -E fe_combat.py <输出目录> <combat_sets.gd> [预览.png]
输出：<目录>/<角色>/<动作>.png（横排条带）、<目录>/arrow.png，以及元数据 GDScript（CombatSets.SETS）
"""
import math
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# ---------------- 栅格化 ----------------


class Canvas:
    def __init__(self, w, h):
        self.w, self.h = w, h
        self.px = [[None] * w for _ in range(h)]

    def put(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h and c is not None:
            self.px[y][x] = c

    def get(self, x, y):
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.px[y][x]
        return None

    def to_image(self):
        from PIL import Image
        img = Image.new("RGBA", (self.w, self.h), (0, 0, 0, 0))
        for y in range(self.h):
            for x in range(self.w):
                c = self.px[y][x]
                if c is not None:
                    img.putpixel((x, y), c + (255,))
        return img


def _dist_seg(px, py, ax, ay, bx, by):
    dx, dy = bx - ax, by - ay
    L2 = dx * dx + dy * dy
    t = 0.0 if L2 == 0 else max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / L2))
    cx, cy = ax + t * dx, ay + t * dy
    return math.hypot(px - cx, py - cy), (px - cx, py - cy), t


def limb(cv, a, b, r, light, shade, outline, r_end=None):
    """粗线段：半径 r（可渐细到 r_end），下半边暗色，外圈 1px 描边"""
    r_end = r if r_end is None else r_end
    ax, ay = a
    bx, by = b
    x0, x1 = int(min(ax, bx) - max(r, r_end) - 2), int(max(ax, bx) + max(r, r_end) + 2)
    y0, y1 = int(min(ay, by) - max(r, r_end) - 2), int(max(ay, by) + max(r, r_end) + 2)
    nx, ny = -(by - ay), (bx - ax)
    if ny < 0:
        nx, ny = -nx, -ny
    fill, edge = [], []
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            d, off, t = _dist_seg(x + 0.5, y + 0.5, ax, ay, bx, by)
            rr = r + (r_end - r) * t
            if d <= rr:
                side = off[0] * nx + off[1] * ny
                fill.append((x, y, shade if side > rr * 0.25 else light))
            elif d <= rr + 1.0:
                edge.append((x, y))
    for x, y in edge:
        if cv.get(x, y) is None or cv.get(x, y) == outline:
            cv.put(x, y, outline)
    for x, y, c in fill:
        cv.put(x, y, c)


def poly(cv, pts, light, shade, outline):
    """实心多边形（武器头）：上半亮、下半暗，外圈描边"""
    xs = [p[0] for p in pts]
    ys = [p[1] for p in pts]
    x0, x1, y0, y1 = int(min(xs)) - 2, int(max(xs)) + 2, int(min(ys)) - 2, int(max(ys)) + 2
    cy = (min(ys) + max(ys)) / 2

    def inside(px, py):
        c = False
        n = len(pts)
        for i in range(n):
            xa, ya = pts[i]
            xb, yb = pts[(i + 1) % n]
            if (ya > py) != (yb > py):
                if px < (xb - xa) * (py - ya) / (yb - ya) + xa:
                    c = not c
        return c

    filled = set()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            if inside(x + 0.5, y + 0.5):
                filled.add((x, y))
    for x, y in filled:
        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            q = (x + dx, y + dy)
            if q not in filled and (cv.get(*q) is None or cv.get(*q) == outline):
                cv.put(q[0], q[1], outline)
    for x, y in filled:
        cv.put(x, y, shade if y > cy + 1 else light)


def stamp(cv, art, pal, ox, oy):
    for y, row in enumerate(art):
        for x, ch in enumerate(row):
            if ch != ".":
                cv.put(ox + x, oy + y, pal[ch])


def _dir(angle_deg):
    a = math.radians(angle_deg)
    return math.cos(a), math.sin(a)


# ---------------- 武器 ----------------

def w_sword(cv, pal, hand, angle, length=26, blade_r=1.4, **_):
    """blade_r：刃宽（细剑 0.9、阔刃剑 1.9）"""
    dx, dy = _dir(angle)
    hx, hy = hand
    limb(cv, (hx - dx * 4, hy - dy * 4), (hx, hy), 1.0, pal["grip"], pal["grip_d"], pal["K"])
    limb(cv, (hx + dx * 2, hy + dy * 2), (hx + dx * length, hy + dy * length), blade_r, pal["blade"], pal["blade_d"], pal["K"], r_end=min(0.4, blade_r))
    gx, gy = -dy, dx
    limb(cv, (hx + dx * 1.5 - gx * 3, hy + dy * 1.5 - gy * 3), (hx + dx * 1.5 + gx * 3, hy + dy * 1.5 + gy * 3), 0.9, pal["gold"], pal["gold_d"], pal["K"])


def w_axe(cv, pal, hand, angle, length=24, head=1.0, **_):
    """斧：手握柄尾往 angle 方向伸出，斧头在柄端、刃口朝「挥砍方向」（顺时针一侧）"""
    dx, dy = _dir(angle)
    hx, hy = hand
    end = (hx + dx * length, hy + dy * length)
    limb(cv, (hx - dx * 3, hy - dy * 3), end, 1.2, pal["grip"], pal["grip_d"], pal["K"])
    gx, gy = -dy, dx                      # 刃口一侧
    s = head

    def P(u, v):
        return (hx + dx * u + gx * v, hy + dy * u + gy * v)
    L = length
    pts = [P(L - 9 * s, 1), P(L - 11 * s, 7 * s), P(L - 5 * s, 11 * s), P(L + 2 * s, 10 * s), P(L + 1, 1), P(L + 1, -3 * s), P(L - 7 * s, -3 * s)]
    poly(cv, pts, pal["blade"], pal["blade_d"], pal["K"])


def w_lance(cv, pal, hand, angle, length=56, butt=14, **_):
    dx, dy = _dir(angle)
    hx, hy = hand
    tip_base = (hx + dx * length, hy + dy * length)
    limb(cv, (hx - dx * butt, hy - dy * butt), tip_base, 1.2, pal["grip"], pal["grip_d"], pal["K"])
    gx, gy = -dy, dx
    bx, by = tip_base
    pts = [(bx - gx * 3, by - gy * 3), (bx + dx * 12, by + dy * 12), (bx + gx * 3, by + gy * 3)]
    poly(cv, pts, pal["blade"], pal["blade_d"], pal["K"])
    limb(cv, (bx - gx * 3, by - gy * 3), (bx + gx * 3, by + gy * 3), 0.9, pal["gold"], pal["gold_d"], pal["K"])


def w_bow(cv, pal, hand, angle=0, draw=0.0, string_hand=None, arrow=False, **_):
    """竖弓握在 hand；draw 0..1 表示弦被拉到 string_hand 的程度；arrow 表示搭着箭"""
    hx, hy = hand
    top, bot = (hx - 4, hy - 15), (hx - 4, hy + 15)
    belly = (hx + 3, hy)
    limb(cv, top, (hx + 1, hy - 8), 1.3, pal["grip"], pal["grip_d"], pal["K"], r_end=1.5)
    limb(cv, (hx + 1, hy - 8), belly, 1.5, pal["grip"], pal["grip_d"], pal["K"])
    limb(cv, belly, (hx + 1, hy + 8), 1.5, pal["grip"], pal["grip_d"], pal["K"])
    limb(cv, (hx + 1, hy + 8), bot, 1.5, pal["grip"], pal["grip_d"], pal["K"], r_end=1.3)
    sx = hx - 4
    if string_hand is not None and draw > 0:
        sx = hx - 4 + (string_hand[0] - (hx - 4)) * draw
    sy = hy
    for a, b in (((top[0], top[1] + 1), (sx, sy)), ((sx, sy), (bot[0], bot[1] - 1))):
        steps = int(max(abs(b[0] - a[0]), abs(b[1] - a[1]))) + 1
        for i in range(steps + 1):
            t = i / max(1, steps)
            cv.put(int(a[0] + (b[0] - a[0]) * t), int(a[1] + (b[1] - a[1]) * t), pal["string"])
    if arrow:
        limb(cv, (sx, sy), (hx + 10, hy), 0.5, pal["blade_d"], pal["blade_d"], pal["K"])
        poly(cv, [(hx + 10, hy - 2), (hx + 15, hy), (hx + 10, hy + 2)], pal["blade"], pal["blade_d"], pal["K"])


def w_staff(cv, pal, hand, angle, length=30, butt=10, **_):
    """治疗杖：木杆，杖头是金环套一颗宝珠"""
    dx, dy = _dir(angle)
    hx, hy = hand
    tip = (hx + dx * length, hy + dy * length)
    limb(cv, (hx - dx * butt, hy - dy * butt), tip, 1.1, pal["grip"], pal["grip_d"], pal["K"])
    cx, cy = hx + dx * (length + 4), hy + dy * (length + 4)
    ring = [(cx + 4.5 * math.cos(math.radians(a)), cy + 4.5 * math.sin(math.radians(a))) for a in range(0, 360, 45)]
    for i in range(len(ring)):
        limb(cv, ring[i], ring[(i + 1) % len(ring)], 0.9, pal["gold"], pal["gold_d"], pal["K"])
    limb(cv, (cx, cy), (cx, cy), 1.6, pal.get("gem", (136, 216, 248)), pal.get("gem_d", (72, 144, 216)), pal["K"])
    gx, gy = -dy, dx
    limb(cv, (tip[0] - gx * 2.5, tip[1] - gy * 2.5), (tip[0] + gx * 2.5, tip[1] + gy * 2.5), 0.8, pal["gold"], pal["gold_d"], pal["K"])


WEAPONS = {"sword": w_sword, "axe": w_axe, "lance": w_lance, "bow": w_bow, "staff": w_staff}


# ---------------- 拼帧 ----------------

def _add(p, o):
    return (p[0] + o[0], p[1] + o[1])


def build_frame(u, pose):
    """u：角色配置；pose：这一帧的骨架。坐标都是画布像素"""
    cv = Canvas(*u["frame"])
    pal = u["pal"]
    K = pal["K"]
    L = u["limbs"]
    body = u["body"]
    t0 = pose["torso"]
    if "mount" in u:
        _draw_horse(cv, u, pose)
    sh_b, sh_f = _add(t0, body["sh_b"]), _add(t0, body["sh_f"])
    hip_b, hip_f = _add(t0, body["hip_b"]), _add(t0, body["hip_f"])

    def seg(key, a, b, end=None):
        c1, c2, r = L[key]
        limb(cv, a, b, r, pal[c1], pal[c2], K, r_end=end)

    # 披风挂在肩后，最先画（在后腿、后臂之下）
    if u.get("cape"):
        stamp(cv, u["cape"], pal, t0[0] + body["cape"][0], t0[1] + body["cape"][1])
    wpn = u["weapon"]
    behind = wpn.get("behind", False)
    if behind and "wpn" in pose:
        WEAPONS[wpn["type"]](cv, pal, pose["hand_f"], pose["wpn"], **{**wpn, **pose.get("wpn_args", {})})
    # 后腿、后臂
    if "knee_b" in pose:
        seg("thigh_b", hip_b, pose["knee_b"])
        seg("shin_b", pose["knee_b"], pose["foot_b"], L["shin_b"][2] * 0.85)
        limb(cv, (pose["foot_b"][0] - 1, pose["foot_b"][1] + 1), (pose["foot_b"][0] + 3, pose["foot_b"][1] + 1), 1.3, pal[L["shin_b"][1]], pal[L["shin_b"][1]], K)
    seg("arm_b", sh_b, pose["elbow_b"])
    seg("fore_b", pose["elbow_b"], pose["hand_b"], L["fore_b"][2] * 0.85)
    # 前腿
    if "knee_f" in pose:
        seg("thigh_f", hip_f, pose["knee_f"])
        seg("shin_f", pose["knee_f"], pose["foot_f"], L["shin_f"][2] * 0.85)
        limb(cv, (pose["foot_f"][0] - 1, pose["foot_f"][1] + 1), (pose["foot_f"][0] + 3, pose["foot_f"][1] + 1), 1.3, pal[L["shin_f"][0]], pal[L["shin_f"][1]], K)
    # 躯干、下摆、头
    stamp(cv, u["torso"], pal, t0[0], t0[1])
    if u.get("skirt"):
        stamp(cv, u["skirt"], pal, t0[0] + body["skirt"][0], t0[1] + body["skirt"][1])
    stamp(cv, u["head"], pal, t0[0] + body["head"][0] + pose.get("head_dx", 0), t0[1] + body["head"][1] + pose.get("head_dy", 0))
    # 盾：挂在后手上，挡在身前
    if u.get("shield"):
        sw, sh = len(u["shield"][0]), len(u["shield"])
        stamp(cv, u["shield"], pal, int(pose["hand_b"][0] - sw // 2), int(pose["hand_b"][1] - sh // 2))
    # 骑手的腿（马上）
    if "rider_knee" in pose:
        seg("thigh_f", hip_f, pose["rider_knee"])
        seg("shin_f", pose["rider_knee"], pose["rider_foot"], L["shin_f"][2] * 0.85)
    # 前臂 + 武器
    seg("arm_f", sh_f, pose["elbow_f"])
    seg("fore_f", pose["elbow_f"], pose["hand_f"], L["fore_f"][2] * 0.85)
    if not behind and "wpn" in pose:
        args = {**wpn, **pose.get("wpn_args", {})}
        if wpn["type"] == "bow":
            args["string_hand"] = pose["hand_b"]
        WEAPONS[wpn["type"]](cv, pal, pose["hand_f"], pose["wpn"], **args)
    c1, c2, _ = L["fore_f"]
    limb(cv, pose["hand_f"], pose["hand_f"], 1.6, pal[c1], pal[c2], K)
    return cv.to_image()


def _draw_horse(cv, u, pose):
    m = u["mount"]
    pal = u["pal"]
    K = pal["K"]
    hx, hy = pose["horse"]
    # 远侧两条腿先画（暗一档），马身，近侧两条腿
    for key in ("hind_b", "fore_b"):
        a = _add((hx, hy), m["attach"][key])
        k, f = pose[key]
        limb(cv, a, k, 2.3, pal["q"], pal["q"], K, r_end=1.6)
        limb(cv, k, f, 1.4, pal["q"], pal["q"], K, r_end=1.2)
        limb(cv, (f[0] - 1, f[1] + 1), (f[0] + 2, f[1] + 1), 1.4, pal["Z"], pal["Z"], K)
    stamp(cv, m["art"], pal, hx, hy)
    for key in ("hind_f", "fore_f"):
        a = _add((hx, hy), m["attach"][key])
        k, f = pose[key]
        limb(cv, a, k, 2.5, pal["Q"], pal["q"], K, r_end=1.7)
        limb(cv, k, f, 1.5, pal["Q"], pal["q"], K, r_end=1.3)
        limb(cv, (f[0] - 1, f[1] + 1), (f[0] + 2, f[1] + 1), 1.4, pal["Z"], pal["Z"], K)


PAD = 24      # 画布四周留白：挥到最远的刀尖、枪尖、跃起的头都不贴边


def _shift_any(v, dx, dy):
    if isinstance(v, tuple) and len(v) == 2 and all(isinstance(c, (int, float)) for c in v):
        return (v[0] + dx, v[1] + dy)
    if isinstance(v, tuple):
        return tuple(_shift_any(c, dx, dy) for c in v)
    return v


def padded(u):
    """返回四周加 PAD 留白后的角色配置（帧尺寸、脚底、所有姿势坐标一起平移）"""
    w, h = u["frame"]
    q = dict(u)
    q["frame"] = (w + PAD * 2, h + PAD * 2)
    q["foot"] = (u["foot"][0] + PAD, u["foot"][1] + PAD)
    q["poses"] = {n: {k: _shift_any(v, PAD, PAD) for k, v in pose.items()} for n, pose in u["poses"].items()}
    return q


def render_unit(u):
    return {name: build_frame(u, p) for name, p in u["poses"].items()}


def build_strips(u, frames):
    from PIL import Image
    w, h = u["frame"]
    out = {}
    for anim, spec in u["anims"].items():
        seq = spec["frames"]
        img = Image.new("RGBA", (w * len(seq), h), (0, 0, 0, 0))
        for i, name in enumerate(seq):
            img.alpha_composite(frames[name], (w * i, 0))
        out[anim] = img
    return out


def preview(path, units, scale=3):
    from PIL import Image, ImageDraw
    rows = [(k, u, render_unit(u)) for k, u in units.items()]
    W = max(len(f) * (u["frame"][0] * scale + 6) for _, u, f in rows)
    H = sum(u["frame"][1] * scale + 18 for _, u, _ in rows)
    out = Image.new("RGBA", (W, H), (96, 132, 80, 255))
    d = ImageDraw.Draw(out)
    y = 0
    for key, u, frames in rows:
        fw, fh = u["frame"]
        for i, (name, img) in enumerate(frames.items()):
            x = i * (fw * scale + 6)
            d.rectangle([x, y + u["foot"][1] * scale, x + fw * scale, y + u["foot"][1] * scale + 2], fill=(60, 80, 40, 255))
            out.alpha_composite(img.resize((fw * scale, fh * scale), Image.NEAREST), (x, y))
            d.text((x + 3, y + fh * scale + 2), f"{key}/{name}", fill=(255, 255, 255, 255))
        y += fh * scale + 18
    out.save(path)


NL = chr(10)
TAB = chr(9)


def write_sets_gd(path, units):
    """把帧尺寸、脚底锚点、放大倍数、出手距离、各动作 [帧率, 出手帧] 写成 GDScript 常量（导出包里不依赖 json）"""
    lines = [
        "class_name CombatSets",
        "## 由 tools/pixelart/fe_combat.py 生成，不要手改。战斗特写角色条带的元数据。",
        "",
        "const SETS := {",
    ]
    for key, u in units.items():
        anims = ", ".join(f'"{a}": [{s["fps"]}, {s.get("impact", -1)}]' for a, s in u["anims"].items())
        lines.append(
            TAB + f'"{key}": {{"frame": Vector2i({u["frame"][0]}, {u["frame"][1]}), "feet": Vector2({u["foot"][0]}, {u["foot"][1]}), '
            f'"scale": {u["scale"]}, "reach": {u.get("reach", 140)}, "anims": {{{anims}}}}},')
    lines.append("}")
    with open(path, "w", encoding="utf-8", newline=NL) as f:
        f.write(NL.join(lines) + NL)


def arrow_image():
    cv = Canvas(18, 7)
    from fe_combat_art import WEAPON_COLORS as C
    K = (32, 24, 20)
    limb(cv, (1, 3), (12, 3), 0.5, C["grip"], C["grip"], K)
    poly(cv, [(12, 1), (17, 3), (12, 5)], C["blade"], C["blade_d"], K)
    poly(cv, [(0, 1), (3, 3), (0, 5)], (232, 224, 200), (180, 170, 150), K)
    return cv.to_image()


if __name__ == "__main__":
    from fe_combat_art import UNITS as RAW  # noqa: E402
    UNITS = {k: padded(u) for k, u in RAW.items()}
    out_dir, gd_path = sys.argv[1], sys.argv[2]
    for key, u in UNITS.items():
        frames = render_unit(u)
        d = os.path.join(out_dir, key)
        os.makedirs(d, exist_ok=True)
        for anim, img in build_strips(u, frames).items():
            img.save(os.path.join(d, anim + ".png"))
    arrow_image().save(os.path.join(out_dir, "arrow.png"))
    write_sets_gd(gd_path, UNITS)
    if len(sys.argv) > 3:
        preview(sys.argv[3], UNITS)
