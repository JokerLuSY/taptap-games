class_name Chapter13
extends ChapterBase
## 第十三章「潜入圣都」：布鲁诺的船把一行人送进圣都的地下水道。限定出击 6 人，必须带小雀（她开场回队，会开锁）。
## 水道 → 审判所地牢 → 出口水门。西里尔关在审判所的牢房里（开门后【对话】回队）；
## 诺雅的姐姐、天马骑士赛莲第 3 回合巡逻过来（诺雅【说得】）；地牢深处的「培养室」里，三具灰烬傀儡第 5 回合醒来。
## 胜利：艾德里克到达出口水门。典狱长格里姆守在门洞里。

const CHAPTER_TITLE := "第十三章 · 潜入圣都"
const VICTORY_TITLE := "第十三章 · 完"
const VICTORY_SUB := "水门在身后落下。圣都的钟声，一直响到天亮。"
const DEFEAT_SUB := "圣都的水道很深。没有人知道，下面沉着什么……"
const BG := ""

## 34×24。西南角是布鲁诺的船靠岸的平台（我方出发点）；西边是一条带水渠的大水道（两座桥），往北接审判所地牢。
## 地牢中间一条长走廊：北侧四间牢房（三扇牢门：杂物间 / 西里尔 / 证物间，东头是没门的看守室），
## 南侧是刑讯室、「培养室」（石柱 = 破培养槽，三具灰烬傀儡）和锁着的典狱长室。走廊东头出去是东水道，顺着往南到出口水门。
## 北岸步道（第 17–18 行）有一道铁栅（牢门），开了就能沿河直奔水门——这是给盗贼 / 钥匙留的近路。
const MAP := [
	"##################################",
	"#SSSS~SSSS##################SS~SS#",
	"#SSSS~SSSS##QSS#SSS#SSQ#SSS#IS~SS#",
	"#SISS~SSIS##SSS#SSS#SSS#SSS#SS~SS#",
	"#SSSSBSSSS##SSS#SSS#SSS#SSS#SSBSS#",
	"#SSSS~SSSS##SSS#SSS#SSS#SSS#SS~SS#",
	"#SSSS~SSSS###O###O###O###S##SS~SI#",
	"#SSSS~SSSSSSSSSSSSSSSSSSSSSSSS~SS#",
	"#SISS~SSISSSSSSISSSISSSISSSSSS~SS#",
	"#SSSS~SSSS###S######S####O##SS~SS#",
	"#SSSS~SSSS##SSSS#SSSSSSS#SS#SS~SS#",
	"#SSSSBSSSS##SSSS#SISSSIS#SS#SSBSS#",
	"#SSSS~SSSS##SSSS#SSSSSSS#SS#SS~SS#",
	"#SISS~SSIS##SSSS#SISSSIS#SS#IS~SS#",
	"#SSSS~SSSS##SSSS#SSSSSSS#SQ#SS~SI#",
	"#SSSS~wwww##################SS~SS#",
	"#SSSSSwwww##################SSSSS#",
	"#SSSSSSSSSSSS#SSSSSSSSSSSSSSSSSSSG",
	"#SSSSSSSSSSSSOSSSSSSSSSSSSSSSSSSSG",
	"#SSSSS~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"#SSSSS~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"#SSSSSSSSSSSQ#####################",
	"#SSSSS############################",
	"##################################",
]

const LEVELS := []                # 全图同一高度

const GOAL := [Vector2i(33, 17), Vector2i(33, 18)]
const CELL_CYRIL := Vector2i(17, 3)
const DOOR_CYRIL := Vector2i(17, 6)
const CHESTS := {Vector2i(12, 2): "elixir", Vector2i(22, 2): "killing_edge", Vector2i(26, 14): "hero_crest",
	Vector2i(12, 21): "door_key"}
const PUPPETS := ["puppet1", "puppet2", "puppet3"]
const PUPPET_WAKE := 5            # 第 5 回合开始，培养室里的傀儡醒来
const SELENE_LEAVES := 8          # 诺雅不在时，赛莲第 8 回合开始撤走

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_SPARROW := Color(0.95, 0.85, 0.45)
const C_LANCE := Color(0.8, 0.9, 0.75)
const C_GWEN := Color(1.0, 0.75, 0.6)
const C_OSCAR := Color(0.8, 0.82, 0.9)
const C_VICTOR := Color(0.75, 0.65, 0.95)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_BRUNO := Color(0.9, 0.75, 0.55)
const C_CYRIL := Color(1.0, 0.72, 0.42)
const C_SELENE := Color(0.8, 0.9, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _SOLDIER := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 12,
	"hp": 31, "pwr": 11, "skl": 9, "spd": 9, "dfn": 9, "res": 3, "mov": 5,
	"weapons": ["steel_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _ARMOR := {"name": "审判所狱卒", "class": "重甲兵", "faction": "enemy", "level": 12,
	"hp": 34, "pwr": 12, "skl": 7, "spd": 4, "dfn": 14, "res": 3, "mov": 4,
	"weapons": ["steel_lance"], "color": Color(0.62, 0.60, 0.58),
	"hair": "short", "hair_color": Color(0.30, 0.26, 0.22), "armor": Color(0.58, 0.56, 0.54)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 11,
	"hp": 27, "pwr": 10, "skl": 11, "spd": 10, "dfn": 5, "res": 4, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 11,
	"hp": 24, "pwr": 11, "skl": 9, "spd": 9, "dfn": 4, "res": 9, "mov": 5,
	"weapons": ["thunder"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _DARK := {"name": "审判所咒术师", "class": "暗法师", "faction": "enemy", "level": 12,
	"hp": 27, "pwr": 12, "skl": 8, "spd": 8, "dfn": 5, "res": 10, "mov": 5,
	"weapons": ["flux"], "color": Color(0.40, 0.34, 0.48),
	"hair": "hood", "armor": Color(0.36, 0.30, 0.44)}
const _CLERIC := {"name": "审判所修女", "class": "修女", "faction": "enemy", "level": 11,
	"hp": 23, "pwr": 10, "skl": 8, "spd": 10, "dfn": 3, "res": 11, "mov": 5,
	"weapons": ["heal_staff"], "color": Color(0.94, 0.92, 0.86),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.84)}
const _GRAY := {"name": "灰袍众", "class": "探子", "faction": "enemy", "level": 12,
	"hp": 28, "pwr": 10, "skl": 13, "spd": 14, "dfn": 6, "res": 5, "mov": 6,
	"weapons": ["steel_sword"], "color": Color(0.52, 0.52, 0.56),
	"hair": "hood", "armor": Color(0.46, 0.46, 0.50)}
const _MYRM := {"name": "教会剑士", "class": "剑士", "faction": "enemy", "level": 12,
	"hp": 29, "pwr": 10, "skl": 14, "spd": 15, "dfn": 6, "res": 5, "mov": 5,
	"weapons": ["steel_sword"], "color": Color(0.78, 0.76, 0.80),
	"hair": "short", "hair_color": Color(0.25, 0.22, 0.20), "armor": Color(0.74, 0.72, 0.78)}
const _THIEF := {"name": "水道鼠", "class": "盗贼", "faction": "enemy", "level": 11,
	"hp": 24, "pwr": 8, "skl": 11, "spd": 15, "dfn": 4, "res": 3, "mov": 6,
	"weapons": ["iron_sword"], "color": Color(0.50, 0.46, 0.38),
	"hair": "hood", "armor": Color(0.46, 0.42, 0.34)}
## 灰烬傀儡：被灰烬魔法改造过的活人。守备高、不会说话；第 5 回合之前是培养槽里一动不动的「东西」（中立）
const _PUPPET := {"name": "灰烬傀儡", "class": "灰烬傀儡", "faction": "npc", "level": 13, "stationary": true,
	"hp": 36, "pwr": 13, "skl": 10, "spd": 8, "dfn": 13, "res": 4, "mov": 4,
	"weapons": ["ash_claw"], "color": Color(0.42, 0.40, 0.44),
	"hair": "hood", "armor": Color(0.38, 0.36, 0.40)}
const _PEGASUS := {"name": "天马骑士", "class": "天马骑士", "faction": "enemy", "level": 12,
	"hp": 27, "pwr": 10, "skl": 11, "spd": 15, "dfn": 6, "res": 10, "mov": 7,
	"weapons": ["steel_lance"], "color": Color(0.90, 0.92, 0.98),
	"hair": "short", "hair_color": Color(0.70, 0.60, 0.40), "armor": Color(0.88, 0.90, 0.96)}

const UNITS := [
	# 我方（名单为空直接开打时用这些数值；有名单时按名单里的存档生成到这些位置）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 13,
		"hp": 31, "pwr": 11, "skl": 14, "spd": 14, "dfn": 9, "res": 6, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(3, 18), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 7,
		"hp": 35, "pwr": 14, "skl": 15, "spd": 17, "dfn": 10, "res": 5, "mov": 5,
		"weapons": ["ember_blade", "iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(4, 18), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	# 小雀：离队中，本章开场回队（before_spawn_status 设 active）
	{"id": "sparrow", "name": "小雀", "class": "盗贼", "faction": "player", "level": 11,
		"hp": 25, "pwr": 8, "skl": 13, "spd": 17, "dfn": 5, "res": 5, "mov": 6,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 50, "pwr": 30, "skl": 50, "spd": 65, "dfn": 15, "res": 25},
		"pos": Vector2i(2, 19), "color": Color(0.55, 0.70, 0.45),
		"hair": "short", "hair_color": Color(0.62, 0.38, 0.22), "armor": Color(0.40, 0.58, 0.44)},
	{"id": "noya", "pos": Vector2i(3, 20), "name": "诺雅", "class": "修女", "faction": "player", "level": 11,
		"hp": 24, "pwr": 10, "skl": 9, "spd": 12, "dfn": 4, "res": 11, "mov": 5, "weapons": ["heal_staff", "mend_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 45}},
	{"id": "lance", "pos": Vector2i(4, 19), "name": "兰斯", "class": "骑士", "faction": "player", "level": 12,
		"hp": 32, "pwr": 11, "skl": 10, "spd": 9, "dfn": 10, "res": 3, "mov": 7, "weapons": ["iron_lance", "javelin"],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20}},
	{"id": "victor", "pos": Vector2i(2, 20), "name": "维克多", "class": "暗法师", "faction": "player", "level": 12,
		"hp": 27, "pwr": 11, "skl": 9, "spd": 8, "dfn": 6, "res": 11, "mov": 5, "weapons": ["flux"],
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45}},
	{"id": "kain", "pos": Vector2i(3, 19), "name": "凯因", "class": "佣兵", "faction": "player", "level": 13,
		"hp": 33, "pwr": 12, "skl": 16, "spd": 17, "dfn": 8, "res": 4, "mov": 5, "weapons": ["steel_sword", "iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25, "res": 20}},
	{"id": "nina", "pos": Vector2i(4, 20), "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 12,
		"hp": 28, "pwr": 10, "skl": 14, "spd": 12, "dfn": 5, "res": 4, "mov": 5, "weapons": ["steel_bow", "iron_bow"],
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15, "res": 25}},
	# 敌方：西水道
	{"id": "myrm1", "pos": Vector2i(9, 17)},
	{"id": "soldier1", "pos": Vector2i(2, 10)},
	{"id": "graycloak1", "pos": Vector2i(7, 12)},
	{"id": "archer1", "pos": Vector2i(8, 5), "hold": true},
	{"id": "thief1", "pos": Vector2i(8, 1), "items": ["vulnerary", "elixir"]},
	# 审判所地牢：走廊、看守室、刑讯室
	{"id": "armor1", "pos": Vector2i(11, 8), "hold": true},
	{"id": "soldier2", "pos": Vector2i(17, 7)},
	{"id": "mage1", "pos": Vector2i(23, 8)},
	{"id": "graycloak2", "pos": Vector2i(25, 3), "items": ["door_key"]},
	{"id": "archer2", "pos": Vector2i(26, 4), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(13, 12), "hold": true},
	{"id": "cleric1", "pos": Vector2i(14, 11)},
	# 培养室：三具灰烬傀儡（第 5 回合醒来）
	{"id": "puppet1", "pos": Vector2i(20, 11)},
	{"id": "puppet2", "pos": Vector2i(19, 13)},
	{"id": "puppet3", "pos": Vector2i(21, 13)},
	# 东水道、北岸步道
	{"id": "soldier3", "pos": Vector2i(29, 5)},
	{"id": "myrm2", "pos": Vector2i(32, 9)},
	{"id": "archer3", "pos": Vector2i(32, 14), "hold": true},
	{"id": "mage2", "pos": Vector2i(28, 12)},
	{"id": "graycloak3", "pos": Vector2i(18, 17), "items": ["vulnerary"]},
	{"id": "soldier4", "pos": Vector2i(24, 18)},
	{"id": "armor2", "pos": Vector2i(31, 18), "hold": true},
	# 典狱长格里姆：守在出口水门的门洞里
	{"id": "grimm", "name": "格里姆", "class": "重甲兵", "faction": "enemy", "level": 15,
		"hp": 42, "pwr": 15, "skl": 10, "spd": 6, "dfn": 15, "res": 5, "mov": 4,
		"weapons": ["silver_lance"], "items": ["door_key"], "boss": true, "stationary": true, "sprite": "barrett",
		"pos": Vector2i(33, 17), "color": Color(0.50, 0.46, 0.44),
		"hair": "short", "hair_color": Color(0.22, 0.20, 0.18), "armor": Color(0.48, 0.46, 0.44)},
]

## 赛莲：诺雅的姐姐，教会天马骑士。第 3 回合从东水道上空巡逻过来
const SELENE := {"id": "selene", "name": "赛莲", "class": "天马骑士", "faction": "enemy", "level": 9,
	"hp": 23, "pwr": 8, "skl": 10, "spd": 13, "dfn": 5, "res": 9, "mov": 7,
	"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
	"growths": {"hp": 55, "pwr": 35, "skl": 50, "spd": 65, "dfn": 15, "res": 45},
	"pos": Vector2i(31, 2), "color": Color(0.85, 0.88, 0.98),
	"hair": "ponytail", "hair_color": Color(0.92, 0.86, 0.62), "armor": Color(0.88, 0.90, 0.98)}

## 西里尔：第七章四散后在王都被捕，关在审判所的牢房里。名单里没有他（直接从这一章开打）时用这份数值
const CYRIL_FALLBACK := {"name": "西里尔", "class": "魔道士", "level": 11,
	"hp": 27, "pwr": 12, "skl": 10, "spd": 11, "dfn": 5, "res": 10, "mov": 5,
	"weapons": ["fire", "thunder"], "items": [],
	"growths": {"hp": 50, "pwr": 55, "skl": 45, "spd": 50, "dfn": 15, "res": 45},
	"color": Color(0.55, 0.35, 0.25), "hair": "short", "hair_color": Color(0.30, 0.34, 0.48), "armor": Color(0.50, 0.38, 0.26)}

## 第 3 回合：赛莲与一名天马骑士；第 4 回合：灰袍众从身后的水道追来；第 7 回合：东水道上游来教会兵
const WAVES := {
	3: [SELENE, {"id": "pegasus1", "pos": Vector2i(29, 2)}],
	4: [{"id": "graycloak_r1", "pos": Vector2i(1, 1)}, {"id": "graycloak_r2", "pos": Vector2i(2, 1)}],
	7: [{"id": "soldier_r1", "pos": Vector2i(32, 1)}, {"id": "soldier_r2", "pos": Vector2i(28, 1)}],
}


func chapter_id() -> String:
	return "ch13"


func prep_mode() -> String:
	return "full"


## 潜入限定：6 人
func deploy_limit() -> int:
	return 6


## 必须出击：艾德里克、缇娅，还有带路的小雀（她在的话）
func forced_ids() -> Array:
	var out := lose_ids()
	if _here("sparrow"):
		out.append("sparrow")
	return out


func extra_deploy_slots() -> Array:
	return [Vector2i(1, 18), Vector2i(1, 20), Vector2i(5, 18), Vector2i(5, 21), Vector2i(2, 21)]


func templates() -> Dictionary:
	return {"soldier": _SOLDIER, "armor": _ARMOR, "archer": _ARCHER, "mage": _MAGE, "darkmage": _DARK,
		"cleric": _CLERIC, "graycloak": _GRAY, "myrm": _MYRM, "thief": _THIEF, "puppet": _PUPPET, "pegasus": _PEGASUS}


func lose_ids() -> Array:
	return ["edric", "tia"]


## 名单里在队、但本章没写位置的人：船靠岸的平台上
func extra_slots() -> Array:
	return [Vector2i(1, 18), Vector2i(1, 19), Vector2i(1, 20), Vector2i(1, 21), Vector2i(2, 21), Vector2i(3, 21),
		Vector2i(4, 21), Vector2i(5, 21), Vector2i(1, 22), Vector2i(2, 22), Vector2i(3, 22), Vector2i(4, 22),
		Vector2i(5, 22), Vector2i(2, 18), Vector2i(5, 18), Vector2i(1, 17), Vector2i(2, 17), Vector2i(3, 17)]


## 小雀离队中 → 开场回队（补等级）。转幕后 / 阵亡的回不来，on_battle_start 里换成钥匙
func before_spawn_status() -> Dictionary:
	if Campaign.can_rejoin("sparrow"):
		Campaign.catch_up("sparrow")
		flags["sparrow_back"] = true
		return {"sparrow": "active"}
	return {}


func goal_tiles() -> Array:
	return GOAL


func chests() -> Dictionary:
	return CHESTS


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "steel_lance", "steel_axe", "steel_bow", "thunder", "flux", "mend_staff"]


func is_won() -> bool:
	var e = battle.get_unit("edric")
	return e != null and e.is_alive() and e.grid_pos in GOAL


func win_condition() -> String:
	return tr("艾德里克到达出口水门")


func lose_condition() -> String:
	return tr("艾德里克或缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	# 小雀的三种情况：在队（带路）/ 转幕后（画了地图）/ 阵亡或从没入过队（布鲁诺或老水道工带路）
	if _here("sparrow"):
		flags["sparrow_mode"] = "here"
	elif Campaign.status_of("sparrow") == "retired":
		flags["sparrow_mode"] = "map"
	else:
		flags["sparrow_mode"] = "guide"
	# 西里尔：作为中立单位关在牢房里（离队中 / 名单为空）。转幕后、阵亡、已经在队的不进牢房
	var cy = null
	if battle.get_unit("cyril") == null:
		cy = battle.rejoin_unit("cyril", CELL_CYRIL, "npc", CYRIL_FALLBACK)
	flags["cyril_cell"] = cy != null and cy.is_npc()
	await battle.play_dialogue(_pre_battle())
	if flags["sparrow_mode"] != "here":
		var e = battle.get_unit("edric")
		if e != null:
			e.receive("door_key")
			e.receive("door_key")
		battle.notify(tr("艾德里克 得到了 2 把钥匙"))


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		if t == 3:
			battle.show_banner(tr("天马骑士巡逻！"), Color(0.75, 0.85, 1.0))
			await battle.play_dialogue(_selene_arrives())
		else:
			battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
			if t == 4:
				await battle.play_dialogue(_pursuers())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t == PUPPET_WAKE and not flags.get("puppets_awake", false):
		flags["puppets_awake"] = true
		_wake_puppets()
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("灰烬傀儡苏醒了！"), Color(0.85, 0.75, 0.95))
		await battle.play_dialogue(_puppets_wake())
	if t == SELENE_LEAVES:
		var s = battle.get_unit("selene")
		if s != null and s.is_alive() and not s.is_player() and not _here("noya"):
			await battle.play_dialogue(_selene_leaves())
			battle.units.erase(s)
			s.queue_free()
			battle.notify(tr("赛莲飞走了"))


## 培养室的傀儡：中立 → 敌方，开始行动
func _wake_puppets() -> void:
	for id in PUPPETS:
		var p = battle.get_unit(id)
		if p != null and p.is_alive() and p.is_npc():
			p.faction = "enemy"
			p.stationary = false
			p.queue_redraw()


func on_resume() -> void:
	if flags.get("puppets_awake", false):
		_wake_puppets()


func on_before_combat(att, def) -> void:
	if "grimm" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "grimm" else att
		await battle.play_dialogue(_boss_edric() if other.unit_id == "edric" else _boss())
	if "selene" in [att.unit_id, def.unit_id] and not flags.get("selene_fight", false):
		var s = battle.get_unit("selene")
		if s != null and not s.is_player():
			flags["selene_fight"] = true
			await battle.play_dialogue(_selene_fight())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "grimm" and def_died:
		await battle.play_dialogue(_boss_death())
	elif def.unit_id == "selene" and def_died:
		await battle.play_dialogue(_selene_death())


## 牢门：西里尔的牢房（他不在就是别的「私藏火种」的犯人），其余是空牢房 / 证物间
func on_door(u, pos: Vector2i) -> void:
	if pos == DOOR_CYRIL:
		var cy = battle.get_unit("cyril")
		if cy != null and cy.is_alive() and cy.is_npc():
			await battle.play_dialogue(_cyril_door())
			battle.hint(tr("走到西里尔身边【对话】，让他回到队伍"))
		elif not flags.get("prisoner", false):
			flags["prisoner"] = true
			await battle.play_dialogue(_prisoner())
			u.receive("elfire")
			battle.notify(tr("获得 炎枪"))
	elif pos == Vector2i(13, 18) and not flags.get("grate", false):
		flags["grate"] = true
		await battle.play_dialogue(_grate_open())


func recruits() -> Dictionary:
	var out := {"selene": ["noya"]}
	# 西里尔：开了牢门，谁走过去都能【对话】（整备界面不提示「需要谁出击」）
	if battle != null and battle.state != battle.S.PREP:
		out["cyril"] = _player_ids()
	return out


func recruit_lines(target_id: String, by_id: String) -> Array:
	if target_id == "cyril":
		return _cyril_recruit(by_id)
	return _selene_recruit()


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false
	if t.unit_id == "selene":
		battle.hint(tr("赛莲是天马骑士：能飞过水渠，但怕弓箭"))


func talks() -> Array:
	return [["edric", "sparrow", "edric_sparrow"], ["victor", "cyril", "victor_cyril"]]


func talk_lines(key: String) -> Array:
	if key == "edric_sparrow":
		return [
			_l("小雀", C_SPARROW, "喂，金头发的。你就是缇娅说的那个「王都再见」的少爷？"),
			_l("艾德里克", C_EDRIC, "……她是这么跟你说我的？"),
			_l("小雀", C_SPARROW, "她说你人不坏，就是太讲礼数。走个水道还要先说「失礼了」。"),
			_l("艾德里克", C_EDRIC, "在别人的地盘上，礼数总是要的。……何况这是你的地盘。"),
			_l("小雀", C_SPARROW, "……哼。那你记着：前面第三根柱子底下的砖是松的，别踩。这是本地盘主送你的。"),
			_l("艾德里克", C_EDRIC, "多谢。……失礼了，盘主大人。"),
			_l("小雀", C_SPARROW, "噗——你这人真是没救了。"),
		]
	return [
		_l("维克多", C_VICTOR, "「私藏火种的西里尔」。我在研究所的禁书目录上见过你的名字。"),
		_l("西里尔", C_CYRIL, "那份目录的抄写人，难道是你？字丑得很有名。"),
		_l("维克多", C_VICTOR, "……是我。我抄过三百本该烧的书，每抄一本，就偷偷多留一份。"),
		_l("西里尔", C_CYRIL, "那我得谢谢你。我背着的这几本，说不定就是你留下来的。"),
		_l("维克多", C_VICTOR, "等这件事了结，我们对一对。教会烧掉的，和我们记住的——差了多少。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["puppets_seen"] = true


func on_defeat() -> void:
	var e = battle.get_unit("edric")
	if e != null and not e.is_alive():
		await battle.play_dialogue(_defeat_edric())
	else:
		await battle.play_dialogue(_defeat_tia())


# ==================== 工具 ====================

## 我方、活着、在地图上
func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


func _player_ids() -> Array:
	var out: Array = []
	for u in battle.units:
		if u.is_player() and u.is_alive():
			out.append(u.unit_id)
	return out


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var mode: String = flags.get("sparrow_mode", "here")
	var lines: Array = [
		_l("", C_NARR, "子夜。一条没挂灯的走私船，顺着暗流滑进了圣都城墙底下的排水口。"),
	]
	if Campaign.alive_in_story("bruno"):
		lines.append(_l("布鲁诺", C_BRUNO, "就送到这儿。往东出了水门，就是城外的河——我在那儿等你们到天亮。"))
		lines.append(_l("布鲁诺", C_BRUNO, "天一亮，水门的闸就落下来。到时候你们还在里头，我可不等。"))
	lines.append(_l("艾德里克", C_EDRIC, "审判所的地牢就在这片水道上面。父亲最后一封信里写着：「圣都审判所，有我要找的答案。」"))
	lines.append(_l("缇娅", C_TIA, "上一回，我差点被装在笼子里送进这座城。……这一回，是我自己走进来的。"))
	if mode == "here":
		if flags.get("sparrow_back", false):
			lines.append(_l("小雀", C_SPARROW, "——你们可算来了！我在这底下蹲了半个月，耗子都认识我了！"))
			lines.append(_l("缇娅", C_TIA, "小雀？！你怎么会在这儿……"))
			lines.append(_l("小雀", C_SPARROW, "那天晚上在白垣镇，我钻水道跑掉以后，就一路跟着铁笼车的车辙走。车辙进了圣都，我就进了下水道。"))
			lines.append(_l("小雀", C_SPARROW, "这底下的路，我画了满满一墙。……我知道你会来的。你说过，活着才能再见嘛。"))
			lines.append(_l("缇娅", C_TIA, "……嗯。谢谢你，小雀。"))
		else:
			lines.append(_l("小雀", C_SPARROW, "水道我熟。门交给我，锁交给我，你们跟紧就行。"))
		lines.append(_l("小雀", C_SPARROW, "对了——审判所前几天新关进去一个人。抱着一本烧焦的书，嘴还特别碎。"))
	elif mode == "map":
		lines.append(_l("缇娅", C_TIA, "小雀的伤还没好，来不了。……可她把这片水道画给了我们。"))
		lines.append(_l("", C_NARR, "皱巴巴的纸上，歪歪扭扭的线条画满了水渠、暗门和锁眼。纸角包着两把磨得发亮的钥匙。"))
		lines.append(_l("缇娅", C_TIA, "她说：「牢门的锁都一个样，这两把能开。省着点用。」"))
		lines.append(_l("", C_NARR, "地图的空白处还写着一行字：审判所新关了个抱着烧焦的书的人。"))
	elif Campaign.alive_in_story("bruno"):
		lines.append(_l("布鲁诺", C_BRUNO, "没有会开锁的小鬼，就拿这个凑合。走私的人，谁手里没几把官家的钥匙？"))
		lines.append(_l("", C_NARR, "布鲁诺丢过来两把钥匙。"))
		lines.append(_l("布鲁诺", C_BRUNO, "还有，码头上的人说，审判所前几天新关了个抱着烧焦的书的法师。你们要找的，是不是他？"))
	else:
		lines.append(_l("老水道工", C_NPC, "你们就是要进审判所的人？……我在这水道里干了四十年，那些铁门的锁，都是我看着装上的。"))
		lines.append(_l("", C_NARR, "老人塞过来两把钥匙。"))
		lines.append(_l("老水道工", C_NPC, "前几天，他们又往里头拖了一个抱着烧焦的书的年轻人。……能救就救吧。"))
	lines.append(_l("缇娅", C_TIA, "烧焦的书……是西里尔！他说过要去王都大书库等我们的。"))
	if Campaign.alive_in_story("noya"):
		lines.append(_l("诺雅", C_NOYA, "圣都的夜空，是天马骑士团巡逻的。……我的姐姐，就在骑士团里。"))
		lines.append(_l("诺雅", C_NOYA, "如果真的遇上她——请让我去跟她说。"))
	lines.append(_l("艾德里克", C_EDRIC, "人少，就不能硬拼。救出西里尔，查清父亲的下落，然后从东边的出口水门离开。"))
	return lines


func _turn2_hint() -> Array:
	var lines: Array = []
	if flags.get("sparrow_mode", "here") == "here":
		lines.append(_l("小雀", C_SPARROW, "牢门都锁着。我站到门旁边就能【开门】；箱子也一样，站上去就能撬开。"))
		lines.append(_l("小雀", C_SPARROW, "河边那道铁栅也是门——开了能抄近路直奔水门。不过那边守得也紧。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "钥匙只有两把。拿着钥匙的人站到牢门旁边就能【开门】，用一次少一把。"))
		lines.append(_l("艾德里克", C_EDRIC, "西里尔的牢房必须开。剩下那把……留着见机行事。"))
	return lines


func _selene_arrives() -> Array:
	var lines: Array = [
		_l("", C_NARR, "东水道的天井上方，响起了翅膀拍打的声音。"),
		_l("赛莲", C_SELENE, "天马骑士团赛莲，夜巡。……水道里有火光？报上名来，否则以入侵圣都论处！"),
	]
	if _here("noya"):
		lines.append(_l("诺雅", C_NOYA, "那个声音……姐姐！"))
		lines.append(_l("诺雅", C_NOYA, "请让我过去！我去跟她说——走到她身边，我会【说得】她的。"))
	elif Campaign.alive_in_story("noya"):
		lines.append(_l("缇娅", C_TIA, "金色的头发，和诺雅一模一样……是她的姐姐。可诺雅不在这里。"))
		lines.append(_l("缇娅", C_TIA, "……尽量别伤她。打退了就好。"))
	else:
		lines.append(_l("缇娅", C_TIA, "金色的头发……诺雅说过，她的姐姐在天马骑士团。"))
		lines.append(_l("缇娅", C_TIA, "……诺雅。要是你还在就好了。"))
	return lines


func _pursuers() -> Array:
	return [
		_l("灰袍众", C_ENEMY, "下水道的老鼠，往审判所钻了！跟上，一个也别放跑！"),
		_l("缇娅", C_TIA, "身后也来人了。……别停下，往前走！"),
	]


func _puppets_wake() -> Array:
	var lines: Array = [
		_l("", C_NARR, "培养室里，破裂的玻璃槽中，那些一直垂着头的「人」，同时抬起了脸。"),
		_l("", C_NARR, "它们的眼睛里没有光，只有一层灰。皮肤底下，像有余烬在缓缓地流。"),
		_l("缇娅", C_TIA, "那是……人？还活着吗？"),
	]
	if _here("victor"):
		lines.append(_l("维克多", C_VICTOR, "……灰烬傀儡。我在研究所的笔记里写过它们，可亲眼看到，还是第一次。"))
		lines.append(_l("维克多", C_VICTOR, "用灰烬魔法把活人烧空，只留下会动的躯壳。不疼、不怕、不会停——也不会再记得自己是谁。"))
		lines.append(_l("艾德里克", C_EDRIC, "教会……在圣都的地底下，做这种事？"))
		lines.append(_l("维克多", C_VICTOR, "你父亲追查的，就是这个。……小心，它们守备很硬，用魔法打。"))
	elif Campaign.alive_in_story("victor"):
		lines.append(_l("艾德里克", C_EDRIC, "维克多说过的「灰烬傀儡」……原来是真的。把活人烧空，只剩下会动的躯壳。"))
		lines.append(_l("艾德里克", C_EDRIC, "父亲追查的，就是这个吗……！它们身子很硬，用魔法打！"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "父亲的笔记里画过这样的东西……「灰烬傀儡」。把活人烧空，只剩下会动的躯壳。"))
		lines.append(_l("艾德里克", C_EDRIC, "教会竟然在圣都的地底下……！它们身子很硬，用魔法打！"))
	lines.append(_l("缇娅", C_TIA, "……我身上的火，在发抖。它们身上，也有火的味道。"))
	return lines


func _selene_leaves() -> Array:
	return [
		_l("赛莲", C_SELENE, "……天快亮了。巡逻到此为止，我得回去禀报骑士团。"),
		_l("赛莲", C_SELENE, "入侵者，下一次在天上遇见，我不会再手下留情。"),
	]


func _selene_fight() -> Array:
	if Campaign.alive_in_story("noya"):
		return [
			_l("赛莲", C_SELENE, "你们身上……有修女的祈祷气息。你们见过一个叫诺雅的孩子吗？"),
			_l("赛莲", C_SELENE, "不，不必回答。——天马骑士团，只问罪，不问话！"),
		]
	return [
		_l("赛莲", C_SELENE, "圣都的夜空由我们守护。入侵者，退下！"),
	]


func _selene_death() -> Array:
	return [
		_l("赛莲", C_SELENE, "诺雅……我……还没去……接你……"),
	]


func _selene_recruit() -> Array:
	return [
		_l("诺雅", C_NOYA, "姐姐！是我，诺雅！"),
		_l("赛莲", C_SELENE, "诺雅……？你、你不是被押回圣都受审了吗？你怎么会和这些人……"),
		_l("诺雅", C_NOYA, "是他们救了我。押我的人，是审判官大人；救我的人，是被教会叫作「异端」的人。"),
		_l("诺雅", C_NOYA, "姐姐，你一直在天上看着这座城。……你没有看见吗？地牢里那些玻璃槽，那些不会说话的人。"),
		_l("赛莲", C_SELENE, "……我看见过。夜巡的时候，天井底下有灰色的光。骑士团长说，那是「净化」。"),
		_l("诺雅", C_NOYA, "那不是净化。那是把人烧空。……姐姐，你从小教我，天马只驮心里干净的人。"),
		_l("赛莲", C_SELENE, "……你长大了，诺雅。比我还会说话了。"),
		_l("赛莲", C_SELENE, "好。我跟你走。这一回，换我跟在你后面飞。"),
	]


func _cyril_door() -> Array:
	return [
		_l("西里尔", C_CYRIL, "……门开了？这个时辰不该是送饭的。"),
		_l("西里尔", C_CYRIL, "啊，这脚步声——不是狱卒。狱卒走路没这么心虚。"),
	]


func _cyril_recruit(by_id: String) -> Array:
	var lines: Array = []
	if by_id == "tia":
		lines.append(_l("缇娅", C_TIA, "西里尔！"))
		lines.append(_l("西里尔", C_CYRIL, "缇娅……你逃出笼子了？哈，我就知道。火是关不住的。"))
		lines.append(_l("缇娅", C_TIA, "你说要在王都大书库等我。怎么等到地牢里来了？"))
		lines.append(_l("西里尔", C_CYRIL, "大书库的禁书区，守得比地牢还严。我刚翻到想看的那一页，就被逮住了。"))
	else:
		lines.append(_l("西里尔", C_CYRIL, "你们是……缇娅的同伴？她也来了？"))
		lines.append(_l("西里尔", C_CYRIL, "那就好。我在王都大书库被逮住的时候，还以为再也见不到那团火了。"))
	lines.append(_l("西里尔", C_CYRIL, "我在大书库的禁书区，看见了一卷没被烧干净的记录——八百年前，那场大火之后。"))
	lines.append(_l("西里尔", C_CYRIL, "上面说，大火之后，教会做的第一件事，是收走了所有的「圣器」。……后面的字，被人刮掉了。"))
	lines.append(_l("西里尔", C_CYRIL, "书被他们收走了。可字，都在我脑子里。——走吧，我还欠这座城一场火。"))
	return lines


func _prisoner() -> Array:
	var lines: Array = [
		_l("老学者", C_NPC, "……门？门开了？你们不是审判所的人？"),
		_l("老学者", C_NPC, "我只是在家里多藏了一本讲火的书，就被关了三年。……这个，你们拿去。"),
		_l("老学者", C_NPC, "是我藏在稻草底下的。在这里点不着，在外面——总有人能点着。"),
	]
	if Campaign.status_of("cyril") == "dead":
		lines.append(_l("缇娅", C_TIA, "（西里尔……你要是在，一定会跟这位老人聊上一整夜吧。）"))
	return lines


func _grate_open() -> Array:
	return [
		_l("", C_NARR, "生锈的铁栅吱呀一声打开了。河边的步道一直通到东边——出口水门的方向。"),
	]


func _boss() -> Array:
	return [
		_l("格里姆", C_BOSS, "审判所典狱长格里姆。在我的地牢里，只有两种人：关着的，和死了的。"),
		_l("格里姆", C_BOSS, "你们想当哪一种？"),
	]


func _boss_edric() -> Array:
	return [
		_l("格里姆", C_BOSS, "金发，细剑……菲恩家的小崽子。你和你父亲长得真像。"),
		_l("艾德里克", C_EDRIC, "你见过我父亲？！他在哪里！"),
		_l("格里姆", C_BOSS, "见过。他在我的地牢里住过三天，一句求饶的话也没说过。"),
		_l("格里姆", C_BOSS, "后来，他被「请」去了更深的地方。……比这里深得多，也冷得多。"),
		_l("艾德里克", C_EDRIC, "——让开！"),
	]


func _boss_death() -> Array:
	return [
		_l("格里姆", C_BOSS, "呵……找吧……等你找到他……你会希望……自己没找……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "出口水门的铁闸，在最后一个人钻出去的瞬间落了下来。"),
		_l("", C_NARR, "城外的河面上，一盏没挂旗的船灯，正等在雾里。"),
	]
	if Campaign.alive_in_story("bruno"):
		lines.append(_l("布鲁诺", C_BRUNO, "上船！快！钟楼那边已经开始敲了！"))
	if _here("cyril"):
		lines.append(_l("西里尔", C_CYRIL, "三个月来第一次吹到风。……原来外面的风是这个味道。"))
	if _here("selene"):
		lines.append(_l("赛莲", C_SELENE, "骑士团很快会发现我没回去。……天马在天上，比船快。我替你们看着后面。"))
		lines.append(_l("诺雅", C_NOYA, "姐姐……谢谢你。"))
	lines.append(_l("缇娅", C_TIA, "艾德里克。你父亲……"))
	lines.append(_l("艾德里克", C_EDRIC, "他来过这里。……被「请」去了更深的地方。"))
	lines.append(_l("艾德里克", C_EDRIC, "那些傀儡，那些玻璃槽，还有典狱长的话——我不愿去想。可我必须去想。"))
	lines.append(_l("缇娅", C_TIA, "那就一起想。你一个人想，会想到最坏的地方去的。"))
	lines.append(_l("艾德里克", C_EDRIC, "……嗯。先离开圣都。教会的骑士团，天亮就会追上来。"))
	return lines


func _defeat_edric() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "父亲……我离您……只差一点了……"),
		_l("", C_NARR, "圣都的水道很深。那一夜沉下去的，没有再浮上来。"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "又……回到笼子里了吗……"),
		_l("", C_NARR, "火种，终究还是被送进了圣都。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "holy", "from": "harbor", "lines": [
		_l("", CB_NARR, "圣都。圣焰教会的心脏，八百年来从没有一个「异端」活着走出来过。"),
		_l("", CB_NARR, "从银湾港出发的走私船，趁着没有月亮的夜晚，驶向了城墙底下的水道。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "圣都 · 审判所地牢", "mood": "dungeon", "lines": [
			_l("", CB_NARR, "天亮了。审判官塞拉斯站在一间空荡荡的牢房前。牢门的锁，被人用很漂亮的手法打开了。"),
			_l("圣焰教会兵", CB_ENEMY, "审判官大人！入侵者从水门逃了。培养室……也被人闯进去了。"),
			_l("塞拉斯", CB_SILAS, "……我知道了。下去吧。"),
			_l("塞拉斯", CB_SILAS, "（培养室？审判所的地底下，什么时候多了一间我不知道的屋子？）"),
		]},
		{"title": "圣都 · 大圣堂", "mood": "church", "lines": [
			_l("莫尔甘", CB_MORGAN, "老鼠在地窖里转了一圈，又出去了。……让他们去吧。"),
			_l("莫尔甘", CB_MORGAN, "那位菲恩家的少爷，看见了不该看的东西。他会一路追下去的——追到他父亲身边。"),
			_l("七号", CB_SEVEN, "……"),
			_l("莫尔甘", CB_MORGAN, "七号。去把那位领主大人也请来吧。……父子重逢的场面，总该有人布置。"),
			_l("七号", CB_SEVEN, "……是。"),
		]},
	]
