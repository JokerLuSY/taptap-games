class_name Chapter12
extends ChapterBase
## 第十二章「银湾港」：找回四散的同伴，再找一条船去圣都的水门。
## 凯因、妮娜在港口的两个角落被教会兵追着（中立单位），缇娅走到身边【对话】就回队；
## 已阵亡 / 转幕后的人不出现，改一句台词交代。走私船的船老大布鲁诺被港务官胁迫、是敌方，
## 凯因（或缇娅）【说得】入队。海盗从沙滩登岸增援。胜利：击败守在港务所王座上的港务官卡尔顿。

const CHAPTER_TITLE := "第十二章 · 银湾港"
const VICTORY_TITLE := "第十二章 · 完"
const VICTORY_SUB := "船帆鼓满了风。船头，指着圣都。"
const DEFEAT_SUB := "银湾港的潮水，涨了又退……"
const BG := ""

## 34×22。我方从西边大街进港；北边是街区（民宅 D、三户可访问 H、武器店 Y、道具店 V），
## 南边是沙滩（s）和三座栈桥（B），布鲁诺的走私船停在中间那座栈桥的尽头；
## 东边临海是石墙围起来的港务所（城门 G），港务官卡尔顿坐在王座 K 上。
## 凯因被追到东北角的小巷，妮娜被追到西南的沙滩。
const MAP := [
	"....S.........S.......S...........",
	".DD.S....DD.F.S....D..S....DD...F.",
	"....S.DD......S.DD....S.DD........",
	".D..S....H.D..S.......S.......DD..",
	"....S.......W.S...H.D.S...F.......",
	"..F.S.........S.......S.......DD..",
	"SSSSSSSSSSSSSSSSSSSSSSSSSSS..F...~",
	"....S.........S.......S..........~",
	".D..S..DD...Y.S.D..D..S.D..######~",
	"..D.S.....D...S..D....S..D.#ISSS#~",
	".H..S.........S.....V.S....#SSSS#~",
	"....SSSSSSSSSSSSSSSSSSS....GSSKS#~",
	"....S......F..S.......SSSSS#SSSS#~",
	"F...S...DDD...S..DDD..S....#ISSS#~",
	"....S..D...D..S.....F.S..DD######~",
	"ssssssssssssssssssssssssssssssss~~",
	"ssssssssssssssssssssssssssssssss~~",
	"~~~~~B~~~~~~~~BB~~~~~~~B~~~~~~~~~~",
	"~~~~~B~~~~~~~~BB~~~~~~~B~~~~~~~~~~",
	"~~~~~B~~~~~~~~BB~~~~~~~B~~~~~~~~~~",
	"~~~~~~~~~~~~~BBBB~~~~~~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]

const LEVELS := []

const KAIN_POS := Vector2i(31, 1)
const NINA_POS := Vector2i(2, 16)
const VISIT_SAILOR := Vector2i(9, 3)
const VISIT_INN := Vector2i(18, 4)
const VISIT_LOCKSMITH := Vector2i(1, 10)
const SHOP_ARMORY := Vector2i(12, 8)
const SHOP_VENDOR := Vector2i(20, 10)

## 凯因、妮娜：名单为空（直接从本章开打的测试）时用的默认数值
const KAIN_FALLBACK := {"name": "凯因", "class": "佣兵", "level": 11,
	"hp": 30, "pwr": 11, "skl": 14, "spd": 16, "dfn": 6, "res": 3, "mov": 5,
	"weapons": ["iron_sword", "steel_sword"], "items": ["vulnerary"],
	"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25},
	"color": Color(0.45, 0.40, 0.55), "hair": "short", "hair_color": Color(0.20, 0.18, 0.24),
	"armor": Color(0.38, 0.34, 0.42)}
const NINA_FALLBACK := {"name": "妮娜", "class": "弓箭手", "level": 10,
	"hp": 24, "pwr": 9, "skl": 13, "spd": 11, "dfn": 5, "res": 3, "mov": 5,
	"weapons": ["iron_bow", "steel_bow"], "items": ["vulnerary"],
	"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15},
	"color": Color(0.45, 0.60, 0.35), "hair": "ponytail", "hair_color": Color(0.55, 0.36, 0.20),
	"armor": Color(0.42, 0.55, 0.32)}

const C_TIA := Color(1.0, 0.62, 0.45)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_LANCE := Color(0.8, 0.9, 0.75)
const C_GWEN := Color(1.0, 0.78, 0.6)
const C_OSCAR := Color(0.78, 0.82, 0.9)
const C_MIRA := Color(0.75, 0.95, 0.85)
const C_VICTOR := Color(0.78, 0.7, 0.95)
const C_BRUNO := Color(0.85, 0.72, 0.55)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _CHURCH := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 10,
	"hp": 29, "pwr": 10, "skl": 8, "spd": 8, "dfn": 7, "res": 2, "mov": 5,
	"weapons": ["iron_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _SOLDIER := {"name": "港口卫兵", "class": "枪兵", "faction": "enemy", "level": 11,
	"hp": 30, "pwr": 11, "skl": 9, "spd": 9, "dfn": 8, "res": 2, "mov": 5,
	"weapons": ["steel_lance"], "color": Color(0.55, 0.62, 0.75),
	"hair": "short", "hair_color": Color(0.30, 0.26, 0.20), "armor": Color(0.50, 0.58, 0.72)}
const _KNIGHT := {"name": "港口骑兵", "class": "骑士", "faction": "enemy", "level": 11,
	"hp": 32, "pwr": 11, "skl": 9, "spd": 8, "dfn": 10, "res": 2, "mov": 7,
	"weapons": ["iron_lance", "javelin"], "color": Color(0.55, 0.60, 0.72),
	"hair": "short", "hair_color": Color(0.45, 0.36, 0.24), "armor": Color(0.56, 0.62, 0.76)}
const _ARMOR := {"name": "港务重甲", "class": "重甲兵", "faction": "enemy", "level": 11,
	"hp": 33, "pwr": 11, "skl": 7, "spd": 3, "dfn": 14, "res": 2, "mov": 4,
	"weapons": ["iron_lance"], "color": Color(0.50, 0.55, 0.65),
	"hair": "short", "armor": Color(0.52, 0.58, 0.70)}
const _ARCHER := {"name": "港口弓兵", "class": "弓箭手", "faction": "enemy", "level": 10,
	"hp": 27, "pwr": 10, "skl": 10, "spd": 9, "dfn": 5, "res": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.55, 0.62, 0.70),
	"hair": "hood", "armor": Color(0.50, 0.56, 0.66)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 11,
	"hp": 26, "pwr": 11, "skl": 9, "spd": 9, "dfn": 3, "res": 10, "mov": 5,
	"weapons": ["fire", "thunder"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _PIRATE := {"name": "海盗", "class": "山贼", "faction": "enemy", "level": 11,
	"hp": 33, "pwr": 12, "skl": 6, "spd": 8, "dfn": 5, "res": 1, "mov": 5,
	"weapons": ["iron_axe", "hand_axe"], "color": Color(0.35, 0.40, 0.55),
	"hair": "spiky", "hair_color": Color(0.18, 0.14, 0.10), "armor": Color(0.30, 0.36, 0.50)}

const UNITS := [
	# 我方：名单里有存档时用存档；这里只给位置和直接进本章时的默认数值
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 11,
		"hp": 31, "pwr": 10, "skl": 12, "spd": 13, "dfn": 8, "res": 4, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(1, 6), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 6,
		"hp": 37, "pwr": 13, "skl": 16, "spd": 17, "dfn": 9, "res": 5, "mov": 6,
		"weapons": ["ember_blade"], "items": ["vulnerary"], "wexp": {"sword": 71},
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(1, 7), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 11,
		"hp": 32, "pwr": 11, "skl": 10, "spd": 9, "dfn": 10, "res": 2, "mov": 7,
		"weapons": ["iron_lance", "javelin"], "items": [],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(0, 6), "color": Color(0.35, 0.55, 0.40),
		"hair": "short", "hair_color": Color(0.35, 0.28, 0.20), "armor": Color(0.45, 0.60, 0.48)},
	{"id": "gwen", "name": "葛温", "class": "骑士", "faction": "player", "level": 10,
		"hp": 30, "pwr": 11, "skl": 8, "spd": 11, "dfn": 8, "res": 1, "mov": 7,
		"weapons": ["iron_lance", "steel_lance"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 50, "skl": 35, "spd": 50, "dfn": 25, "res": 15},
		"pos": Vector2i(0, 7), "color": Color(0.70, 0.35, 0.30),
		"hair": "ponytail", "hair_color": Color(0.85, 0.50, 0.20), "armor": Color(0.68, 0.38, 0.32)},
	{"id": "oscar", "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 12,
		"hp": 34, "pwr": 12, "skl": 8, "spd": 4, "dfn": 15, "res": 2, "mov": 4,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(0, 5), "color": Color(0.50, 0.52, 0.60),
		"hair": "short", "hair_color": Color(0.45, 0.42, 0.40), "armor": Color(0.60, 0.62, 0.70)},
	{"id": "mira", "name": "米拉", "class": "枪兵", "faction": "player", "level": 11,
		"hp": 29, "pwr": 10, "skl": 11, "spd": 12, "dfn": 7, "res": 4, "mov": 5,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 40, "skl": 50, "spd": 55, "dfn": 25, "res": 25},
		"pos": Vector2i(1, 5), "color": Color(0.40, 0.62, 0.55),
		"hair": "ponytail", "hair_color": Color(0.30, 0.22, 0.16), "armor": Color(0.42, 0.58, 0.50)},
	{"id": "victor", "name": "维克多", "class": "暗法师", "faction": "player", "level": 11,
		"hp": 26, "pwr": 11, "skl": 8, "spd": 7, "dfn": 5, "res": 11, "mov": 5,
		"weapons": ["flux"], "items": ["vulnerary"],
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45},
		"pos": Vector2i(2, 7), "color": Color(0.34, 0.30, 0.44),
		"hair": "short", "hair_color": Color(0.22, 0.20, 0.26), "armor": Color(0.30, 0.28, 0.38)},
	{"id": "noya", "name": "诺雅", "class": "修女", "faction": "player", "level": 9,
		"hp": 21, "pwr": 7, "skl": 8, "spd": 10, "dfn": 3, "res": 9, "mov": 5,
		"weapons": ["heal_staff"], "items": ["vulnerary"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 50},
		"pos": Vector2i(2, 5), "color": Color(0.95, 0.92, 0.85),
		"hair": "ponytail", "hair_color": Color(0.85, 0.75, 0.50), "armor": Color(0.92, 0.90, 0.84)},
	# 敌方：追凯因、妮娜的教会兵
	{"id": "church1", "pos": Vector2i(30, 0), "hold": true},
	{"id": "church2", "pos": Vector2i(30, 2), "hold": true},
	{"id": "church3", "pos": Vector2i(4, 15), "hold": true},
	{"id": "church4", "pos": Vector2i(3, 14), "hold": true},
	# 街区
	{"id": "soldier1", "pos": Vector2i(8, 6)},
	{"id": "soldier2", "pos": Vector2i(14, 9), "hold": true},
	{"id": "archer1", "pos": Vector2i(11, 10)},
	{"id": "mage1", "pos": Vector2i(17, 6), "items": ["vulnerary"]},
	{"id": "armor1", "pos": Vector2i(22, 7), "hold": true},
	{"id": "knight1", "pos": Vector2i(18, 10)},
	# 码头
	{"id": "pirate1", "pos": Vector2i(10, 16)},
	{"id": "pirate2", "pos": Vector2i(18, 16)},
	{"id": "pirate3", "pos": Vector2i(24, 15), "hold": true},
	{"id": "archer2", "pos": Vector2i(12, 14), "hold": true},
	{"id": "pirate4", "pos": Vector2i(14, 17), "hold": true, "items": ["elixir"]},
	# 港务所
	{"id": "armor2", "pos": Vector2i(26, 11), "hold": true},
	{"id": "soldier3", "pos": Vector2i(25, 12), "hold": true},
	{"id": "armor3", "pos": Vector2i(28, 11), "hold": true},
	{"id": "mage2", "pos": Vector2i(29, 10), "hold": true},
	{"id": "archer3", "pos": Vector2i(29, 12), "hold": true},
	# 布鲁诺：走私船的船老大，被港务官胁迫、守着自己的船。凯因（或缇娅）【说得】入队
	{"id": "bruno", "name": "布鲁诺", "class": "战士", "faction": "enemy", "level": 10,
		"hp": 36, "pwr": 12, "skl": 8, "spd": 8, "dfn": 6, "res": 1, "mov": 5,
		"weapons": ["iron_axe", "hand_axe"], "items": ["vulnerary"], "hold": true,
		"growths": {"hp": 85, "pwr": 55, "skl": 35, "spd": 35, "dfn": 25, "res": 10},
		"pos": Vector2i(15, 19), "color": Color(0.55, 0.40, 0.30),
		"hair": "short", "hair_color": Color(0.20, 0.14, 0.10), "armor": Color(0.45, 0.36, 0.28), "scar": true},
	# 港务官卡尔顿：港务所的王座上
	{"id": "carlton", "name": "卡尔顿", "class": "重甲兵", "faction": "enemy", "level": 14,
		"hp": 40, "pwr": 15, "skl": 9, "spd": 5, "dfn": 17, "res": 4, "mov": 4,
		"weapons": ["steel_lance", "javelin"], "boss": true, "stationary": true, "sprite": "barrett",
		"items": ["elixir"],
		"pos": Vector2i(30, 11), "color": Color(0.45, 0.50, 0.62),
		"hair": "short", "hair_color": Color(0.55, 0.50, 0.42), "armor": Color(0.48, 0.55, 0.70)},
]

## 第 3、5 回合海盗从沙滩登岸；第 7 回合北边街口来卫兵
const WAVES := {
	3: [{"id": "pirate_r1", "pos": Vector2i(8, 16)}, {"id": "pirate_r2", "pos": Vector2i(20, 16)}],
	5: [{"id": "pirate_r3", "pos": Vector2i(28, 16)}, {"id": "pirate_r4", "pos": Vector2i(0, 16)}],
	7: [{"id": "soldier_r1", "pos": Vector2i(22, 0)}, {"id": "archer_r1", "pos": Vector2i(14, 0)}],
}


func chapter_id() -> String:
	return "ch12"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 7


func forced_ids() -> Array:
	return ["edric", "tia"]


func extra_deploy_slots() -> Array:
	return [Vector2i(2, 6), Vector2i(3, 7), Vector2i(3, 5), Vector2i(0, 4)]


func templates() -> Dictionary:
	return {"church": _CHURCH, "soldier": _SOLDIER, "knight": _KNIGHT, "armor": _ARMOR, "archer": _ARCHER,
		"mage": _MAGE, "pirate": _PIRATE}


func lose_ids() -> Array:
	return ["edric", "tia"]


func extra_slots() -> Array:
	return [Vector2i(2, 6), Vector2i(3, 7), Vector2i(3, 5), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4),
		Vector2i(0, 8), Vector2i(1, 9)]


func shops() -> Dictionary:
	return {SHOP_ARMORY: ["iron_sword", "steel_sword", "killing_edge", "armorslayer", "iron_lance", "steel_lance",
			"javelin", "steel_axe", "hand_axe", "steel_bow", "thunder", "flux"],
		SHOP_VENDOR: ["vulnerary", "elixir", "door_key", "heal_staff", "mend_staff"]}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "steel_lance", "steel_axe", "steel_bow", "heal_staff"]


func is_won() -> bool:
	var c = battle.get_unit("carlton")
	if c != null and not c.is_alive():
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("击败港务官卡尔顿")


func lose_condition() -> String:
	return tr("艾德里克或缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	_spawn_friends()
	await battle.play_dialogue(_pre_battle())


## 凯因、妮娜作为中立单位出场（阵亡 / 转幕后的回不来，rejoin_unit 返回 null）
func _spawn_friends() -> void:
	var fresh := Campaign.roster.is_empty()
	battle.rejoin_unit("kain", KAIN_POS, "npc", KAIN_FALLBACK if fresh else {})
	battle.rejoin_unit("nina", NINA_POS, "npc", NINA_FALLBACK if fresh else {})
	# 绿色第三方：躲着，教会兵靠近了才还手（友军阶段行动）；缇娅【对话】后回队
	for id in ["kain", "nina"]:
		var u = battle.get_unit(id)
		if u != null:
			u.set_meta("fights", true)
			u.hold = true


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		if t == 7:
			battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		else:
			battle.show_banner(tr("海盗登岸了！"), Color(1.0, 0.5, 0.3))
		if t == 3:
			await battle.play_dialogue(_pirates())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


func on_before_combat(att, def) -> void:
	if "carlton" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())
	elif "bruno" in [att.unit_id, def.unit_id] and not flags.get("bruno_fight", false):
		var b = att if att.unit_id == "bruno" else def
		if not b.is_player():
			flags["bruno_fight"] = true
			await battle.play_dialogue(_bruno_fight())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "carlton" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_SAILOR:
		await battle.play_dialogue(_visit_sailor())
		u.receive("armorslayer")
		battle.notify(tr("获得 破甲剑"))
	elif pos == VISIT_INN:
		await battle.play_dialogue(_visit_inn())
		battle.add_gold(1500)
		battle.notify(tr("获得 1500G"))
	elif pos == VISIT_LOCKSMITH:
		await battle.play_dialogue(_visit_locksmith())
		u.receive("door_key")
		battle.notify(tr("获得 钥匙"))


## 凯因、妮娜：缇娅【对话】回队。布鲁诺：凯因【说得】，凯因不在时缇娅也能说得
func recruits() -> Dictionary:
	return {"kain": ["tia"], "nina": ["tia"], "bruno": ["kain", "tia"]}


func recruit_lines(target_id: String, by_id: String) -> Array:
	if target_id == "kain":
		return _kain_back()
	if target_id == "nina":
		return _nina_back()
	if by_id == "kain":
		return _bruno_by_kain()
	return _bruno_by_tia()


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false
	if t.unit_id == "bruno":
		battle.hint(tr("布鲁诺入队了。他的船，就是去圣都的路"))


func talks() -> Array:
	return [["tia", "kain", "tia_kain_ch12"], ["nina", "mira", "nina_mira"]]


func talk_lines(key: String) -> Array:
	if key == "tia_kain_ch12":
		return [
			_l("凯因", C_KAIN, "缇娅。那天晚上，我说「杀出去」……要是真冲了，大家都得死在那儿。"),
			_l("缇娅", C_TIA, "所以我才让大家分头跑。"),
			_l("凯因", C_KAIN, "嗯。你做得对。……可我这几个月，天天梦见那辆笼车。"),
			_l("缇娅", C_TIA, "我已经出来了。……凯因，下次我被关起来，你还会来吗？"),
			_l("凯因", C_KAIN, "不会有下次。下次，我站在笼子前面。"),
		]
	return [
		_l("妮娜", C_NINA, "你的枪握得很低。在沼泽里长大的？"),
		_l("米拉", C_MIRA, "雾沼村。你呢？弓拉得这么稳，是猎户家的吧。"),
		_l("妮娜", C_NINA, "山脚下的猎户。……我爹被佣兵杀了。那些佣兵，后来查出来是教会雇的。"),
		_l("米拉", C_MIRA, "我们村子，也是被教会雇的强盗烧的。"),
		_l("妮娜", C_NINA, "……那我们找的，是同一伙人。"),
		_l("米拉", C_MIRA, "嗯。到时候，你射第一箭，我刺第一枪。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	var tia = battle.get_unit("tia")
	if tia != null and not tia.is_alive():
		await battle.play_dialogue([
			_l("缇娅", C_TIA, "大家……好不容易……又见面了……"),
			_l("", C_NARR, "银湾港的潮水，涨了又退。"),
		])
		return
	await battle.play_dialogue([
		_l("艾德里克", C_EDRIC, "船……就在眼前了……父亲……"),
		_l("", C_NARR, "银湾港的潮水，涨了又退。"),
	])


# ==================== 台词 ====================

## 凯因 / 妮娜不出场时的交代：阵亡的缺席，转幕后的在旅店养伤
func _absent_lines() -> Array:
	var lines: Array = []
	var ks := Campaign.status_of("kain")
	if ks == "retired":
		lines.append(_l("缇娅", C_TIA, "凯因的伤还没好，在港口的旅店养伤。……今天，他来不了。"))
	elif ks == "dead":
		lines.append(_l("缇娅", C_TIA, "……要是凯因还在，他一定第一个冲进港口。"))
	var ns := Campaign.status_of("nina")
	if ns == "retired":
		lines.append(_l("缇娅", C_TIA, "妮娜在港口的旅店养伤，托人捎了话：「别管我，先把船弄到手。」"))
	elif ns == "dead":
		lines.append(_l("缇娅", C_TIA, "妮娜的弓……我还留着。今天，替她看着这片海。"))
	return lines


func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "银湾港。王国东岸最大的港口，从这里坐船，三天就能到圣都的水门。"),
		_l("", C_NARR, "可港口里到处是教会兵，挨家挨户在搜「巫女的同党」。"),
		_l("卡尔顿", C_BOSS, "所有船只一律扣下！没有港务所的许可，一条舢板也不许出海！"),
	]
	var kain = battle.get_unit("kain")
	var nina = battle.get_unit("nina")
	if kain != null:
		lines.append(_l("凯因", C_KAIN, "（东北边的小巷）啧……追了三条街了，教会的人还真是不嫌累。"))
	if nina != null:
		lines.append(_l("妮娜", C_NINA, "（西南边的沙滩）箭……只剩最后几支了……"))
	if kain != null or nina != null:
		lines.append(_l("缇娅", C_TIA, "那个声音……！是大家！他们还活着！"))
		lines.append(_l("缇娅", C_TIA, "艾德里克，我去接他们。……我走到他们身边，他们就会认出我。"))
	lines.append_array(_absent_lines())
	lines.append(_l("艾德里克", C_EDRIC, "去圣都要坐船。听说中间那座栈桥上，有一条走私船。"))
	if battle.get_unit("victor") != null:
		lines.append(_l("维克多", C_VICTOR, "船老大叫布鲁诺。被港务官扣着船、拿着把柄，只能替港务所卖命。"))
	lines.append(_l("艾德里克", C_EDRIC, "先救人，再借船。目标是港务所里的港务官！"))
	return lines


func _turn2_hint() -> Array:
	var lines: Array = []
	if battle.get_unit("kain") != null or battle.get_unit("nina") != null:
		lines.append(_l("缇娅", C_TIA, "凯因在东北角，妮娜在西南边的沙滩。……我得亲自过去【对话】。"))
	if battle.get_unit("kain") != null:
		lines.append(_l("艾德里克", C_EDRIC, "栈桥上那个船老大，也许你的同伴认识？"))
		lines.append(_l("缇娅", C_TIA, "布鲁诺……？凯因以前提过这个名字，是他的老酒友。让凯因去【说得】，准没错。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "栈桥上那个船老大不像坏人。……缇娅，你去跟他说说看【说得】。"))
	return lines


func _pirates() -> Array:
	return [
		_l("海盗", C_ENEMY, "港务官大人说了！抓到巫女的同党，赏金翻倍！兄弟们，上岸！"),
		_l("葛温", C_GWEN, "连海盗都请来了？这港务官跟教会穿一条裤子！"),
	]


func _kain_back() -> Array:
	return [
		_l("凯因", C_KAIN, "又来一个？……行啊，再来几个都——"),
		_l("缇娅", C_TIA, "凯因。"),
		_l("凯因", C_KAIN, "……缇娅？你、你不是被抓去圣都了吗？！"),
		_l("缇娅", C_TIA, "半路被人劫下来了。……劫车的是个领主家的少爷。"),
		_l("凯因", C_KAIN, "哈……哈哈。我还以为这辈子，得自己一个人去圣都砸笼子了。"),
		_l("凯因", C_KAIN, "剑还没卷刃。……算我一个。"),
	]


func _nina_back() -> Array:
	return [
		_l("妮娜", C_NINA, "站住！……我还有箭，别以为我——"),
		_l("缇娅", C_TIA, "妮娜！是我！"),
		_l("妮娜", C_NINA, "缇娅……？真的是你……"),
		_l("妮娜", C_NINA, "那天晚上我顺着河往东跑，一直跑到海边……每天都来码头看，有没有从圣都回来的船。"),
		_l("缇娅", C_TIA, "不用等船了。我们一起去圣都——这次是我们去砸他们的门。"),
		_l("妮娜", C_NINA, "……嗯！箭不够了，可我还有弓。走吧！"),
	]


func _bruno_by_kain() -> Array:
	return [
		_l("布鲁诺", C_BRUNO, "谁敢靠近我的船，我就劈了谁！……嗯？"),
		_l("凯因", C_KAIN, "布鲁诺，你这嗓门，隔着三条街都听得见。"),
		_l("布鲁诺", C_BRUNO, "凯因？！你小子还活着！上回欠我的酒钱，还没还呢！"),
		_l("凯因", C_KAIN, "先别提酒钱。你怎么替港务所卖命了？你不是最讨厌官府的人吗。"),
		_l("布鲁诺", C_BRUNO, "……卡尔顿扣了我的船，还抓了我两个伙计。说我不替他守码头，就把他们送去圣都「审判」。"),
		_l("凯因", C_KAIN, "那就一起把卡尔顿揍趴下。人救回来，船也拿回来。……然后，借你的船去一趟圣都。"),
		_l("布鲁诺", C_BRUNO, "去圣都？！……哈！好！老子早就想往那帮神棍的水门里开一船了！"),
	]


func _bruno_by_tia() -> Array:
	return [
		_l("布鲁诺", C_BRUNO, "红头发的丫头？……你就是他们满港口在找的「巫女」？"),
		_l("缇娅", C_TIA, "是我。你守着船，不是因为想守，对吧？你的眼睛一直在看港务所。"),
		_l("布鲁诺", C_BRUNO, "……卡尔顿扣了我的船，还抓了我两个伙计。我不替他守码头，他们就得去圣都受审。"),
		_l("缇娅", C_TIA, "那我们去把卡尔顿打倒，把你的人救出来。作为交换——借我们一条船，去圣都。"),
		_l("布鲁诺", C_BRUNO, "……丫头，你胆子比我还大。行！这买卖，我做了！"),
	]


func _bruno_fight() -> Array:
	return [
		_l("布鲁诺", C_BRUNO, "对不住了！我的伙计还在港务官手里！"),
	]


func _visit_sailor() -> Array:
	return [
		_l("老水手", C_NPC, "港务官那身铁皮，刀枪都不怎么进得去。"),
		_l("老水手", C_NPC, "这把破甲剑，是我年轻时跑船从南方带回来的。专砍铁罐头。拿去！"),
	]


func _visit_inn() -> Array:
	return [
		_l("旅店老板娘", C_NPC, "几位客官是外地来的吧？港口封了，客人都走光了。"),
		_l("旅店老板娘", C_NPC, "这些是被扣了船的商人们凑的。谁能让港口重新开张，钱就归谁。"),
	]


func _visit_locksmith() -> Array:
	return [
		_l("锁匠", C_NPC, "要去圣都？那边的牢门，用的都是我师父那一派的锁。"),
		_l("锁匠", C_NPC, "这把钥匙能开一扇。……别问我是怎么做出来的。"),
	]


func _boss() -> Array:
	return [
		_l("卡尔顿", C_BOSS, "港务官卡尔顿。……这港口里的一条船、一个人，都归港务所管。"),
		_l("艾德里克", C_EDRIC, "扣下人家的船，抓了人家的伙计，这也叫「管」？"),
		_l("卡尔顿", C_BOSS, "教会给的赏金，够我再买十条船。你们这些人的脑袋，就是赏金！"),
	]


func _boss_death() -> Array:
	return [
		_l("卡尔顿", C_BOSS, "我的……港口……我的……赏金……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "港务所的旗子降了下来。被扣的船一条条解开了缆绳。"),
	]
	var bruno = battle.get_unit("bruno")
	var bruno_in: bool = bruno != null and bruno.is_alive() and bruno.is_player()
	if bruno_in:
		lines.append(_l("布鲁诺", C_BRUNO, "伙计们都救出来了！……好，说话算话。我的船，送你们去圣都！"))
		lines.append(_l("布鲁诺", C_BRUNO, "大船进不了圣都的正港。不过下水道有个出口通到河里，我年轻时运私货走过。"))
	else:
		lines.append(_l("兰斯", C_LANCE, "港口里的船老大们说，只要付够钱，有人肯从下水道的出口把我们送进圣都。"))
	var kain = battle.get_unit("kain")
	var nina = battle.get_unit("nina")
	if kain != null and kain.is_alive() and kain.is_player():
		lines.append(_l("凯因", C_KAIN, "圣都……西里尔说过，他要去王都大书库等你。可小雀那丫头，说不定就在圣都。"))
	if nina != null and nina.is_alive() and nina.is_player():
		lines.append(_l("妮娜", C_NINA, "白垣镇那晚，小雀说过「下水道」……她最熟悉那种地方。"))
	lines.append(_l("缇娅", C_TIA, "西里尔、小雀……还有两个人没找回来。"))
	lines.append(_l("艾德里克", C_EDRIC, "还有我的父亲。……所有的线，都通向圣都。"))
	lines.append(_l("艾德里克", C_EDRIC, "出发吧。去圣都。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "harbor", "from": "riverford", "lines": [
		_l("", CB_NARR, "从白鹭渡顺着大河往东，走到了尽头，就是海。"),
		_l("", CB_NARR, "银湾港。白垣镇那一夜四散的同伴，有人往这里来了。"),
	]}


func epilogue() -> Array:
	var bruno = battle.get_unit("bruno")
	var bruno_in: bool = bruno != null and bruno.is_alive() and bruno.is_player()
	var ship: Array = [
		_l("", CB_NARR, "夜里的海上没有月亮。一条不点灯的船，贴着海岸往北驶去。"),
	]
	if bruno_in:
		ship.append(_l("布鲁诺", C_BRUNO, "前面那片黑乎乎的礁石后面，就是圣都下水道的出口。天亮前能到。"))
	else:
		ship.append(_l("", CB_NARR, "雇来的船夫一言不发，只顾着划桨。前面，是圣都下水道的出口。"))
	ship.append(_l("缇娅", C_TIA, "……一个月前，我坐着铁笼车往圣都去。现在，我自己坐船回去。"))
	ship.append(_l("艾德里克", C_EDRIC, "这一次，是去开门的。"))
	return [
		{"title": "通往圣都的海上", "mood": "night", "lines": ship},
		{"title": "圣都 · 审判所地牢", "mood": "dungeon", "lines": [
			_l("", CB_NARR, "圣都，审判所地牢。最深处的那扇铁门前，站着一个灰色的身影。"),
			_l("", CB_NARR, "它不吃饭，不睡觉，也不说话。三天三夜，一步都没有挪动过。"),
			_l("七号", CB_SEVEN, "……有人来了。"),
		]},
	]
