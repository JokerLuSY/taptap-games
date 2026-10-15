"""全区域放大 QA 检查穿模"""
from PIL import Image

SRC = r"E:\projects\taptap\ember_oath\tools\shots\01_map.png"
OUT_DIR = r"E:\projects\taptap\ember_oath\tools\shots"

jobs = [
    ((0, 48, 320, 240), "qa_nw.png", 2),        # 西北: 森林带/西屋/农田
    ((320, 48, 640, 240), "qa_n_mid.png", 2),   # 北中: 水井/道路/东屋
    ((640, 48, 960, 240), "qa_ne.png", 2),      # 东北: 高台/东屋
    ((0, 240, 320, 432), "qa_w_river.png", 2),  # 西河岸: 沙滩/芦苇
    ((320, 240, 640, 432), "qa_bridge.png", 2), # 桥区
    ((640, 240, 960, 432), "qa_e_river.png", 2),# 东河岸: 瀑布口
    ((0, 432, 480, 688), "qa_sw.png", 2),       # 西南: 山地/山贼
    ((480, 432, 960, 688), "qa_se.png", 2),     # 东南: 山/沙滩
]

img = Image.open(SRC)
for box, name, scale in jobs:
    crop = img.crop(box)
    crop = crop.resize((crop.width * scale, crop.height * scale), Image.NEAREST)
    crop.save(OUT_DIR + "\\" + name)
    print("saved", name)
