class_name GameData
## 静态数据：武器、职业、地形、道具、武器相克、武器等级

## 武器：type 类型 / mt 威力 / hit 命中 / crit 必杀 / rng 射程 / rank 需要的武器等级（"prf" = 专属）
## uses 耐久（-1 = 不会坏）/ wexp 每次战斗涨的武器经验 / magic 魔法（打魔防） / prf 专属的单位 id
const WEAPONS := {
	"iron_sword": {"name": "铁剑", "type": "sword", "mt": 5, "hit": 90, "crit": 5, "rng": [1], "rank": "E", "uses": 46, "wexp": 1},
	# 炎刃：缇娅觉醒后的专属剑，沿用剑的突进斩击，不会坏
	"ember_blade": {"name": "炎刃", "type": "sword", "mt": 7, "hit": 90, "crit": 5, "rng": [1], "rank": "prf", "prf": ["tia"], "uses": -1, "wexp": 2},
	"silver_lance": {"name": "银枪", "type": "lance", "mt": 12, "hit": 80, "crit": 5, "rng": [1], "rank": "A", "uses": 20, "wexp": 1},
	"javelin": {"name": "投枪", "type": "lance", "mt": 7, "hit": 70, "crit": 0, "rng": [1, 2], "rank": "D", "uses": 20, "wexp": 1},
	"iron_axe": {"name": "铁斧", "type": "axe", "mt": 7, "hit": 75, "crit": 0, "rng": [1], "rank": "E", "uses": 45, "wexp": 1},
	"war_axe": {"name": "战斧", "type": "axe", "mt": 9, "hit": 65, "crit": 0, "rng": [1], "rank": "D", "uses": 30, "wexp": 1},
	"iron_bow": {"name": "铁弓", "type": "bow", "mt": 6, "hit": 80, "crit": 5, "rng": [2], "rank": "E", "uses": 45, "wexp": 1},
	"steel_sword": {"name": "钢剑", "type": "sword", "mt": 8, "hit": 75, "crit": 0, "rng": [1], "rank": "D", "uses": 30, "wexp": 1},
	# 细剑：艾德里克的家传剑，轻、准、易出必杀
	"rapier": {"name": "细剑", "type": "sword", "mt": 6, "hit": 95, "crit": 10, "rng": [1], "rank": "prf", "prf": ["edric"], "uses": 40, "wexp": 2},
	"iron_lance": {"name": "铁枪", "type": "lance", "mt": 7, "hit": 80, "crit": 0, "rng": [1], "rank": "E", "uses": 45, "wexp": 1},
	"steel_lance": {"name": "钢枪", "type": "lance", "mt": 10, "hit": 70, "crit": 0, "rng": [1], "rank": "D", "uses": 30, "wexp": 1},
	"hand_axe": {"name": "手斧", "type": "axe", "mt": 7, "hit": 60, "crit": 0, "rng": [1, 2], "rank": "E", "uses": 20, "wexp": 1},
	"short_bow": {"name": "短弓", "type": "bow", "mt": 5, "hit": 85, "crit": 5, "rng": [2], "rank": "E", "uses": 22, "wexp": 1},
	"steel_bow": {"name": "钢弓", "type": "bow", "mt": 9, "hit": 70, "crit": 0, "rng": [2], "rank": "D", "uses": 30, "wexp": 1},
	# 治疗杖：不能攻击，也不能反击。回复量 = mt + 使用者的力（魔力）
	"heal_staff": {"name": "治疗杖", "type": "staff", "mt": 8, "hit": 100, "crit": 0, "rng": [1], "rank": "E", "uses": 30, "wexp": 1},
	"mend_staff": {"name": "回复杖", "type": "staff", "mt": 16, "hit": 100, "crit": 0, "rng": [1], "rank": "C", "uses": 20, "wexp": 2},
	# ---- 魔法：打魔防，射程 1~2。三系相克：理 → 光 → 暗 → 理 ----
	"fire": {"name": "火焰", "type": "anima", "mt": 5, "hit": 90, "crit": 0, "rng": [1, 2], "rank": "E", "uses": 40, "wexp": 1, "magic": true},
	"thunder": {"name": "雷霆", "type": "anima", "mt": 8, "hit": 80, "crit": 5, "rng": [1, 2], "rank": "D", "uses": 35, "wexp": 1, "magic": true},
	"elfire": {"name": "炎蛇", "type": "anima", "mt": 10, "hit": 85, "crit": 0, "rng": [1, 2], "rank": "C", "uses": 30, "wexp": 2, "magic": true},
	"lightning": {"name": "圣光", "type": "light", "mt": 4, "hit": 95, "crit": 5, "rng": [1, 2], "rank": "E", "uses": 35, "wexp": 1, "magic": true},
	"flux": {"name": "暗影", "type": "dark", "mt": 7, "hit": 80, "crit": 0, "rng": [1, 2], "rank": "D", "uses": 45, "wexp": 1, "magic": true},
	# ---- 第二篇起 ----
	"silver_sword": {"name": "银剑", "type": "sword", "mt": 13, "hit": 80, "crit": 0, "rng": [1], "rank": "A", "uses": 20, "wexp": 1},
	"killing_edge": {"name": "暗刃", "type": "sword", "mt": 9, "hit": 75, "crit": 30, "rng": [1], "rank": "C", "uses": 20, "wexp": 1},
	"armorslayer": {"name": "破甲剑", "type": "sword", "mt": 8, "hit": 80, "crit": 0, "rng": [1], "rank": "D", "uses": 18, "wexp": 1, "slay": "armor"},
	"horseslayer": {"name": "拒马枪", "type": "lance", "mt": 7, "hit": 70, "crit": 0, "rng": [1], "rank": "D", "uses": 16, "wexp": 1, "slay": "mounted"},
	"killer_lance": {"name": "锐锋枪", "type": "lance", "mt": 10, "hit": 70, "crit": 30, "rng": [1], "rank": "C", "uses": 20, "wexp": 1},
	"steel_axe": {"name": "钢斧", "type": "axe", "mt": 11, "hit": 65, "crit": 0, "rng": [1], "rank": "D", "uses": 30, "wexp": 1},
	"killer_axe": {"name": "锐锋斧", "type": "axe", "mt": 11, "hit": 65, "crit": 30, "rng": [1], "rank": "C", "uses": 20, "wexp": 1},
	"silver_axe": {"name": "银斧", "type": "axe", "mt": 15, "hit": 70, "crit": 0, "rng": [1], "rank": "A", "uses": 20, "wexp": 1},
	"tomahawk": {"name": "回旋斧", "type": "axe", "mt": 13, "hit": 65, "crit": 0, "rng": [1, 2], "rank": "A", "uses": 15, "wexp": 1},
	"silver_bow": {"name": "银弓", "type": "bow", "mt": 13, "hit": 75, "crit": 0, "rng": [2], "rank": "A", "uses": 20, "wexp": 1},
	"longbow": {"name": "长弓", "type": "bow", "mt": 5, "hit": 65, "crit": 0, "rng": [2, 3], "rank": "C", "uses": 20, "wexp": 1},
	"killer_bow": {"name": "锐锋弓", "type": "bow", "mt": 9, "hit": 75, "crit": 30, "rng": [2], "rank": "C", "uses": 20, "wexp": 1},
	"bolganone": {"name": "熔岩爆", "type": "anima", "mt": 14, "hit": 75, "crit": 0, "rng": [1, 2], "rank": "B", "uses": 20, "wexp": 3, "magic": true},
	"shine": {"name": "闪光", "type": "light", "mt": 6, "hit": 90, "crit": 8, "rng": [1, 2], "rank": "D", "uses": 30, "wexp": 1, "magic": true},
	"divine": {"name": "神圣", "type": "light", "mt": 10, "hit": 85, "crit": 10, "rng": [1, 2], "rank": "B", "uses": 25, "wexp": 2, "magic": true},
	"nosferatu": {"name": "吸血", "type": "dark", "mt": 10, "hit": 70, "crit": 0, "rng": [1, 2], "rank": "C", "uses": 20, "wexp": 2, "magic": true},
	"fenrir": {"name": "冥狼", "type": "dark", "mt": 15, "hit": 70, "crit": 0, "rng": [1, 2], "rank": "A", "uses": 20, "wexp": 3, "magic": true},
	# 灰烬傀儡的武器：灰烬凝成的爪刃（不会坏，敌方专属）
	"ash_claw": {"name": "灰烬之爪", "type": "sword", "mt": 9, "hit": 85, "crit": 10, "rng": [1], "rank": "C", "uses": -1, "wexp": 1},
	# 加雷斯的家传战斧
	"wolf_axe": {"name": "苍狼战斧", "type": "axe", "mt": 12, "hit": 75, "crit": 5, "rng": [1], "rank": "prf", "prf": ["gareth"], "uses": -1, "wexp": 2},
}

## 物理三角：剑克斧, 斧克枪, 枪克剑；魔法三角：理克光, 光克暗, 暗克理
const TRIANGLE := {"sword": "axe", "axe": "lance", "lance": "sword", "anima": "light", "light": "dark", "dark": "anima"}

## 武器等级：累计武器经验达到这个值就升一级（GBA 火纹的门槛）
const RANKS := ["E", "D", "C", "B", "A", "S"]
const RANK_EXP := {"E": 1, "D": 31, "C": 71, "B": 121, "A": 181, "S": 251}
const WEAPON_TYPES := ["sword", "lance", "axe", "bow", "anima", "light", "dark", "staff"]
const TYPE_NAMES := {"sword": "剑", "lance": "枪", "axe": "斧", "bow": "弓", "anima": "理", "light": "光", "dark": "暗", "staff": "杖"}

## 职业：ranks 能用的武器类型及初始等级 / promote 转职目标 / item 需要的转职道具 / bonus 转职加成
## con 体格（救出：被救者体格 ≤ 救出者的救出值）/ mounted 骑马 / flying 飞行
const CLASSES := {
	# ---- 物理基础职业 ----
	"剑士": {"ranks": {"sword": "D"}, "promote": "剑圣", "item": "hero_crest", "con": 6,
		"bonus": {"hp": 5, "pwr": 2, "skl": 2, "spd": 1, "dfn": 2, "res": 2, "mov": 1}},
	"佣兵": {"ranks": {"sword": "D"}, "promote": "勇者", "item": "hero_crest", "con": 9,
		"bonus": {"hp": 5, "pwr": 2, "skl": 2, "spd": 2, "dfn": 2, "res": 1, "mov": 1}},
	"战士": {"ranks": {"axe": "D"}, "promote": "勇士", "item": "hero_crest", "con": 11,
		"bonus": {"hp": 4, "pwr": 2, "skl": 3, "spd": 1, "dfn": 2, "res": 2, "mov": 1}},
	"山贼": {"ranks": {"axe": "D"}, "promote": "狂战士", "item": "hero_crest", "con": 12,
		"bonus": {"hp": 4, "pwr": 1, "skl": 1, "spd": 1, "dfn": 2, "res": 2, "mov": 1}},
	"枪兵": {"ranks": {"lance": "D"}, "promote": "枪斗士", "item": "hero_crest", "con": 9,
		"bonus": {"hp": 4, "pwr": 2, "skl": 2, "spd": 2, "dfn": 2, "res": 2, "mov": 1}},
	"骑士": {"ranks": {"lance": "D"}, "promote": "圣骑士", "item": "hero_crest", "con": 9, "mounted": true,
		"bonus": {"hp": 2, "pwr": 1, "skl": 1, "spd": 1, "dfn": 2, "res": 1, "mov": 1}},
	"重甲兵": {"ranks": {"lance": "D"}, "promote": "将军", "item": "hero_crest", "con": 13,
		"bonus": {"hp": 4, "pwr": 2, "skl": 2, "spd": 3, "dfn": 2, "res": 3, "mov": 1}},
	"弓箭手": {"ranks": {"bow": "D"}, "promote": "狙击手", "item": "hero_crest", "con": 7,
		"bonus": {"hp": 3, "pwr": 1, "skl": 2, "spd": 2, "dfn": 2, "res": 3, "mov": 1}},
	"天马骑士": {"ranks": {"lance": "D"}, "promote": "隼骑士", "item": "overlord_crest", "con": 5, "flying": true,
		"bonus": {"hp": 5, "pwr": 2, "skl": 0, "spd": 0, "dfn": 2, "res": 2, "mov": 1}},
	"盗贼": {"ranks": {"sword": "E"}, "promote": "刺客", "item": "overlord_crest", "con": 6,
		"bonus": {"hp": 3, "pwr": 1, "skl": 0, "spd": 0, "dfn": 2, "res": 2, "mov": 1}},
	# ---- 魔法基础职业 ----
	"修女": {"ranks": {"staff": "D"}, "promote": "司祭", "item": "sage_crest", "con": 5,
		"bonus": {"hp": 3, "pwr": 1, "skl": 2, "spd": 1, "dfn": 2, "res": 2, "mov": 1}, "magic": true},
	"魔道士": {"ranks": {"anima": "D"}, "promote": "贤者", "item": "sage_crest", "con": 6,
		"bonus": {"hp": 4, "pwr": 1, "skl": 1, "spd": 1, "dfn": 2, "res": 3, "mov": 1}, "magic": true},
	"暗法师": {"ranks": {"dark": "D"}, "promote": "德鲁伊", "item": "sage_crest", "con": 8,
		"bonus": {"hp": 4, "pwr": 0, "skl": 3, "spd": 2, "dfn": 2, "res": 2, "mov": 1}, "magic": true},
	# ---- 上级职业（转职后多一种武器，初始等级取原武器等级与这里的较高者） ----
	"剑圣": {"ranks": {"sword": "C"}, "con": 7},
	"勇者": {"ranks": {"sword": "C", "axe": "D"}, "con": 11},
	"勇士": {"ranks": {"axe": "C", "bow": "D"}, "con": 13},
	"狂战士": {"ranks": {"axe": "C"}, "con": 14},
	"枪斗士": {"ranks": {"lance": "C", "sword": "D"}, "con": 11},
	"圣骑士": {"ranks": {"lance": "C", "sword": "D"}, "con": 11, "mounted": true},
	"将军": {"ranks": {"lance": "C", "axe": "D"}, "con": 15},
	"狙击手": {"ranks": {"bow": "C"}, "con": 8},
	"隼骑士": {"ranks": {"lance": "C", "sword": "D"}, "con": 6, "flying": true},
	"刺客": {"ranks": {"sword": "C"}, "con": 7},
	"司祭": {"ranks": {"staff": "C", "light": "D"}, "con": 6, "magic": true},
	"贤者": {"ranks": {"anima": "C", "staff": "D"}, "con": 7, "magic": true},
	"德鲁伊": {"ranks": {"dark": "C", "staff": "D"}, "con": 9, "magic": true},
	# ---- 剧情 / 敌方专属 ----
	"炎刃使": {"ranks": {"sword": "C"}, "con": 7},
	"领主骑士": {"ranks": {"sword": "C"}, "con": 7},
	"山贼头目": {"ranks": {"axe": "B"}, "con": 14},
	"佣兵队长": {"ranks": {"sword": "B"}, "con": 11},
	"圣焰审判官": {"ranks": {"lance": "A", "sword": "C"}, "con": 11, "mounted": true},
	"追捕队长": {"ranks": {"lance": "B", "sword": "C"}, "con": 11, "mounted": true},
	"探子": {"ranks": {"sword": "D"}, "con": 6},
	# ---- 第二篇 ----
	"修士": {"ranks": {"staff": "D"}, "promote": "司祭", "item": "sage_crest", "con": 7,
		"bonus": {"hp": 3, "pwr": 1, "skl": 2, "spd": 1, "dfn": 2, "res": 2, "mov": 1}, "magic": true},
	"王子": {"ranks": {"axe": "C"}, "con": 13},
	"灰烬傀儡": {"ranks": {"sword": "B"}, "con": 10},
}

const TERRAIN := {
	".": {"name": "平原", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	"R": {"name": "道路", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	"F": {"name": "森林", "pass": true, "cost": 2, "dfn": 0, "avo": 10},
	"H": {"name": "民居", "pass": true, "cost": 1, "dfn": 0, "avo": 5},
	"B": {"name": "木桥", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	"~": {"name": "河流", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	"M": {"name": "山地", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	"f": {"name": "农田", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	"g": {"name": "高地", "pass": true, "cost": 1, "dfn": 0, "avo": 5},
	"s": {"name": "沙滩", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	"W": {"name": "水井", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	"X": {"name": "崖壁", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	# 第二章焦土。程序色块，不新增精灵图集。
	"C": {"name": "焦土", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	"E": {"name": "火焰", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	"Z": {"name": "废墟", "pass": true, "cost": 2, "dfn": 1, "avo": 5},
	# 大地图用：堡垒每回合开始回复 heal% HP
	"T": {"name": "堡垒", "pass": true, "cost": 2, "dfn": 2, "avo": 20, "heal": 20},
	"h": {"name": "丘陵", "pass": true, "cost": 2, "dfn": 1, "avo": 15},
	"w": {"name": "浅滩", "pass": true, "cost": 3, "dfn": 0, "avo": 0},
	"P": {"name": "栅栏", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	"A": {"name": "营帐", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	"D": {"name": "民宅", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	# 城堡：城墙、石地、城门、王座、石柱
	"#": {"name": "城墙", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
	"S": {"name": "石地", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	"G": {"name": "城门", "pass": true, "cost": 1, "dfn": 2, "avo": 20, "heal": 10},
	"K": {"name": "王座", "pass": true, "cost": 1, "dfn": 3, "avo": 30, "heal": 20},
	"I": {"name": "石柱", "pass": true, "cost": 2, "dfn": 1, "avo": 20},
	# 宝箱：盗贼站上去能开（章节 chests() 给内容）
	"Q": {"name": "宝箱", "pass": true, "cost": 1, "dfn": 0, "avo": 0},
	# 商店：站上去买卖（章节 shops() 给货架）
	"V": {"name": "道具店", "pass": true, "cost": 1, "dfn": 0, "avo": 10},
	"Y": {"name": "武器店", "pass": true, "cost": 1, "dfn": 0, "avo": 10},
	# 牢门 / 铁门：关着走不过去。盗贼（或带钥匙的人）站在旁边【开门】，开了变石地
	"O": {"name": "牢门", "pass": false, "cost": 99, "dfn": 0, "avo": 0},
}

## 道具：heal 回复量 / promote 转职道具（对应职业表里的 item）/ uses 使用次数 / price 商店价格
const ITEMS := {
	"vulnerary": {"name": "伤药", "heal": 10, "desc": "恢复 10 点 HP", "uses": 3, "price": 300},
	"elixir": {"name": "万灵药", "heal": 99, "desc": "HP 全部恢复", "uses": 3, "price": 3000},
	"hero_crest": {"name": "勇者之证", "promote": true, "desc": "物理系 Lv10 以上可转职", "uses": 1, "price": 10000},
	"sage_crest": {"name": "贤者之证", "promote": true, "desc": "魔法系 Lv10 以上可转职", "uses": 1, "price": 10000},
	"overlord_crest": {"name": "霸王之证", "promote": true, "desc": "盗贼、天马系 Lv10 以上可转职", "uses": 1, "price": 10000},
	"door_key": {"name": "钥匙", "key": true, "desc": "打开相邻的一扇牢门", "uses": 1, "price": 500},
	"pure_water": {"name": "圣水", "desc": "（剧情道具）", "uses": 1, "price": 900},
}

## 武器价格（商店）：每次耐久的单价 × 耐久，专属武器不卖
const WEAPON_PRICE := {"E": 10, "D": 18, "C": 30, "B": 45, "A": 60, "S": 80}


## 上级职业（含剧情转职的炎刃使）：离队回归补等级时按 +20 级算
const PROMOTED := ["剑圣", "勇者", "勇士", "狂战士", "枪斗士", "圣骑士", "将军", "狙击手", "隼骑士", "刺客", "司祭", "贤者", "德鲁伊", "炎刃使"]
## 飞行单位飞不过去的地形（其余地形一律消耗 1、不吃地形加成）
const FLY_BLOCK := ["#", "E"]


static func is_promoted(cls: String) -> bool:
	return cls in PROMOTED


static func is_flying(cls: String) -> bool:
	return bool(class_data(cls).get("flying", false))


## 攻击方武器类型对防守方的克制: 1 = 克制, -1 = 被克, 0 = 无关系
static func triangle_dir(a_type: String, d_type: String) -> int:
	if TRIANGLE.get(a_type, "") == d_type:
		return 1
	if TRIANGLE.get(d_type, "") == a_type:
		return -1
	return 0


static func dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## 累计武器经验 → 等级字母（不到 E 门槛返回 ""）
static func rank_of(points: int) -> String:
	var out := ""
	for r in RANKS:
		if points >= RANK_EXP[r]:
			out = r
	return out


static func rank_index(r: String) -> int:
	return RANKS.find(r)


static func class_data(label: String) -> Dictionary:
	return CLASSES.get(label, {})


static func weapon_price(id: String) -> int:
	var w: Dictionary = WEAPONS.get(id, {})
	if w.is_empty() or w.get("rank", "E") == "prf" or int(w.get("uses", -1)) <= 0:
		return 0
	return int(WEAPON_PRICE.get(w["rank"], 10)) * int(w["uses"])


static func item_price(id: String) -> int:
	if ITEMS.has(id):
		return int(ITEMS[id].get("price", 0))
	return weapon_price(id)
