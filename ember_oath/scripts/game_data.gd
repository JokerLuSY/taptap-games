class_name GameData
## 静态数据：武器、地形、道具、武器相克

const WEAPONS := {
	"iron_sword": {"name": "铁剑", "type": "sword", "mt": 5, "hit": 90, "crit": 5, "rng": [1]},
	"silver_lance": {"name": "银枪", "type": "lance", "mt": 12, "hit": 80, "crit": 5, "rng": [1]},
	"javelin": {"name": "投枪", "type": "lance", "mt": 7, "hit": 70, "crit": 0, "rng": [1, 2]},
	"iron_axe": {"name": "铁斧", "type": "axe", "mt": 7, "hit": 75, "crit": 0, "rng": [1]},
	"war_axe": {"name": "战斧", "type": "axe", "mt": 9, "hit": 65, "crit": 0, "rng": [1]},
	"iron_bow": {"name": "铁弓", "type": "bow", "mt": 6, "hit": 80, "crit": 5, "rng": [2]},
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
