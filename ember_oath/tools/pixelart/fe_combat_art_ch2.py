"""第 2–5 章新角色的战斗特写数据（原创）。结构同 fe_combat_art.py，骨架姿势尽量复用第一章那几套。

新增的部件：cape（艾德里克的披风，最先画）、shield（巴雷特的大盾，挂在后手）、staff 武器（诺雅的治疗杖）。
"""
from fe_combat_art import (  # noqa: F401
    P, pal, shift_all,
    SWORD_POSES, SWORD_ANIMS, SWORD_BODY,
    AXE_POSES, AXE_ANIMS, AXE_BODY, AXE_LIMBS,
    BOW_POSES, BOW_ANIMS,
    HORSE, HORSE_ATTACH, _horse_pose, HX, HY, STAND, GALLOP0, GALLOP1, RIDER,
    TIA, ARCHER, SCOUT, BALTO,
)

ANIM_IDLE = {"frames": ["idle0", "idle0", "idle1", "idle1"], "fps": 4}
ANIM_RUN = {"frames": ["run0", "run1", "run0", "run1"], "fps": 10}
ANIM_HIT = {"frames": ["hit", "hit", "idle0"], "fps": 8}
ANIM_DEATH = {"frames": ["hit", "kneel", "kneel", "kneel"], "fps": 5}

# ============================================================
# 哈洛：柴斧少年（同山贼骨架）。普攻 = 劈；必杀 = 连劈两斧
# ============================================================
# 少年拿斧不扛肩：待机 / 跑步时斧头斜举在身前
HARLO_POSES = dict(AXE_POSES)
HARLO_POSES.update({
    "idle0": P((30, 36), (30, 46), (34, 50), (42, 45), (47, 48), (33, 57), (29, 71), (44, 57), (48, 71), wpn=-58),
    "idle1": P((30, 37), (30, 47), (34, 51), (42, 46), (47, 49), (33, 58), (29, 71), (44, 58), (48, 71), wpn=-56),
    "run0": P((34, 37), (30, 46), (27, 51), (45, 45), (50, 47), (32, 58), (22, 69), (48, 57), (54, 70), wpn=-48, head_dx=1),
    "run1": P((34, 36), (32, 46), (31, 51), (44, 44), (49, 46), (36, 58), (34, 71), (42, 57), (46, 68), wpn=-45, head_dx=1),
})
HARLO = {
    "reach": 118,
    "frame": (80, 88), "foot": (40, 84), "scale": 3,
    "pal": pal(
        K=(36, 24, 28),
        S=(240, 196, 152), s=(196, 140, 100), E=(40, 28, 24), W=(248, 248, 248),
        H=(160, 96, 48), h=(104, 56, 32), L=(208, 144, 80),
        T=(88, 136, 200), t=(56, 88, 152),
        B=(128, 88, 56), b=(80, 56, 36),
        P=(112, 96, 80), p=(76, 64, 56),
    ),
    "head": [
        "....K..K..K.......",
        "...KHK.KHKKHK.....",
        "..KHLHKHHHKHHK....",
        ".KhHHHHHLHHHHHK...",
        "KhhHHHHHHHHHHHHK..",
        "KhhHHHhHHHHHHHHHK.",
        ".KhHHhSSSSSHHSSHK.",
        ".KhHhSSSSSSSSSSSK.",
        "..KhSSSSSSKKSSSSK.",
        "..KhSSSSSKWEKSSSK.",
        "..KhSSSSSSKEKSSsK.",
        "..KhsSSSSSSSSSSK..",
        "...KhsSSSSSSSKSK..",
        "....KsSSSSSSsK....",
        ".....KKssssKK.....",
        ".......KKKK.......",
    ],
    "torso": [
        "....KKKKKKKK....",
        "..KKTTTSSTTTKK..",
        ".KtTTTTSsTTTTtK.",
        "KtTBTTTTTTTTTTtK",
        "KtTTBTTTTTTTTTtK",
        "KtTTTBTTTTTTTTtK",
        ".KtTTTBTTTTTTtK.",
        ".KttTTTBTTTTttK.",
        ".KtttTTTBTTtttK.",
        "..KttTTTTBTttK..",
        "..KBBBBGGBBBBK..",
        "..KbbbbbbbbbbK..",
        "..KPPPPPPPPPPK..",
        "..KKKKKKKKKKKK..",
    ],
    "body": AXE_BODY,
    "limbs": {**AXE_LIMBS, "arm_b": ("t", "t", 2.5), "arm_f": ("T", "t", 2.5)},
    "weapon": {"type": "axe", "length": 22, "head": 0.85},
    "poses": shift_all(HARLO_POSES, 12),
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": AXE_ANIMS["attack"],
        "crit": {"frames": ["wind", "wind", "dash", "slash", "follow", "wind", "dash", "slash", "slash", "follow"], "fps": 13, "impact": 7},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}

# ============================================================
# 妮娜：猎户女儿（弓手骨架，露脸长辫、头巾）。必杀 = 压低弓步、长蓄力
# ============================================================
NINA_POSES = dict(BOW_POSES)
NINA_POSES.update({
    "low0": P((25, 39), (33, 46), (39, 44), (43, 43), (49, 43), (25, 60), (14, 66), (42, 58), (49, 66), wpn=0, wpn_args={"draw": 0.0, "arrow": True}),
    "low1": P((24, 39), (23, 44), (30, 42), (43, 43), (49, 43), (25, 60), (14, 66), (42, 58), (49, 66), wpn=0, wpn_args={"draw": 1.0, "arrow": True}),
    "lowrel": P((24, 39), (19, 43), (23, 39), (43, 43), (50, 43), (25, 60), (14, 66), (42, 58), (49, 66), wpn=0, wpn_args={"draw": 0.0, "arrow": False}),
})
NINA = {
    "reach": 140,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(32, 24, 20),
        H=(176, 96, 56), h=(120, 60, 36), L=(224, 152, 104),
        R=(200, 64, 56), r=(136, 36, 36),
        O=(184, 144, 96), o=(128, 96, 60),
        S=(244, 204, 164), s=(204, 152, 116), E=(40, 48, 32), W=(248, 248, 248),
        T=(72, 132, 76), t=(44, 88, 52),
        B=(112, 80, 56), b=(68, 48, 36),
    ),
    "head": [
        "......KKKKKK......",
        "....KKHHHHHHKK....",
        "...KHHHHHHHLLHK...",
        "..KhHHHHHHHHHLHK..",
        ".KhhHHHHHHHHHHHK..",
        ".KhhRRRRRRRRRRRK..",
        ".KhHHHhSSSSKKSSK..",
        ".KhHHhSSSSKWEKSK..",
        ".KhHHhSSSSSKEKSK..",
        ".KhhHhSSSSSSSSSK..",
        "..KhHHhSSSSSSsK...",
        "..KhHHKhSSSsKK....",
        "..KhHK.KKKKK......",
        "..KhHK............",
        "..KrRK............",
        "..KhHK............",
        "...KhK............",
        "....K.............",
    ],
    "torso": ARCHER["torso"],
    "skirt": ARCHER["skirt"],
    "body": {**SWORD_BODY, "head": (-4, -13)},
    "limbs": ARCHER["limbs"],
    "weapon": {"type": "bow"},
    "poses": NINA_POSES,
    "anims": {
        **BOW_ANIMS,
        "crit": {"frames": ["aim0", "low0", "low1", "low1", "low1", "low1", "lowrel", "lowrel", "aim0"], "fps": 9, "impact": 6},
    },
}

# ============================================================
# 凯因：黑烬佣兵团新人（剑士骨架，缇娅的躯干换配色：余烬色围巾 + 炭灰外套）
# 普攻 = 横斩；必杀 = 横斩接回身上撩
# ============================================================
KAIN_POSES = dict(SWORD_POSES)
KAIN_POSES.update({
    "high": SCOUT["poses"]["high"],
    "rise": P((33, 38), (31, 48), (28, 51), (44, 37), (50, 30), (31, 59), (21, 66), (47, 58), (53, 66), wpn=-60, head_dx=2, wpn_args={"length": 28}),
    "low": P((30, 41), (29, 51), (27, 54), (40, 50), (44, 56), (29, 61), (19, 66), (45, 60), (51, 66), wpn=150, head_dx=1),
})
KAIN = {
    "reach": 125,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(32, 24, 28),
        H=(88, 72, 80), h=(52, 40, 52), L=(128, 112, 120),
        S=(236, 196, 156), s=(196, 140, 104), E=(40, 32, 32), W=(248, 248, 248),
        R=(224, 104, 48), r=(152, 56, 32),
        A=(88, 84, 100), a=(56, 52, 68),
        C=(184, 176, 168), c=(132, 124, 120),
        B=(92, 68, 52), b=(56, 40, 32),
    ),
    "head": [
        "......KKKKKK......",
        "....KKHHHHHHKK....",
        "...KHHHLHHHHHHK...",
        "..KhHHHHLHHHHHHK..",
        ".KhhHHHHHHHHHHHK..",
        "KRRKRRRRRRRRRRRK..",
        "KrRKhHHhSSSSKKSK..",
        ".KrKhHhSSSSKWEKSK.",
        ".KrKhHhSSSSSKEKSK.",
        "..KKhhHSSSSSSSSSK.",
        "...KhHHhSSSSSSsK..",
        "....KhHHhSSSsKK...",
        ".....KKhHHhKK.....",
        ".......KKKKK......",
    ],
    "torso": TIA["torso"],
    "skirt": TIA["skirt"],
    "body": {**SWORD_BODY, "head": (-4, -13)},
    "limbs": {
        "arm_b": ("a", "a", 2.0), "fore_b": ("s", "s", 1.7), "arm_f": ("A", "a", 2.0), "fore_f": ("S", "s", 1.7),
        "thigh_b": ("b", "b", 2.6), "shin_b": ("b", "b", 2.3), "thigh_f": ("b", "b", 2.6), "shin_f": ("B", "b", 2.3),
    },
    "weapon": {"type": "sword", "length": 24},
    "poses": KAIN_POSES,
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": SWORD_ANIMS["attack"],
        "crit": {"frames": ["wind", "wind", "dash", "slash", "follow", "low", "rise", "rise", "idle0"], "fps": 12, "impact": 6},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}

# ============================================================
# 艾德里克：领主之子（剑士骨架 + 披风），细剑。普攻 = 弓步直刺；必杀 = 三连刺
# ============================================================
EDRIC_POSES = dict(SWORD_POSES)
EDRIC_POSES.update({
    "guard": P((27, 37), (26, 47), (29, 50), (34, 43), (32, 41), (28, 58), (22, 66), (40, 58), (45, 66), wpn=-10, head_dx=-1),
    "lunge": P((35, 40), (33, 50), (30, 53), (47, 42), (56, 42), (32, 60), (20, 66), (51, 59), (58, 66), wpn=0, head_dx=2, wpn_args={"length": 30}),
    "lunge_hi": P((35, 39), (33, 49), (30, 52), (47, 39), (55, 36), (32, 59), (20, 66), (51, 58), (58, 66), wpn=-12, head_dx=2, wpn_args={"length": 30}),
    "lunge_lo": P((35, 41), (33, 51), (30, 54), (47, 45), (55, 48), (32, 61), (20, 66), (51, 60), (58, 66), wpn=12, head_dx=2, wpn_args={"length": 30}),
    "flourish": P((30, 37), (29, 47), (31, 51), (42, 39), (48, 33), (30, 58), (24, 66), (42, 58), (47, 66), wpn=-78, head_dx=1),
})
EDRIC = {
    "reach": 128,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(24, 24, 44),
        H=(72, 112, 200), h=(40, 64, 136), L=(136, 176, 240),
        S=(244, 212, 176), s=(204, 160, 128), E=(32, 40, 80), W=(248, 248, 248),
        M=(216, 220, 232), m=(144, 148, 176),
        T=(56, 88, 176), t=(32, 52, 120), A=(56, 88, 176), a=(32, 52, 120),
        D=(48, 64, 136), d=(28, 36, 88), R=(184, 40, 48),
        B=(88, 64, 52), b=(52, 40, 36),
        blade=(240, 244, 252), blade_d=(168, 180, 204),
    ),
    "head": [
        "......KKKKKK.......",
        "....KKHHHHHHKK.....",
        "...KHHHHLLHHHHK....",
        "..KhHHHHHHLLHHHK...",
        ".KhhHHHHHHHHHHHHK..",
        ".KhHHHHHhHHHHHHHHK.",
        ".KhHHHhHSHHHHHSHHK.",
        ".KhHHhHSSSHHSSSSK..",
        "..KhHhSSSSSKKSSSK..",
        "..KhHhSSSSKWEKSSK..",
        "..KhhhSSSSSKEKSSK..",
        "...KhhSSSSSSSSSsK..",
        "...KhhsSSSSSSSSK...",
        "....KhKsSSSSSKK....",
        ".....KK.KsssKK.....",
        ".........KKK.......",
    ],
    "torso": BALTO["torso"],
    "skirt": TIA["skirt"],
    "cape": [
        "......KKKKKK",
        "....KKDDDDDK",
        "...KDDDDDDDK",
        "..KDDDDDDDdK",
        "..KDDDDDDdK.",
        ".KDDDDDDDdK.",
        ".KDDDDDDddK.",
        ".KDDDDDDdK..",
        "KDDDDDDDdK..",
        "KDDDDDDddK..",
        "KDDDDDDdK...",
        "KDDDDDDdK...",
        "KDDDDDddK...",
        "KDDDDDdK....",
        "KRDDDDdK....",
        "KRRDDddK....",
        ".KRRRdK.....",
        "..KKKK......",
    ],
    "body": {**SWORD_BODY, "head": (-4, -15), "cape": (-7, 1)},
    "limbs": {
        "arm_b": ("t", "t", 2.0), "fore_b": ("s", "s", 1.7), "arm_f": ("T", "t", 2.0), "fore_f": ("S", "s", 1.7),
        "thigh_b": ("b", "b", 2.5), "shin_b": ("b", "b", 2.3), "thigh_f": ("b", "b", 2.5), "shin_f": ("B", "b", 2.3),
    },
    "weapon": {"type": "sword", "length": 28, "blade_r": 0.9},
    "poses": EDRIC_POSES,
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": {"frames": ["guard", "guard", "lunge", "lunge", "idle0"], "fps": 12, "impact": 2},
        "crit": {"frames": ["flourish", "flourish", "guard", "lunge_hi", "guard", "lunge_lo", "guard", "lunge", "lunge", "lunge", "idle0"], "fps": 14, "impact": 7},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}
# ============================================================
# 诺雅：见习修女，治疗杖。不攻击；attack / crit 是举杖施法动作，备用
# ============================================================
STAFF_POSES = {
    "idle0": P((26, 36), (26, 46), (29, 50), (38, 45), (42, 47), (29, 58), (27, 66), (39, 58), (43, 66), wpn=-90),
    "idle1": P((26, 37), (26, 47), (29, 51), (38, 46), (42, 48), (29, 59), (27, 66), (39, 59), (43, 66), wpn=-90),
    "run0": P((30, 37), (25, 45), (21, 50), (40, 45), (44, 49), (27, 57), (18, 64), (42, 57), (48, 65), wpn=-72, head_dx=1),
    "run1": P((30, 36), (28, 45), (27, 51), (38, 45), (42, 50), (31, 57), (29, 66), (37, 56), (40, 63), wpn=-70, head_dx=1),
    "raise": P((26, 36), (30, 43), (36, 40), (40, 39), (44, 32), (29, 58), (27, 66), (39, 58), (43, 66), wpn=-82),
    "cast": P((26, 35), (31, 40), (37, 34), (41, 34), (46, 25), (29, 57), (27, 66), (39, 57), (43, 66), wpn=-86, head_dy=-1),
    "hit": P((22, 37), (21, 47), (18, 50), (34, 46), (38, 50), (26, 58), (22, 66), (35, 59), (39, 66), wpn=-110, head_dx=-3),
    "kneel": P((27, 46), (26, 55), (28, 61), (38, 54), (43, 58), (23, 64), (14, 66), (40, 58), (43, 66), wpn=-160, head_dx=-1, head_dy=1),
}
NOYA = {
    "reach": 120,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(28, 28, 48),
        W=(248, 248, 248), w=(200, 200, 216),
        H=(240, 208, 120), h=(192, 152, 80),
        S=(248, 216, 184), s=(212, 168, 136), E=(48, 72, 128),
        T=(72, 88, 168), t=(44, 56, 120),
        C=(240, 240, 244), c=(184, 184, 200),
        B=(80, 64, 72), b=(52, 44, 56),
        gem=(136, 216, 248), gem_d=(72, 144, 216),
    ),
    "head": [
        "......KKKKKK......",
        "....KKWWWWWWKK....",
        "...KWWWWWWWWWWK...",
        "..KwWWWWWWWWWWWK..",
        ".KwwWWWWWWWWWWWK..",
        ".KwwWWTTTTTTTTTK..",
        ".KwWWTHHHSSSSSSK..",
        ".KwWWTHSSSSKKSSK..",
        ".KwWWTSSSSKWEKSK..",
        ".KwWWTSSSSSKEKSK..",
        ".KwwWTSSSSSSSSSK..",
        ".KwwWWTSSSSSSsK...",
        ".KwwwWWTSSSsKK....",
        "..KwwwWWTKKK......",
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
        "KtTTTTTGTTTTtK",
        ".KtTTTGGGTTtK.",
        ".KtTTTTGTTTtK.",
        ".KttTTTTTTttK.",
        "..KTTTTTTTTK..",
        "..KKKKKKKKKK..",
    ],
    "skirt": [
        "...KtTTTTTTTTTTtK...",
        "...KttTTTTTTTTTttK..",
        "..KtTTTTTTTTTTTTtK..",
        "..KtTTTtTTTTTTTTtK..",
        "..KtTTTtTTTTTtTTtK..",
        "..KtTTtTTTTTTtTTTK..",
        ".KtTTTtTTTTTTtTTTtK.",
        ".KtTTtTTTTTTTTtTTtK.",
        ".KtTTtTTTTTTTTtTTTK.",
        ".KtTTtTTTTTTTTtTTTtK",
        "KttTtTTTTTTTTTtTTTtK",
        "KtTTtTTTTTTTTTTtTTtK",
        "KtTtTTTTTTTTTTTtTTtK",
        "KCCCCCCCCCCCCCCCCCCK",
        "KKKKKKKKKKKKKKKKKKKK",
    ],
    "body": {**SWORD_BODY, "head": (-4, -15), "skirt": (-3, 11)},
    "limbs": {
        "arm_b": ("t", "t", 2.0), "fore_b": ("s", "s", 1.6), "arm_f": ("T", "t", 2.0), "fore_f": ("S", "s", 1.6),
        "thigh_b": ("b", "b", 2.3), "shin_b": ("b", "b", 2.1), "thigh_f": ("b", "b", 2.3), "shin_f": ("B", "b", 2.1),
    },
    "weapon": {"type": "staff", "length": 30, "butt": 12},
    "poses": STAFF_POSES,
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": {"frames": ["idle0", "raise", "raise", "cast", "cast", "cast", "raise"], "fps": 9, "impact": 3},
        "crit": {"frames": ["idle0", "raise", "raise", "cast", "cast", "cast", "cast", "cast", "raise"], "fps": 9, "impact": 4},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}

# ============================================================
# 步行长枪（圣焰教会步兵）：88×72，脚底 y=68。双手持枪
# ============================================================
FOOT_LANCE_POSES = {
    "idle0": P((26, 36), (28, 46), (34, 49), (40, 45), (44, 46), (29, 58), (27, 66), (39, 58), (43, 66), wpn=-62),
    "idle1": P((26, 37), (28, 47), (34, 50), (40, 46), (44, 47), (29, 59), (27, 66), (39, 59), (43, 66), wpn=-62),
    "run0": P((30, 37), (32, 46), (38, 48), (42, 45), (47, 46), (27, 57), (18, 64), (42, 57), (48, 65), wpn=-18, head_dx=2),
    "run1": P((30, 36), (32, 45), (38, 47), (42, 44), (47, 45), (31, 57), (29, 66), (37, 56), (40, 63), wpn=-15, head_dx=2),
    "wind": P((23, 38), (22, 47), (27, 49), (31, 45), (36, 46), (25, 59), (18, 66), (37, 59), (43, 66), wpn=-6, head_dx=-1),
    "thrust": P((33, 39), (38, 47), (45, 46), (47, 43), (56, 44), (31, 59), (20, 66), (48, 58), (55, 66), wpn=0, head_dx=2),
    "follow": P((32, 39), (36, 47), (42, 46), (45, 44), (52, 45), (31, 59), (21, 66), (47, 58), (54, 66), wpn=4, head_dx=2),
    "over": P((25, 36), (33, 36), (40, 30), (42, 36), (47, 29), (27, 58), (21, 66), (39, 58), (44, 66), wpn=14, head_dx=-1, wpn_args={"butt": 8}),
    "stab": P((33, 38), (39, 42), (46, 38), (48, 42), (55, 38), (31, 59), (20, 66), (48, 58), (55, 66), wpn=18, head_dx=2, wpn_args={"butt": 8}),
    "hit": P((22, 37), (23, 47), (28, 49), (33, 46), (37, 47), (26, 58), (22, 66), (35, 59), (39, 66), wpn=-45, head_dx=-3),
    "kneel": P((27, 46), (28, 55), (33, 58), (39, 54), (44, 58), (23, 64), (14, 66), (40, 58), (43, 66), wpn=8, head_dx=-1, head_dy=1),
}
FOOT_LANCE_ANIMS = {
    "idle": ANIM_IDLE, "run": ANIM_RUN,
    "attack": {"frames": ["wind", "wind", "thrust", "thrust", "follow"], "fps": 11, "impact": 2},
    "crit": {"frames": ["wind", "over", "over", "over", "stab", "stab", "follow"], "fps": 10, "impact": 4},
    "hit": ANIM_HIT, "death": ANIM_DEATH,
}
CHURCH = {
    "reach": 160,
    "frame": (88, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(36, 28, 36),
        W=(244, 240, 232), w=(188, 180, 176),
        R=(200, 40, 48), r=(136, 24, 36),
        M=(176, 180, 196), m=(112, 116, 140),
        S=(236, 196, 156), s=(196, 140, 104), E=(40, 32, 32),
        B=(96, 72, 56), b=(60, 44, 36),
    ),
    "head": [
        "......KKKKKK......",
        "....KKWWWWWWKK....",
        "...KWWWWRWWWWWK...",
        "..KwWWWRRRWWWWWK..",
        ".KwwWWWWRWWWWWWK..",
        ".KwwMMMMMMMMMMMK..",
        ".KwWWwSSSSKKSSSK..",
        ".KwWWwSSSKWEKSSK..",
        ".KwWWwSSSSKEKSSK..",
        ".KwWWwSSSSSSSSSK..",
        ".KwwWWwSSSSSSsK...",
        "..KwwWWWwSSsKK....",
        "...KKwwWWWWK......",
        ".....KKKKKK.......",
    ],
    "torso": [
        "...KKKKKKK....",
        "..KMMMMMMMKK..",
        ".KmMMMMMMMMMK.",
        "KWKmmMMMMMmKWK",
        "KWWKKKKKKKKWWK",
        "KwWWWWRRWWWWwK",
        "KwWWWRRRRWWWwK",
        ".KwWWWRRWWWwK.",
        ".KwWWWRRWWWwK.",
        ".KwwWWRRWWwwK.",
        "..KwWWWWWWwK..",
        "..KbbbGGbbbK..",
        "..KKKKKKKKKK..",
    ],
    "skirt": [
        ".KwWWWWRRWWWWwK.",
        "KwwWWWWRRWWWWwwK",
        "KwWWWwWRRWwWWWwK",
        "KwWWwKWRRWKwWWwK",
        ".KwK..KRRK..KwK.",
        "..K....KK....K..",
    ],
    "body": {**SWORD_BODY, "head": (-4, -13)},
    "limbs": {
        "arm_b": ("m", "m", 2.0), "fore_b": ("s", "s", 1.7), "arm_f": ("M", "m", 2.0), "fore_f": ("S", "s", 1.7),
        "thigh_b": ("b", "b", 2.5), "shin_b": ("b", "b", 2.3), "thigh_f": ("b", "b", 2.5), "shin_f": ("B", "b", 2.3),
    },
    "weapon": {"type": "lance", "length": 34, "butt": 14},
    "poses": FOOT_LANCE_POSES,
    "anims": FOOT_LANCE_ANIMS,
}

# ============================================================
# 巴雷特：教会追捕队长，重甲 + 大盾 + 长枪（斧系的壮汉骨架，单手持枪）
# 普攻 = 举盾突刺；必杀 = 盾击接重刺
# ============================================================
ARMOR_POSES = {
    "idle0": P((30, 36), (31, 45), (37, 49), (44, 44), (48, 47), (33, 57), (29, 71), (44, 57), (48, 71), wpn=-75),
    "idle1": P((30, 37), (31, 46), (37, 50), (44, 45), (48, 48), (33, 58), (29, 71), (44, 58), (48, 71), wpn=-75),
    "run0": P((33, 37), (34, 46), (40, 50), (46, 43), (51, 46), (32, 58), (24, 70), (47, 57), (53, 70), wpn=-30, head_dx=1),
    "run1": P((33, 36), (34, 45), (40, 49), (46, 42), (51, 45), (35, 58), (33, 71), (42, 57), (46, 69), wpn=-28, head_dx=1),
    "wind": P((27, 36), (29, 45), (36, 48), (36, 43), (34, 46), (30, 57), (23, 71), (43, 57), (49, 71), wpn=-4, head_dx=-1),
    "thrust": P((36, 37), (38, 46), (45, 49), (52, 41), (61, 42), (34, 58), (24, 71), (52, 57), (59, 71), wpn=0, head_dx=1),
    "follow": P((35, 38), (37, 47), (44, 50), (50, 43), (57, 44), (34, 59), (24, 71), (51, 58), (58, 71), wpn=5, head_dx=1),
    "bash": P((35, 37), (42, 44), (53, 46), (44, 43), (40, 46), (33, 58), (23, 71), (51, 57), (58, 71), wpn=-50, head_dx=1),
    "hit": P((26, 35), (27, 44), (33, 47), (38, 44), (42, 47), (30, 57), (26, 71), (40, 58), (44, 71), wpn=-55, head_dx=-3),
    "kneel": P((30, 46), (31, 55), (37, 58), (44, 55), (48, 59), (28, 68), (18, 71), (44, 60), (47, 71), wpn=10, head_dx=-1, head_dy=1),
}
BARRETT = {
    "reach": 150,
    "frame": (96, 88), "foot": (40, 84), "scale": 3,
    "pal": pal(
        K=(28, 24, 36),
        M=(184, 188, 208), m=(116, 120, 148), x=(240, 244, 252),
        W=(240, 236, 228), w=(184, 176, 172),
        R=(192, 36, 44), r=(128, 20, 32),
        E=(232, 72, 56),
        B=(96, 72, 56), b=(60, 44, 36),
    ),
    "head": [
        "..KKK.............",
        ".KRRRKK...........",
        "KRrrRRRKKKKK......",
        "KrK.KRMMMMMMKK....",
        ".K..KMMMMMMMMMK...",
        "...KMMMxMMMMMMMK..",
        "...KmMMMxMMMMMMK..",
        "...KmMMMKKKKKKKK..",
        "...KmMMMMMKEEKMK..",
        "...KmMMMMKKKKKKK..",
        "...KmmMMMMMMMMMK..",
        "...KmmMMMMKMKMMK..",
        "....KmmMMMMMMMK...",
        ".....KKmmmmmmK....",
        ".......KKKKKK.....",
    ],
    "torso": [
        "..KKKKKKKKKKKK..",
        ".KxMMMMMMMMMMxK.",
        "KxMMMMMMMMMMMMmK",
        "KmMMMWWWRWWWMMmK",
        "KmKMWWWRRRWWWKmK",
        ".KMMWWWWRWWWWMK.",
        ".KMMWWWWRWWWWMK.",
        ".KmMwWWWRWWWwMK.",
        ".KmMwwWWRWWwwmK.",
        "..KmMMMMMMMMmK..",
        "..KBBBBGGBBBBK..",
        "..KbbbbbbbbbbK..",
        "..KMMMMMMMMMMK..",
        "..KmmmmmmmmmmK..",
        "..KKKKKKKKKKKK..",
    ],
    "shield": [
        "KKKKKKKKKKKK",
        "KMWWWWWWWWMK",
        "KMWWWRRWWWMK",
        "KMWWWRRWWWMK",
        "KMRRRRRRRRMK",
        "KMRRRRRRRRMK",
        "KMWWWRRWWWMK",
        "KMWWWRRWWWMK",
        ".KMWWRRWWMK.",
        ".KMWWRRWWMK.",
        "..KMWRRWMK..",
        "...KMRRMK...",
        "....KMMK....",
        ".....KK.....",
    ],
    "body": {**AXE_BODY, "head": (-1, -13)},
    "limbs": {
        "arm_b": ("m", "m", 2.8), "fore_b": ("m", "m", 2.4), "arm_f": ("M", "m", 2.8), "fore_f": ("M", "m", 2.4),
        "thigh_b": ("m", "m", 3.1), "shin_b": ("m", "m", 2.8), "thigh_f": ("M", "m", 3.1), "shin_f": ("M", "m", 2.8),
    },
    "weapon": {"type": "lance", "length": 36, "butt": 14},
    "poses": shift_all(ARMOR_POSES, 12),
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": {"frames": ["wind", "wind", "thrust", "thrust", "follow"], "fps": 10, "impact": 2},
        "crit": {"frames": ["wind", "bash", "bash", "wind", "wind", "thrust", "thrust", "follow"], "fps": 10, "impact": 5},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}

# ============================================================
# 黑烬佣兵：兜帽皮甲（探子的躯干换配色、露脸）。普攻 / 必杀用剑系通用招式
# ============================================================
MERC = {
    "reach": 120,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(28, 24, 28),
        V=(84, 76, 80), v=(52, 46, 52),
        S=(232, 188, 148), s=(188, 132, 100), E=(32, 24, 24), W=(248, 248, 248),
        T=(176, 84, 44), t=(116, 52, 32),
        B=(72, 60, 56), b=(44, 36, 36),
    ),
    "head": [
        "...................",
        "......KKKKKK.......",
        "....KKVVVVVVKK.....",
        "...KVVVVVVVVVVK....",
        "..KvVVVVVVVVVVVK...",
        ".KvvVVVVVVVVVVVK...",
        ".KvvVVvSSSSSSSVK...",
        ".KvVVvSSSSKKSSSK...",
        ".KvVVvSSSKWEKSSK...",
        ".KvVvSSSSSKEKSSK...",
        ".KvvVSSSSSSSSSK....",
        "..KvVvSSSSSSsK.....",
        "...KKvvSSssKK......",
        ".....KKKKKK........",
    ],
    "torso": SCOUT["torso"],
    "skirt": SCOUT["skirt"],
    "body": {**SWORD_BODY, "head": (-4, -13)},
    "limbs": SCOUT["limbs"],
    "weapon": {"type": "sword", "length": 23},
    "poses": SWORD_POSES,
    "anims": SWORD_ANIMS,
}

# ============================================================
# 霍克：佣兵队长，独眼罩、毛领黑外套、阔刃剑。普攻 = 重劈；必杀 = 劈下接上撩
# ============================================================
HAWK_POSES = dict(KAIN_POSES)
HAWK = {
    "reach": 125,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(28, 20, 24),
        H=(152, 48, 40), h=(96, 28, 28), L=(200, 88, 64),
        S=(228, 180, 140), s=(180, 124, 92), E=(28, 20, 20), W=(248, 248, 248),
        R=(168, 144, 112), r=(116, 96, 76),
        A=(60, 56, 68), a=(36, 34, 44),
        C=(176, 40, 48), c=(116, 24, 36),
        B=(88, 64, 48), b=(52, 38, 30),
        blade=(224, 228, 236), blade_d=(140, 148, 168),
    ),
    "head": [
        "..K....K..K.......",
        ".KHK..KHKKHK......",
        ".KHHKKHHHKHHKK....",
        "..KHHHHHLHHHHHK...",
        ".KhHHHHHHHHHHHHK..",
        "KhhHHHHHHHHHHHHHK.",
        "KhHHHhHHKHHHHHHHK.",
        ".KhHhHSSSKSSSHSSK.",
        ".KhhSSSSSSKKKKSSK.",
        "..KhSSSSSSKKKKSSK.",
        "..KhsSSSSSSKKSSsK.",
        "..KhssSSSSSSSSSK..",
        "...KhsssSSSSsKSK..",
        "....KssssssssK....",
        ".....KKssssKK.....",
        ".......KKKK.......",
    ],
    "torso": TIA["torso"],
    "skirt": [
        ".KaAAAAAAAAAAaK.",
        "KaaAAAAAAAAAAaaK",
        "KaAAAaAAAAaAAAaK",
        "KaAAAaAAAAaAAAAK",
        "KaAAaaAAAaaAAAaK",
        "KaAAaAAAAaAAAAaK",
        "KaAAaAAAAaAAAAaK",
        "KaAaKAAAaKAAAaK.",
        ".KaK.KAaK.KAaK..",
        "..K...KK...KK...",
    ],
    "body": {**SWORD_BODY, "head": (-5, -15)},
    "limbs": {
        "arm_b": ("a", "a", 2.2), "fore_b": ("s", "s", 1.8), "arm_f": ("A", "a", 2.2), "fore_f": ("S", "s", 1.8),
        "thigh_b": ("b", "b", 2.6), "shin_b": ("b", "b", 2.4), "thigh_f": ("b", "b", 2.6), "shin_f": ("B", "b", 2.4),
    },
    "weapon": {"type": "sword", "length": 29, "blade_r": 1.9},
    "poses": HAWK_POSES,
    "anims": {
        "idle": ANIM_IDLE, "run": ANIM_RUN,
        "attack": {"frames": ["wind", "wind", "high", "slash", "follow", "follow"], "fps": 11, "impact": 3},
        "crit": {"frames": ["wind", "wind", "wind", "high", "slash", "follow", "low", "rise", "rise", "rise", "idle0"], "fps": 12, "impact": 7},
        "hit": ANIM_HIT, "death": ANIM_DEATH,
    },
}

# ============================================================
# 骑马长枪：圣焰骑士、塞拉斯（巴尔托的马和骨架，换配色）
# ============================================================
def _horse_recolor(table):
    return ["".join(table.get(c, c) for c in row) for row in HORSE]


# 马衣：T/t → W/w（白底），金边 g 不变
HORSE_WHITE_CLOTH = _horse_recolor({"T": "W", "t": "w"})
HORSE_RED_CLOTH = _horse_recolor({"T": "R", "t": "r"})

MOUNT_POSES = {k: v for k, v in BALTO["poses"].items() if k in ("idle0", "idle1", "run0", "run1", "wind", "thrust", "follow", "hit", "raise")}
KNIGHT_ANIMS = {
    "idle": ANIM_IDLE, "run": ANIM_RUN,
    "attack": {"frames": ["wind", "wind", "thrust", "thrust", "follow"], "fps": 10, "impact": 2},
    "crit": {"frames": ["wind", "wind", "wind", "wind", "thrust", "thrust", "follow"], "fps": 9, "impact": 4},
    "hit": ANIM_HIT,
    "death": {"frames": ["hit", "hit", "hit", "hit"], "fps": 5},
}

KNIGHT = {
    "reach": 185,
    "frame": (124, 96), "foot": (54, 92), "scale": 3,
    "pal": pal(
        K=(32, 24, 32),
        M=(216, 220, 232), m=(140, 144, 168),
        W=(244, 240, 232), w=(184, 176, 176),
        T=(192, 40, 48), t=(128, 24, 36), R=(192, 40, 48),
        S=(236, 196, 156), s=(196, 140, 104), E=(32, 24, 32),
        Q=(128, 84, 56), q=(84, 54, 36), Z=(44, 30, 24),
        B=(96, 72, 56), b=(60, 44, 36),
        g=(248, 208, 80),
    ),
    "head": [
        "......KKKK........",
        ".....KRRRRK.......",
        "...KKKKRRKKKKK....",
        "..KMMMMMMMMMMMK...",
        ".KmMMMMMMMMMMMMK..",
        ".KmMMMMMMMMMMMMK..",
        ".KmMMMMKKKKKKKMK..",
        ".KmMMMKSSSKWEKMK..",
        ".KmMMMKSSSSKEKMK..",
        ".KmMMMMKKSSSSSMK..",
        ".KmmMMMMMKSSSMK...",
        "..KmmMMMMMMMMK....",
        "...KKmmmmmmKK.....",
        ".....KKKKKK.......",
    ],
    "torso": BALTO["torso"],
    "body": {**BALTO["body"], "head": (-3, -13)},
    "limbs": BALTO["limbs"],
    "mount": {"art": HORSE_WHITE_CLOTH, "attach": HORSE_ATTACH},
    "weapon": {"type": "lance", "length": 40, "butt": 12},
    "poses": MOUNT_POSES,
    "anims": KNIGHT_ANIMS,
}

# ---- 塞拉斯：银发金冠、白外衣红内衬，黑马红马衣、银枪。必杀 = 高举长枪、俯身贯刺 ----
SILAS_POSES = dict(MOUNT_POSES)
SILAS_POSES.update({
    "hold": _horse_pose(HX - 2, HY, STAND, RIDER, (4, 5), (10, 1), (13, 0), (15, -7), wpn=-120, head_dx=-1),
    "plunge": _horse_pose(HX + 6, HY - 2, GALLOP0, RIDER, (8, 6), (15, 4), (19, 2), (26, 0), wpn=10, head_dx=1),
    "charge": _horse_pose(HX + 10, HY - 3, GALLOP0, RIDER, (9, 7), (17, 7), (21, 5), (28, 4), wpn=0, head_dx=1),
})
SILAS = {
    "reach": 190,
    "frame": (124, 96), "foot": (54, 92), "scale": 3,
    "pal": pal(
        K=(28, 20, 36),
        H=(184, 192, 216), h=(116, 124, 160), L=(236, 240, 252), w=(176, 176, 200),
        M=(236, 236, 244), m=(168, 168, 192),
        T=(168, 28, 48), t=(108, 16, 36), R=(168, 28, 48), r=(108, 16, 36),
        S=(240, 208, 180), s=(200, 156, 128), E=(96, 32, 48), W=(248, 248, 248),
        Q=(64, 60, 76), q=(40, 36, 52), Z=(200, 204, 220),
        B=(72, 56, 60), b=(44, 36, 44),
        G=(248, 208, 80), g=(248, 208, 80),
        grip=(200, 204, 220), grip_d=(128, 132, 156),
        blade=(248, 252, 255), blade_d=(176, 188, 212),
    ),
    "head": [
        "......KKKKKK......",
        "....KKHHHHHHKK....",
        "...KHHHHHHLLHHK...",
        "..KhHHHHHHHHLHHK..",
        ".KhhGGGGGGGGGGGK..",
        "KhhHHHHhSSSSSSHK..",
        "KhHHHHhSSSSKKSSK..",
        "KhHHHhSSSSKWEKSK..",
        "KhhHHhSSSSSKEKSK..",
        "KhhHHhSSSSSSSSSK..",
        ".KhhHHhSSSSSSsK...",
        ".KhhhHHhSSSsKK....",
        "..KhhhHHKKKK......",
        "...KhhhHK.........",
        "....KKhhK.........",
        "......KK..........",
    ],
    "torso": BALTO["torso"],
    "cape": [
        "......KKKKK",
        "....KKWWWWK",
        "...KWWWWWwK",
        "..KWWWWWWwK",
        "..KWWWWWwK.",
        ".KWWWWWWwK.",
        ".KWWWWWwwK.",
        "KWWWWWWwK..",
        "KWWWWWwwK..",
        "KWWWWWwK...",
        "KWWWWwwK...",
        "KGWWWwK....",
        ".KGGGwK....",
        "..KKKK.....",
    ],
    "body": {**BALTO["body"], "head": (-3, -15), "cape": (-9, 0)},
    "limbs": BALTO["limbs"],
    "mount": {"art": HORSE_RED_CLOTH, "attach": HORSE_ATTACH},
    "weapon": {"type": "lance", "length": 44, "butt": 12},
    "poses": SILAS_POSES,
    "anims": {
        **KNIGHT_ANIMS,
        "crit": {"frames": ["raise", "hold", "hold", "hold", "plunge", "charge", "charge", "follow"], "fps": 10, "impact": 5},
    },
}

UNITS_CH2 = {
    "harlo": HARLO,
    "nina": NINA,
    "kain": KAIN,
    "edric": EDRIC,
    "noya": NOYA,
    "church": CHURCH,
    "barrett": BARRETT,
    "merc": MERC,
    "hawk": HAWK,
    "knight": KNIGHT,
    "silas": SILAS,
}
