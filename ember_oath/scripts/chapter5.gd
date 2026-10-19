class_name Chapter5
extends ChapterBase
## 第五章「离别」：缇娅告别重伤的养父，带妮娜、凯因、诺雅南下。哈洛、托比留在村里照顾巴尔托。
## 守渡口：坚守到第 7 回合渡船到来（或击败追捕队长巴雷特）即通关。
## 第 3 回合是缇娅炎刃使觉醒的剧情点：满 Lv10 当场转职，不满就只演剧情、顺延到满级后的下一章开场。
## 章末与回程的艾德里克在渡口约定「王都再见」。

const CHAPTER_TITLE := "第五章 · 离别"
const VICTORY_TITLE := "第五章 · 完"
const VICTORY_SUB := "渡口一别。下一次见面，是在王都。"
const DEFEAT_SUB := "渡船靠岸时，岸上已经没有人了……"
const BG := ""

const HOLD_TURNS := 6             # 撑过 6 个回合，第 7 回合开始时渡船到

## 渡口在河湾里的一块半岛上，北面只有 (6,5)(7,5) 两格能过来：守住这道口子等船
const MAP := [
	"FFFF...FFF.MMMM",
	"F.H...R.......M",
	"..F...R...F....",
	"......R...FF...",
	".F....RRRR.....",
	"~~~~~~..~~~~~~~",
	"~~~~~~F.FR..~~~",
	"~~~~~~..RR...~~",
	"~~~~~~~~~~BB~~~",
	"~~~~~~~~~~~~~~~",
]

const LEVELS := [
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"000000110000000",
	"000000111111000",
	"000000111111100",
	"000000000011000",
	"000000000000000",
]

const C_TIA := Color(1.0, 0.62, 0.45)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_HARLO := Color(0.85, 0.95, 0.6)
const C_TOBY := Color(0.95, 0.75, 0.55)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)
const C_AWAKE := Color(1.0, 0.45, 0.2)

const _CHURCH := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 4,
	"hp": 22, "pwr": 6, "skl": 4, "spd": 4, "dfn": 4, "mov": 5,
	"weapons": ["iron_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _KNIGHT := {"name": "圣焰骑士", "class": "骑士", "faction": "enemy", "level": 5,
	"hp": 25, "pwr": 7, "skl": 5, "spd": 5, "dfn": 6, "mov": 7,
	"weapons": ["iron_lance"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _MERC := {"name": "黑烬佣兵", "class": "佣兵", "faction": "enemy", "level": 4,
	"hp": 23, "pwr": 6, "skl": 6, "spd": 7, "dfn": 3, "mov": 5,
	"weapons": ["iron_sword"], "color": Color(0.30, 0.28, 0.30),
	"hair": "short", "hair_color": Color(0.18, 0.16, 0.16), "armor": Color(0.28, 0.26, 0.28)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 4,
	"hp": 20, "pwr": 5, "skl": 6, "spd": 5, "dfn": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}

const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 5,
	"hp": 19, "pwr": 6, "skl": 5, "spd": 5, "dfn": 2, "res": 6, "mov": 5,
	"weapons": ["fire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}

const UNITS := [
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 7,
		"hp": 26, "pwr": 8, "skl": 9, "spd": 10, "dfn": 5, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(7, 6), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "nina", "pos": Vector2i(9, 7), "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 4,
		"hp": 20, "pwr": 6, "skl": 9, "spd": 8, "dfn": 3, "mov": 5, "weapons": ["iron_bow"],
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15}},
	{"id": "kain", "pos": Vector2i(6, 6), "name": "凯因", "class": "佣兵", "faction": "player", "level": 5,
		"hp": 24, "pwr": 7, "skl": 10, "spd": 11, "dfn": 4, "mov": 5, "weapons": ["iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25}},
	{"id": "noya", "pos": Vector2i(8, 7), "name": "诺雅", "class": "修女", "faction": "player", "level": 3,
		"hp": 17, "pwr": 4, "skl": 5, "spd": 7, "dfn": 1, "mov": 5, "weapons": ["heal_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15}},
	# 敌方先头部队
	{"id": "church1", "pos": Vector2i(6, 1)},
	{"id": "merc3", "pos": Vector2i(3, 3)},
	{"id": "merc1", "pos": Vector2i(8, 2)},
	{"id": "merc2", "pos": Vector2i(12, 2)},
	{"id": "archer1", "pos": Vector2i(13, 3)},
	# 追捕队长巴雷特：重甲，坐镇北面山道口不动
	{"id": "barrett", "name": "巴雷特", "class": "追捕队长", "faction": "enemy", "level": 8,
		"hp": 34, "pwr": 10, "skl": 6, "spd": 3, "dfn": 11, "mov": 4,
		"weapons": ["steel_lance"], "boss": true, "stationary": true,
		"pos": Vector2i(6, 0), "color": Color(0.70, 0.66, 0.60),
		"hair": "short", "hair_color": Color(0.30, 0.25, 0.20), "armor": Color(0.62, 0.60, 0.58), "scar": true},
]

## 按回合涌来的追兵
const WAVES := {
	2: [{"id": "merc_r0", "pos": Vector2i(0, 4)}],
	3: [{"id": "merc_r1", "pos": Vector2i(10, 0)}, {"id": "church_r1", "pos": Vector2i(14, 2)}],
	4: [{"id": "archer_r1", "pos": Vector2i(7, 0)}, {"id": "mage_r1", "pos": Vector2i(5, 0)}],
	5: [{"id": "merc_r2", "pos": Vector2i(4, 0)}],
}


func chapter_id() -> String:
	return "ch5"


func templates() -> Dictionary:
	return {"church": _CHURCH, "knight": _KNIGHT, "merc": _MERC, "archer": _ARCHER, "mage": _MAGE}


func lose_ids() -> Array:
	return ["tia"]


func extra_slots() -> Array:
	return [Vector2i(10, 7), Vector2i(11, 7), Vector2i(10, 6), Vector2i(11, 6)]


## 哈洛、托比留在村里照顾巴尔托（第 23 章回归）
func before_spawn_status() -> Dictionary:
	var out := {}
	for id in ["harlo", "bandit6"]:
		if Campaign.status_of(id) == "active":
			out[id] = "away"
	return out


func is_won() -> bool:
	if battle.turn > HOLD_TURNS:
		return true
	var b = battle.get_unit("barrett")
	if b != null and not b.is_alive():
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("坚守渡口到第 7 回合，或击败巴雷特")


func lose_condition() -> String:
	return tr("缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_farewell())
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("追兵来了！"), Color(1.0, 0.5, 0.3))
	if t == 3 and not flags.get("awaken_point", false):
		flags["awaken_point"] = true
		await _awaken_point()
	elif t == HOLD_TURNS and not flags.get("ferry_hint", false):
		flags["ferry_hint"] = true
		await battle.play_dialogue(_ferry_hint())


func on_before_combat(att, def) -> void:
	if "barrett" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "barrett" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == Vector2i(2, 1):
		await battle.play_dialogue(_visit_farm())
		u.give("vulnerary")
		battle.notify(tr("获得 伤药"))


func talks() -> Array:
	return [["tia", "noya", "tia_noya"], ["kain", "tia", "kain_tia"]]


func talk_lines(key: String) -> Array:
	if key == "tia_noya":
		return [
			_l("诺雅", C_NOYA, "缇娅……你真的不怕吗？教会说你的火会烧掉一切。"),
			_l("缇娅", C_TIA, "怕。可是那天在村里，它没有烧我，也没有烧哈洛。"),
			_l("诺雅", C_NOYA, "……圣典里写，八百年前的炎之巫女烧毁了半个大陆。可圣典没写，她为什么要那样做。"),
			_l("缇娅", C_TIA, "那我们就去王都，把没写的那一半找出来。"),
		]
	return [
		_l("凯因", C_KAIN, "缇娅，教会出钱，黑烬动手。要是哪天在路上碰见团长……"),
		_l("缇娅", C_TIA, "你会站在哪一边？"),
		_l("凯因", C_KAIN, "……站在你这边。我只是想问她一句，为什么接这单活。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	await battle.play_dialogue(_defeat_tia())


## 炎刃使觉醒的剧情点：满 Lv10 当场转职；不满只演剧情，顺延（见大纲「转职规则」）
func _awaken_point() -> void:
	var tia = battle.get_unit("tia")
	if tia == null or not tia.is_alive():
		return
	Audio.play_sfx("awaken")
	await battle.play_dialogue(_awaken_lines())
	if tia.class_label == "炎刃使":
		return
	if tia.level >= 10:
		Campaign.flags.erase("tia_awaken_pending")
		await battle.awaken_tia(false)
	else:
		Campaign.flags["tia_awaken_pending"] = true
		await battle.play_dialogue(_awaken_not_yet())


# ==================== 台词 ====================

func _farewell() -> Array:
	var lines: Array = [
		_l("", C_NARR, "三天后。灰岩村南面，大河的渡口。"),
		_l("巴尔托", C_BALTO, "去吧，缇娅。教会不会只来一次。王都人多，藏得住人。"),
		_l("缇娅", C_TIA, "可你的伤……"),
		_l("巴尔托", C_BALTO, "死不了。……你母亲的事，等你回来，老夫全告诉你。"),
	]
	if Campaign.status_of("harlo") == "away":
		lines.append(_l("哈洛", C_HARLO, "缇娅姐，村子交给我们！等你回来，房子都盖好了！"))
	if Campaign.status_of("bandit6") == "away":
		lines.append(_l("托比", C_TOBY, "我、我会照顾老爷子的！劈柴烧水我都会！"))
	lines.append(_l("缇娅", C_TIA, "……嗯。巴尔托，你答应过我的，不许耍赖。"))
	lines.append(_l("巴尔托", C_BALTO, "（叹气）……嗯。老夫答应你。"))
	return lines


func _pre_battle() -> Array:
	return [
		_l("", C_NARR, "渡船还要半天才到。北面的山道上，追兵的火把亮了起来。"),
		_l("巴雷特", C_BOSS, "教会追捕队长巴雷特。审判官大人有令：异端缇娅，死活不论。"),
		_l("凯因", C_KAIN, "教会兵、骑士……还有黑烬的人。他们是一伙的。"),
		_l("妮娜", C_NINA, "背后是河，退不了了。"),
		_l("缇娅", C_TIA, "那就不退。守住渡口，等船来！"),
	]


func _awaken_lines() -> Array:
	return [
		_l("", C_NARR, "河风里，缇娅的剑又热了起来。和那天在村里一样。"),
		_l("缇娅", C_TIA, "又是这团火……这一次，我不想再让它散掉。"),
	]


func _awaken_not_yet() -> Array:
	return [
		_l("", C_NARR, "火焰在剑身上亮了一瞬，又一次散去。"),
		_l("缇娅", C_TIA, "……还不够。现在的我，还握不住它。"),
		_l("诺雅", C_NOYA, "缇娅，你的手在发抖。"),
		_l("缇娅", C_TIA, "没事。总有一天，我会握住的。"),
	]


func _ferry_hint() -> Array:
	return [
		_l("妮娜", C_NINA, "河面上有船帆！渡船要到了，再撑一会儿！"),
	]


func _boss() -> Array:
	return [
		_l("巴雷特", C_BOSS, "异端的火？我这身铁甲，烧不穿。"),
		_l("缇娅", C_TIA, "那就一刀一刀砍穿它。"),
	]


func _boss_death() -> Array:
	return [
		_l("巴雷特", C_BOSS, "审判官大人……异端……向南……逃了……"),
	]


func _visit_farm() -> Array:
	return [
		_l("村民", C_NPC, "你就是灰岩村那个红头发的姑娘？……教会的人问过我。我什么都没说。"),
		_l("村民", C_NPC, "拿着这个，路上用。王都那边，可比这儿乱多了。"),
	]


func _post_battle() -> Array:
	return [
		_l("", C_NARR, "渡船靠了岸。从船上跳下来的，是一个熟悉的身影。"),
		_l("艾德里克", C_EDRIC, "缇娅？……果然是你们！我在对岸就看见这边在打仗。"),
		_l("缇娅", C_TIA, "艾德里克！你不是回家了吗？"),
		_l("艾德里克", C_EDRIC, "回去了。父亲看了那封密信，说要亲自去圣都问个明白，让我先回领地等消息。"),
		_l("艾德里克", C_EDRIC, "你们呢？教会的人追得这么紧……"),
		_l("缇娅", C_TIA, "我要去王都。找出是谁想要我的火，为什么。"),
		_l("艾德里克", C_EDRIC, "……我送不了你。领地离不开人。"),
		_l("艾德里克", C_EDRIC, "等父亲回来，我就去王都找你。我们在王都再见。"),
		_l("缇娅", C_TIA, "嗯。王都再见。"),
		_l("", C_NARR, "渡船离了岸。缇娅回头时，艾德里克还站在渡口，一直没有走。"),
		_l("", C_NARR, "那时谁也不知道，他的父亲再也不会回到菲恩城了。"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "对不起……巴尔托……我回不去了……"),
		_l("", C_NARR, "缇娅倒在了渡口。渡船靠岸时，岸上已经没有人了。"),
	]
