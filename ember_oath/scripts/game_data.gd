class_name GameData
## 静态数据：武器、地形、道具、武器相克

const WEAPONS := {
	"iron_sword": {"name": "铁剑", "type": "sword", "mt": 5, "hit": 90, "crit": 5, "rng": [1]},
	# 炎刃：剑系，沿用剑的突进斩击。觉醒后替换铁剑，不另做武器动作。
	"ember_blade": {"name": "炎刃", "type": "sword", "mt": 7, "hit": 90, "crit": 5, "rng": [1]},
	"silver_lance": {"name": "银枪", "type": "lance", "mt": 12, "hit": 80, "crit": 5, "rng": [1]},
	"javelin": {"name": "投枪", "type": "lance", "mt": 7, "hit": 70, "crit": 0, "rng": [1, 2]},
	"iron_axe": {"name": "铁斧", "type": "axe", "mt": 7, "hit": 75, "crit": 0, "rng": [1]},
	"war_axe": {"name": "战斧", "type": "axe", "mt": 9, "hit": 65, "crit": 0, "rng": [1]},
	"iron_bow": {"name": "铁弓", "type": "bow", "mt": 6, "hit": 80, "crit": 5, "rng": [2]},
	"steel_sword": {"name": "钢剑", "type": "sword", "mt": 8, "hit": 75, "crit": 0, "rng": [1]},
	# 细剑：艾德里克的家传剑，轻、准、易出必杀
	"rapier": {"name": "细剑", "type": "sword", "mt": 6, "hit": 95, "crit": 10, "rng": [1]},
	"iron_lance": {"name": "铁枪", "type": "lance", "mt": 7, "hit": 80, "crit": 0, "rng": [1]},
	"steel_lance": {"name": "钢枪", "type": "lance", "mt": 10, "hit": 70, "crit": 0, "rng": [1]},
	"hand_axe": {"name": "手斧", "type": "axe", "mt": 7, "hit": 60, "crit": 0, "rng": [1, 2]},
	"short_bow": {"name": "短弓", "type": "bow", "mt": 5, "hit": 85, "crit": 5, "rng": [2]},
	# 治疗杖：不能攻击，也不能反击。回复量 = mt + 使用者的力
	"heal_staff": {"name": "治疗杖", "type": "staff", "mt": 8, "hit": 100, "crit": 0, "rng": [1]},
}

## 武器相克: 剑克斧, 斧克枪, 枪克剑
const TRIANGLE := {"sword": "axe", "axe": "lance", "lance": "sword"}

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
}

const ITEMS := {
	"vulnerary": {"name": "伤药", "heal": 10, "desc": "恢复 10 点 HP"},
}


## 攻击方武器类型对防守方的克制: 1 = 克制, -1 = 被克, 0 = 无关系
static func triangle_dir(a_type: String, d_type: String) -> int:
	if TRIANGLE.get(a_type, "") == d_type:
		return 1
	if TRIANGLE.get(d_type, "") == a_type:
		return -1
	return 0


static func dist(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)
