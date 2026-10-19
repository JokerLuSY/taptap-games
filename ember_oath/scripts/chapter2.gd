class_name Chapter2
extends RefCounted
## 第二章「燃烧的村庄」：灰岩村被焚，缇娅强制觉醒为炎刃使，击破放火的敌人即可通关。
## 焦土 C / 火焰 E / 废墟 Z 由 Board 用程序色块绘制，不另做地图或精灵图集。

const CHAPTER_TITLE := "第二章 · 燃烧的村庄"
const VICTORY_TITLE := "第二章 · 完"
const VICTORY_SUB := "灰岩村燃尽了。火，却还在缇娅剑上。"
const DEFEAT_SUB := "灰岩村葬于火海……"

## 不用手绘底图：和第一章一样走 CC0 图块（MapTiles）。
const BG := ""

## 15×10。北侧村庄焦土与火焰，南侧平地进军。E 不可踏。
const MAP := [
	"FCCZEEEZCCZECCF",
	"F.CZE.Z.C.EZ..F",
	"..CC.R.R.R.CC..",
	".HC..R...R..CZ.",
	".....R...R.....",
	"...E.R...R.E...",
	"...............",
	"...............",
	"...............",
	"...............",
]

const LEVELS := [
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
]

const C_TIA := Color(1.0, 0.62, 0.45)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)
const C_AWAKE := Color(1.0, 0.45, 0.2)

## 与设计大纲一致：保留当前能力，HP+3 / 力+2 / 防+1，等级重置为 1。
const PROMOTE_BONUS := {"hp": 3, "pwr": 2, "dfn": 1}

const UNITS := [
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 1,
		"hp": 20, "pwr": 5, "skl": 6, "spd": 7, "dfn": 3, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(5, 8), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "balto", "name": "巴尔托", "class": "圣骑士", "faction": "player", "level": 8,
		"hp": 26, "pwr": 8, "skl": 9, "spd": 8, "dfn": 7, "mov": 7,
		"weapons": ["silver_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 40, "pwr": 20, "skl": 25, "spd": 25, "dfn": 20},
		"pos": Vector2i(8, 8), "color": Color(0.45, 0.55, 0.75),
		"hair": "short", "hair_color": Color(0.75, 0.75, 0.78), "armor": Color(0.70, 0.73, 0.82)},
	{"id": "bandit1", "pos": Vector2i(2, 2)},
	{"id": "bandit2", "pos": Vector2i(11, 2)},
	{"id": "bandit3", "pos": Vector2i(5, 4)},
	# 探子：可击破的普通敌人，没有说得，不挡通关。立绘暂用山贼。
	{"id": "scout1", "name": "探子", "class": "探子", "faction": "enemy", "level": 1,
		"hp": 16, "pwr": 3, "skl": 4, "spd": 6, "dfn": 2, "mov": 5,
		"weapons": ["iron_sword"], "pos": Vector2i(13, 4), "color": Color(0.40, 0.42, 0.38),
		"hair": "hood", "hair_color": Color(0.25, 0.22, 0.18), "armor": Color(0.35, 0.38, 0.32)},
	{"id": "marco", "name": "马尔科", "class": "山贼头目", "faction": "enemy", "level": 3,
		"hp": 28, "pwr": 7, "skl": 4, "spd": 3, "dfn": 4, "mov": 5,
		"weapons": ["war_axe"], "stationary": true, "boss": true,
		"pos": Vector2i(7, 1), "color": Color(0.55, 0.28, 0.18),
		"hair": "spiky", "hair_color": Color(0.18, 0.10, 0.08), "armor": Color(0.42, 0.24, 0.18), "scar": true},
]

const SUPPORTS := {}

var battle = null
var visited := {}
var f_awaken := false
var f_boss := false
var f_scout := false


func on_battle_start() -> void:
	# 地图 BGM 已由 battle 播放（复用第一章）。这里只叠火焰 loop。
	Audio.play_loop("fire")
	await battle.play_dialogue(_pre_battle())
	await _awaken()


func on_turn_start(_t: int) -> void:
	if false:
		await battle.play_dialogue([])


func on_before_combat(_att, def) -> void:
	if def.unit_id == "marco" and not f_boss:
		f_boss = true
		await battle.play_dialogue(_boss())
	elif def.unit_id == "scout1" and not f_scout:
		f_scout = true
		await battle.play_dialogue(_scout())


func on_after_combat(_att, _def, _def_died: bool) -> void:
	if false:
		await battle.play_dialogue([])


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == Vector2i(1, 3):
		await battle.play_dialogue(_visit())
		u.items.append("vulnerary")
		battle.notify(tr("获得 伤药"))


func get_talk_partner(_u):
	return null


func on_talk(_u) -> void:
	if false:
		await battle.play_dialogue([])


func get_support_partner(_u):
	return null


func on_support(_u) -> void:
	if false:
		await battle.play_dialogue([])


func get_recruit_target(_u):
	return null


func on_recruit(_u) -> void:
	if false:
		await battle.play_dialogue([])


func win_condition() -> String:
	return tr("击败所有敌人")


func lose_condition() -> String:
	return tr("缇娅或巴尔托阵亡")


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	var tia = battle.get_unit("tia")
	if tia == null or not tia.is_alive():
		await battle.play_dialogue(_defeat_tia())
	else:
		await battle.play_dialogue(_defeat_balto())


func _awaken() -> void:
	if f_awaken:
		return
	Audio.play_sfx("awaken")
	await battle.play_dialogue(_awaken_lines())
	var tia = battle.get_unit("tia")
	tia.promote("炎刃使", PROMOTE_BONUS, ["ember_blade"])
	tia.hair_color = Color(1.0, 0.42, 0.12)
	tia.armor_color = Color(0.72, 0.28, 0.16)
	tia.body_color = Color(0.95, 0.40, 0.22)
	tia.queue_redraw()
	f_awaken = true
	Audio.play_sfx("promote")
	Audio.play_sfx("fire")
	battle.show_banner(tr("觉醒 · 炎刃使"), Color(1.0, 0.45, 0.15))
	battle.notify(tr("缇娅转职为炎刃使！"))


func _l(n: String, c: Color, t: String) -> Dictionary:
	return {"name": n, "color": c, "text": tr(t)}


func _pre_battle() -> Array:
	return [
		_l("", C_NARR, "夜。灰岩村的麦田和屋顶都烧着了。"),
		_l("缇娅", C_TIA, "村子……怎么会变成这样！"),
		_l("巴尔托", C_BALTO, "他们不是来抢粮的。这火，是冲你来的。"),
		_l("缇娅", C_TIA, "哈洛呢？婆婆呢？！"),
		_l("巴尔托", C_BALTO, "往林子里撤了。放火的人还在村里。"),
		_l("缇娅", C_TIA, "我要灭了这火，也灭了他们！"),
		_l("巴尔托", C_BALTO, "别冲太前。焦土难走，火焰踏不得。"),
	]


func _awaken_lines() -> Array:
	return [
		_l("", C_NARR, "火焰扑上缇娅的剑。她没有退。"),
		_l("缇娅", C_TIA, "热……这热是从我自己身上来的？"),
		_l("巴尔托", C_BALTO, "缇娅！把剑放下——！"),
		_l("缇娅·觉醒", C_AWAKE, "……不。这火听我的。"),
		_l("缇娅·觉醒", C_AWAKE, "村子已经烧了。接下来，我来烧回去！"),
		_l("", C_NARR, "剑士之路在火里折断。炎刃使，于此觉醒。"),
	]


func _visit() -> Array:
	return [
		_l("村民", C_NPC, "缇娅！井边的人都跑了……伤药给你，求你活着！"),
		_l("缇娅", C_TIA, "先活下去。火，我来挡。"),
	]


func _scout() -> Array:
	return [
		_l("探子", C_ENEMY, "红头发……就是她！得赶紧回报团里！"),
		_l("缇娅", C_TIA, "你跑不掉。"),
	]


func _boss() -> Array:
	return [
		_l("马尔科", C_BOSS, "烧得真漂亮。那丫头的头发，跟这火一个色！"),
		_l("缇娅", C_TIA, "你烧的是我的家！"),
		_l("马尔科", C_BOSS, "上头要的是活口。可惜，你挡路了。"),
	]


func _post_battle() -> Array:
	return [
		_l("", C_NARR, "火势终于被压住。灰岩村只剩下焦黑的梁。"),
		_l("缇娅·觉醒", C_AWAKE, "人是打退了……村子却没了。"),
		_l("巴尔托", C_BALTO, "你体内的火，今天认了你。这不是结束。"),
		_l("缇娅·觉醒", C_AWAKE, "我知道。谁让村子烧起来，我就去找谁。"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "火……好大……"),
		_l("", C_NARR, "缇娅倒下了。灰岩村的火，再也没有人去扑。"),
	]


func _defeat_balto() -> Array:
	return [
		_l("巴尔托", C_BALTO, "缇娅……别让这火烧到你自己……"),
		_l("", C_NARR, "巴尔托倒下了。火海吞没了灰岩村。"),
	]
