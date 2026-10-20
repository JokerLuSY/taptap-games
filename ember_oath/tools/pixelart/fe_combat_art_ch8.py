"""第二篇新角色 / 新兵种的战斗特写数据（原创）。

加雷斯：布罗登王子，重甲 + 家传战斧（山贼 / 哈洛的斧骨架，配重甲躯干和短披风）。
灰烬傀儡：灰白皮肤、兜帽、发光的眼，手上是灰烬凝成的爪刃（探子那套短剑骨架）。
天马骑士：骑马骑士的骨架和马，换成白马 + 一对向后上方扬起的翅膀，骑手戴轻盔。
"""
from fe_combat_art import pal, shift_all, SCOUT_POSES, SCOUT_ANIMS, SWORD_BODY, AXE_BODY, AXE_LIMBS, HORSE, HORSE_ATTACH, BALTO
from fe_combat_art import AXE_ANIMS
from fe_combat_art_ch2 import HARLO_POSES, KNIGHT, ANIM_IDLE, ANIM_RUN, ANIM_HIT, ANIM_DEATH

# ============================================================
# 加雷斯
# ============================================================
GARETH = {
    "reach": 125,
    "frame": (80, 88), "foot": (40, 84), "scale": 3,
    "pal": pal(
        K=(32, 24, 28),
        S=(236, 192, 150), s=(192, 136, 98), E=(40, 28, 24), W=(248, 248, 248),
        H=(150, 84, 44), h=(98, 52, 28), L=(200, 128, 72),
        M=(176, 184, 200), m=(108, 116, 140), x=(236, 240, 248),
        T=(52, 108, 72), t=(32, 70, 48),
        B=(110, 76, 50), b=(70, 48, 32),
    ),
    "head": [
        "..................",
        "....KKK.KKKK......",
        "...KHHHKHHHHKK....",
        "..KHHLHHHHLHHHK...",
        ".KhHHHHHHHHHHHHK..",
        "KhhGGGGGGGGGGGGK..",
        "KhHHHhSSSSSSHHSK..",
        "KhHHhSSSSSKKSSSK..",
        "KhHhSSSSSKWEKSSK..",
        ".KhhSSSSSSKEKSSK..",
        ".KhSSSSSSSSSSSSK..",
        "..KhsSSSSSSSHSK...",
        "..KhhHHsSSSHHHK...",
        "...KKhHHHHHHKK....",
        ".....KKKKKKK......",
    ],
    "torso": [
        "..KKKKKKKKKKKK..",
        ".KxMMMMMMMMMMxK.",
        "KxMMMMMMMMMMMMmK",
        "KmMMTTTTTTTTMMmK",
        "KmKMTTTGGTTTMKmK",
        ".KMMTTGGGGTTMMK.",
        ".KMMTTTGGTTTMMK.",
        ".KmMTTTTTTTTMmK.",
        ".KmMtTTTTTTtMmK.",
        "..KmMMMMMMMMmK..",
        "..KBBBBGGBBBBK..",
        "..KbbbbbbbbbbK..",
        "..KMMMMMMMMMMK..",
        "..KmmmmmmmmmmK..",
        "..KKKKKKKKKKKK..",
    ],
    "body": {**AXE_BODY, "head": (-1, -13)},
    "limbs": {
        "arm_b": ("m", "m", 2.8), "fore_b": ("m", "m", 2.4), "arm_f": ("M", "m", 2.8), "fore_f": ("M", "m", 2.4),
        "thigh_b": ("m", "m", 3.0), "shin_b": ("m", "m", 2.7), "thigh_f": ("M", "m", 3.0), "shin_f": ("M", "m", 2.7),
    },
    "weapon": {"type": "axe", "length": 26, "head": 1.15},
    "poses": shift_all(HARLO_POSES, 12),
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": AXE_ANIMS["attack"],
        "crit": {"frames": ["wind", "wind", "wind", "dash", "slash", "slash", "follow", "wind", "dash", "slash", "slash", "follow"], "fps": 12, "impact": 5},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}

# ============================================================
# 灰烬傀儡
# ============================================================
PUPPET = {
    "reach": 112,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(24, 20, 28),
        H=(84, 78, 92), h=(54, 50, 62),
        S=(196, 192, 188), s=(146, 140, 140), E=(255, 140, 60), W=(255, 220, 120),
        V=(72, 66, 80), v=(44, 40, 52),
        T=(110, 104, 116), t=(72, 68, 80),
        B=(60, 54, 62), b=(36, 32, 40),
        blade=(120, 116, 124), blade_d=(70, 66, 74), grip=(60, 54, 62), grip_d=(36, 32, 40),
    ),
    "head": [
        ".......KKKKK.......",
        ".....KKHHHHHKK.....",
        "....KHHHHHHHHHK....",
        "...KHHHHHHHHHHHK...",
        "..KhHHHHHHHHHHHHK..",
        "..KhHHKKKKKKKKHHK..",
        "..KhHKSSSSSSSSKHK..",
        "..KhHKSSSSKKSSKHK..",
        "..KhHKSSSKWEKSKHK..",
        "..KhhKSSSSKKSSKHK..",
        "...KhKsSSSSSSsKK...",
        "....KhKssSSssKK....",
        ".....KKKKssKKK.....",
        ".......KKKK........",
    ],
    "torso": [
        "...KKKKKKK....",
        "..KVVVVVVVKK..",
        ".KvVVVVVVVVVK.",
        "KVvvVVVVVVvvVK",
        "KVKvvvvvvvvKVK",
        "KvVVKSSSKVVVvK",
        "KvVVVKSKVVVVvK",
        "KvVVVVVVVVVVvK",
        ".KvVVVVVVVVvK.",
        ".KvVVVVVVVVvK.",
        ".KvvVVVVVVvvK.",
        "..KbbbbbbbbbK.",
        "..KKKKKKKKKKK.",
    ],
    "skirt": [
        ".KvVVVVVVVVVVvK.",
        "KvvVVVVVVVVVVvvK",
        "KvVVVvVVVVvVVVvK",
        "KvVVvKVVVvKVVVvK",
        ".KvK..KvK..KvK..",
        "..K....K....K...",
    ],
    "body": {**SWORD_BODY, "head": (-4, -13)},
    "limbs": {
        "arm_b": ("s", "s", 1.7), "fore_b": ("s", "s", 1.4), "arm_f": ("S", "s", 1.7), "fore_f": ("S", "s", 1.4),
        "thigh_b": ("b", "b", 2.1), "shin_b": ("b", "b", 1.9), "thigh_f": ("b", "b", 2.1), "shin_f": ("B", "b", 1.9),
    },
    "weapon": {"type": "sword", "length": 12},
    "poses": SCOUT_POSES,
    "anims": SCOUT_ANIMS,
}

# ============================================================
# 天马骑士
# ============================================================
WING = [
    "KK............................",
    "KWKK..........................",
    "KWWWKK........................",
    ".KWWWWKK......................",
    ".KwWWWWWKK....................",
    "..KwWWWWWWKK..................",
    "..KwwWWWWWWWKK................",
    "...KwWWWWWWWWWKK..............",
    "...KwwWWWWWWWWWWKK............",
    "....KwwWWWWWWWWWWWKK..........",
    "....KKwwWWWWWWWWWWWWKK........",
    "...KWWKwwWWWWWWWWWWWWWKK......",
    "...KwWWKwwwWWWWWWWWWWWWWKK....",
    "....KwWWKKwwwWWWWWWWWWWWWWK...",
    ".....KwwWWKKwwwwWWWWWWWWWWWK..",
    "......KwwWWWKKwwwwwWWWWWWWWWK.",
    ".......KKwwWWWKKKwwwwwwWWWWWK.",
    ".........KKwwwWWWKKKwwwwwwwwK.",
    "...........KKwwwwWWWKKKKwwwwK.",
    ".............KKKwwwwwwWWWWKKK.",
    "................KKKKwwwwwwwwK.",
    "....................KKKKKKKKK.",
]


def _horse_recolor(table):
    return ["".join(table.get(c, c) for c in row) for row in HORSE]


# 白马：马衣换成天蓝（T/t → R/r），鬃毛尾巴 Z 用浅金
HORSE_PEGASUS = _horse_recolor({"T": "R", "t": "r"})

PEGASUS = dict(KNIGHT)
PEGASUS.update({
    "reach": 175,
    "frame": (124, 96), "foot": (54, 92), "scale": 3,
    "pal": pal(
        K=(32, 28, 44),
        M=(224, 228, 240), m=(150, 156, 180),
        W=(252, 252, 252), w=(196, 200, 220),
        T=(72, 132, 208), t=(44, 88, 160), R=(96, 160, 224), r=(56, 108, 180),
        S=(244, 206, 170), s=(206, 152, 116), E=(40, 40, 72),
        Q=(248, 248, 252), q=(196, 200, 216), Z=(236, 216, 150),
        B=(96, 80, 72), b=(60, 48, 44),
        H=(236, 196, 104), h=(176, 132, 60),
        g=(248, 208, 80),
    ),
    "head": [
        "......KKKKKK......",
        "....KKMMMMMMKK....",
        "...KMMMMMMMMMMK...",
        "..KmMMMMMMMMMMMK..",
        ".KmMMMMMMMMMMMMK..",
        ".KmMMMMKKKKKKKMK..",
        ".KHMMMKSSSKWEKMK..",
        ".KHHMMKSSSSKEKMK..",
        ".KhHHMMKSSSSSSMK..",
        ".KhHHHMMKSSSSMK...",
        ".KhhHHHHKKKKKK....",
        "..KhhHHHK.........",
        "...KKhhK..........",
        ".....KK...........",
    ],
    "mount": {"art": HORSE_PEGASUS, "attach": HORSE_ATTACH, "wings": WING, "wing_at": (6, -12)},
    "weapon": {"type": "lance", "length": 38, "butt": 12},
})

UNITS_CH8 = {
    "gareth": GARETH,
    "puppet": PUPPET,
    "pegasus": PEGASUS,
}
