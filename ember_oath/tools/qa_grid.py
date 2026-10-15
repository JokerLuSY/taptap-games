"""把 01_map.png(游戏实图) 和 ch1_bg.png(纯背景) 切成 4x3 网格 3x放大, 逐一 QA"""
from PIL import Image
import os

OUT = r"E:\projects\taptap\ember_oath\tools\shots\grid"
os.makedirs(OUT, exist_ok=True)

for src, tag in [
    (r"E:\projects\taptap\ember_oath\tools\shots\01_map.png", "game"),
    (r"E:\projects\taptap\ember_oath\art\maps\ch1_bg.png", "bg"),
]:
    img = Image.open(src)
    W, H = img.size  # game 图可能是 2x 窗口尺寸
    sx, sy = W / 960.0, H / 640.0
    cols, rows = 4, 3
    for gy in range(rows):
        for gx in range(cols):
            x0 = int(gx * 240 * sx)
            y0 = int(gy * 214 * sy)
            x1 = int(min(960, (gx + 1) * 240 + 64) * sx)
            y1 = int(min(640, (gy + 1) * 214 + 64) * sy)
            crop = img.crop((x0, y0, x1, y1))
            crop = crop.resize((crop.width * 2, crop.height * 2), Image.NEAREST)
            crop.save(os.path.join(OUT, "%s_g%d%d.png" % (tag, gx, gy)))
    print(tag, img.size, "done")
