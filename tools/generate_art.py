# -*- coding: utf-8 -*-
"""《失踪的邻居》占位美术生成器
统一风格: 夜间冷蓝 + 一盏暖黄台灯。全部程序生成, 无第三方素材。
输出到 missing_neighbor/art/
"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageFilter, ImageOps

random.seed(20261008)

ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "missing_neighbor", "art")
W, H = 1080, 1920

# 调色板
NIGHT_TOP = (10, 14, 28)
NIGHT_BOT = (26, 34, 58)
FLOOR_C = (14, 18, 32)
SIL = (7, 9, 18)            # 剪影(近黑)
SIL2 = (18, 23, 40)         # 次剪影
RIM = (70, 82, 120)         # 冷色描边
WARM = (255, 190, 90)       # 暖黄
WARM_SOFT = (255, 214, 140)
PAPER = (228, 222, 205)
RED = (176, 58, 66)
ICON_BG = (32, 40, 66)


def lerp(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))


def new_bg(top=NIGHT_TOP, bottom=NIGHT_BOT):
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        d.line([(0, y), (W, y)], fill=lerp(top, bottom, y / H))
    return img


def add_glow(img, cx, cy, radius, color=WARM, strength=0.85):
    """径向暖光"""
    grad = Image.radial_gradient("L").resize((radius * 2, radius * 2))
    alpha = ImageOps.invert(grad).point(lambda v: int(v * strength))
    glow = Image.new("RGBA", (radius * 2, radius * 2), color + (255,))
    glow.putalpha(alpha)
    img.paste(Image.new("RGB", glow.size, (0, 0, 0)), (cx - radius, cy - radius), glow)


def vignette(img, strength=110):
    grad = Image.radial_gradient("L").resize((W, H))
    mask = grad.point(lambda v: int(max(0, v - 90) * strength / 165))
    black = Image.new("RGB", (W, H), (0, 0, 0))
    img.paste(black, (0, 0), mask)


def grain(img, sigma=14, alpha=8):
    noise = Image.effect_noise((W, H), sigma).convert("L")
    overlay = Image.merge("RGB", (noise, noise, noise))
    img.paste(Image.blend(img, overlay, alpha / 255.0), (0, 0))


def floor_line(d, y=1500, color=FLOOR_C):
    d.rectangle([0, y, W, H], fill=color)
    d.line([(0, y), (W, y)], fill=lerp(color, RIM, 0.35), width=3)


def rect_sil(d, box, color=SIL, rim=True):
    d.rectangle(box, fill=color)
    if rim:
        x0, y0, x1, y1 = box
        d.line([(x0, y0), (x1, y0)], fill=RIM, width=2)


def window_night(d, box, lit_windows=3):
    """夜景窗户: 深蓝玻璃 + 远处零星的灯"""
    x0, y0, x1, y1 = box
    d.rectangle(box, fill=(16, 24, 46), outline=RIM, width=4)
    d.line([( (x0+x1)//2, y0), ((x0+x1)//2, y1)], fill=RIM, width=3)
    for _ in range(lit_windows):
        wx = random.randint(x0 + 12, x1 - 26)
        wy = random.randint(y0 + 12, y1 - 26)
        d.rectangle([wx, wy, wx + 12, wy + 16], fill=WARM_SOFT)


def save(img, rel):
    path = os.path.join(ROOT, rel)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("bg:", rel)


# ---------------- 12 关背景 ----------------

def level_01():  # 门廊
    img = new_bg(); d = ImageDraw.Draw(img)
    floor_line(d, 1500)
    add_glow(img, 540, 330, 260, WARM, 0.5)          # 门灯
    d.ellipse([500, 290, 580, 370], fill=(40, 34, 26), outline=WARM, width=3)
    rect_sil(d, [330, 410, 750, 1500], SIL2)          # 门框
    rect_sil(d, [360, 440, 720, 1500], SIL)           # 门
    d.rectangle([430, 700, 650, 840], fill=PAPER)     # 门上纸条(热点)
    for i in range(4):
        d.line([(450, 730 + i * 26), (630, 730 + i * 26)], fill=(90, 88, 80), width=4)
    d.rectangle([790, 600, 910, 660], fill=(46, 52, 76), outline=RIM, width=3)  # 门牌(热点)
    d.ellipse([680, 1050, 710, 1080], fill=WARM_SOFT)  # 门把手
    rect_sil(d, [80, 1150, 300, 1500], SIL)           # 鞋柜(热点)
    d.rectangle([380, 1520, 700, 1600], fill=(24, 20, 30))  # 地垫
    vignette(img); grain(img)
    save(img, "bg/level_01.png")


def level_02():  # 客厅
    img = new_bg(); d = ImageDraw.Draw(img)
    floor_line(d, 1480)
    add_glow(img, 880, 760, 300, WARM, 0.75)          # 落地灯
    d.polygon([(860, 800), (900, 800), (890, 1480), (870, 1480)], fill=SIL)
    d.ellipse([830, 720, 930, 800], fill=(60, 48, 30), outline=WARM, width=3)
    rect_sil(d, [110, 1050, 640, 1330], SIL)          # 沙发
    rect_sil(d, [110, 980, 640, 1080], SIL2)
    d.rectangle([180, 1120, 330, 1250], fill=(20, 26, 44))  # 沙发缝(热点)
    rect_sil(d, [300, 1400, 720, 1520], SIL)          # 茶几
    for i in range(3):                                 # 散落的纸
        d.polygon([(360 + i * 90, 1560 + i * 30), (430 + i * 90, 1550 + i * 30),
                   (440 + i * 90, 1600 + i * 30), (370 + i * 90, 1610 + i * 30)], fill=(52, 50, 58))
    rect_sil(d, [700, 950, 990, 1480], SIL2)          # 抽屉柜(热点)
    d.rectangle([720, 1000, 970, 1080], fill=SIL)
    d.rectangle([730, 1100, 960, 1170], fill=(12, 15, 28))
    d.polygon([(500, 1640), (640, 1640), (640, 1740), (500, 1740)], fill=(30, 34, 50))  # 倒扣相框(热点)
    d.line([(500, 1640), (640, 1740)], fill=RIM, width=3)
    vignette(img); grain(img)
    save(img, "bg/level_02.png")


def level_03():  # 厨房
    img = new_bg(); d = ImageDraw.Draw(img)
    floor_line(d, 1500)
    window_night(d, [80, 320, 360, 700], 2)
    rect_sil(d, [0, 950, 380, 1500], SIL2)            # 橱柜
    d.rectangle([60, 980, 240, 1060], fill=(10, 13, 24), outline=RIM, width=2)  # 水槽
    rect_sil(d, [800, 620, 1040, 1500], SIL)          # 冰箱
    d.line([(800, 900), (1040, 900)], fill=RIM, width=3)
    d.rectangle([850, 700, 950, 780], fill=PAPER)     # 冰箱贴便签(热点)
    rect_sil(d, [300, 1220, 780, 1360], SIL2)         # 餐桌(热点)
    d.ellipse([380, 1240, 500, 1300], fill=(40, 44, 60))   # 碗1(吃过)
    d.ellipse([600, 1240, 720, 1300], fill=(48, 52, 70))   # 碗2(没动)
    rect_sil(d, [830, 1420, 950, 1560], SIL)          # 垃圾桶(热点)
    d.polygon([(860, 1400), (910, 1400), (905, 1440), (866, 1440)], fill=PAPER)
    add_glow(img, 540, 260, 220, WARM, 0.45)          # 顶灯
    vignette(img); grain(img)
    save(img, "bg/level_03.png")


def level_04():  # 阳台
    img = new_bg(); d = ImageDraw.Draw(img)
    # 对面楼
    for bx, bw in [(60, 220), (330, 260), (640, 200), (880, 180)]:
        d.rectangle([bx, 260, bx + bw, 1050], fill=(13, 18, 34))
        for wy in range(300, 1000, 90):
            for wx in range(bx + 20, bx + bw - 30, 60):
                if random.random() < 0.18:
                    d.rectangle([wx, wy, wx + 26, wy + 36], fill=WARM_SOFT)
                else:
                    d.rectangle([wx, wy, wx + 26, wy + 36], fill=(20, 27, 48))
    d.rectangle([430, 560, 510, 610], fill=WARM_SOFT)  # 对面亮着的窗(热点)
    floor_line(d, 1420)
    d.rectangle([0, 1080, W, 1120], fill=SIL2)        # 栏杆(热点)
    for x in range(40, W, 90):
        d.line([(x, 1120), (x, 1420)], fill=SIL2, width=10)
    d.rectangle([470, 1020, 600, 1080], fill=(30, 36, 54), outline=RIM, width=3)  # 对讲机(热点)
    d.line([(580, 1020), (600, 950)], fill=RIM, width=4)
    d.line([(660, 420), (1000, 420)], fill=RIM, width=3)   # 晾衣绳
    d.polygon([(700, 420), (860, 420), (880, 640), (680, 640)], fill=(34, 40, 60))  # 男士衬衫(热点)
    d.ellipse([120, 1240, 260, 1420], fill=SIL)       # 花盆
    d.polygon([(150, 1240), (190, 1120), (230, 1240)], fill=(16, 30, 26))
    vignette(img); grain(img)
    save(img, "bg/level_04.png")


def level_05():  # 书房
    img = new_bg(); d = ImageDraw.Draw(img)
    floor_line(d, 1480)
    rect_sil(d, [60, 300, 360, 1480], SIL2)           # 书架
    for sy in range(360, 1420, 180):
        d.line([(70, sy), (350, sy)], fill=RIM, width=2)
        x = 80
        while x < 330:
            bw = random.randint(18, 34); bh = random.randint(100, 150)
            d.rectangle([x, sy - bh, x + bw, sy], fill=random.choice([(24, 30, 50), (34, 28, 44), (22, 36, 44)]))
            x += bw + 4
    rect_sil(d, [420, 1150, 1000, 1290], SIL)         # 书桌
    d.rectangle([430, 1290, 470, 1500], fill=SIL); d.rectangle([950, 1290, 990, 1500], fill=SIL)
    d.polygon([(560, 1100), (740, 1100), (760, 1170), (540, 1170)], fill=PAPER)  # 日记(热点)
    d.line([(650, 1100), (650, 1170)], fill=(90, 88, 80), width=3)
    d.rectangle([830, 1050, 900, 1150], fill=(40, 36, 30))  # 笔筒(热点)
    add_glow(img, 950, 980, 240, WARM, 0.8)           # 台灯
    d.polygon([(930, 1000), (980, 1000), (970, 1150), (940, 1150)], fill=SIL)
    d.ellipse([910, 950, 1000, 1010], fill=(60, 48, 30), outline=WARM, width=3)
    d.rectangle([480, 1320, 640, 1500], fill=SIL2)    # 椅子
    vignette(img); grain(img)
    save(img, "bg/level_05.png")


def level_06():  # 电脑桌
    img = new_bg(); d = ImageDraw.Draw(img)
    floor_line(d, 1480)
    add_glow(img, 580, 860, 320, (150, 190, 255), 0.5)   # 屏幕冷光
    rect_sil(d, [250, 1150, 830, 1290], SIL)          # 桌子
    d.rectangle([420, 760, 740, 1000], fill=(120, 150, 200), outline=SIL, width=8)  # 显示器(热点)
    d.rectangle([440, 780, 720, 980], fill=(170, 195, 230))
    for i in range(5):
        d.line([(460, 810 + i * 34), (700 - random.randint(0, 120), 810 + i * 34)], fill=(90, 110, 140), width=6)
    d.rectangle([540, 1000, 620, 1150], fill=SIL)
    d.rectangle([440, 1170, 700, 1210], fill=(16, 20, 34))  # 键盘
    d.rectangle([745, 790, 815, 860], fill=PAPER)     # 屏幕边便签(热点)
    d.rectangle([290, 1090, 400, 1150], fill=(44, 48, 66))  # 药盒(热点)
    d.polygon([(470, 1500), (800, 1500), (850, 1920), (420, 1920)], fill=SIL2)  # 椅背
    vignette(img); grain(img)
    save(img, "bg/level_06.png")


def level_07():  # 储物间
    img = new_bg(); d = ImageDraw.Draw(img)
    floor_line(d, 1500)
    add_glow(img, 540, 240, 200, WARM_SOFT, 0.55)     # 灯泡
    d.line([(540, 0), (540, 210)], fill=RIM, width=3)
    d.ellipse([510, 210, 570, 270], fill=WARM_SOFT)
    box = [(70, 1150, 330, 1450), (90, 900, 320, 1150), (380, 1200, 660, 1480),
           (400, 950, 640, 1200), (700, 1100, 980, 1480)]
    for i, b in enumerate(box):
        d.rectangle(b, fill=lerp((46, 36, 24), (30, 24, 16), i / 4), outline=(20, 16, 10), width=3)
        d.line([((b[0]+b[2])//2, b[1]), ((b[0]+b[2])//2, b[3])], fill=(24, 19, 12), width=3)
    d.rectangle([430, 1010, 590, 1090], fill=PAPER)   # 姓名标签(热点)
    d.line([(450, 1040), (570, 1040)], fill=(90, 88, 80), width=5)
    d.line([(450, 1065), (550, 1065)], fill=(90, 88, 80), width=5)
    d.ellipse([720, 850, 800, 990], outline=SIL, width=14)  # 旧球拍(热点)
    d.line([(760, 990), (780, 1120)], fill=SIL, width=12)
    vignette(img); grain(img)
    save(img, "bg/level_07.png")


def level_08():  # 浴室
    img = new_bg(top=(12, 20, 30), bottom=(22, 34, 48)); d = ImageDraw.Draw(img)
    for x in range(0, W, 135):                        # 瓷砖缝
        d.line([(x, 0), (x, 1500)], fill=(16, 26, 38), width=2)
    for y in range(0, 1500, 135):
        d.line([(0, y), (W, y)], fill=(16, 26, 38), width=2)
    floor_line(d, 1500, (16, 24, 34))
    d.rectangle([120, 560, 400, 900], fill=(30, 44, 60), outline=RIM, width=4)  # 镜子(热点)
    d.polygon([(150, 880), (260, 600), (300, 600), (190, 880)], fill=(44, 62, 82))
    rect_sil(d, [100, 1000, 420, 1160], SIL2)         # 洗手台
    d.ellipse([180, 1010, 340, 1100], fill=(12, 16, 26))
    d.line([(700, 800), (950, 800)], fill=RIM, width=6)   # 毛巾架
    d.rectangle([720, 810, 900, 1120], fill=(52, 46, 52))   # 毛巾(热点)
    d.polygon([(760, 950), (830, 980), (810, 1060), (750, 1030)], fill=(64, 30, 32))  # 血迹
    rect_sil(d, [430, 1380, 1030, 1700], SIL2)        # 浴缸
    d.rectangle([450, 1400, 1010, 1460], fill=(20, 28, 40))
    d.line([(920, 1150), (920, 1380)], fill=RIM, width=5)  # 淋浴管
    vignette(img); grain(img)
    save(img, "bg/level_08.png")


def level_09():  # 走廊
    img = new_bg(); d = ImageDraw.Draw(img)
    d.polygon([(0, 1920), (1080, 1920), (760, 1450), (320, 1450)], fill=FLOOR_C)  # 透视地面
    add_glow(img, 540, 300, 260, (200, 210, 230), 0.4)   # 冷顶灯
    d.rectangle([480, 240, 600, 300], fill=(120, 130, 150))
    rect_sil(d, [120, 500, 440, 1500], SIL)           # 左门 1701(热点)
    d.rectangle([150, 530, 410, 1480], fill=(12, 15, 26))
    d.ellipse([380, 1000, 415, 1035], fill=WARM_SOFT)     # 锁孔(热点)
    d.line([(398, 1035), (398, 1090)], fill=WARM_SOFT, width=5)  # 卡着的钥匙
    rect_sil(d, [640, 500, 960, 1500], SIL)           # 右门 1702
    d.rectangle([670, 530, 930, 1480], fill=(12, 15, 26))
    d.polygon([(700, 560), (760, 560), (760, 760), (700, 760)], fill=(70, 26, 30))  # 春联(热点)
    d.polygon([(840, 560), (900, 560), (900, 760), (840, 760)], fill=(70, 26, 30))
    d.rectangle([480, 900, 600, 1100], fill=(40, 30, 30), outline=RIM, width=3)  # 消防栓(热点)
    vignette(img); grain(img)
    save(img, "bg/level_09.png")


def level_10():  # 线索板总汇
    img = new_bg(); d = ImageDraw.Draw(img)
    floor_line(d, 1520)
    add_glow(img, 880, 1250, 260, WARM, 0.7)
    d.rectangle([120, 330, 960, 1250], fill=(52, 40, 30), outline=(26, 20, 14), width=8)  # 软木板
    pins = []
    for i in range(9):
        px = 180 + (i % 3) * 260 + random.randint(-20, 20)
        py = 420 + (i // 3) * 260 + random.randint(-20, 20)
        pins.append((px, py))
        w, h = 150, 110
        d.rectangle([px - w//2, py - h//2, px + w//2, py + h//2], fill=PAPER if i % 2 else (200, 210, 220))
        d.ellipse([px - 6, py - h//2 - 6, px + 6, py - h//2 + 6], fill=RED)
    for a, b in [(0, 4), (1, 3), (2, 5), (4, 7), (3, 6), (5, 8), (6, 7)]:
        d.line([pins[a], pins[b]], fill=RED, width=3)
    d.rectangle([430, 640, 650, 830], fill=(210, 216, 224), outline=RED, width=4)  # 监控拼图(热点)
    d.line([(540, 640), (540, 830)], fill=(120, 124, 132), width=3)
    d.line([(430, 735), (650, 735)], fill=(120, 124, 132), width=3)
    d.polygon([(480, 800), (520, 700), (560, 800)], fill=(60, 66, 80))  # 拼图里的人影
    rect_sil(d, [700, 1300, 1020, 1520], SIL)         # 桌子
    d.ellipse([850, 1180, 940, 1260], fill=(60, 48, 30), outline=WARM, width=3)
    vignette(img); grain(img)
    save(img, "bg/level_10.png")


def level_11():  # 天台
    img = new_bg(top=(8, 10, 24), bottom=(20, 26, 46)); d = ImageDraw.Draw(img)
    for _ in range(120):                              # 星星
        x, y = random.randint(0, W), random.randint(0, 800)
        d.point([(x, y)], fill=(200, 210, 230))
    add_glow(img, 860, 240, 150, (220, 226, 240), 0.5)   # 月亮
    d.ellipse([820, 200, 900, 280], fill=(225, 230, 245))
    for bx in range(0, W, 130):                       # 城市剪影
        bh = random.randint(200, 520)
        d.rectangle([bx, 1150 - bh, bx + 110, 1150], fill=(10, 13, 26))
        for _ in range(6):
            wx = random.randint(bx + 8, bx + 90); wy = random.randint(1150 - bh + 10, 1130)
            d.rectangle([wx, wy, wx + 8, wy + 10], fill=WARM_SOFT)
    floor_line(d, 1150, (16, 19, 32))
    d.rectangle([0, 1150, W, 1190], fill=SIL2)        # 护栏
    for x in range(30, W, 100):
        d.line([(x, 1190), (x, 1420)], fill=SIL2, width=8)
    d.line([(0, 1420), (W, 1420)], fill=SIL2, width=8)
    rect_sil(d, [100, 850, 360, 1420], SIL)           # 水箱(热点)
    d.rectangle([180, 800, 300, 860], fill=PAPER)     # 信(热点)
    d.polygon([(700, 700), (950, 700), (980, 1150), (670, 1150)], fill=(40, 44, 62))  # 晾着的床单(热点)
    d.rectangle([430, 1350, 560, 1500], fill=(24, 28, 44))  # 烟灰缸改为小凳
    vignette(img); grain(img)
    save(img, "bg/level_11.png")


def level_12():  # 最终门
    img = new_bg(top=(8, 9, 16), bottom=(18, 20, 34)); d = ImageDraw.Draw(img)
    floor_line(d, 1520, (10, 11, 20))
    # 门缝强光
    d.polygon([(500, 1450), (580, 1450), (900, 1920), (180, 1920)], fill=(240, 220, 180))
    add_glow(img, 540, 900, 420, WARM_SOFT, 0.9)
    rect_sil(d, [400, 420, 680, 1520], SIL2)          # 门框
    d.polygon([(430, 450), (560, 480), (560, 1500), (430, 1500)], fill=(12, 13, 22))  # 半开的门
    d.polygon([(560, 480), (650, 450), (650, 1500), (560, 1500)], fill=(250, 236, 205))  # 门后白光(热点)
    d.ellipse([520, 1000, 545, 1025], fill=WARM_SOFT)
    d.rectangle([760, 580, 930, 800], fill=PAPER)     # 日历(热点)
    for i in range(4):
        d.line([(780, 640 + i * 36), (910, 640 + i * 36)], fill=(120, 116, 108), width=3)
    d.ellipse([810, 690, 870, 750], outline=RED, width=5)  # 圈出的日期
    rect_sil(d, [120, 1180, 260, 1520], SIL)          # 伞架(热点)
    d.polygon([(150, 1000), (180, 1000), (175, 1350), (155, 1350)], fill=(30, 34, 52))
    d.polygon([(200, 1020), (230, 1020), (225, 1350), (205, 1350)], fill=(44, 30, 36))
    vignette(img, 90); grain(img)
    save(img, "bg/level_12.png")


def ending_bg():  # 结局: 医院病房, 她坐在病床边
    img = Image.new("RGB", (W, H))
    d = ImageDraw.Draw(img)
    for y in range(H):
        d.line([(0, y), (W, y)], fill=lerp((196, 204, 216), (150, 158, 174), y / H))
    d.rectangle([0, 1420, W, H], fill=(166, 172, 186))
    d.line([(0, 1420), (W, 1420)], fill=(140, 146, 160), width=3)
    add_glow(img, 820, 500, 420, (255, 246, 225), 0.75)      # 窗光
    d.rectangle([700, 260, 960, 760], fill=(232, 238, 246), outline=(120, 128, 144), width=6)
    d.line([(830, 260), (830, 760)], fill=(120, 128, 144), width=4)
    d.rectangle([90, 500, 300, 1420], fill=(140, 148, 164), outline=(110, 118, 134), width=4)  # 门
    # 病床
    d.rectangle([330, 1050, 900, 1240], fill=(222, 226, 234), outline=(150, 156, 170), width=4)
    d.rectangle([330, 980, 420, 1050], fill=(238, 240, 244))   # 枕头
    d.rectangle([320, 1240, 350, 1500], fill=(120, 126, 140))
    d.rectangle([880, 1240, 910, 1500], fill=(120, 126, 140))
    c = (16, 18, 30)                                           # 她的剪影(坐在床边)
    d.ellipse([560, 700, 660, 810], fill=c)                    # 头
    d.pieslice([545, 680, 675, 840], 180, 360, fill=c)         # 发
    d.polygon([(520, 830), (690, 830), (720, 1080), (500, 1080)], fill=c)  # 身
    d.polygon([(500, 1080), (720, 1080), (700, 1330), (520, 1330)], fill=c)  # 腿(坐姿)
    d.rectangle([500, 1330, 560, 1420], fill=c)
    d.rectangle([640, 1330, 700, 1420], fill=c)
    rim = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    rd.arc([560, 700, 660, 810], -70, 70, fill=(255, 240, 210, 230), width=5)
    rd.line([(690, 840), (718, 1060)], fill=(255, 240, 210, 200), width=5)
    img = Image.alpha_composite(img.convert("RGBA"), rim).convert("RGB")
    vignette(img, 60); grain(img)
    save(img, "bg/ending.png")


def menu_bg():  # 主菜单: 走廊尽头一扇虚掩的门, 暖光漏出
    img = new_bg(top=(6, 8, 16), bottom=(16, 20, 36)); d = ImageDraw.Draw(img)
    d.polygon([(0, 1920), (1080, 1920), (720, 1400), (360, 1400)], fill=(12, 15, 26))
    d.polygon([(470, 1450), (610, 1450), (980, 1920), (100, 1920)], fill=(238, 214, 165))
    add_glow(img, 540, 950, 480, WARM_SOFT, 0.85)
    rect_sil(d, [420, 480, 660, 1460], SIL2)
    d.polygon([(450, 510), (560, 540), (560, 1450), (450, 1450)], fill=(10, 11, 20))
    d.polygon([(560, 540), (630, 510), (630, 1450), (560, 1450)], fill=(252, 240, 210))
    vignette(img, 100); grain(img)
    save(img, "bg/menu_bg.png")


# ---------------- 图标 ----------------

def icon_canvas():
    img = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([8, 8, 248, 248], 28, fill=ICON_BG + (255,), outline=RIM + (255,), width=3)
    return img, d


def save_icon(img, name):
    path = os.path.join(ROOT, "icons", name + ".png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("icon:", name)


def glyph_paper(d, box=(70, 50, 186, 206), color=PAPER):
    d.rectangle(box, fill=color)


def icon_note():
    img, d = icon_canvas(); glyph_paper(d)
    for i in range(5):
        d.line([(88, 80 + i * 26), (168, 80 + i * 26)], fill=(110, 106, 96), width=5)
    save_icon(img, "note")


def icon_access():
    img, d = icon_canvas()
    d.rounded_rectangle([48, 78, 208, 178], 12, fill=PAPER)
    d.ellipse([70, 100, 122, 152], outline=(60, 70, 100), width=6)
    d.line([(96, 126), (96, 108)], fill=(60, 70, 100), width=5)
    d.line([(96, 126), (112, 126)], fill=(60, 70, 100), width=5)
    d.rectangle([140, 100, 190, 116], fill=(150, 146, 136))
    d.rectangle([140, 130, 178, 146], fill=(150, 146, 136))
    save_icon(img, "access_record")


def icon_wristband():
    img, d = icon_canvas()
    d.arc([48, 68, 208, 208], 200, 340, fill=(140, 170, 210), width=26)
    d.polygon([(60, 190), (90, 160), (100, 200), (76, 210)], fill=(140, 170, 210))
    for i in range(3):
        d.line([(150 + i * 18, 120), (158 + i * 18, 140)], fill=(200, 206, 216), width=4)
    save_icon(img, "wristband")


def icon_receipt():
    img, d = icon_canvas()
    pts = [(78, 46)] + [(78 + i * 14, 46 + (8 if i % 2 else 0)) for i in range(8)] + [(186, 46), (186, 210), (78, 210)]
    d.polygon(pts, fill=PAPER)
    for i in range(5):
        d.line([(94, 84 + i * 24), (170 - (i % 2) * 30, 84 + i * 24)], fill=(110, 106, 96), width=5)
    save_icon(img, "receipt")


def icon_walkie():
    img, d = icon_canvas()
    d.rounded_rectangle([88, 80, 168, 210], 10, fill=(60, 68, 92))
    d.line([(150, 80), (170, 30)], fill=(150, 156, 170), width=8)
    d.rectangle([100, 96, 156, 130], fill=(140, 170, 200))
    for i in range(3):
        d.line([(100, 150 + i * 16), (156, 150 + i * 16)], fill=(36, 40, 56), width=5)
    save_icon(img, "walkie")


def icon_diary():
    img, d = icon_canvas()
    d.rounded_rectangle([58, 50, 198, 206], 8, fill=(86, 48, 44))
    d.rectangle([70, 50, 86, 206], fill=(60, 32, 30))
    d.rectangle([150, 120, 186, 150], fill=WARM_SOFT)
    save_icon(img, "diary")


def icon_browser():
    img, d = icon_canvas()
    d.rounded_rectangle([44, 66, 212, 170], 10, fill=(170, 195, 230))
    d.rectangle([44, 66, 212, 92], fill=(90, 110, 140))
    for i in range(3):
        d.line([(60, 112 + i * 20), (190 - i * 34, 112 + i * 20)], fill=(110, 130, 160), width=6)
    d.rectangle([112, 170, 144, 196], fill=(60, 68, 92))
    save_icon(img, "browser")


def icon_nametag():
    img, d = icon_canvas()
    d.polygon([(56, 96), (150, 96), (204, 152), (150, 208), (56, 208)], fill=PAPER)
    d.ellipse([160, 140, 184, 164], fill=ICON_BG)
    d.line([(90, 140), (140, 140)], fill=(110, 106, 96), width=6)
    d.line([(90, 166), (130, 166)], fill=(110, 106, 96), width=6)
    save_icon(img, "nametag")


def icon_towel():
    img, d = icon_canvas()
    d.line([(56, 70), (200, 70)], fill=(150, 156, 170), width=8)
    d.rectangle([76, 76, 180, 200], fill=(120, 110, 118))
    d.polygon([(110, 130), (150, 140), (140, 180), (104, 168)], fill=(88, 36, 40))
    save_icon(img, "towel")


def icon_keys():
    img, d = icon_canvas()
    d.ellipse([88, 40, 168, 120], outline=(200, 200, 210), width=10)
    d.line([(110, 116), (80, 200)], fill=(220, 190, 120), width=12)
    d.line([(80, 200), (100, 206)], fill=(220, 190, 120), width=8)
    d.line([(92, 176), (112, 182)], fill=(220, 190, 120), width=8)
    d.line([(146, 116), (130, 190)], fill=(160, 164, 176), width=12)
    d.line([(160, 130), (196, 176)], fill=(120, 124, 136), width=6)  # 缺失的一把(虚位)
    save_icon(img, "keys")


def icon_puzzle():
    img, d = icon_canvas()
    d.rectangle([58, 68, 198, 188], fill=(210, 216, 224))
    d.line([(128, 68), (128, 188)], fill=(120, 124, 132), width=4)
    d.line([(58, 128), (198, 128)], fill=(120, 124, 132), width=4)
    d.polygon([(98, 176), (128, 108), (158, 176)], fill=(60, 66, 80))
    d.ellipse([118, 92, 138, 112], fill=(60, 66, 80))
    save_icon(img, "puzzle")


def icon_letter():
    img, d = icon_canvas()
    d.rectangle([52, 88, 204, 180], fill=PAPER)
    d.polygon([(52, 88), (128, 150), (204, 88)], outline=(150, 146, 136), width=0)
    d.line([(52, 88), (128, 150), (204, 88)], fill=(150, 146, 136), width=4)
    d.ellipse([112, 126, 144, 158], fill=RED)
    save_icon(img, "letter")


def icon_idcard():
    img, d = icon_canvas()
    d.rounded_rectangle([46, 76, 210, 180], 10, fill=(210, 214, 222))
    d.ellipse([66, 100, 106, 140], fill=(120, 130, 150))
    d.pieslice([60, 132, 112, 190], 180, 360, fill=(120, 130, 150))
    for i in range(3):
        d.line([(126, 104 + i * 22), (192, 104 + i * 22)], fill=(140, 144, 154), width=6)
    save_icon(img, "idcard")


def icon_photo():
    img, d = icon_canvas()
    d.rectangle([56, 66, 200, 190], fill=(214, 210, 198))
    d.rectangle([70, 80, 186, 160], fill=(90, 120, 150))
    d.polygon([(70, 160), (120, 104), (150, 160)], fill=(60, 80, 100))
    d.ellipse([150, 92, 170, 112], fill=WARM_SOFT)
    save_icon(img, "photo")


def icon_cup():
    img, d = icon_canvas()
    d.polygon([(76, 90), (170, 90), (160, 200), (86, 200)], fill=(210, 214, 222))
    d.arc([150, 110, 200, 160], -80, 80, fill=(210, 214, 222), width=10)
    save_icon(img, "cup")


def icon_pills():
    img, d = icon_canvas()
    d.rounded_rectangle([88, 60, 168, 200], 14, fill=(200, 206, 216))
    d.rectangle([88, 60, 168, 96], fill=(140, 60, 60))
    d.rectangle([100, 120, 156, 156], fill=PAPER)
    save_icon(img, "pills")


def icon_shirt():
    img, d = icon_canvas()
    d.polygon([(96, 66), (160, 66), (200, 100), (180, 130), (164, 116), (164, 200),
               (92, 200), (92, 116), (76, 130), (56, 100)], fill=(90, 100, 130))
    save_icon(img, "shirt")


def icon_plant():
    img, d = icon_canvas()
    d.polygon([(88, 140), (168, 140), (156, 210), (100, 210)], fill=(140, 90, 60))
    d.polygon([(128, 140), (96, 80), (120, 96), (128, 60), (138, 96), (162, 78)], fill=(70, 110, 80))
    save_icon(img, "plant")


def icon_racket():
    img, d = icon_canvas()
    d.ellipse([76, 44, 180, 160], outline=(170, 150, 110), width=10)
    for i in range(4):
        d.line([(92 + i * 22, 50), (92 + i * 22, 154)], fill=(150, 134, 100), width=2)
    d.line([(150, 150), (190, 214)], fill=(140, 100, 70), width=12)
    save_icon(img, "racket")


def icon_album():
    img, d = icon_canvas()
    d.rounded_rectangle([60, 70, 196, 196], 8, fill=(70, 80, 110))
    d.rectangle([76, 86, 180, 150], fill=(120, 140, 170))
    d.ellipse([150, 160, 176, 186], fill=WARM_SOFT)
    save_icon(img, "album")


def icon_calendar():
    img, d = icon_canvas()
    d.rectangle([62, 66, 194, 200], fill=PAPER)
    d.rectangle([62, 66, 194, 96], fill=(150, 60, 60))
    for i in range(3):
        for j in range(3):
            d.rectangle([78 + j * 36, 112 + i * 26, 100 + j * 36, 130 + i * 26], fill=(190, 186, 176))
    d.ellipse([114, 138, 140, 164], outline=RED, width=5)
    save_icon(img, "calendar")


def icon_umbrella():
    img, d = icon_canvas()
    d.pieslice([56, 60, 200, 204], 180, 360, fill=(80, 90, 120))
    d.line([(128, 132), (128, 210)], fill=(160, 164, 176), width=8)
    d.arc([112, 190, 144, 226], 0, 180, fill=(160, 164, 176), width=8)
    save_icon(img, "umbrella")


def icon_plate():
    img, d = icon_canvas()
    d.rounded_rectangle([66, 96, 190, 160], 8, fill=(70, 78, 108))
    d.line([(86, 128), (170, 128)], fill=(160, 166, 180), width=6)
    save_icon(img, "plate")


def icon_slippers():
    img, d = icon_canvas()
    d.rounded_rectangle([70, 90, 120, 200], 24, fill=(90, 98, 128))
    d.rounded_rectangle([136, 90, 186, 200], 24, fill=(90, 98, 128))
    d.arc([76, 110, 114, 150], 180, 360, fill=(60, 66, 90), width=8)
    d.arc([142, 110, 180, 150], 180, 360, fill=(60, 66, 90), width=8)
    save_icon(img, "slippers")


def icon_bowl():
    img, d = icon_canvas()
    d.pieslice([66, 90, 190, 220], 0, 180, fill=(210, 214, 222))
    d.ellipse([66, 80, 190, 120], fill=(240, 242, 246))
    save_icon(img, "bowl")


def icon_map():
    img, d = icon_canvas()
    d.polygon([(56, 80), (112, 64), (160, 80), (200, 64), (200, 176), (160, 192), (112, 176), (56, 192)], fill=(200, 196, 180))
    d.line([(112, 64), (112, 176)], fill=(150, 146, 132), width=3)
    d.line([(160, 80), (160, 192)], fill=(150, 146, 132), width=3)
    d.ellipse([120, 110, 144, 134], fill=RED)
    save_icon(img, "map")


def icon_string():
    img, d = icon_canvas()
    d.ellipse([66, 66, 190, 190], outline=RED, width=10)
    d.ellipse([96, 96, 160, 160], outline=(140, 48, 56), width=8)
    save_icon(img, "string")


def icon_charger():
    img, d = icon_canvas()
    d.rectangle([96, 60, 160, 120], fill=(200, 204, 212))
    d.line([(112, 60), (112, 40)], fill=(200, 204, 212), width=8)
    d.line([(144, 60), (144, 40)], fill=(200, 204, 212), width=8)
    d.arc([80, 120, 200, 220], 20, 160, fill=(160, 164, 176), width=8)
    save_icon(img, "charger")


def icon_drawer():
    img, d = icon_canvas()
    d.rectangle([66, 60, 190, 200], fill=(80, 64, 48))
    d.rectangle([78, 76, 178, 120], fill=(50, 38, 28))
    d.rectangle([78, 132, 178, 186], fill=(96, 78, 58))
    d.ellipse([120, 152, 136, 168], fill=(200, 190, 160))
    save_icon(img, "drawer")


ICONS = [icon_note, icon_access, icon_wristband, icon_receipt, icon_walkie, icon_diary,
         icon_browser, icon_nametag, icon_towel, icon_keys, icon_puzzle, icon_letter,
         icon_idcard, icon_photo, icon_cup, icon_pills, icon_shirt, icon_plant,
         icon_racket, icon_album, icon_calendar, icon_umbrella, icon_plate,
         icon_slippers, icon_bowl, icon_map, icon_string, icon_charger, icon_drawer]


def character():
    """林晚音背影剪影 600x1400 透明底"""
    img = Image.new("RGBA", (600, 1400), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    c = (10, 12, 22, 255)
    d.ellipse([230, 90, 370, 250], fill=c)                 # 头
    d.pieslice([210, 60, 390, 300], 180, 360, fill=c)      # 头发
    d.ellipse([300, 40, 380, 130], fill=c)                 # 发髻
    d.rectangle([270, 240, 330, 320], fill=c)              # 颈
    d.polygon([(160, 340), (440, 340), (480, 900), (120, 900)], fill=c)   # 大衣
    d.polygon([(160, 340), (120, 900), (90, 900), (130, 360)], fill=c)    # 左臂
    d.polygon([(440, 340), (480, 900), (510, 900), (470, 360)], fill=c)   # 右臂
    d.polygon([(200, 900), (400, 900), (420, 1350), (180, 1350)], fill=c) # 下摆
    d.rectangle([220, 1350, 280, 1400], fill=c)
    d.rectangle([320, 1350, 380, 1400], fill=c)
    # 暖色轮廓光(右侧)
    rim = Image.new("RGBA", (600, 1400), (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    rd.arc([230, 90, 370, 250], -60, 80, fill=(255, 200, 120, 220), width=6)
    rd.line([(440, 360), (478, 880)], fill=(255, 200, 120, 200), width=6)
    rd.line([(400, 920), (418, 1330)], fill=(255, 200, 120, 160), width=5)
    img = Image.alpha_composite(img, rim)
    path = os.path.join(ROOT, "characters", "lin_silhouette.png")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("character: lin_silhouette.png")


def app_icon():
    img = Image.new("RGB", (512, 512), NIGHT_TOP)
    d = ImageDraw.Draw(img)
    add_glow(img, 256, 256, 240, WARM, 0.8)
    d.polygon([(216, 420), (296, 420), (420, 512), (92, 512)], fill=(240, 220, 180))
    d.rectangle([196, 120, 316, 430], fill=(24, 28, 46))
    d.polygon([(226, 140), (256, 150), (256, 420), (226, 420)], fill=(8, 9, 16))
    d.polygon([(256, 150), (300, 140), (300, 420), (256, 420)], fill=(252, 240, 210))
    path = os.path.join(ROOT, "..", "icon.png")
    img.save(path)
    print("app icon: icon.png")


if __name__ == "__main__":
    for f in [level_01, level_02, level_03, level_04, level_05, level_06,
              level_07, level_08, level_09, level_10, level_11, level_12,
              menu_bg, ending_bg]:
        f()
    for f in ICONS:
        f()
    character()
    app_icon()
    print("DONE")
