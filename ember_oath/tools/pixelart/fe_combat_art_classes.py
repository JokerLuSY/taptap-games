"""通用职业的战斗特写数据（原创）：魔道士。骨架用诺雅那套施法姿势，手里换成魔导书（tome）。

普攻 = 举书吟唱、前推放出火焰；必杀 = 吟唱更久（画面上加压暗和大火柱）。
"""
from fe_combat_art import pal, SWORD_BODY  # noqa: F401
from fe_combat_art_ch2 import STAFF_POSES, ANIM_IDLE, ANIM_RUN, ANIM_HIT, ANIM_DEATH

MAGE = {
    "reach": 140,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(40, 28, 32),
        W=(244, 236, 216), w=(196, 184, 160),
        S=(248, 216, 184), s=(212, 168, 136), E=(64, 40, 40),
        T=(232, 224, 200), t=(184, 168, 136),
        R=(184, 48, 48), r=(128, 32, 40),
        C=(240, 236, 224), c=(192, 184, 168),
        B=(96, 72, 64), b=(60, 44, 40),
        tome=(176, 48, 48), tome_d=(112, 28, 36), page=(248, 240, 216),
    ),
    "head": [
        "......KKKKKK......",
        "....KKWWWWWWKK....",
        "...KWWWWWWWWWWK...",
        "..KwWWWWWWWWWWWK..",
        ".KwwWWWWWWWWWWWK..",
        ".KwwWWRRRRRRRRRK..",
        ".KwWWRSSSSSSSSSK..",
        ".KwWWRSSSSSKKSSK..",
        ".KwWWRSSSSKWEKSK..",
        ".KwWWRSSSSSKEKSK..",
        ".KwwWRSSSSSSSSSK..",
        ".KwwWWRSSSSSSsK...",
        ".KwwwWWRSSSsKK....",
        "..KwwwWWRKKK......",
        "...KKwwwWK........",
        ".....KKKK.........",
    ],
    "torso": [
        "...KKKKKKK....",
        "..KCCCCCCCKK..",
        ".KcCCCCCCCCCK.",
        "KTccCCCCCCCcK.",
        "KTKccccCCccKTK",
        "KTTTKccccKTTTK",
        "KtTTTKKKKTTTtK",
        "KtTTTTRRTTTTtK",
        ".KtTTTRRTTTtK.",
        ".KtTTTRRTTTtK.",
        ".KttTTRRTTttK.",
        "..KTTTTTTTTK..",
        "..KKKKKKKKKK..",
    ],
    "skirt": [
        "...KtTTTTTTTTTTtK...",
        "...KttTTTTRRTTTttK..",
        "..KtTTTTTTRRTTTTtK..",
        "..KtTTTtTTRRTTTTtK..",
        "..KtTTTtTTRRTtTTtK..",
        "..KtTTtTTTRRTtTTTK..",
        ".KtTTTtTTTRRTtTTTtK.",
        ".KtTTtTTTTRRTTtTTtK.",
        ".KtTTtTTTTRRTTtTTTK.",
        ".KtTTtTTTTRRTTtTTTtK",
        "KttTtTTTTTRRTTtTTTtK",
        "KtTTtTTTTTRRTTTtTTtK",
        "KtTtTTTTTTRRTTTtTTtK",
        "KRRRRRRRRRRRRRRRRRRK",
        "KKKKKKKKKKKKKKKKKKKK",
    ],
    "body": {**SWORD_BODY, "head": (-4, -15), "skirt": (-3, 11)},
    "limbs": {
        "arm_b": ("t", "t", 2.0), "fore_b": ("s", "s", 1.6), "arm_f": ("T", "t", 2.0), "fore_f": ("S", "s", 1.6),
        "thigh_b": ("b", "b", 2.3), "shin_b": ("b", "b", 2.1), "thigh_f": ("b", "b", 2.3), "shin_f": ("B", "b", 2.1),
    },
    "weapon": {"type": "tome"},
    "poses": STAFF_POSES,
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": {"frames": ["idle0", "raise", "raise", "cast", "cast", "cast", "raise"], "fps": 9, "impact": 3},
        "crit": {"frames": ["idle0", "raise", "raise", "raise", "raise", "cast", "cast", "cast", "raise"], "fps": 9, "impact": 5},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}

UNITS_CLASSES = {
    "mage": MAGE,
}
