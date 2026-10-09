# -*- coding: utf-8 -*-
"""《见缝插针》TapTap 封面 1920x1080: 星空 + 发光轮盘 + 标题"""
import math
import os
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

random.seed(99)
ROOT = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "pin_circle", "docs")
W, H = 1920, 1080
CYAN = (60, 220, 255)
ORANGE = (255, 184, 77)

img = Image.new("RGB", (W, H))
d = ImageDraw.Draw(img)
for y in range(H):
    t = y / H
    d.line([(0, y), (W, y)], fill=(int(8 + 16 * t), int(10 + 18 * t), int(26 + 34 * t)))
for _ in range(160):
    x, y = random.randint(0, W), random.randint(0, H)
    r = random.uniform(1, 3)
    a = random.randint(80, 200)
    d.ellipse([x - r, y - r, x + r, y + r], fill=(a, int(a * 1.05), 255))

# 轮盘(右半部分)
cx, cy, R = 1330, 540, 330
glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
for i in range(6):
    gd.ellipse([cx - R - 90 + i * 16, cy - R - 90 + i * 16, cx + R + 90 - i * 16, cy + R + 90 - i * 16],
               outline=CYAN + (26,), width=40)
glow = glow.filter(ImageFilter.GaussianBlur(30))
img.paste(Image.new("RGB", (W, H), (0, 0, 0)), (0, 0), glow)
d = ImageDraw.Draw(img)
# 盘面
for i in range(24, 0, -1):
    t = i / 24
    c = tuple(int(CYAN[k] * 0.45 * t + 10 * (1 - t)) for k in range(3))
    d.ellipse([cx - R * t, cy - R * t, cx + R * t, cy + R * t], fill=c)
d.ellipse([cx - R, cy - R, cx + R, cy + R], outline=CYAN, width=14)
# 针
for deg in [15, 70, 130, 200, 250, 300]:
    a = math.radians(deg)
    x0, y0 = cx + math.cos(a) * (R - 16), cy + math.sin(a) * (R - 16)
    x1, y1 = cx + math.cos(a) * (R + 96), cy + math.sin(a) * (R + 96)
    d.line([(x0, y0), (x1, y1)], fill=ORANGE, width=10)
    d.ellipse([x1 - 24, y1 - 24, x1 + 24, y1 + 24], fill=ORANGE)
    d.ellipse([x1 - 16, y1 - 20, x1 - 4, y1 - 8], fill=(255, 240, 220))
# 中央数字
font_big = ImageFont.truetype("C:/Windows/Fonts/msyhbd.ttc", 180)
d.text((cx, cy), "7", font=font_big, fill=(240, 246, 255), anchor="mm")

# 标题(左侧)
font_title = ImageFont.truetype("C:/Windows/Fonts/msyhbd.ttc", 230)
font_sub = ImageFont.truetype("C:/Windows/Fonts/msyh.ttc", 56)
d.text((120, 330), "见缝插针", font=font_title, fill=(240, 248, 255))
d.text((126, 600), "点击 · 旋转 · 别碰到其他针", font=font_sub, fill=(150, 170, 200))
d.line([(126, 700), (700, 700)], fill=CYAN, width=4)

os.makedirs(ROOT, exist_ok=True)
img.save(os.path.join(ROOT, "cover_1920x1080.png"))
print("cover saved")
