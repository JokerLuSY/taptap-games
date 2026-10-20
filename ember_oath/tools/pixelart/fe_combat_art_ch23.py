"""第三篇新角色的战斗特写数据（原创）。骨架都复用已有几套，头部逐像素手画、配色各自定。

奥瑞恩：弓手骨架。金头带、灰发、白胡子，深绿斗篷。
欧文：魔道士骨架（举书吟唱）。不戴兜帽，金冠、浅金长发，白法袍配金边蓝衬，金色魔导书。
莉莉丝：魔道士骨架。灰白长发、苍白皮肤、红眼，深紫长袍、暗色魔导书。
罗兰：艾德里克的剑士骨架（带披风）。棕发、胡茬，钢胸甲，红披风。
七号：灰烬傀儡骨架（短剑爪刃）。不戴兜帽，灰白短发、黑色高领。
莫尔甘：魔道士骨架。白金高冠、白发白须，紫法袍配白色圣带。
炎龙：骑马骨架换成红鳞炎龙（马身改色、金角、火色鬃尾）+ 一对龙翼，背上是莫尔甘。
"""
from fe_combat_art import pal, ARCHER, HORSE
from fe_combat_art_classes import MAGE
from fe_combat_art_ch2 import EDRIC, KNIGHT
from fe_combat_art_ch8 import PUPPET, WING

# ============================================================
ORION = dict(ARCHER)
ORION.update({
    "pal": pal(
        K=(32, 28, 28),
        H=(176, 176, 180), h=(118, 118, 126), V=(228, 228, 232), G=(232, 188, 72),
        O=(72, 104, 72), o=(48, 72, 48),
        S=(232, 192, 156), s=(190, 140, 108), E=(40, 40, 48), W=(248, 248, 248),
        T=(84, 116, 80), t=(56, 80, 54),
        B=(104, 76, 56), b=(64, 46, 36),
    ),
    "head": [
        "......KKKKKK......",
        "....KKHHHHHHKK....",
        "...KHHHHHHHHHHK...",
        "..KhHHHHHHHHHHHK..",
        ".KhhGGGGGGGGGGGK..",
        ".KhhHHHhSSSSSSHK..",
        ".KhHHHhSSSSKKSSK..",
        ".KhHHhSSSSKWEKSK..",
        ".KhHHhSSSSSKEKSK..",
        ".KhhHhSSSSSSSSSK..",
        "..KhHhVVSSSVVVsK..",
        "...KhVVVVVVVVVK...",
        "....KVVVVVVVVK....",
        ".....KVVVVVVK.....",
        "......KKKKKK......",
    ],
})

# ============================================================
_LONG_HAIR_CROWN = [
    "......KKKKKK......",
    "....KKHHHHHHKK....",
    "...KHHHHHHHHHHK...",
    "..KhHHHHHHHHHHHK..",
]

OWEN = dict(MAGE)
OWEN.update({
    "pal": pal(
        K=(36, 32, 40),
        H=(236, 224, 180), h=(184, 168, 120), G=(232, 188, 72),
        W=(248, 248, 248), w=(196, 188, 176),
        S=(244, 212, 180), s=(204, 160, 128), E=(52, 72, 120),
        T=(240, 236, 228), t=(196, 188, 176),
        R=(224, 184, 72), r=(160, 120, 40),
        C=(96, 124, 200), c=(64, 86, 150),
        B=(96, 80, 72), b=(60, 50, 46),
        tome=(232, 188, 72), tome_d=(160, 120, 40), page=(250, 244, 220),
    ),
    "head": _LONG_HAIR_CROWN + [
        ".KhhGGGGGGGGGGGK..",
        ".KhhHHHhSSSSSSHK..",
        ".KhHHHhSSSSKKSSK..",
        ".KhHHhSSSSKWEKSK..",
        ".KhHHhSSSSSKEKSK..",
        ".KhhHhSSSSSSSSSK..",
        ".KhhHHhSSSSSSsK...",
        ".KhhhHHhSSSsKK....",
        "..KhhhHHKKKK......",
        "...KhhhHK.........",
        "....KKhhK.........",
        "......KK..........",
    ],
})

LILITH = dict(MAGE)
LILITH.update({
    "pal": pal(
        K=(32, 26, 40),
        H=(216, 216, 226), h=(150, 150, 170),
        W=(248, 248, 248), w=(170, 166, 180),
        S=(240, 222, 214), s=(200, 180, 176), E=(200, 40, 60),
        T=(76, 58, 100), t=(48, 38, 68),
        R=(150, 146, 158), r=(100, 96, 110),
        C=(100, 84, 124), c=(66, 54, 88),
        B=(70, 58, 80), b=(44, 36, 52),
        tome=(64, 40, 88), tome_d=(36, 24, 52), page=(220, 210, 230),
    ),
    "head": _LONG_HAIR_CROWN + [
        ".KhhHHHHHHHHHHHK..",
        ".KhhHHHhHHHHHHHHK.",
        ".KhHHHhSSSSSSHHK..",
        ".KhHHhSSSSKKSSHK..",
        ".KhHhSSSSKWEKSHK..",
        ".KhHhSSSSSKEKSHK..",
        ".KhhHSSSSSSSSHHK..",
        ".KhhHHSSSSSSsHK...",
        ".KhhHHHhSSSsHK....",
        ".KhhhHHHKKKHK.....",
        "..KhhhHHHhK.......",
        "...KKhhhhK........",
        ".....KKKK.........",
    ],
})

# ============================================================
ROLAND = dict(EDRIC)
ROLAND.update({
    "reach": 130,
    "pal": {**EDRIC["pal"], **pal(
        K=(30, 24, 28),
        H=(120, 80, 48), h=(80, 52, 30), L=(170, 118, 72),
        S=(232, 190, 150), s=(190, 140, 104), E=(44, 32, 28),
        D=(168, 40, 44), d=(104, 24, 30),
        T=(120, 84, 60), t=(80, 54, 40), A=(120, 84, 60), a=(80, 54, 40),
    )},
    "head": [
        "..................",
        "....KKKK.KKKK.....",
        "...KHHHHKHHHHKK...",
        "..KHHLHHHHLHHHHK..",
        ".KhHHHHHHHHHHHHK..",
        "KhhHHHHHHHHHHHHK..",
        "KhHHHhSSSSSSHHSK..",
        "KhHHhSSSSSKKSSSK..",
        "KhHhSSSSSKWEKSSK..",
        ".KhhSSSSSSKEKSSK..",
        ".KhSSSSSSSSSSSSK..",
        "..KhsSSssSSSsSK...",
        "..KhhsssssssssK...",
        "...KKsSSSSSsKK....",
        ".....KKKKKKK......",
    ],
})

# ============================================================
SEVEN = dict(PUPPET)
SEVEN.update({
    "pal": {**PUPPET["pal"], **pal(
        K=(24, 20, 28),
        H=(184, 180, 186), h=(124, 120, 130),
        S=(234, 226, 222), s=(192, 182, 182), E=(110, 112, 136), W=(250, 250, 250),
        V=(54, 50, 62), v=(32, 30, 40),
        blade=(150, 146, 156), blade_d=(90, 86, 96),
    )},
    "head": [
        ".......KKKKK.......",
        ".....KKHHHHHKK.....",
        "....KHHHHHHHHHK....",
        "...KHHHHHHHHHHHK...",
        "..KhHHHHHHHHHHHHK..",
        "..KhHHHhhHHHHHHHK..",
        "..KhHHhSSSSSSSHHK..",
        "..KhHhSSSSKKSSSHK..",
        "..KhHhSSSKWEKSSHK..",
        "..KhhhSSSSKEKSSHK..",
        "..KhhhSSSSSSSSsHK..",
        "...KhhKsSSSSSsKK...",
        "....KKKKssssKK.....",
        "......KVVVVVK......",
        ".......KKKKK.......",
    ],
})

# ============================================================
_MORGAN_HEAD = [
    "........KK........",
    ".......KWWK.......",
    "......KWWGWK......",
    ".....KWWWGWWK.....",
    "....KWWWWGWWWK....",
    "...KGGGGGGGGGGK...",
    "..KhHHHHSSSSSSHK..",
    ".KhHHHHSSSSKKSSK..",
    ".KhHHHSSSSKWEKSK..",
    ".KhHHHSSSSSKEKSK..",
    ".KhHHVVSSSSSSSSK..",
    "..KhVVVVSSSVVVK...",
    "...KVVVVVVVVVK....",
    "....KVVVVVVVK.....",
    ".....KKVVVVKK.....",
    ".......KKKK.......",
]
_MORGAN_PAL = dict(
    K=(32, 24, 40),
    H=(232, 232, 238), h=(172, 172, 184), V=(240, 240, 244), G=(232, 188, 72),
    W=(246, 242, 234), w=(196, 190, 184),
    S=(236, 210, 190), s=(196, 164, 146), E=(150, 90, 210),
)
MORGAN = dict(MAGE)
MORGAN.update({
    "pal": pal(
        **_MORGAN_PAL,
        T=(110, 72, 150), t=(72, 46, 104),
        R=(232, 188, 72), r=(160, 120, 40),
        C=(240, 236, 228), c=(196, 188, 176),
        B=(80, 60, 90), b=(50, 38, 60),
        tome=(232, 188, 72), tome_d=(160, 120, 40), page=(250, 244, 220),
    ),
    "head": _MORGAN_HEAD,
})

# ============================================================
# 炎龙：马的轮廓换红鳞配色，耳朵改成金角；翅膀用天马那张翅膀换成龙翼的火红色
_HORNED = []
for y, row in enumerate(HORSE):
    row = "".join({"T": "R", "t": "r"}.get(c, c) for c in row)        # 马衣 → 深红鳞片
    if y <= 3:
        row = "".join("g" if (c == "Q" and x >= 48) else c for x, c in enumerate(row))
    _HORNED.append(row)


def _upscale(rows, k=1.5):
    """最近邻放大字符画（龙翼比天马的翅膀大一圈）"""
    h, w = len(rows), len(rows[0])
    H, W = int(h * k), int(w * k)
    return ["".join(rows[min(h - 1, int(y / k))][min(w - 1, int(x / k))] for x in range(W)) for y in range(H)]


DRAGON_WING = _upscale(["".join({"W": "F", "w": "f"}.get(c, c) for c in row) for row in WING], 1.3)

DRAGON = dict(KNIGHT)
DRAGON.update({
    "reach": 170,
    "pal": pal(
        **_MORGAN_PAL,
        M=(240, 236, 228), m=(180, 172, 168),
        T=(110, 72, 150), t=(72, 46, 104), R=(150, 40, 36), r=(100, 24, 28),
        Q=(204, 66, 48), q=(140, 36, 32), Z=(250, 180, 64),
        F=(226, 84, 56), f=(150, 44, 36),
        B=(80, 60, 90), b=(50, 38, 60), g=(244, 200, 80),
        tome=(232, 188, 72), tome_d=(160, 120, 40), page=(250, 244, 220),
    ),
    "head": _MORGAN_HEAD,
    "mount": {"art": _HORNED, "attach": KNIGHT["mount"]["attach"], "wings": DRAGON_WING, "wing_at": (-4, -15)},
    "weapon": {"type": "tome"},
})

UNITS_CH23 = {
    "orion": ORION,
    "owen": OWEN,
    "lilith": LILITH,
    "roland": ROLAND,
    "seven": SEVEN,
    "morgan": MORGAN,
    "dragon": DRAGON,
}
