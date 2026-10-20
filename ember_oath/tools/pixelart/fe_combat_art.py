"""战斗特写角色数据（原创）：调色板、头 / 躯干 / 下摆 / 马身像素图、骨架姿势、动作表。

坐标一律是画布像素（左上原点，朝右）。躯干位置 torso 是躯干图左上角；
肩、髋、头、下摆相对躯干的偏移写在 body 里，各姿势只给手肘 / 手 / 膝 / 脚和武器角度。
武器角度：0° 朝右、90° 朝下、-90° 朝上。
"""

WEAPON_COLORS = {
    "blade": (232, 240, 248), "blade_d": (152, 168, 192),
    "grip": (120, 72, 48), "grip_d": (72, 40, 28),
    "gold": (248, 208, 80), "gold_d": (176, 120, 40),
    "string": (232, 224, 200),
}


def pal(**kw):
    p = dict(WEAPON_COLORS)
    p["G"] = WEAPON_COLORS["gold"]
    p.update(kw)
    return p


def P(torso, eb, hb, ef, hf, kb=None, fb=None, kf=None, ff=None, wpn=None, head_dx=0, head_dy=0, **extra):
    d = {"torso": torso, "elbow_b": eb, "hand_b": hb, "elbow_f": ef, "hand_f": hf, "head_dx": head_dx, "head_dy": head_dy}
    if kb is not None:
        d.update({"knee_b": kb, "foot_b": fb, "knee_f": kf, "foot_f": ff})
    if wpn is not None:
        d["wpn"] = wpn
    d.update(extra)
    return d


def shift(pose, dx=0, dy=0):
    """整个姿势平移（待机呼吸、跑步起伏用）"""
    out = {}
    for k, v in pose.items():
        if isinstance(v, tuple) and len(v) == 2 and k not in ("foot_b", "foot_f"):
            out[k] = (v[0] + dx, v[1] + dy)
        else:
            out[k] = v
    return out


# ============================================================
# 剑系（缇娅、探子）：72×72，脚底 y=68
# ============================================================
SWORD_POSES = {
    "idle0": P((26, 36), (26, 46), (29, 50), (40, 45), (45, 48), (29, 58), (27, 66), (39, 58), (43, 66), wpn=22),
    "idle1": P((26, 37), (26, 47), (29, 51), (40, 46), (45, 49), (29, 59), (27, 66), (39, 59), (43, 66), wpn=24),
    "run0": P((30, 37), (25, 45), (21, 50), (40, 44), (44, 49), (27, 57), (18, 64), (42, 57), (48, 65), wpn=-165, head_dx=2),
    "run1": P((30, 36), (28, 45), (27, 51), (38, 45), (40, 50), (31, 57), (29, 66), (37, 56), (40, 63), wpn=-160, head_dx=2),
    "wind": P((22, 38), (20, 47), (24, 50), (28, 41), (24, 33), (24, 59), (18, 66), (37, 60), (43, 66), wpn=-120, head_dx=-1),
    "dash": P((32, 39), (30, 49), (26, 52), (38, 45), (32, 39), (30, 59), (20, 66), (47, 58), (53, 66), wpn=-150, head_dx=2),
    "slash": P((34, 39), (32, 49), (29, 52), (47, 43), (55, 45), (32, 59), (22, 66), (49, 59), (55, 66), wpn=18, head_dx=2, wpn_args={"length": 28}),
    "follow": P((33, 40), (32, 50), (30, 53), (45, 49), (51, 54), (32, 60), (22, 66), (47, 60), (53, 66), wpn=70, head_dx=2),
    "hit": P((22, 37), (21, 47), (18, 50), (35, 46), (38, 51), (26, 58), (22, 66), (35, 59), (39, 66), wpn=40, head_dx=-3),
    "kneel": P((27, 46), (26, 55), (28, 61), (40, 54), (44, 60), (23, 64), (14, 66), (40, 58), (43, 66), wpn=85, head_dx=-1, head_dy=1),
}
SWORD_ANIMS = {
    "idle": {"frames": ["idle0", "idle0", "idle1", "idle1"], "fps": 4},
    "run": {"frames": ["run0", "run1", "run0", "run1"], "fps": 10},
    "attack": {"frames": ["wind", "dash", "slash", "follow", "follow"], "fps": 11, "impact": 2},
    "crit": {"frames": ["wind", "wind", "wind", "dash", "slash", "slash", "follow"], "fps": 10, "impact": 4},
    "hit": {"frames": ["hit", "hit", "idle0"], "fps": 8},
    "death": {"frames": ["hit", "kneel", "kneel", "kneel"], "fps": 5},
}
SWORD_BODY = {"sh_b": (2, 4), "sh_f": (11, 4), "hip_b": (5, 14), "hip_f": (9, 14), "skirt": (-1, 11), "head": (-5, -16)}

# ---------------- 缇娅 ----------------
TIA = {
    "reach": 130,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(40, 24, 32),
        H=(216, 64, 48), h=(152, 32, 32), L=(248, 136, 96),
        S=(248, 216, 176), s=(224, 160, 120), E=(48, 40, 72), W=(248, 248, 248),
        R=(200, 40, 48), r=(136, 24, 40),
        A=(176, 120, 72), a=(120, 76, 48),
        C=(240, 232, 216), c=(192, 176, 160),
        B=(112, 80, 60), b=(64, 44, 36),
    ),
    "head": [
        "........KKKKK.......",
        "......KKHHLLHKK.....",
        ".....KHHHHHLLHHK....",
        "..KK.KHHHHHHHHLHK...",
        ".KhhKHHHHhHHHHHHHK..",
        "KhhhhHHHhHHHHHHHHHK.",
        "KhhKhHHhHHHHHHHHHHK.",
        "KhK.KhHhHHSHHHHSHHK.",
        "Kh..KhHhHSSSHHSSSHK.",
        "KK..KhHhSSSSSSKKSSK.",
        ".K..KhHhSSSSSKWEKSK.",
        "....KhhSSSSSSKEEKSK.",
        "....KhhsSSSSSSSSSK..",
        ".....KhsSSSSSSKsK...",
        "......KhsSSSSssK....",
        ".......KKssssKK.....",
        ".........KsK........",
        ".........KK.........",
    ],
    "torso": [
        "...KKKKKKK....",
        "..KRRRRRRRKK..",
        ".KrRRRRRRRRRK.",
        "KArrRRRRRRRrK.",
        "KAKrrrrRRrrKAK",
        "KAACKrrrrKCAAK",
        "KaACCKKKKCCAaK",
        "KaACCCCCCCCAaK",
        ".KaACCCCCCAaK.",
        ".KaAAcCCcAAaK.",
        ".KaaAAAAAAaaK.",
        "..KBBGGGGBBK..",
        "..KKKKKKKKKK..",
    ],
    "skirt": [
        ".KaAAAAAAAAAAaK.",
        "KaaAAAAAAAAAAaaK",
        "KaAAAaAAAAaAAAaK",
        "KaAAAaAAAAaAAAAK",
        "KaAAaaAAAaaAAAaK",
        "KaAAaKAAAaKAAAaK",
        "KaAaK.KAaK.KAaK.",
        ".KaK...KK...KK..",
        "..K.............",
    ],
    "body": SWORD_BODY,
    "limbs": {
        "arm_b": ("c", "c", 2.0), "fore_b": ("s", "s", 1.7), "arm_f": ("C", "c", 2.0), "fore_f": ("S", "s", 1.7),
        "thigh_b": ("b", "b", 2.6), "shin_b": ("b", "b", 2.3), "thigh_f": ("b", "b", 2.6), "shin_f": ("B", "b", 2.3),
    },
    "weapon": {"type": "sword", "length": 26},
    "poses": SWORD_POSES,
    "anims": SWORD_ANIMS,
}

# ---------------- 探子：蒙面短剑 ----------------
SCOUT = {
    "reach": 115,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(28, 20, 36),
        V=(96, 72, 120), v=(56, 40, 80),
        S=(240, 200, 160), s=(200, 150, 112), E=(32, 24, 48), W=(248, 248, 248),
        T=(120, 48, 56), t=(80, 28, 40),
        B=(72, 60, 72), b=(44, 36, 48),
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
        ".KvVvVVVVVVVVVVK...",
        ".KvvVVVVVVVVVVK....",
        "..KvVVVVVVVVVK.....",
        "...KKvvvvvvKK......",
        ".....KKKKKK........",
    ],
    "torso": [
        "...KKKKKKK....",
        "..KVVVVVVVKK..",
        ".KvVVVVVVVVVK.",
        "KTvvVVVVVVvvKT",
        "KTKvvvvvvvvKTK",
        "KtTTKKKKKKTTtK",
        "KtTTTTTTTTTTtK",
        "KtTTTTTTTTTTtK",
        ".KtTTTTTTTTtK.",
        ".KtTTTTTTTTtK.",
        ".KttTTTTTTttK.",
        "..KbbbGGbbbK..",
        "..KKKKKKKKKK..",
    ],
    "skirt": [
        ".KtTTTTTTTTTTtK.",
        "KttTTTTTTTTTTttK",
        "KtTTTtTTTTtTTTtK",
        "KtTTtKTTTtKTTTtK",
        ".KtK..KtK..KtK..",
        "..K....K....K...",
    ],
    "body": {**SWORD_BODY, "head": (-4, -13)},
    "limbs": {
        "arm_b": ("v", "v", 2.0), "fore_b": ("s", "s", 1.6), "arm_f": ("V", "v", 2.0), "fore_f": ("S", "s", 1.6),
        "thigh_b": ("b", "b", 2.4), "shin_b": ("b", "b", 2.2), "thigh_f": ("b", "b", 2.4), "shin_f": ("B", "b", 2.2),
    },
    "weapon": {"type": "sword", "length": 17},
    "poses": SWORD_POSES,
    "anims": SWORD_ANIMS,
}

# ============================================================
# 斧系（山贼、头目）：80×76，脚底 y=72
# ============================================================
AXE_POSES = {
    "idle0": P((30, 36), (30, 46), (34, 50), (44, 42), (46, 35), (33, 57), (29, 71), (44, 57), (48, 71), wpn=-150),
    "idle1": P((30, 37), (30, 47), (34, 51), (44, 43), (46, 36), (33, 58), (29, 71), (44, 58), (48, 71), wpn=-148),
    "run0": P((34, 37), (30, 46), (27, 51), (46, 42), (48, 35), (32, 58), (22, 69), (48, 57), (54, 70), wpn=-155, head_dx=1),
    "run1": P((34, 36), (32, 46), (31, 51), (45, 42), (47, 35), (36, 58), (34, 71), (42, 57), (46, 68), wpn=-152, head_dx=1),
    "wind": P((27, 34), (30, 26), (36, 19), (40, 25), (38, 17), (30, 56), (23, 71), (44, 57), (50, 71), wpn=-100, head_dx=-1),
    "dash": P((36, 37), (38, 30), (44, 24), (47, 31), (46, 23), (34, 58), (24, 71), (52, 57), (58, 71), wpn=-70, head_dx=1),
    "slash": P((38, 39), (42, 46), (52, 47), (51, 41), (57, 47), (36, 59), (26, 71), (54, 58), (60, 71), wpn=35, head_dx=2),
    "follow": P((38, 41), (42, 48), (50, 53), (49, 47), (54, 55), (36, 60), (26, 71), (54, 59), (60, 71), wpn=80, head_dx=2),
    "hit": P((26, 35), (26, 45), (22, 49), (38, 44), (42, 48), (30, 57), (26, 71), (40, 58), (44, 71), wpn=60, head_dx=-3),
    "kneel": P((30, 46), (30, 56), (32, 63), (44, 55), (48, 62), (28, 68), (18, 71), (44, 60), (47, 71), wpn=10, head_dx=-1, head_dy=1),
}
AXE_ANIMS = {
    "idle": {"frames": ["idle0", "idle0", "idle1", "idle1"], "fps": 4},
    "run": {"frames": ["run0", "run1", "run0", "run1"], "fps": 10},
    "attack": {"frames": ["wind", "wind", "dash", "slash", "follow", "follow"], "fps": 11, "impact": 3},
    "crit": {"frames": ["wind", "wind", "wind", "wind", "dash", "slash", "slash", "follow"], "fps": 10, "impact": 5},
    "hit": {"frames": ["hit", "hit", "idle0"], "fps": 8},
    "death": {"frames": ["hit", "kneel", "kneel", "kneel"], "fps": 5},
}
AXE_BODY = {"sh_b": (2, 3), "sh_f": (13, 3), "hip_b": (5, 13), "hip_f": (11, 13), "head": (-1, -15)}
AXE_LIMBS = {
    "arm_b": ("s", "s", 2.6), "fore_b": ("s", "s", 2.2), "arm_f": ("S", "s", 2.6), "fore_f": ("S", "s", 2.2),
    "thigh_b": ("p", "p", 3.0), "shin_b": ("b", "b", 2.6), "thigh_f": ("P", "p", 3.0), "shin_f": ("B", "b", 2.6),
}

BANDIT = {
    "reach": 118,
    "frame": (80, 76), "foot": (40, 72), "scale": 3,
    "pal": pal(
        K=(40, 24, 24),
        S=(232, 180, 132), s=(184, 124, 88), E=(40, 28, 24), W=(248, 248, 248),
        H=(96, 56, 32), h=(64, 36, 20),
        R=(200, 48, 40), r=(136, 24, 24),
        B=(120, 84, 56), b=(80, 52, 32),
        P=(96, 84, 72), p=(64, 56, 48),
    ),
    "head": [
        "......KKKKKK......",
        "....KKRRRRRRKK....",
        "...KrRRRRRRRRRK...",
        "..KrrRRRRRRRRRRK..",
        ".KKrrrrrrrrrrrrK..",
        "KrKhHHHSSSSSSSSK..",
        "KrKhHHSSSSSKKSSK..",
        ".KKhHSSSSSKWEKSSK.",
        "...KhHSSSSSKEKSSK.",
        "...KhHSSSSSSSSSsK.",
        "...KhHHSSSSSSSSK..",
        "...KhHHHHSSSHHHK..",
        "....KhHHHHHHHHK...",
        ".....KhhHHHHHK....",
        "......KKhhhhK.....",
        "........KKKK......",
    ],
    "torso": [
        "....KKKKKKKK....",
        "..KKSSSSSSSSKK..",
        ".KsSSSSSSSSSSsK.",
        "KsSSSSsSSsSSSSsK",
        "KsSSSSSsSsSSSSsK",
        "KsSSSsSSSSsSSSsK",
        ".KsSSSSSSSSSSsK.",
        ".KssSSSSSSSSssK.",
        ".KsssSSSSSSsssK.",
        "..KssSSSSSSssK..",
        "..KBBBBGGBBBBK..",
        "..KbbbbbbbbbbK..",
        "..KPPPPPPPPPPK..",
        "..KKKKKKKKKKKK..",
    ],
    "body": AXE_BODY,
    "limbs": AXE_LIMBS,
    "weapon": {"type": "axe", "length": 24, "head": 1.0},
    "poses": AXE_POSES,
    "anims": AXE_ANIMS,
}

BOSS = {
    "reach": 125,
    "frame": (80, 76), "foot": (40, 72), "scale": 3,
    "pal": pal(
        K=(32, 20, 24),
        S=(224, 172, 128), s=(176, 116, 84), E=(32, 20, 20), W=(248, 248, 248),
        H=(48, 36, 32), h=(28, 20, 20),
        M=(168, 168, 184), m=(104, 104, 128), x=(240, 232, 208),
        F=(136, 104, 72), f=(88, 64, 44),
        A=(152, 40, 40), a=(96, 24, 32),
        B=(96, 64, 44), b=(60, 40, 28),
        P=(72, 56, 52), p=(48, 36, 36),
    ),
    "head": [
        "KK..............KK",
        "KxK..KKKKKKKK..KxK",
        ".KxKKMMMMMMMMKKxK.",
        "..KxMMMmmmmMMMxK..",
        "..KMMMMMMMMMMMMK..",
        "..KmmmmmmmmmmmmK..",
        "..KhHSSSSSSKKSSK..",
        "..KhHSSSSSKWEKSK..",
        "..KhHSSSSSSKEKSK..",
        "..KhHSSSSSSSSSsK..",
        "..KhHHSSSSSSSSK...",
        "..KhHHHSSSHHHHK...",
        "...KhHHHHHHHHK....",
        "....KhhHHHHHK.....",
        ".....KKhhhhK......",
        ".......KKKK.......",
    ],
    "torso": [
        "..KKKKKKKKKKKK..",
        ".KFFFFFFFFFFFFK.",
        "KFfFFFfFFfFFFfFK",
        "KfFAAAAAAAAAAFfK",
        "KfKAaAAAAAAaAKfK",
        ".KAAaAAAAAAaAAK.",
        ".KAAAaAAAAaAAAK.",
        ".KaAAAAAAAAAAaK.",
        ".KaAAAAAAAAAAaK.",
        "..KaAAAAAAAAaK..",
        "..KBBBBGGBBBBK..",
        "..KbbbbbbbbbbK..",
        "..KPPPPPPPPPPK..",
        "..KKKKKKKKKKKK..",
    ],
    "body": AXE_BODY,
    "limbs": {**AXE_LIMBS, "arm_b": ("a", "a", 2.8), "arm_f": ("A", "a", 2.8)},
    "weapon": {"type": "axe", "length": 26, "head": 1.3},
    "poses": AXE_POSES,
    "anims": AXE_ANIMS,
}

# ============================================================
# 弓箭手：72×72，脚底 y=68
# ============================================================
BOW_POSES = {
    "idle0": P((26, 36), (26, 46), (29, 50), (38, 45), (43, 50), (29, 58), (27, 66), (39, 58), (43, 66), wpn=0),
    "idle1": P((26, 37), (26, 47), (29, 51), (38, 46), (43, 51), (29, 59), (27, 66), (39, 59), (43, 66), wpn=0),
    "run0": P((30, 37), (25, 45), (21, 50), (40, 45), (45, 50), (27, 57), (18, 64), (42, 57), (48, 65), wpn=0, head_dx=2),
    "run1": P((30, 36), (28, 45), (27, 51), (38, 46), (42, 51), (31, 57), (29, 66), (37, 56), (40, 63), wpn=0, head_dx=2),
    "aim0": P((26, 36), (34, 43), (40, 41), (44, 40), (50, 40), (28, 58), (24, 66), (40, 58), (45, 66), wpn=0, wpn_args={"draw": 0.0, "arrow": True}),
    "aim1": P((25, 36), (24, 41), (31, 39), (44, 40), (50, 40), (28, 58), (23, 66), (40, 58), (45, 66), wpn=0, wpn_args={"draw": 1.0, "arrow": True}),
    "release": P((25, 36), (20, 40), (24, 36), (44, 40), (51, 40), (28, 58), (23, 66), (40, 58), (45, 66), wpn=0, wpn_args={"draw": 0.0, "arrow": False}),
    "hit": P((22, 37), (21, 47), (18, 50), (34, 46), (38, 51), (26, 58), (22, 66), (35, 59), (39, 66), wpn=0, head_dx=-3),
    "kneel": P((27, 46), (26, 55), (28, 61), (38, 54), (43, 60), (23, 64), (14, 66), (40, 58), (43, 66), wpn=0, head_dx=-1, head_dy=1),
}
BOW_ANIMS = {
    "idle": {"frames": ["idle0", "idle0", "idle1", "idle1"], "fps": 4},
    "run": {"frames": ["run0", "run1", "run0", "run1"], "fps": 10},
    "attack": {"frames": ["aim0", "aim1", "aim1", "release", "release", "aim0"], "fps": 9, "impact": 3},
    "crit": {"frames": ["aim0", "aim1", "aim1", "aim1", "aim1", "release", "release", "aim0"], "fps": 9, "impact": 5},
    "hit": {"frames": ["hit", "hit", "idle0"], "fps": 8},
    "death": {"frames": ["hit", "kneel", "kneel", "kneel"], "fps": 5},
}
ARCHER = {
    "reach": 140,
    "frame": (72, 72), "foot": (36, 68), "scale": 3,
    "pal": pal(
        K=(32, 24, 20),
        O=(120, 112, 64), o=(80, 72, 40),
        S=(240, 200, 160), s=(200, 150, 112), E=(40, 28, 24), W=(248, 248, 248),
        T=(152, 56, 48), t=(104, 32, 32),
        B=(112, 80, 56), b=(68, 48, 36),
    ),
    "head": [
        "......KKKKKK......",
        "....KKOOOOOOKK....",
        "...KOOOOOOOOOOK...",
        "..KoOOOOOOOOOOOK..",
        ".KooOOOOOOOOOOOK..",
        ".KooOOOoSSSSSSOK..",
        ".KoOOOoSSSSKKSSK..",
        ".KoOOoSSSSKWEKSK..",
        ".KoOOoSSSSSKEKSK..",
        ".KooOoSSSSSSSSSK..",
        "..KoOOoSSSSSSsK...",
        "...KoOOooSSsKK....",
        "....KKoOOooK......",
        "......KKKKK.......",
    ],
    "torso": [
        "...KKKKKKK....",
        "..KOOOOOOOKK..",
        ".KoOOOOOOOOOK.",
        "KToooOOOOoooK.",
        "KTTKooooooKTTK",
        "KtTTKKKKKKTTtK",
        "KtTTTBTTTTTTtK",
        "KtTTTTBTTTTTtK",
        ".KtTTTTBTTTtK.",
        ".KtTTTTTBTTtK.",
        ".KttTTTTTTttK.",
        "..KbbbGGbbbK..",
        "..KKKKKKKKKK..",
    ],
    "skirt": [
        ".KtTTTTTTTTTTtK.",
        "KttTTTTTTTTTTttK",
        "KtTTTtTTTTtTTTtK",
        "KtTTtKTTTtKTTTtK",
        ".KtK..KtK..KtK..",
        "..K....K....K...",
    ],
    "body": {**SWORD_BODY, "head": (-4, -13)},
    "limbs": {
        "arm_b": ("t", "t", 2.0), "fore_b": ("s", "s", 1.6), "arm_f": ("T", "t", 2.0), "fore_f": ("S", "s", 1.6),
        "thigh_b": ("b", "b", 2.4), "shin_b": ("b", "b", 2.2), "thigh_f": ("b", "b", 2.4), "shin_f": ("B", "b", 2.2),
    },
    "weapon": {"type": "bow"},
    "poses": BOW_POSES,
    "anims": BOW_ANIMS,
}

# ============================================================
# 巴尔托：骑马圣骑士持枪，124×96，蹄底 y=92
# ============================================================
HORSE = [
    "....................................................KK..KK......",
    "...................................................KQK.KQK......",
    "..................................................KQQKKQQK......",
    "................................................KKZQQQQQQK......",
    "...............................................KZZQQQQQQQQK.....",
    "..............................................KZZQQQQQQQQQQK....",
    ".............................................KZZQQQQQKEQQQQQK...",
    "............................................KZZQQQQQQKKQQQQQQK..",
    "...........................................KZZQQQQQQQQQQQQQQQQK.",
    "..........................................KZZQQQQqQQQKKqqQQQQQK.",
    ".........................................KZZQQQQqQQK..KKqqqqQQK",
    "........................................KZZQQQQqQQK.....KKqqqqK",
    "..............KKKKKKKKKKKKKKKKKKKKKKKKKKZZQQQQqQQK.......KKKKK..",
    "...KKK......KTTTTTTTTTTTTTTTTTTTTTTTTKKQQQQQqQQK................",
    "..KZZZK....KTTTTTTTTTTTTTTTTTTTTTTTTTTKQQQQqQQK.................",
    ".KZZZZK...KTTTTTTTTTTTTTTTTTTTTTTTTTTTTKQQqQQQK.................",
    ".KZZZK...KtTTTTTTTTTTTTTTTTTTTTTTTTTTTTKQqQQQK..................",
    "KZZZK....KtTTTTTTTTTTTTTTTTTTTTTTTTTTTTtKqQQQK..................",
    "KZZK....KqtTTTTTTTTTTTTTTTTTTTTTTTTTTTTtKqQQK...................",
    "KZZK....KqtTTTTTTTTTTTTTTTTTTTTTTTTTTTTtKqQQK...................",
    "KZZK....KqttTTTTTTTTTTTTTTTTTTTTTTTTTTttKqQQK...................",
    "KZK.....KQqttttttttttttttttttttttttttttKqQQK....................",
    "KZK.....KQQqggggggggggggggggggggggggggKqqQK.....................",
    ".KZK....KQQQqqqqqqqqqqqqqqqqqqqqqqqqqqqqQK......................",
    ".KZK.....KQQQQqqqqqqqqqqqqqqqqqqqqqqqqQQK.......................",
    "..KK......KKQQQQQQQQQQQQQQQQQQQQQQQQQKK.........................",
    "............KKKKKKKKKKKKKKKKKKKKKKKKK...........................",
]
HORSE_ATTACH = {"hind_b": (13, 24), "hind_f": (17, 24), "fore_b": (33, 24), "fore_f": (37, 24)}


def _horse_pose(hx, hy, legs, rider, eb, hb, ef, hf, wpn, head_dx=0):
    """legs：四条腿 (膝, 蹄)；rider：骑手躯干左上相对马身左上；手的坐标相对骑手躯干左上"""
    tx, ty = hx + rider[0], hy + rider[1]
    d = P((tx, ty), (tx + eb[0], ty + eb[1]), (tx + hb[0], ty + hb[1]), (tx + ef[0], ty + ef[1]), (tx + hf[0], ty + hf[1]), wpn=wpn, head_dx=head_dx)
    d["horse"] = (hx, hy)
    d.update({k: ((hx + v[0], hy + v[1]), (hx + v[2], hy + v[3])) for k, v in legs.items()})
    # 骑手的腿：从髋往前下，脚踩马镫，挂在马腹侧
    d["rider_knee"] = (tx + 13, ty + 17)
    d["rider_foot"] = (tx + 11, ty + 24)
    return d


HX, HY = 24, 49
STAND = {"hind_b": (12, 33, 12, 42), "hind_f": (17, 33, 18, 42), "fore_b": (33, 33, 33, 42), "fore_f": (38, 33, 39, 42)}
GALLOP0 = {"hind_b": (9, 32, 2, 39), "hind_f": (14, 33, 8, 41), "fore_b": (40, 31, 48, 35), "fore_f": (43, 32, 51, 38)}
GALLOP1 = {"hind_b": (16, 33, 22, 41), "hind_f": (20, 33, 25, 42), "fore_b": (31, 33, 27, 42), "fore_f": (35, 33, 31, 42)}
RIDER = (20, 1)
LANCE_POSES = {
    "idle0": _horse_pose(HX, HY, STAND, RIDER, (4, 8), (12, 10), (15, 6), (18, 2), wpn=-75),
    "idle1": _horse_pose(HX, HY + 1, STAND, RIDER, (4, 8), (12, 10), (15, 6), (18, 2), wpn=-75),
    "run0": _horse_pose(HX, HY - 2, GALLOP0, RIDER, (4, 8), (12, 10), (15, 6), (19, 5), wpn=-15),
    "run1": _horse_pose(HX, HY, GALLOP1, RIDER, (4, 8), (12, 10), (15, 6), (19, 5), wpn=-12),
    "wind": _horse_pose(HX - 2, HY, STAND, RIDER, (3, 8), (6, 9), (9, 7), (12, 5), wpn=-5, head_dx=-1),
    "thrust": _horse_pose(HX + 4, HY - 2, GALLOP0, RIDER, (8, 7), (16, 7), (20, 5), (27, 4), wpn=0),
    "follow": _horse_pose(HX + 3, HY, GALLOP1, RIDER, (7, 8), (14, 9), (18, 6), (24, 7), wpn=8),
    "hit": _horse_pose(HX - 3, HY - 1, STAND, RIDER, (3, 8), (8, 10), (12, 7), (15, 3), wpn=-60, head_dx=-2),
}
LANCE_ANIMS = {
    "idle": {"frames": ["idle0", "idle0", "idle1", "idle1"], "fps": 4},
    "run": {"frames": ["run0", "run1", "run0", "run1"], "fps": 10},
    "attack": {"frames": ["wind", "wind", "thrust", "thrust", "follow"], "fps": 10, "impact": 2},
    "crit": {"frames": ["wind", "wind", "wind", "wind", "thrust", "thrust", "follow"], "fps": 9, "impact": 4},
    "hit": {"frames": ["hit", "hit", "idle0"], "fps": 8},
    "death": {"frames": ["hit", "hit", "hit", "hit"], "fps": 5},
}
BALTO = {
    "reach": 185,
    "frame": (124, 96), "foot": (54, 92), "scale": 3,
    "pal": pal(
        K=(24, 24, 40),
        W=(232, 232, 240), w=(168, 168, 184), Y=(248, 248, 248),
        S=(240, 204, 168), s=(200, 152, 120), E=(32, 32, 56),
        M=(200, 208, 224), m=(128, 136, 160),
        T=(72, 112, 200), t=(40, 64, 136),
        Q=(160, 104, 64), q=(112, 68, 40), Z=(56, 36, 28),
        B=(96, 72, 56), b=(60, 44, 36),
        g=(248, 208, 80),
    ),
    "head": [
        "......KKKKKK......",
        "....KKWWWWWWKK....",
        "...KwWWWWWWWWWK...",
        "..KwWWWWWWWWWWWK..",
        ".KwwWWwSSSSSSWWK..",
        ".KwwWwSSSSKKSSSK..",
        ".KwWwSSSSKYEKSSK..",
        ".KwWwSSSSSKEKSSK..",
        ".KwWwSSSSSSSSSsK..",
        ".KwwWWWSSSSSWWK...",
        "..KwWWWWWWWWWK....",
        "...KwWWWWWWWK.....",
        "....KKwwwwKK......",
        "......KKKK........",
    ],
    "torso": [
        "...KKKKKKKK...",
        "..KMMMMMMMMKK.",
        ".KmMMMMMMMMMMK",
        "KTKmMMMMMMMmKT",
        "KTTKmmMMMmmKTK",
        "KtTTKKKKKKKTtK",
        "KtTMMMMMMMMTtK",
        ".KtMMmMMmMMtK.",
        ".KtTMMMMMMTtK.",
        "..KTTTTTTTTK..",
        "..KbbbGGbbbK..",
        "..KKKKKKKKKK..",
    ],
    "body": {"sh_b": (2, 3), "sh_f": (11, 3), "hip_b": (5, 11), "hip_f": (8, 11), "head": (-3, -13)},
    "limbs": {
        "arm_b": ("m", "m", 2.0), "fore_b": ("m", "m", 1.7), "arm_f": ("M", "m", 2.0), "fore_f": ("M", "m", 1.7),
        "thigh_b": ("t", "t", 2.4), "shin_b": ("b", "b", 2.0), "thigh_f": ("T", "t", 2.4), "shin_f": ("B", "b", 2.0),
    },
    "mount": {"art": HORSE, "attach": HORSE_ATTACH},
    "weapon": {"type": "lance", "length": 40, "butt": 12},
    "poses": LANCE_POSES,
    "anims": LANCE_ANIMS,
}


# ============================================================
# 各角色专属招式：普攻和必杀是两套动作；主角缇娅和同用剑的探子招式不同
# ============================================================
def shift_all(poses, dy):
    """整套姿势下移 dy（画布加高给跳跃留空间时用）"""
    out = {}
    for name, pose in poses.items():
        q = {}
        for k, v in pose.items():
            if isinstance(v, tuple) and len(v) == 2 and all(isinstance(c, (int, float)) for c in v):
                q[k] = (v[0], v[1] + dy)
            else:
                q[k] = v
        out[name] = q
    return out


# ---- 缇娅（72×100，地面 y=96）：普攻 = 压低身形拔刀突斩；必杀 = 跃起空中回旋、俯冲斩落 ----
TIA_POSES = shift_all(SWORD_POSES, 28)
TIA_POSES.update({
    "crouch": P((24, 70), (22, 79), (26, 83), (32, 77), (28, 74), (24, 87), (19, 95), (36, 85), (41, 95), wpn=-165, head_dx=-1, head_dy=1),
    "leap": P((28, 38), (28, 40), (33, 32), (36, 34), (35, 25), (30, 58), (26, 64), (40, 56), (41, 64), wpn=-95, head_dx=1),
    "spin": P((32, 34), (30, 44), (26, 47), (30, 41), (24, 43), (34, 54), (30, 61), (44, 53), (46, 61), wpn=-175, head_dx=1),
    "dive": P((36, 50), (38, 58), (44, 60), (48, 56), (54, 60), (34, 70), (26, 75), (46, 68), (50, 77), wpn=45, head_dx=2, wpn_args={"length": 30}),
    "land": P((36, 72), (38, 82), (44, 84), (50, 80), (58, 82), (32, 92), (24, 96), (50, 86), (55, 96), wpn=8, head_dx=2, head_dy=1, wpn_args={"length": 30}),
})
TIA_ANIMS = {
    "idle": {"frames": ["idle0", "idle0", "idle1", "idle1"], "fps": 4},
    "run": {"frames": ["run0", "run1", "run0", "run1"], "fps": 10},
    "attack": {"frames": ["crouch", "crouch", "dash", "slash", "follow", "follow"], "fps": 12, "impact": 3},
    "crit": {"frames": ["crouch", "crouch", "leap", "leap", "spin", "spin", "dive", "land", "land", "land"], "fps": 10, "impact": 6},
    "hit": {"frames": ["hit", "hit", "idle0"], "fps": 8},
    "death": {"frames": ["hit", "kneel", "kneel", "kneel"], "fps": 5},
}

# ---- 探子：普攻 = 短剑直刺；必杀 = 斜劈接回身直刺（两段） ----
SCOUT_POSES = dict(SWORD_POSES)
SCOUT_POSES.update({
    "draw": P((27, 38), (26, 48), (29, 51), (32, 45), (27, 46), (28, 59), (22, 66), (39, 59), (44, 66), wpn=-5, head_dx=-1),
    "thrust": P((34, 39), (32, 49), (29, 52), (46, 43), (54, 43), (32, 59), (22, 66), (49, 59), (55, 66), wpn=0, head_dx=2),
    "high": P((32, 38), (30, 48), (27, 51), (42, 37), (48, 33), (30, 59), (21, 66), (46, 58), (52, 66), wpn=-35, head_dx=2),
})
SCOUT_ANIMS = {
    "idle": SWORD_ANIMS["idle"], "run": SWORD_ANIMS["run"],
    "attack": {"frames": ["draw", "draw", "thrust", "thrust", "idle0"], "fps": 12, "impact": 2},
    "crit": {"frames": ["wind", "wind", "high", "slash", "follow", "draw", "thrust", "thrust", "idle0"], "fps": 12, "impact": 6},
    "hit": SWORD_ANIMS["hit"], "death": SWORD_ANIMS["death"],
}

# ---- 山贼：普攻 = 举斧劈下；必杀 = 抡斧旋风斩一整圈 ----
BANDIT_POSES = dict(AXE_POSES)
BANDIT_POSES.update({
    "spin0": P((30, 36), (30, 46), (24, 48), (34, 44), (26, 46), (33, 57), (27, 71), (45, 57), (50, 71), wpn=-170, head_dx=-1),
    "spin1": P((32, 34), (34, 28), (40, 22), (40, 28), (40, 20), (33, 56), (26, 71), (46, 57), (51, 71), wpn=-90),
    "spin2": P((36, 38), (40, 44), (50, 44), (50, 40), (56, 42), (35, 58), (25, 71), (53, 58), (59, 71), wpn=10, head_dx=2),
    "spin3": P((38, 40), (42, 48), (48, 54), (48, 50), (50, 56), (36, 59), (26, 71), (54, 59), (60, 71), wpn=100, head_dx=2),
    "spin4": P((36, 38), (36, 48), (32, 52), (40, 48), (34, 52), (35, 58), (27, 71), (52, 58), (57, 71), wpn=160, head_dx=1),
})
BANDIT_ANIMS = dict(AXE_ANIMS)
BANDIT_ANIMS["crit"] = {"frames": ["spin0", "spin0", "spin1", "spin2", "spin3", "spin4", "spin0", "spin1", "spin2", "spin3", "follow"], "fps": 14, "impact": 8}

# ---- 头目（80×100，地面 y=96）：普攻 = 劈；必杀 = 跃起砸地 ----
BOSS_POSES = shift_all(AXE_POSES, 24)
BOSS_POSES.update({
    "crouch": P((30, 66), (30, 74), (34, 78), (40, 70), (42, 62), (32, 84), (26, 95), (44, 84), (50, 95), wpn=-150, head_dx=-1, head_dy=1),
    "jump": P((32, 42), (34, 36), (40, 30), (40, 34), (38, 28), (34, 62), (30, 70), (44, 60), (46, 70), wpn=-95),
    "smash": P((38, 66), (44, 74), (54, 78), (50, 70), (58, 76), (34, 85), (24, 95), (56, 84), (62, 95), wpn=70, head_dx=2, head_dy=1, wpn_args={"length": 28}),
})
BOSS_ANIMS = dict(AXE_ANIMS)
BOSS_ANIMS["crit"] = {"frames": ["crouch", "crouch", "crouch", "jump", "jump", "jump", "smash", "smash", "smash", "follow"], "fps": 11, "impact": 6}

# ---- 弓箭手：必杀 = 久蓄力（画面上加光环和发光箭） ----
ARCHER_ANIMS = dict(BOW_ANIMS)
ARCHER_ANIMS["crit"] = {"frames": ["aim0", "aim1", "aim1", "aim1", "aim1", "aim1", "aim1", "release", "release", "aim0"], "fps": 9, "impact": 7}

# ---- 巴尔托：普攻 = 突刺；必杀 = 头顶回旋长枪后冲锋刺击 ----
LANCE_POSES.update({
    "raise": _horse_pose(HX - 1, HY, STAND, RIDER, (4, 6), (10, 2), (14, 2), (17, -4), wpn=-100),
    "twirl1": _horse_pose(HX - 1, HY - 1, STAND, RIDER, (4, 6), (10, 2), (14, 2), (17, -4), wpn=-165),
    "twirl2": _horse_pose(HX - 1, HY - 1, GALLOP1, RIDER, (4, 6), (10, 2), (14, 2), (17, -4), wpn=150),
    "charge": _horse_pose(HX + 9, HY - 3, GALLOP0, RIDER, (9, 7), (17, 7), (21, 5), (28, 4), wpn=0, head_dx=1),
})
LANCE_ANIMS["crit"] = {"frames": ["raise", "twirl1", "twirl2", "raise", "twirl1", "twirl2", "wind", "charge", "charge", "follow"], "fps": 11, "impact": 7}

TIA.update({"frame": (72, 100), "foot": (36, 96), "poses": TIA_POSES, "anims": TIA_ANIMS})
SCOUT.update({"poses": SCOUT_POSES, "anims": SCOUT_ANIMS})
BANDIT.update({"frame": (80, 88), "foot": (40, 84), "poses": shift_all(BANDIT_POSES, 12), "anims": BANDIT_ANIMS})
BOSS.update({"frame": (80, 100), "foot": (40, 96), "poses": BOSS_POSES, "anims": BOSS_ANIMS})
ARCHER.update({"anims": ARCHER_ANIMS})

# ---- 第 2–5 章新角色的数据在 fe_combat_art_ch2.py（要用上面这些骨架，所以放在最后导入）----
from fe_combat_art_ch2 import UNITS_CH2  # noqa: E402

from fe_combat_art_classes import UNITS_CLASSES  # noqa: E402

from fe_combat_art_ch6 import UNITS_CH6  # noqa: E402

from fe_combat_art_ch8 import UNITS_CH8  # noqa: E402

UNITS = {
    "tia": TIA,
    "balto": BALTO,
    "bandit": BANDIT,
    "archer": ARCHER,
    "scout": SCOUT,
    "boss": BOSS,
    **UNITS_CH2,
    **UNITS_CLASSES,
    **UNITS_CH6,
    **UNITS_CH8,
}
