class_name Chapter22
extends ChapterBase
## 第二十二章「圣焰神殿」（第二篇终章）：八百年前封印不灭之火的地方。抢在教会前面拿到「星之杖」「日之剑」，
## 并夺回教会偷走的「炎之冠」「天之枪」。四座祭坛（王座 K，金框标出）：我方单位行动结束时站在祭坛上，就取回那件圣器。
## 北边两座祭坛室有牢门（盗贼 / 钥匙开，近路），也能从窄廊绕到侧门（远路）——没有盗贼也不会卡关。
## 七号作为敌人出现，但不会被击杀：一次交战后 HP 降到四成以下（或意外被打倒）就撤退。
## 胜利：取回四座祭坛的圣器，并击败亲卫队长伊格纳兹。败北：艾德里克、缇娅、加雷斯任一阵亡。
## 结局：八圣器在封印台上共鸣，莫尔甘现身揭示「巫女之血是封印最后的钥匙」，七号掳走缇娅（章末缇娅离队）。

const CHAPTER_TITLE := "第二十二章 · 圣焰神殿"
const VICTORY_TITLE := "第二篇「寻父之旅」 · 完"
const VICTORY_SUB := "八件圣器，一件不少。少了的，是那团火。"
const DEFEAT_SUB := "神殿的大门合上了。封印台前，只剩白色的火……"
const BG := ""

## 36×26。南边神殿正门进来 → 中殿 → 横贯东西的大厅。四座祭坛（王座 K）在四个角落的祭坛室里：
## 南边两间朝中殿开口；北边两间可以走窄廊绕到侧门（远），也可以开大厅里的牢门（近，盗贼 / 钥匙）。
## 正北是封印之间，亲卫队长伊格纳兹守在门口。
const MAP := [
	"####################################",
	"##SSSSSSSS#S#SSSSSSSSSS#S#SSSSSSSS##",
	"##SISKSSISSS#SISSWWSSIS#SSSISSKSIS##",
	"##SSSSSSSS#S#SSSISSISSS#S#SSSSSSSS##",
	"##SSSSSSSS#S#SSSSSSSSSS#S#SSSSSSSS##",
	"##SSSSSSSS#S#SISSSSSSIS#S#SSSSSSSS##",
	"##SSSSSSSS#S#SSSSSSSSSS#S#SSSSSSSS##",
	"##SSSSSSSS#S#SSSSSSSSSS#S#SSSSSSSS##",
	"#####O#####S#####GG#####S#####O#####",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"#SSSSSISSSSZSSSSSSSSSSSSSSSSSISSSSS#",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSZ#",
	"#SSSSSSSSSSSSSSSSSSSSSSZSSSSSSSSSSS#",
	"###########SSSSSSSSSSSSSS###########",
	"##SSSSSSSS#SSISSSSSSSSISS#SSSSSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##SSSSSSSS#SSISSSSSSSSISS#SSSSSSSS##",
	"##SISKSSIS#SSSSSSSSSSSSSS#SISSKSIS##",
	"##SSSSSSSS#SZSSISSSSISSSS#SSSSSSSS##",
	"###########SSSSSSSSSSSSSS###########",
	"#################GG#################",
	".........Z.......RR.....Z...........",
	"......F.....Z....RR.............F...",
	"..FF.............RR......F....FF....",
	"....F......F.....RR.........F.......",
]

const LEVELS := []                # 全图同一高度

## 祭坛 → 圣器
const ALTARS := {
	Vector2i(5, 2): "star_staff",
	Vector2i(30, 2): "sun_sword",
	Vector2i(5, 18): "flame_crown",
	Vector2i(30, 18): "sky_spear",
}
const RELIC_NAMES := {
	"flame_crown": "炎之冠", "sky_spear": "天之枪", "iron_shield": "铁之盾", "moon_mirror": "月之镜",
	"wind_bow": "风之弓", "earth_axe": "地之斧", "star_staff": "星之杖", "sun_sword": "日之剑",
}
const ALL_RELICS := ["flame_crown", "sky_spear", "iron_shield", "moon_mirror", "wind_bow", "earth_axe", "star_staff", "sun_sword"]
const SEVEN_RETREAT_PCT := 0.4

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(1.0, 0.8, 0.5)
const C_VERA := Color(0.95, 0.6, 0.55)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_SEVEN := Color(0.7, 0.68, 0.72)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_HARLO := Color(0.85, 0.95, 0.6)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

## 敌兵：Lv18–20，上级 6–10，灰烬傀儡
const _PALADIN := {"name": "亲卫圣骑士", "class": "圣骑士", "faction": "enemy", "level": 8,
	"hp": 50, "pwr": 19, "skl": 16, "spd": 15, "dfn": 17, "res": 10, "mov": 8,
	"weapons": ["steel_lance", "steel_sword"], "color": Color(0.90, 0.88, 0.94),
	"hair": "short", "hair_color": Color(0.70, 0.62, 0.40), "armor": Color(0.96, 0.94, 1.0)}
const _GENERAL := {"name": "亲卫将军", "class": "将军", "faction": "enemy", "level": 8,
	"hp": 52, "pwr": 20, "skl": 13, "spd": 9, "dfn": 23, "res": 9, "mov": 5,
	"weapons": ["steel_lance", "steel_axe"], "color": Color(0.88, 0.86, 0.92),
	"hair": "short", "armor": Color(0.94, 0.92, 0.98)}
const _SAGE := {"name": "神殿贤者", "class": "贤者", "faction": "enemy", "level": 8,
	"hp": 42, "pwr": 18, "skl": 16, "spd": 13, "dfn": 9, "res": 17, "mov": 6,
	"weapons": ["elfire"], "color": Color(0.96, 0.92, 0.80),
	"hair": "hood", "armor": Color(0.96, 0.92, 0.78)}
const _SNIPER := {"name": "神殿狙击手", "class": "狙击手", "faction": "enemy", "level": 7,
	"hp": 43, "pwr": 17, "skl": 19, "spd": 16, "dfn": 12, "res": 8, "mov": 6,
	"weapons": ["steel_bow", "longbow"], "color": Color(0.90, 0.86, 0.76),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _MYRM := {"name": "亲卫剑圣", "class": "剑圣", "faction": "enemy", "level": 7,
	"hp": 45, "pwr": 17, "skl": 21, "spd": 20, "dfn": 12, "res": 9, "mov": 6,
	"weapons": ["steel_sword"], "color": Color(0.90, 0.88, 0.94),
	"hair": "short", "hair_color": Color(0.25, 0.22, 0.20), "armor": Color(0.94, 0.92, 0.98)}
const _PUPPET := {"name": "灰烬傀儡", "class": "灰烬傀儡", "faction": "enemy", "level": 19,
	"hp": 44, "pwr": 15, "skl": 12, "spd": 11, "dfn": 16, "res": 6, "mov": 5,
	"weapons": ["ash_claw"], "color": Color(0.45, 0.42, 0.44),
	"hair": "short", "hair_color": Color(0.55, 0.52, 0.50), "armor": Color(0.40, 0.38, 0.40)}
const _CLERIC := {"name": "神殿司祭", "class": "司祭", "faction": "enemy", "level": 7,
	"hp": 36, "pwr": 15, "skl": 12, "spd": 13, "dfn": 7, "res": 17, "mov": 6,
	"weapons": ["mend_staff"], "color": Color(0.98, 0.96, 0.90),
	"hair": "hood", "armor": Color(0.96, 0.94, 0.88)}
const _DARKMAGE := {"name": "神殿咒术师", "class": "暗法师", "faction": "enemy", "level": 19,
	"hp": 36, "pwr": 15, "skl": 12, "spd": 11, "dfn": 7, "res": 15, "mov": 5,
	"weapons": ["flux"], "color": Color(0.42, 0.38, 0.48),
	"hair": "hood", "armor": Color(0.38, 0.34, 0.44)}

## 七号：第 3 回合从封印之间里走出来。HP、守备很高，一次交战打不倒；受伤到四成以下就撤退
const SEVEN := {"id": "seven", "name": "七号", "class": "灰烬傀儡", "faction": "enemy", "level": 18, "boss": true,
	"hp": 80, "pwr": 15, "skl": 12, "spd": 24, "dfn": 17, "res": 14, "mov": 6,
	"weapons": ["ash_claw"], "pos": Vector2i(17, 6), "color": Color(0.55, 0.52, 0.56),
	"hair": "ponytail", "hair_color": Color(0.80, 0.80, 0.84), "armor": Color(0.42, 0.40, 0.44)}

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 19,
		"hp": 37, "pwr": 15, "skl": 17, "spd": 16, "dfn": 12, "res": 7, "mov": 5,
		"weapons": ["rapier", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(17, 23), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 8,
		"hp": 43, "pwr": 17, "skl": 19, "spd": 20, "dfn": 12, "res": 8, "mov": 6,
		"weapons": ["ember_blade", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(18, 23), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 18,
		"hp": 44, "pwr": 18, "skl": 12, "spd": 10, "dfn": 16, "res": 5, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(17, 22), "color": Color(0.70, 0.55, 0.35),
		"hair": "spiky", "hair_color": Color(0.85, 0.65, 0.30), "armor": Color(0.55, 0.45, 0.35)},
	{"id": "vera", "name": "薇拉", "class": "盗贼", "faction": "player", "level": 18,
		"hp": 34, "pwr": 12, "skl": 18, "spd": 21, "dfn": 8, "res": 7, "mov": 6,
		"weapons": ["killing_edge", "steel_sword"], "wexp": {"sword": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 60, "dfn": 20, "res": 30},
		"pos": Vector2i(18, 22)},
	{"id": "kain", "name": "凯因", "class": "佣兵", "faction": "player", "level": 19,
		"hp": 39, "pwr": 15, "skl": 18, "spd": 19, "dfn": 9, "res": 5, "mov": 5,
		"weapons": ["steel_sword", "killing_edge"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25},
		"pos": Vector2i(16, 22)},
	{"id": "noya", "name": "诺雅", "class": "修女", "faction": "player", "level": 18,
		"hp": 30, "pwr": 13, "skl": 11, "spd": 14, "dfn": 5, "res": 17, "mov": 5,
		"weapons": ["mend_staff", "heal_staff"], "wexp": {"staff": 121},
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 55},
		"pos": Vector2i(17, 24)},
	{"id": "selene", "name": "赛莲", "class": "天马骑士", "faction": "player", "level": 18,
		"hp": 33, "pwr": 12, "skl": 14, "spd": 19, "dfn": 8, "res": 14, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 55, "pwr": 35, "skl": 50, "spd": 65, "dfn": 15, "res": 45},
		"pos": Vector2i(19, 22)},
	{"id": "liss", "name": "莉丝", "class": "弓箭手", "faction": "player", "level": 18,
		"hp": 34, "pwr": 14, "skl": 18, "spd": 16, "dfn": 8, "res": 7, "mov": 5,
		"weapons": ["steel_bow", "longbow"], "wexp": {"bow": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30},
		"pos": Vector2i(16, 23)},
	{"id": "ivy", "name": "艾薇", "class": "魔道士", "faction": "player", "level": 18,
		"hp": 31, "pwr": 16, "skl": 15, "spd": 14, "dfn": 6, "res": 15, "mov": 5,
		"weapons": ["elfire", "thunder"], "wexp": {"anima": 121},
		"growths": {"hp": 45, "pwr": 50, "skl": 45, "spd": 45, "dfn": 15, "res": 50},
		"pos": Vector2i(19, 23)},
	{"id": "rock", "name": "洛克", "class": "重甲兵", "faction": "player", "level": 18,
		"hp": 41, "pwr": 16, "skl": 11, "spd": 7, "dfn": 20, "res": 5, "mov": 4,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 80, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(18, 24)},
	# 中殿
	{"id": "puppet1", "pos": Vector2i(14, 16), "hold": true},
	{"id": "puppet2", "pos": Vector2i(21, 16), "hold": true},
	{"id": "general1", "pos": Vector2i(17, 14), "hold": true},
	{"id": "sniper1", "pos": Vector2i(12, 14), "hold": true},
	{"id": "sniper2", "pos": Vector2i(23, 14), "hold": true},
	{"id": "myrm1", "pos": Vector2i(19, 18), "hold": true, "items": ["elixir"]},
	# 西南、东南祭坛室
	{"id": "puppet3", "pos": Vector2i(4, 16), "hold": true},
	{"id": "sage1", "pos": Vector2i(7, 15), "hold": true},
	{"id": "puppet4", "pos": Vector2i(31, 16), "hold": true},
	{"id": "paladin1", "pos": Vector2i(28, 15), "hold": true},
	# 横贯东西的大厅
	{"id": "paladin2", "pos": Vector2i(8, 10), "hold": true},
	{"id": "paladin3", "pos": Vector2i(27, 10), "hold": true, "items": ["door_key"]},
	{"id": "cleric1", "pos": Vector2i(17, 11)},
	{"id": "darkmage1", "pos": Vector2i(13, 10), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(22, 10), "hold": true},
	# 西北、东北祭坛室
	{"id": "general2", "pos": Vector2i(4, 4), "hold": true},
	{"id": "sage2", "pos": Vector2i(7, 3), "hold": true, "weapons": ["bolganone"]},
	{"id": "general3", "pos": Vector2i(31, 4), "hold": true},
	{"id": "myrm2", "pos": Vector2i(28, 4), "hold": true},
	# 封印之间
	{"id": "sage3", "pos": Vector2i(15, 5), "hold": true, "weapons": ["bolganone"]},
	{"id": "puppet5", "pos": Vector2i(20, 5), "hold": true},
	{"id": "cleric2", "pos": Vector2i(18, 4)},
	# 伊格纳兹：大司祭亲卫队长，守在封印之间门口
	{"id": "ignaz", "name": "伊格纳兹", "class": "圣骑士", "faction": "enemy", "level": 12,
		"hp": 58, "pwr": 22, "skl": 19, "spd": 17, "dfn": 20, "res": 12, "mov": 8,
		"weapons": ["silver_lance", "silver_sword"], "items": ["elixir"], "boss": true, "stationary": true,
		"sprite": "knight", "pos": Vector2i(17, 8), "color": Color(0.92, 0.90, 0.96),
		"hair": "short", "hair_color": Color(0.85, 0.80, 0.65), "armor": Color(1.0, 0.96, 0.85)},
]

## 第 3 回合七号带着傀儡从封印之间里走出来；第 5 回合神殿外绕来亲卫骑兵；第 7 回合封印之间里又醒来傀儡
const WAVES := {
	3: [{"id": "puppet_r1", "pos": Vector2i(16, 6)}, {"id": "puppet_r2", "pos": Vector2i(19, 6)}],
	5: [{"id": "paladin_r1", "pos": Vector2i(0, 23)}, {"id": "paladin_r2", "pos": Vector2i(35, 23)}],
	7: [{"id": "puppet_r3", "pos": Vector2i(15, 3)}, {"id": "puppet_r4", "pos": Vector2i(20, 3)}],
}

const DEPLOY := [Vector2i(15, 22), Vector2i(20, 22), Vector2i(15, 23), Vector2i(20, 23), Vector2i(16, 24),
	Vector2i(19, 24), Vector2i(15, 24), Vector2i(20, 24)]


func chapter_id() -> String:
	return "ch22"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 10


func forced_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_deploy_slots() -> Array:
	return DEPLOY


func templates() -> Dictionary:
	return {"paladin": _PALADIN, "general": _GENERAL, "sage": _SAGE, "sniper": _SNIPER, "myrm": _MYRM,
		"puppet": _PUPPET, "cleric": _CLERIC, "darkmage": _DARKMAGE}


func lose_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_slots() -> Array:
	return DEPLOY


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "silver_sword", "armorslayer", "steel_lance", "silver_lance", "horseslayer", "steel_axe",
		"steel_bow", "silver_bow", "elfire", "bolganone", "mend_staff"]


## 还没取回的祭坛（金框）
func goal_label() -> String:
	return "祭坛"


func goal_tiles() -> Array:
	var out: Array = []
	for p in ALTARS:
		if not flags.get("altar_%d_%d" % [p.x, p.y], false):
			out.append(p)
	return out


func _altars_left() -> int:
	return goal_tiles().size()


func is_won() -> bool:
	if _altars_left() > 0:
		return false
	var b = battle.get_unit("ignaz")
	return b == null or not b.is_alive()


func win_condition() -> String:
	return tr("取回四座祭坛上的圣器，并击败亲卫队长伊格纳兹")


func lose_condition() -> String:
	return tr("艾德里克、缇娅或加雷斯阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		if t == 3:
			battle.spawn_units([SEVEN])
			battle.show_banner(tr("七号出现了！"), Color(0.85, 0.8, 0.9))
			await battle.play_dialogue(_seven_appears())
		else:
			battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


## 站上祭坛：取回那件圣器
func on_action_end(u) -> void:
	if not u.is_alive() or not u.is_player() or not ALTARS.has(u.grid_pos):
		return
	var key := "altar_%d_%d" % [u.grid_pos.x, u.grid_pos.y]
	if flags.get(key, false):
		return
	flags[key] = true
	var relic: String = ALTARS[u.grid_pos]
	battle.board.goal_tiles = goal_tiles()
	Audio.play_sfx("coin")
	battle.notify(tr("取回了圣器「%s」") % tr(RELIC_NAMES[relic]))
	await battle.play_dialogue(_altar_taken(u, relic))


func on_before_combat(att, def) -> void:
	if "ignaz" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var foe = def if att.unit_id == "ignaz" else att
		await battle.play_dialogue(_boss(foe.unit_id))
	if "seven" in [att.unit_id, def.unit_id] and "tia" in [att.unit_id, def.unit_id] and not flags.get("seven_tia", false):
		flags["seven_tia"] = true
		await battle.play_dialogue(_seven_vs_tia())


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("ignaz")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())
		if _altars_left() > 0:
			battle.hint(tr("还有祭坛上的圣器没有取回"))
	await _check_seven()


## 七号不会被击杀：HP 降到四成以下（或者意外被打倒）就撤退——离开地图，不再参战
func _check_seven() -> void:
	if flags.get("seven_gone", false):
		return
	var s = battle.get_unit("seven")
	if s == null or s.is_player() or s.is_npc():
		return
	if s.is_alive() and s.hp > int(s.max_hp * SEVEN_RETREAT_PCT):
		return
	flags["seven_gone"] = true
	await battle.play_dialogue(_seven_retreats())
	s.hp = maxi(1, s.hp)
	s.faction = "npc"
	s.grid_pos = Unit.OFF_MAP
	s.position = s.tile_center()
	s.visible = false
	battle.notify(tr("七号撤退了"))


func talks() -> Array:
	return [["edric", "tia", "edric_tia_22"], ["gareth", "tia", "gareth_tia_22"]]


func talk_lines(key: String) -> Array:
	if key == "edric_tia_22":
		return [
			_l("艾德里克", C_EDRIC, "缇娅，你的手……在发光？"),
			_l("缇娅", C_TIA, "从进神殿开始就这样了。烫得厉害。……像是有人在叫我的名字。"),
			_l("艾德里克", C_EDRIC, "要是撑不住，就退到后面去。"),
			_l("缇娅", C_TIA, "我才不退。……艾德里克，你还记得渡口的约定吗？「王都再见」。"),
			_l("艾德里克", C_EDRIC, "记得。结果我们是在白鹭渡见的面。"),
			_l("缇娅", C_TIA, "（笑）那这次，换个约定吧。等一切结束——我们一起回灰岩村，看看巴尔托。"),
			_l("艾德里克", C_EDRIC, "……好。一言为定。"),
		]
	return [
		_l("加雷斯", C_GARETH, "喂，巫女。打完这一仗，来布罗登玩吧。父王说要请所有人吃烤全羊。"),
		_l("缇娅", C_TIA, "烤全羊？……你父王真的这么说了？"),
		_l("加雷斯", C_GARETH, "……我替他说的。反正他会答应。"),
		_l("缇娅", C_TIA, "哈哈……好。我记住了，烤全羊。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	# 八圣器集齐（之前没拿到的，教会都送进了神殿，这一章一起夺回）
	Campaign.flags["relics"] = ALL_RELICS.duplicate()
	Campaign.flags["tia_taken"] = true
	Campaign.flags["seven_22_fought_tia"] = flags.get("seven_tia", false)


func on_defeat() -> void:
	await battle.play_dialogue(_defeat())


## 篇末：缇娅被七号掳走
func after_victory_status() -> Dictionary:
	return {"tia": "away"}


# ==================== 小工具 ====================

func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


func _has_thief() -> bool:
	for u in battle.units:
		if u.is_alive() and u.is_player() and u.class_label in ["盗贼", "刺客"]:
			return true
	return false


## 之前没能拿到的圣器（铁之盾被抢走、月之镜不在手里等），神殿里一并夺回
func _missing_before() -> Array:
	var have: Array = Campaign.flags.get("relics", [])
	var out: Array = []
	for r in ["iron_shield", "moon_mirror", "wind_bow", "earth_axe"]:
		if not r in have:
			out.append(r)
	return out


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "圣焰神殿。八百年前，八英雄在这里封印了不灭之火。"),
		_l("", C_NARR, "神殿的大门敞开着，像是在等人。"),
		_l("伊格纳兹", C_BOSS, "大司祭亲卫队长，伊格纳兹。……大司祭大人有令：放你们进来。"),
		_l("伊格纳兹", C_BOSS, "可没说过，要让你们活着出去。"),
		_l("艾德里克", C_EDRIC, "四座祭台上……是圣器！星之杖、日之剑——还有教会偷走的炎之冠、天之枪！"),
		_l("加雷斯", C_GARETH, "全都在这儿？好极了，一次拿个干净！"),
		_l("缇娅", C_TIA, "……（手心好烫。神殿深处，有什么东西在叫我。）"),
		_l("艾德里克", C_EDRIC, "派人站上四座祭台，把圣器取回来。然后——打倒那个亲卫队长。"),
	]
	if _has_thief():
		lines.append(_l("艾德里克", C_EDRIC, "北边两座祭坛室的牢门能抄近路。会开锁的人，交给你们了。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "北边两座祭坛室的牢门打不开……那就从两侧的窄廊绕过去。"))
	if _here("vera"):
		lines.append(_l("薇拉", C_VERA, "教会的心脏，门还开着。……这一单，我喜欢。"))
	if not _missing_before().is_empty():
		lines.append(_l("艾德里克", C_EDRIC, "被教会抢走的圣器，一定也藏在这座神殿里。……全部拿回来。"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "金框标出的就是祭坛。站上去、行动结束，就能取回圣器。"),
	]


func _seven_appears() -> Array:
	var spared: bool = Campaign.flags.get("seven_16_spared", false)
	var lines: Array = [
		_l("", C_NARR, "封印之间的深处，一个灰色的身影走了出来。"),
		_l("七号", C_SEVEN, "……你来了。"),
		_l("缇娅", C_TIA, "七号……！"),
	]
	if spared:
		lines.append(_l("缇娅", C_TIA, "上次在地牢，你没有杀我。"))
		lines.append(_l("七号", C_SEVEN, "……这次的命令，是带你走。"))
	else:
		lines.append(_l("七号", C_SEVEN, "命令：带走巫女。其余的——清除。"))
	lines.append(_l("艾德里克", C_EDRIC, "别跟她硬拼！她伤得重了就会退——先拿圣器！"))
	return lines


func _seven_vs_tia() -> Array:
	return [
		_l("七号", C_SEVEN, "……这团火。"),
		_l("缇娅", C_TIA, "七号，你到底想要什么？"),
		_l("七号", C_SEVEN, "傀儡……不会「想要」。"),
	]


func _seven_retreats() -> Array:
	if flags.get("seven_tia", false):
		return [
			_l("七号", C_SEVEN, "……又是这团火。为什么……打不下去……"),
			_l("", C_NARR, "七号像一团被风吹散的灰烬，退进了封印之间的黑暗里。"),
		]
	return [
		_l("七号", C_SEVEN, "……任务，还没有结束。"),
		_l("", C_NARR, "七号像一团被风吹散的灰烬，退进了封印之间的黑暗里。"),
	]


func _altar_taken(u, relic: String) -> Array:
	var lines: Array = []
	match relic:
		"star_staff":
			lines.append(_l("", C_NARR, "祭坛上，一根缀着星辉的法杖微微发亮——「星之杖」。"))
		"sun_sword":
			lines.append(_l("", C_NARR, "祭坛上，一把剑身如晨光般的长剑——「日之剑」。"))
		"flame_crown":
			lines.append(_l("", C_NARR, "祭坛上，一顶赤金的王冠，冠上的宝石像是在燃烧——「炎之冠」。"))
		_:
			lines.append(_l("", C_NARR, "祭坛上，一杆枪尖指向天空的长枪——「天之枪」。"))
	if u.unit_id == "tia":
		lines.append(_l("缇娅", C_TIA, "……它在发烫。和我的手心一样。"))
	var left := _altars_left()
	if left == 0:
		lines.append(_l("艾德里克", C_EDRIC, "四座祭台的圣器，全部取回了！"))
		var b = battle.get_unit("ignaz")
		if b != null and b.is_alive():
			lines.append(_l("艾德里克", C_EDRIC, "剩下的，就是封印之间门口的伊格纳兹！"))
	return lines


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	if foe_id == "tia":
		lines.append(_l("伊格纳兹", C_BOSS, "炎之巫女。大司祭大人等你很久了——不必急，你很快就会站到封印台前。"))
	elif foe_id == "edric":
		lines.append(_l("伊格纳兹", C_BOSS, "埃德蒙的儿子。你父亲当年也走到了这扇门前。"))
		lines.append(_l("艾德里克", C_EDRIC, "……然后被你们变成了傀儡。"))
		lines.append(_l("伊格纳兹", C_BOSS, "然后他学会了服从。"))
	else:
		lines.append(_l("伊格纳兹", C_BOSS, "亲卫队的剑，只为大司祭而挥。"))
	lines.append(_l("伊格纳兹", C_BOSS, "这扇门后面，是你们不该看见的东西。"))
	return lines


func _boss_death() -> Array:
	return [
		_l("伊格纳兹", C_BOSS, "大司祭大人……门……就要开了……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "神殿安静了下来。四座祭坛上的圣器，被一件件捧到了封印之间。"),
	]
	if not _missing_before().is_empty():
		lines.append(_l("", C_NARR, "伊格纳兹身后的箱子里，躺着教会从别处抢来的圣器。"))
	lines.append_array([
		_l("", C_NARR, "炎之冠、天之枪、铁之盾、月之镜、风之弓、地之斧、星之杖、日之剑——八件圣器，摆上了封印台。"),
		_l("", C_NARR, "八件圣器同时亮了起来。地面深处，传来某种巨大之物的心跳。"),
		_l("缇娅", C_TIA, "……好烫。手心……不，全身都……"),
		_l("艾德里克", C_EDRIC, "缇娅？"),
		_l("莫尔甘", C_BOSS, "八件，一件不少。辛苦了，菲恩家的孩子。"),
		_l("艾德里克", C_EDRIC, "大司祭……莫尔甘……！"),
		_l("莫尔甘", C_BOSS, "你父亲查到了一半。圣器是锁——这没错。可八百年来，教会怎么也打不开这把锁。"),
		_l("莫尔甘", C_BOSS, "因为锁上，还缺一把钥匙。……炎之巫女的血。"),
		_l("缇娅", C_TIA, "我的……血？"),
		_l("莫尔甘", C_BOSS, "圣器集齐，封印松动；巫女之血洒上封印台，门就开了。"),
		_l("莫尔甘", C_BOSS, "你们替我跑遍了大陆，把锁一件件送到门前——连钥匙，也亲手带来了。"),
		_l("加雷斯", C_GARETH, "开什么玩笑！我们现在就把圣器全带走——"),
		_l("莫尔甘", C_BOSS, "带得走吗？……七号。"),
		_l("", C_NARR, "灰色的影子从石柱后掠出，比任何人的剑都快。"),
	])
	if Campaign.flags.get("seven_16_spared", false):
		lines.append(_l("七号", C_SEVEN, "……对不起。"))
	else:
		lines.append(_l("七号", C_SEVEN, "……命令，执行。"))
	lines.append_array([
		_l("缇娅", C_TIA, "七号——放开我！"),
		_l("艾德里克", C_EDRIC, "缇娅！！"),
		_l("", C_NARR, "七号抱起缇娅，消失在封印台后的黑暗里。"),
		_l("", C_NARR, "莫尔甘身后，审判官塞拉斯一直站着。他的手按在剑柄上——却始终没有拔出来。"),
		_l("莫尔甘", C_BOSS, "圣器就留给你们吧。没有钥匙的锁，不过是一堆旧铜烂铁。"),
		_l("莫尔甘", C_BOSS, "等下一个满月，来神殿最深处看看——不灭之火，是怎样醒过来的。"),
		_l("", C_NARR, "莫尔甘的身影，在一团白色的火焰里消散了。"),
		_l("加雷斯", C_GARETH, "……可恶！！"),
	])
	if _here("noya"):
		lines.append(_l("诺雅", C_NOYA, "塞拉斯大人……为什么不拔剑……"))
	if _here("kain"):
		lines.append(_l("凯因", C_KAIN, "……又让她一个人被抓走了。和白垣镇那天一样。"))
	if _here("vera"):
		lines.append(_l("薇拉", C_VERA, "这一单，还没完。黑烬接的单子，从来没有半途而废的。"))
	lines.append(_l("艾德里克", C_EDRIC, "……我会把她带回来。不管要去哪里。"))
	return lines


func _defeat() -> Array:
	for id in ["edric", "tia", "gareth"]:
		var u = battle.get_unit(id)
		if u != null and not u.is_alive():
			if id == "edric":
				return [_l("艾德里克", C_EDRIC, "父亲……我……走到这里……了……"),
					_l("", C_NARR, "艾德里克倒下了。神殿的大门，缓缓合上。")]
			if id == "tia":
				return [_l("缇娅", C_TIA, "火……在叫我……"),
					_l("", C_NARR, "缇娅倒下了。她的血，染红了封印台前的石阶。")]
			return [_l("加雷斯", C_GARETH, "烤全羊……还没……请……"),
				_l("", C_NARR, "加雷斯倒下了。布罗登的王子，再也没能回到故乡。")]
	return []


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "temple", "from": "brodden", "lines": [
		_l("", CB_NARR, "埃德蒙笔记上的最后两件圣器——「星之杖」「日之剑」，都在圣焰神殿。"),
		_l("", CB_NARR, "教会偷走的那几件，也都送进了那里。"),
		_l("", CB_NARR, "一行人从布罗登出发，往圣都以北的神殿去。这是第二篇的最后一段路。"),
	]}


func epilogue() -> Array:
	var spared: bool = Campaign.flags.get("seven_16_spared", false)
	var dark: Array = [
		_l("", CB_NARR, "神殿最深处。没有光，只有封印台下传来的、越来越响的心跳。"),
		_l("缇娅", C_TIA, "……为什么。"),
		_l("七号", CB_SEVEN, "……命令。"),
	]
	if spared:
		dark.append(_l("缇娅", C_TIA, "上次你放过我。这次你说「对不起」。……傀儡会说对不起吗？"))
	else:
		dark.append(_l("缇娅", C_TIA, "你抱着我的时候，手在抖。……傀儡会发抖吗？"))
	dark.append(_l("七号", CB_SEVEN, "……不会。"))
	dark.append(_l("", CB_NARR, "七号没有再说话。可她站在铁栏外，一整夜都没有离开。"))
	return [
		{"title": "圣焰神殿 · 最深处", "mood": "dungeon", "lines": dark},
		{"title": "灰岩村", "mood": "night", "lines": [
			_l("哈洛", C_HARLO, "巴尔托先生！王都传来消息……缇娅姐，被教会抓走了！"),
			_l("巴尔托", C_BALTO, "……哈洛，把老夫的枪拿来。"),
			_l("哈洛", C_HARLO, "可、可您的伤——"),
			_l("巴尔托", C_BALTO, "伤早就好了。……去把村里还拿得动武器的人都叫来。"),
			_l("巴尔托", C_BALTO, "灰岩村的人，该出发了。"),
			_l("", CB_NARR, "那一夜，灰岩村的火把排成了一条长长的线，朝着圣都的方向去了。"),
			_l("", CB_NARR, "——第二篇「寻父之旅」 完。"),
		]},
	]
