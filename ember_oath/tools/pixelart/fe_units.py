"""炎烬之誓：原创 GBA 火纹风地图小人（16×16，整只按阵营色调色）。

GBA 火纹的地图小人整只用阵营色板：头发、衣服都落在同一条蓝 / 红色阶上，只有皮肤、金属、皮革另有颜色。
每帧是 16 行 × 16 列的字符网格，一个字符一个像素：
  .        透明
  K        描边 / 内线（生成时按旁边的颜色自动换成对应的深色，即「选择性描边」）
  1..5     阵营色阶，1 最亮、5 最暗
  a b c    皮肤 亮 / 中 / 暗
  x y z    金属 亮 / 中 / 暗
  n m      皮革 中 / 暗        g  金      E  眼睛（阵营最暗描边色）
  w v      白布 亮 / 暗（教会制服、修女头巾，不随阵营变）
用法：python -P -E fe_units.py <输出目录> [预览.png]
"""
import sys
import os

RAMPS = {
    "blue": {"1": (208, 232, 248), "2": (136, 184, 248), "3": (80, 128, 224), "4": (48, 80, 176), "5": (32, 44, 112), "K": (16, 24, 52)},
    "red": {"1": (248, 216, 200), "2": (248, 152, 120), "3": (224, 80, 64), "4": (168, 40, 40), "5": (96, 24, 24), "K": (52, 12, 16)},
}
BASE = {
    "a": (248, 224, 192), "b": (240, 184, 144), "c": (192, 120, 80),
    "x": (248, 248, 248), "y": (184, 192, 208), "z": (104, 112, 136),
    "n": (168, 112, 72), "m": (104, 64, 40), "g": (248, 208, 88),
    "w": (240, 236, 224), "v": (184, 176, 176),
}
## 选择性描边：描边像素取「旁边那块颜色」的深色
OUTLINE_OF = {
    "a": (88, 40, 24), "b": (88, 40, 24), "c": (88, 40, 24),
    "x": (48, 56, 72), "y": (48, 56, 72), "z": (48, 56, 72),
    "n": (48, 26, 14), "m": (48, 26, 14), "g": (96, 64, 16),
    "w": (64, 56, 64), "v": (64, 56, 64),
}

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fe_art import UNITS as ART  # noqa: E402

ROWS = ["idle", "walk_down", "walk_up", "walk_side"]


def shift_down(frame):
    """呼吸帧：整体下沉 1px（最底两行的脚保持不动）"""
    w = len(frame[0])
    return ["." * w] + frame[:-3] + frame[-2:]


def with_legs(view, legs):
    """把腿部行换成 legs（并按宽度补齐）"""
    out = list(view)
    for i, row in enumerate(legs["rows"]):
        out[legs["row"] + i] = row
    return out


def _pad(rows, w):
    """行尾不足宽度的用透明补齐，超宽直接报错"""
    for r in rows:
        assert len(r) <= w, f"行超宽 {len(r)} > {w}: {r!r}"
    return [r.ljust(w, ".") for r in rows]


def frames_for(unit):
    """返回 {动作: [帧]}；走路 = 迈左、并脚、迈右、并脚"""
    art = ART[unit]
    w = art["size"][0]
    v = {k: _pad(rows, w) for k, rows in art["views"].items()}
    res = {"idle": [v["front"], shift_down(v["front"]), v["front"]]}
    for name, view in (("walk_down", "front"), ("walk_up", "back"), ("walk_side", "side")):
        lg = art["legs"][view]
        seq = []
        for k in ("a", "n", "b", "n"):
            seq.append(with_legs(v[view], {"row": lg["row"], "rows": _pad(lg[k], w)}))
        res[name] = seq
    return res


def _family(ch):
    if ch in "12345":
        return "team"
    return ch


def check(unit):
    """尺寸检查：每帧行数、每行字符数都要等于单位的帧尺寸"""
    w, h = ART[unit]["size"]
    for name, frames in frames_for(unit).items():
        for i, f in enumerate(frames):
            assert len(f) == h, f"{unit}/{name}[{i}] 行数 {len(f)} != {h}"
            for y, row in enumerate(f):
                assert len(row) == w, f"{unit}/{name}[{i}] 第 {y} 行宽 {len(row)} != {w}: {row!r}"


def render(frame, team):
    from PIL import Image
    ramp = RAMPS[team]
    pal = dict(BASE)
    pal.update({k: v for k, v in ramp.items() if k != "K"})
    h = len(frame)
    w = len(frame[0])
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    for y, row in enumerate(frame):
        for x, ch in enumerate(row):
            if ch == ".":
                continue
            if ch in "KE":
                img.putpixel((x, y), _outline_color(frame, x, y, ramp) + (255,))
            else:
                img.putpixel((x, y), pal[ch] + (255,))
    return img


def _outline_color(frame, x, y, ramp):
    """描边 / 内线：看上下左右的填色，多数是皮肤就用深褐，金属就用深灰……默认阵营最暗色"""
    votes = {}
    h = len(frame)
    w = len(frame[0])
    for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
        nx, ny = x + dx, y + dy
        if 0 <= nx < w and 0 <= ny < h:
            ch = frame[ny][nx]
            if ch not in ".KE":
                f = _family(ch)
                votes[f] = votes.get(f, 0) + 1
    if not votes:
        return ramp["K"]
    best = max(votes, key=lambda k: (votes[k], k == "team"))
    if best == "team":
        return ramp["K"]
    return OUTLINE_OF.get(best, ramp["K"])


def sheet(unit, team):
    """一行一个动作（ROWS 顺序），每行 4 格；待机只有 3 帧，第 4 格空着"""
    from PIL import Image
    check(unit)
    w, h = ART[unit]["size"]
    fr = frames_for(unit)
    img = Image.new("RGBA", (w * 4, h * len(ROWS)), (0, 0, 0, 0))
    for r, name in enumerate(ROWS):
        for i, f in enumerate(fr[name]):
            img.alpha_composite(render(f, team), (w * i, h * r))
    return img


def preview(path, team="blue"):
    from PIL import Image, ImageDraw
    grass = (152, 184, 72)
    sc = 6
    sheets = [(u, sheet(u, team), sheet(u, "red")) for u in ART]
    w = sum(max(a.size[0], 1) * sc + 20 for _, a, _ in sheets)
    h = max(a.size[1] for _, a, _ in sheets) * sc * 2 + 40
    out = Image.new("RGBA", (w, h), grass + (255,))
    d = ImageDraw.Draw(out)
    x = 0
    for unit, a, b in sheets:
        out.alpha_composite(a.resize((a.size[0] * sc, a.size[1] * sc), Image.NEAREST), (x, 20))
        out.alpha_composite(b.resize((b.size[0] * sc, b.size[1] * sc), Image.NEAREST), (x, 30 + a.size[1] * sc))
        d.text((x + 4, 4), unit, fill=(0, 0, 0, 255))
        x += a.size[0] * sc + 20
    out.save(path)


if __name__ == "__main__":
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    for unit in ART:
        for team in ("blue", "red"):
            sheet(unit, team).save(os.path.join(out_dir, f"{unit}_{team}.png"))
    if len(sys.argv) > 2:
        preview(sys.argv[2])
