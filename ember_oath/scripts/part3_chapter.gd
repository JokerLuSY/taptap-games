class_name Part3Chapter
extends ChapterBase
## 第三篇「不灭之火」（第 23–30 章）各章的公共底子：台词色、按等级缩放的敌兵模板、
## 名单为空（单章测试）时的默认阵容、七号相关的旗标判定和常用小工具。设定见 docs/part3_story.md。

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(1.0, 0.8, 0.5)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_HARLO := Color(0.85, 0.95, 0.6)
const C_TOBY := Color(0.95, 0.75, 0.55)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_VERA := Color(0.95, 0.6, 0.55)
const C_VICTOR := Color(0.78, 0.7, 0.95)
const C_CYRIL := Color(1.0, 0.72, 0.42)
const C_SPARROW := Color(0.95, 0.85, 0.45)
const C_GERARD := Color(0.75, 0.8, 0.95)
const C_SILAS := Color(0.95, 0.92, 1.0)
const C_ORION := Color(0.8, 0.9, 0.7)
const C_OWEN := Color(0.85, 0.95, 1.0)
const C_LILITH := Color(0.85, 0.75, 0.9)
const C_ROLAND := Color(0.9, 0.82, 0.7)
const C_SEVEN := Color(0.7, 0.68, 0.72)
const C_MORGAN := Color(0.85, 0.7, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

## 敌兵模板：ref 是这组能力对应的等级；foe() 按目标等级缩放（每级 HP +1、力技速守 +0.5、魔防 +0.4）
const FOES := {
	"soldier": {"ref": 20, "name": "圣都枪兵", "class": "枪兵", "hp": 38, "pwr": 15, "skl": 13, "spd": 13, "dfn": 12, "res": 5, "mov": 5,
		"weapons": ["steel_lance", "javelin"], "color": Color(0.86, 0.84, 0.78), "hair": "short", "armor": Color(0.84, 0.80, 0.72)},
	"knight": {"ref": 20, "name": "圣焰骑士", "class": "骑士", "hp": 40, "pwr": 16, "skl": 12, "spd": 11, "dfn": 15, "res": 5, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "color": Color(0.84, 0.82, 0.88), "hair": "short", "armor": Color(0.90, 0.88, 0.94)},
	"armor": {"ref": 20, "name": "圣都重甲兵", "class": "重甲兵", "hp": 42, "pwr": 17, "skl": 11, "spd": 6, "dfn": 20, "res": 4, "mov": 4,
		"weapons": ["steel_lance"], "color": Color(0.72, 0.72, 0.76), "hair": "short", "armor": Color(0.76, 0.76, 0.82)},
	"archer": {"ref": 20, "name": "教会弓兵", "class": "弓箭手", "hp": 36, "pwr": 15, "skl": 16, "spd": 14, "dfn": 10, "res": 6, "mov": 5,
		"weapons": ["steel_bow"], "color": Color(0.82, 0.78, 0.70), "hair": "hood", "armor": Color(0.80, 0.76, 0.66)},
	"mage": {"ref": 20, "name": "教会魔道士", "class": "魔道士", "hp": 34, "pwr": 16, "skl": 14, "spd": 13, "dfn": 8, "res": 14, "mov": 5,
		"weapons": ["elfire"], "color": Color(0.92, 0.88, 0.78), "hair": "hood", "armor": Color(0.90, 0.86, 0.74)},
	"darkmage": {"ref": 20, "name": "灰烬术士", "class": "暗法师", "hp": 36, "pwr": 16, "skl": 13, "spd": 11, "dfn": 9, "res": 15, "mov": 5,
		"weapons": ["flux"], "color": Color(0.40, 0.36, 0.46), "hair": "hood", "armor": Color(0.36, 0.32, 0.42)},
	"cleric": {"ref": 8, "name": "神殿司祭", "class": "司祭", "hp": 36, "pwr": 15, "skl": 12, "spd": 13, "dfn": 7, "res": 17, "mov": 6,
		"weapons": ["mend_staff"], "color": Color(0.98, 0.96, 0.90), "hair": "hood", "armor": Color(0.96, 0.94, 0.88)},
	"graycloak": {"ref": 8, "name": "灰袍刺客", "class": "刺客", "hp": 40, "pwr": 16, "skl": 20, "spd": 21, "dfn": 11, "res": 9, "mov": 6,
		"weapons": ["killing_edge"], "color": Color(0.50, 0.50, 0.54), "hair": "hood", "armor": Color(0.44, 0.44, 0.48)},
	"puppet": {"ref": 20, "name": "灰烬傀儡", "class": "灰烬傀儡", "hp": 46, "pwr": 16, "skl": 13, "spd": 12, "dfn": 17, "res": 7, "mov": 5,
		"weapons": ["ash_claw"], "color": Color(0.45, 0.42, 0.44), "hair": "hood", "armor": Color(0.40, 0.38, 0.40)},
	"paladin": {"ref": 8, "name": "亲卫圣骑士", "class": "圣骑士", "hp": 50, "pwr": 19, "skl": 16, "spd": 15, "dfn": 17, "res": 10, "mov": 8,
		"weapons": ["steel_lance", "steel_sword"], "color": Color(0.90, 0.88, 0.94), "hair": "short", "armor": Color(0.96, 0.94, 1.0)},
	"general": {"ref": 8, "name": "亲卫将军", "class": "将军", "hp": 52, "pwr": 20, "skl": 13, "spd": 9, "dfn": 23, "res": 9, "mov": 5,
		"weapons": ["steel_lance", "steel_axe"], "color": Color(0.88, 0.86, 0.92), "hair": "short", "armor": Color(0.94, 0.92, 0.98)},
	"sage": {"ref": 8, "name": "神殿贤者", "class": "贤者", "hp": 42, "pwr": 18, "skl": 16, "spd": 15, "dfn": 9, "res": 17, "mov": 6,
		"weapons": ["elfire"], "color": Color(0.96, 0.92, 0.80), "hair": "hood", "armor": Color(0.96, 0.92, 0.78)},
	"sniper": {"ref": 7, "name": "神殿狙击手", "class": "狙击手", "hp": 43, "pwr": 17, "skl": 19, "spd": 16, "dfn": 12, "res": 8, "mov": 6,
		"weapons": ["steel_bow", "longbow"], "color": Color(0.90, 0.86, 0.76), "hair": "hood", "armor": Color(0.90, 0.86, 0.74)},
	"myrm": {"ref": 7, "name": "亲卫剑圣", "class": "剑圣", "hp": 45, "pwr": 17, "skl": 21, "spd": 20, "dfn": 12, "res": 9, "mov": 6,
		"weapons": ["steel_sword"], "color": Color(0.90, 0.88, 0.94), "hair": "short", "armor": Color(0.94, 0.92, 0.98)},
	"merc": {"ref": 8, "name": "神殿勇者", "class": "勇者", "hp": 48, "pwr": 18, "skl": 18, "spd": 17, "dfn": 13, "res": 7, "mov": 6,
		"weapons": ["steel_sword", "steel_axe"], "color": Color(0.84, 0.80, 0.74), "hair": "short", "armor": Color(0.80, 0.76, 0.70)},
	"fighter": {"ref": 8, "name": "神殿勇士", "class": "勇士", "hp": 52, "pwr": 21, "skl": 15, "spd": 14, "dfn": 12, "res": 6, "mov": 6,
		"weapons": ["steel_axe", "hand_axe"], "color": Color(0.80, 0.70, 0.60), "hair": "spiky", "armor": Color(0.76, 0.66, 0.56)},
	"pegasus": {"ref": 8, "name": "隼骑士", "class": "隼骑士", "hp": 44, "pwr": 17, "skl": 16, "spd": 20, "dfn": 12, "res": 15, "mov": 8,
		"weapons": ["steel_lance", "javelin"], "color": Color(0.92, 0.92, 0.96), "hair": "ponytail", "armor": Color(0.94, 0.94, 0.98)},
}

## 名单为空（直接从某一章开打的测试）时的我方默认数值：第 23 章的水平，stage 每 +1 抬 1 级。
## 写成模板，按 id 套用；章节 UNITS 里只写 id、faction、pos。
const PARTY := {
	"edric": {"name": "艾德里克", "class": "领主骑士", "level": 18, "hp": 36, "pwr": 15, "skl": 17, "spd": 16, "dfn": 12, "res": 7, "mov": 5,
		"weapons": ["rapier", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"color": Color(0.35, 0.50, 0.85), "hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	"tia": {"name": "缇娅", "class": "炎刃使", "level": 9, "hp": 44, "pwr": 17, "skl": 19, "spd": 21, "dfn": 12, "res": 8, "mov": 6,
		"weapons": ["ember_blade", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"color": Color(0.95, 0.40, 0.22), "hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	"gareth": {"name": "加雷斯", "class": "王子", "level": 17, "hp": 44, "pwr": 18, "skl": 12, "spd": 10, "dfn": 16, "res": 5, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"color": Color(0.70, 0.55, 0.35), "hair": "spiky", "hair_color": Color(0.85, 0.65, 0.30), "armor": Color(0.55, 0.45, 0.35)},
	"vera": {"name": "薇拉", "class": "刺客", "level": 3, "hp": 37, "pwr": 13, "skl": 19, "spd": 22, "dfn": 10, "res": 9, "mov": 7,
		"weapons": ["killing_edge", "steel_sword"], "wexp": {"sword": 181},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 60, "dfn": 20, "res": 30}},
	"kain": {"name": "凯因", "class": "勇者", "level": 4, "hp": 44, "pwr": 17, "skl": 20, "spd": 21, "dfn": 11, "res": 6, "mov": 6,
		"weapons": ["silver_sword", "steel_axe"], "wexp": {"sword": 181, "axe": 31},
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25, "res": 20}},
	"noya": {"name": "诺雅", "class": "司祭", "level": 3, "hp": 33, "pwr": 14, "skl": 13, "spd": 15, "dfn": 7, "res": 19, "mov": 6,
		"weapons": ["mend_staff", "shine"], "items": ["vulnerary"], "wexp": {"staff": 121, "light": 31},
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 55}},
	"selene": {"name": "赛莲", "class": "隼骑士", "level": 3, "hp": 38, "pwr": 14, "skl": 14, "spd": 19, "dfn": 10, "res": 16, "mov": 8,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 55, "pwr": 35, "skl": 50, "spd": 65, "dfn": 15, "res": 45}},
	"liss": {"name": "莉丝", "class": "狙击手", "level": 3, "hp": 37, "pwr": 15, "skl": 20, "spd": 18, "dfn": 10, "res": 10, "mov": 6,
		"weapons": ["steel_bow", "longbow"], "wexp": {"bow": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30}},
	"ivy": {"name": "艾薇", "class": "贤者", "level": 3, "hp": 35, "pwr": 17, "skl": 16, "spd": 15, "dfn": 8, "res": 18, "mov": 6,
		"weapons": ["elfire", "bolganone", "mend_staff"], "wexp": {"anima": 121, "staff": 31},
		"growths": {"hp": 45, "pwr": 50, "skl": 45, "spd": 45, "dfn": 15, "res": 50}},
	"rock": {"name": "洛克", "class": "将军", "level": 2, "hp": 45, "pwr": 18, "skl": 13, "spd": 10, "dfn": 22, "res": 8, "mov": 5,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 80, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15}},
	"gerard": {"name": "杰拉德", "class": "圣骑士", "level": 5, "hp": 44, "pwr": 17, "skl": 14, "spd": 13, "dfn": 15, "res": 7, "mov": 8,
		"weapons": ["silver_lance", "steel_sword"], "wexp": {"lance": 181, "sword": 31},
		"growths": {"hp": 60, "pwr": 35, "skl": 35, "spd": 30, "dfn": 30, "res": 15}},
	"victor": {"name": "维克多", "class": "暗法师", "level": 20, "hp": 36, "pwr": 17, "skl": 13, "spd": 12, "dfn": 9, "res": 17, "mov": 5,
		"weapons": ["nosferatu", "flux"], "wexp": {"dark": 121},
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45}},
	# ---- 第一篇回归（第 23 章 rejoin 的 fallback）----
	"balto": {"name": "巴尔托", "class": "圣骑士", "level": 12, "hp": 46, "pwr": 17, "skl": 15, "spd": 12, "dfn": 15, "res": 8, "mov": 8,
		"weapons": ["silver_lance", "steel_sword"], "items": ["vulnerary"], "wexp": {"lance": 181, "sword": 71},
		"growths": {"hp": 40, "pwr": 20, "skl": 25, "spd": 25, "dfn": 20, "res": 15},
		"color": Color(0.45, 0.55, 0.75), "hair": "short", "hair_color": Color(0.75, 0.75, 0.78), "armor": Color(0.70, 0.73, 0.82)},
	"harlo": {"name": "哈洛", "class": "战士", "level": 18, "hp": 46, "pwr": 17, "skl": 13, "spd": 13, "dfn": 11, "res": 4, "mov": 5,
		"weapons": ["steel_axe", "hand_axe"], "wexp": {"axe": 121},
		"growths": {"hp": 85, "pwr": 55, "skl": 35, "spd": 40, "dfn": 30, "res": 15},
		"color": Color(0.70, 0.60, 0.40), "hair": "short", "hair_color": Color(0.50, 0.32, 0.18), "armor": Color(0.55, 0.48, 0.35)},
	"bandit6": {"name": "托比", "class": "山贼", "level": 17, "hp": 45, "pwr": 17, "skl": 9, "spd": 12, "dfn": 9, "res": 3, "mov": 5,
		"weapons": ["steel_axe", "hand_axe"], "wexp": {"axe": 121},
		"growths": {"hp": 80, "pwr": 50, "skl": 30, "spd": 45, "dfn": 25, "res": 15},
		"color": Color(0.55, 0.45, 0.35), "hair": "spiky", "hair_color": Color(0.25, 0.18, 0.12), "armor": Color(0.50, 0.40, 0.30)},
	# ---- 第三篇新同伴 ----
	"orion": {"name": "奥瑞恩", "class": "狙击手", "level": 8, "hp": 40, "pwr": 16, "skl": 19, "spd": 14, "dfn": 11, "res": 8, "mov": 6,
		"weapons": ["silver_bow", "longbow"], "items": ["vulnerary"], "wexp": {"bow": 181},
		"growths": {"hp": 45, "pwr": 30, "skl": 40, "spd": 25, "dfn": 20, "res": 20},
		"color": Color(0.45, 0.55, 0.40), "hair": "short", "hair_color": Color(0.70, 0.70, 0.66), "armor": Color(0.42, 0.50, 0.36)},
	"silas": {"name": "塞拉斯", "class": "圣骑士", "level": 12, "hp": 48, "pwr": 19, "skl": 17, "spd": 15, "dfn": 17, "res": 12, "mov": 8,
		"weapons": ["silver_lance", "steel_sword"], "wexp": {"lance": 181, "sword": 71},
		"growths": {"hp": 55, "pwr": 35, "skl": 35, "spd": 30, "dfn": 30, "res": 25},
		"color": Color(0.92, 0.92, 0.98), "hair": "short", "hair_color": Color(0.88, 0.86, 0.80), "armor": Color(0.96, 0.96, 1.0)},
	"owen": {"name": "欧文", "class": "贤者", "level": 10, "hp": 38, "pwr": 18, "skl": 16, "spd": 14, "dfn": 9, "res": 18, "mov": 6,
		"weapons": ["bolganone", "elfire", "mend_staff"], "wexp": {"anima": 181, "staff": 71},
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 35, "dfn": 15, "res": 45},
		"color": Color(0.40, 0.55, 0.70), "hair": "hood", "hair_color": Color(0.85, 0.85, 0.88), "armor": Color(0.36, 0.50, 0.64)},
	"lilith": {"name": "莉莉丝", "class": "暗法师", "level": 14, "hp": 30, "pwr": 15, "skl": 13, "spd": 14, "dfn": 7, "res": 14, "mov": 5,
		"weapons": ["nosferatu", "flux"], "wexp": {"dark": 121},
		"growths": {"hp": 50, "pwr": 50, "skl": 40, "spd": 50, "dfn": 20, "res": 45},
		"color": Color(0.50, 0.44, 0.55), "hair": "ponytail", "hair_color": Color(0.80, 0.78, 0.82), "armor": Color(0.42, 0.38, 0.48)},
	"seven": {"name": "七号", "class": "灰烬傀儡", "level": 18, "hp": 48, "pwr": 19, "skl": 21, "spd": 24, "dfn": 14, "res": 12, "mov": 6,
		"weapons": ["ash_claw"], "wexp": {"sword": 121},
		"growths": {"hp": 40, "pwr": 40, "skl": 50, "spd": 55, "dfn": 25, "res": 30},
		"color": Color(0.55, 0.52, 0.56), "hair": "ponytail", "hair_color": Color(0.80, 0.80, 0.84), "armor": Color(0.42, 0.40, 0.44)},
	"roland": {"name": "罗兰", "class": "勇者", "level": 12, "hp": 50, "pwr": 19, "skl": 20, "spd": 18, "dfn": 14, "res": 7, "mov": 6,
		"weapons": ["silver_sword", "steel_axe"], "wexp": {"sword": 181, "axe": 71},
		"growths": {"hp": 55, "pwr": 40, "skl": 45, "spd": 40, "dfn": 30, "res": 15},
		"color": Color(0.55, 0.45, 0.35), "hair": "short", "hair_color": Color(0.45, 0.32, 0.22), "armor": Color(0.50, 0.42, 0.34)},
}


## 本章的阶段（第 23 章 = 0），默认阵容按它抬等级
func stage() -> int:
	return 0


## 敌兵模板：kind 见 FOES，lv 目标等级，over 覆盖任意字段
static func foe(kind: String, lv: int, over := {}) -> Dictionary:
	var b: Dictionary = FOES[kind]
	var d := {}
	for k in b:
		if k != "ref":
			d[k] = b[k]
	var n := lv - int(b["ref"])
	d["faction"] = "enemy"
	d["level"] = lv
	d["hp"] = int(b["hp"]) + n
	for k in ["pwr", "skl", "spd", "dfn"]:
		d[k] = int(b[k]) + int(floor(n * 0.5))
	d["res"] = int(b["res"]) + int(floor(n * 0.4))
	for k in over:
		d[k] = over[k]
	return d


## 默认阵容的一个人（stage 抬等级，上限 20）
static func member(id: String, st: int) -> Dictionary:
	var b: Dictionary = PARTY[id]
	var d := {}
	for k in b:
		d[k] = b[k]
	var add := mini(st, 20 - int(b["level"]))
	if add > 0:
		d["level"] = int(b["level"]) + add
		d["hp"] = int(b["hp"]) + add
		for k in ["pwr", "skl", "spd", "dfn"]:
			d[k] = int(b[k]) + int(floor(add * 0.5))
		d["res"] = int(b["res"]) + int(floor(add * 0.34))
	d["faction"] = "player"
	return d


## 模板表：默认阵容（按 id）+ 本章敌兵（子类 foes() 给出）
func templates() -> Dictionary:
	var out := {}
	for id in PARTY:
		out[id] = member(id, stage())
	var f: Dictionary = foes()
	for k in f:
		out[k] = f[k]
	return out


func foes() -> Dictionary:
	return {}


func lose_ids() -> Array:
	return ["edric", "tia", "gareth"]


func lose_condition() -> String:
	return tr("艾德里克、缇娅或加雷斯阵亡")


func prep_mode() -> String:
	return "full"


func forced_ids() -> Array:
	var out := ["edric", "tia", "gareth"]
	if battle != null and _here("seven") and Campaign.flags.get("seven_joined", false):
		out.append("seven")
	return out


# ==================== 小工具 ====================

func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


func _npc(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_npc()


func _has_thief() -> bool:
	for u in battle.units:
		if u.is_alive() and u.is_player() and u.on_map() and u.class_label in ["盗贼", "刺客"]:
			return true
	return false


func _player_ids() -> Array:
	var out: Array = []
	for u in battle.units:
		if u.is_player() and u.is_alive():
			out.append(u.unit_id)
	return out


## 剧情里这个人还在（在队 / 离队 / 转幕后）；名单为空的测试里看地图上有没有
func _in_story(id: String) -> bool:
	if Campaign.roster.is_empty():
		return battle.get_unit(id) != null
	return Campaign.alive_in_story(id)


## 七号入队的三步条件（第 16 / 24 / 26 章）
static func seven_ready() -> bool:
	var f := Campaign.flags
	return bool(f.get("seven_16_spared", false)) and bool(f.get("seven_24_talked", false)) \
		and bool(f.get("seven_26_talked", false)) and not bool(f.get("seven_26_killed", false))


## 回合开始放一波增援（每波只放一次）。返回是否放了
func _wave(t: int, waves: Dictionary, banner := "敌方增援！") -> bool:
	if not waves.has(t) or flags.get("wave_%d" % t, false):
		return false
	flags["wave_%d" % t] = true
	battle.spawn_units(waves[t])
	Audio.play_sfx("reinforce")
	battle.show_banner(tr(banner), Color(1.0, 0.5, 0.3))
	return true


## 让一个单位离开地图（撤退）：不算阵亡，不再参战
func _leave_map(u) -> void:
	if u == null:
		return
	u.hp = maxi(1, u.hp)
	u.faction = "npc"
	u.grid_pos = Unit.OFF_MAP
	u.position = u.tile_center()
	u.visible = false
	battle._update_hover_info()


## 没带盗贼时把钥匙交给艾德里克
func _give_keys(n: int) -> void:
	var e = battle.get_unit("edric")
	if e == null:
		return
	for i in n:
		e.receive("door_key")
	battle.notify(tr("艾德里克 得到了 %d 把钥匙") % n)


## 三主角谁倒下了：通用的败北台词
func _defeat_lines() -> Array:
	for id in ["edric", "tia", "gareth"]:
		var u = battle.get_unit(id)
		if u != null and u.is_player() and not u.is_alive():
			if id == "edric":
				return [_l("艾德里克", C_EDRIC, "缇娅……对不起……约好的……灰岩村……"),
					_l("", C_NARR, "菲恩家最后的骑士倒下了。满月，照样升了起来。")]
			if id == "tia":
				return [_l("缇娅", C_TIA, "火……还没……熄……"),
					_l("", C_NARR, "缇娅倒下了。她的血，终究流到了莫尔甘想要的地方。")]
			return [_l("加雷斯", C_GARETH, "艾德里克……烤全羊……替我……"),
				_l("", C_NARR, "布罗登的苍狼倒下了。")]
	return []


func on_defeat() -> void:
	await battle.play_dialogue(_defeat_lines())


## 「距离满月，还有 N 天」
func _moon(days: int) -> Dictionary:
	if days <= 0:
		return _l("", CB_NARR, "今夜，满月。")
	return _l("", CB_NARR, tr("距离满月，还有 %d 天。") % days)


# ==================== 缇娅 × 七号「名字」（第 28–30 章，真结局条件） ====================

func _name_talk() -> Array:
	return [["tia", "seven", "seven_name"]]


func _name_talk_ok() -> bool:
	return not Campaign.flags.get("seven_named", false)


func _name_lines() -> Array:
	return [
		_l("缇娅", C_TIA, "七号。……我一直不喜欢这么叫你。"),
		_l("七号", C_SEVEN, "这是编号。第七个成功的。前面六个，都碎了。"),
		_l("缇娅", C_TIA, "所以那不是名字。名字是别人叫你的时候，你会想回头的那个声音。"),
		_l("七号", C_SEVEN, "……我没有那种声音。"),
		_l("缇娅", C_TIA, "那我给你一个。……「烬」。灰烬里还留着火的那一点，叫烬。"),
		_l("七号", C_SEVEN, "烬。"),
		_l("七号", C_SEVEN, "……烬。"),
		_l("缇娅", C_TIA, "你看，你回头了。"),
		_l("七号", C_SEVEN, "……嗯。我回头了。"),
	]


func _on_name_talked() -> void:
	Campaign.flags["seven_named"] = true
	battle.notify(tr("七号有了名字：烬"))
