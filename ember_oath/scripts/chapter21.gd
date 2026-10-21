class_name Chapter21
extends ChapterBase
## 第二十一章「铁卫」：布罗登王城。宰相奥斯瓦尔德是莫尔甘的人，软禁了国王，打算把「地之斧」献给教会。
## 洛克（布罗登铁卫，中立）奉王命在城门外等王子回国：加雷斯【对话】他就留下入队。
## 西翼宝库锁着牢门，盗贼（或带钥匙的人）开门后能开宝箱。
## 胜利：加雷斯坐上王座（K），或击败奥斯瓦尔德。败北：艾德里克、缇娅、加雷斯任一阵亡。

const CHAPTER_TITLE := "第二十一章 · 铁卫"
const VICTORY_TITLE := "第二十一章 · 完"
const VICTORY_SUB := "布罗登的城头上，苍狼旗重新升了起来。"
const DEFEAT_SUB := "城门在身后关上，布罗登的苍狼旗再也没有升起……"
const BG := ""

## 34×26。南边城外出发 → 外城正门（洛克站在门外）→ 城下町（喷泉广场、商店、两户可访问）→ 城堡正门 →
## 前庭 → 王座间（奥斯瓦尔德坐在王座上）。西翼宝库锁着牢门（盗贼 / 钥匙开），东翼是兵营。
const MAP := [
	"##################################",
	"##QSQSSQ#SS#SSSSSSSSSS#S#ASSSSSA##",
	"##SSSSSS#SS#SISSKSSSIS#S#SSSSTSS##",
	"##SSSSSS#SS#SSSSSSSSSS#S#SSSSSSS##",
	"##SSSSSS#SS#SISSSSSSIS#S#SSSSSSS##",
	"#####O###SS#SSSSSSSSSS#S#SSSSSSS##",
	"#SSSSSSSSSS#####SS#####S###SS#####",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"#SSSSSSSSSISSSSSSSSSSSSISSSSSSSSS#",
	"################GG################",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"#SDDSSDSSSSSSSSSSSSSSSSSSSSDDSSSS#",
	"#SSSHSSSSSDDSSF....FSDDSSYSSSSSSS#",
	"#SDDSSSSSSSSSS..WW..SSSSSSSSSSDDS#",
	"#SSSSSSSVSSSSSF....FSSSSSSSSSSSSS#",
	"#SSSSSSSSSSDSSSSSSSSSSDDSSSSSHSSS#",
	"#SDDSSDDSSSSDSSSSSSSSSSSSSSDSSDDS#",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"###Z############GG################",
	"....F......T....RR....T...........",
	"...F..F.........RR....FF...F......",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	".......F..F.....RR................",
	"..ffffffFF.FF...RR.......ffffff...",
	"..ffffff.F.F....RR.......ffffff...",
	"................RR................",
]

const LEVELS := []                # 全图同一高度

const THRONE := Vector2i(16, 2)
const VISIT_SMITH := Vector2i(4, 12)
const VISIT_WIDOW := Vector2i(29, 15)
const SHOP_VENDOR := Vector2i(8, 14)
const SHOP_ARMORY := Vector2i(25, 12)
const CHESTS := {Vector2i(2, 1): "hero_crest", Vector2i(4, 1): "silver_lance", Vector2i(7, 1): "elixir"}

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(1.0, 0.8, 0.5)
const C_HAGEN := Color(0.85, 0.75, 0.6)
const C_LISS := Color(0.85, 0.95, 0.7)
const C_VERA := Color(0.95, 0.6, 0.55)
const C_ROCK := Color(0.75, 0.8, 0.9)
const C_KING := Color(0.95, 0.85, 0.6)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

## 敌兵：Lv17–20，上级 5–7。宰相的私兵、被收买的王城守军、教会派来的人
const _BRODDEN := {"name": "宰相私兵", "class": "佣兵", "faction": "enemy", "level": 18,
	"hp": 38, "pwr": 14, "skl": 14, "spd": 13, "dfn": 10, "res": 4, "mov": 5,
	"weapons": ["steel_sword"], "color": Color(0.55, 0.45, 0.40),
	"hair": "short", "hair_color": Color(0.35, 0.28, 0.20), "armor": Color(0.50, 0.42, 0.38)}
const _FIGHTER := {"name": "宰相私兵", "class": "战士", "faction": "enemy", "level": 18,
	"hp": 42, "pwr": 15, "skl": 11, "spd": 10, "dfn": 9, "res": 3, "mov": 5,
	"weapons": ["steel_axe"], "color": Color(0.55, 0.45, 0.40),
	"hair": "spiky", "hair_color": Color(0.40, 0.30, 0.20), "armor": Color(0.50, 0.42, 0.38)}
const _ARMOR := {"name": "王城重甲兵", "class": "重甲兵", "faction": "enemy", "level": 18,
	"hp": 41, "pwr": 16, "skl": 10, "spd": 5, "dfn": 19, "res": 4, "mov": 4,
	"weapons": ["steel_lance"], "color": Color(0.55, 0.58, 0.62),
	"hair": "short", "armor": Color(0.58, 0.60, 0.66)}
const _GENERAL := {"name": "王城将军", "class": "将军", "faction": "enemy", "level": 6,
	"hp": 50, "pwr": 19, "skl": 12, "spd": 8, "dfn": 21, "res": 8, "mov": 5,
	"weapons": ["steel_lance", "steel_axe"], "color": Color(0.55, 0.58, 0.62),
	"hair": "short", "armor": Color(0.62, 0.64, 0.70)}
const _KNIGHT := {"name": "宰相骑兵", "class": "骑士", "faction": "enemy", "level": 18,
	"hp": 39, "pwr": 15, "skl": 12, "spd": 11, "dfn": 14, "res": 4, "mov": 7,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.58, 0.50, 0.42),
	"hair": "short", "armor": Color(0.60, 0.54, 0.48)}
const _PALADIN := {"name": "宰相近卫", "class": "圣骑士", "faction": "enemy", "level": 6,
	"hp": 48, "pwr": 18, "skl": 15, "spd": 14, "dfn": 16, "res": 9, "mov": 8,
	"weapons": ["steel_lance", "steel_sword"], "color": Color(0.60, 0.52, 0.45),
	"hair": "short", "armor": Color(0.66, 0.58, 0.50)}
const _ARCHER := {"name": "王城弓兵", "class": "弓箭手", "faction": "enemy", "level": 18,
	"hp": 35, "pwr": 13, "skl": 14, "spd": 12, "dfn": 8, "res": 5, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.55, 0.50, 0.42),
	"hair": "hood", "armor": Color(0.52, 0.48, 0.40)}
const _SNIPER := {"name": "王城狙击手", "class": "狙击手", "faction": "enemy", "level": 5,
	"hp": 41, "pwr": 16, "skl": 18, "spd": 15, "dfn": 11, "res": 7, "mov": 6,
	"weapons": ["steel_bow", "longbow"], "color": Color(0.55, 0.50, 0.42),
	"hair": "hood", "armor": Color(0.52, 0.48, 0.40)}
const _DARKMAGE := {"name": "宰相咒术师", "class": "暗法师", "faction": "enemy", "level": 18,
	"hp": 33, "pwr": 14, "skl": 11, "spd": 10, "dfn": 6, "res": 14, "mov": 5,
	"weapons": ["flux"], "color": Color(0.40, 0.36, 0.45),
	"hair": "hood", "armor": Color(0.36, 0.32, 0.42)}
const _SAGE := {"name": "教会贤者", "class": "贤者", "faction": "enemy", "level": 6,
	"hp": 40, "pwr": 17, "skl": 15, "spd": 14, "dfn": 8, "res": 16, "mov": 6,
	"weapons": ["elfire"], "color": Color(0.94, 0.90, 0.80),
	"hair": "hood", "armor": Color(0.92, 0.88, 0.78)}
const _CLERIC := {"name": "教会修女", "class": "修女", "faction": "enemy", "level": 17,
	"hp": 29, "pwr": 12, "skl": 9, "spd": 11, "dfn": 4, "res": 15, "mov": 5,
	"weapons": ["mend_staff"], "color": Color(0.95, 0.93, 0.88),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.86)}

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 18,
		"hp": 36, "pwr": 14, "skl": 16, "spd": 16, "dfn": 11, "res": 7, "mov": 5,
		"weapons": ["rapier", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(17, 22), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 6,
		"hp": 41, "pwr": 16, "skl": 18, "spd": 19, "dfn": 11, "res": 7, "mov": 6,
		"weapons": ["ember_blade", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(15, 22), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 17,
		"hp": 42, "pwr": 17, "skl": 11, "spd": 10, "dfn": 15, "res": 5, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(16, 22), "color": Color(0.70, 0.55, 0.35),
		"hair": "spiky", "hair_color": Color(0.85, 0.65, 0.30), "armor": Color(0.55, 0.45, 0.35)},
	{"id": "hagen", "name": "哈根", "class": "战士", "faction": "player", "level": 18,
		"hp": 44, "pwr": 16, "skl": 12, "spd": 11, "dfn": 10, "res": 4, "mov": 5,
		"weapons": ["steel_axe", "hand_axe"], "wexp": {"axe": 121},
		"growths": {"hp": 80, "pwr": 50, "skl": 35, "spd": 30, "dfn": 30, "res": 10},
		"pos": Vector2i(18, 22)},
	{"id": "liss", "name": "莉丝", "class": "弓箭手", "faction": "player", "level": 17,
		"hp": 33, "pwr": 13, "skl": 17, "spd": 15, "dfn": 7, "res": 6, "mov": 5,
		"weapons": ["steel_bow", "iron_bow"], "wexp": {"bow": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30},
		"pos": Vector2i(15, 23)},
	{"id": "vera", "name": "薇拉", "class": "盗贼", "faction": "player", "level": 17,
		"hp": 33, "pwr": 12, "skl": 17, "spd": 20, "dfn": 7, "res": 6, "mov": 6,
		"weapons": ["killing_edge", "steel_sword"], "wexp": {"sword": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 60, "dfn": 20, "res": 30},
		"pos": Vector2i(18, 23)},
	{"id": "noya", "name": "诺雅", "class": "修女", "faction": "player", "level": 17,
		"hp": 29, "pwr": 12, "skl": 10, "spd": 13, "dfn": 4, "res": 16, "mov": 5,
		"weapons": ["mend_staff", "heal_staff"], "wexp": {"staff": 71},
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 55},
		"pos": Vector2i(16, 23)},
	{"id": "ivan", "name": "伊万", "class": "枪兵", "faction": "player", "level": 17,
		"hp": 38, "pwr": 15, "skl": 14, "spd": 15, "dfn": 11, "res": 4, "mov": 5,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 75, "pwr": 45, "skl": 45, "spd": 45, "dfn": 30, "res": 15},
		"pos": Vector2i(17, 23)},
	{"id": "ivy", "name": "艾薇", "class": "魔道士", "faction": "player", "level": 17,
		"hp": 30, "pwr": 15, "skl": 14, "spd": 13, "dfn": 5, "res": 14, "mov": 5,
		"weapons": ["elfire", "thunder"], "wexp": {"anima": 121},
		"growths": {"hp": 45, "pwr": 50, "skl": 45, "spd": 45, "dfn": 15, "res": 50},
		"pos": Vector2i(16, 24)},
	{"id": "oscar", "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 18,
		"hp": 42, "pwr": 15, "skl": 11, "spd": 6, "dfn": 19, "res": 4, "mov": 4,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(17, 24)},
	# 洛克：布罗登铁卫，奉王命在城门外等王子。加雷斯【对话】入队
	{"id": "rock", "name": "洛克", "class": "重甲兵", "faction": "npc", "fights": true, "level": 16, "stationary": true,
		"hp": 38, "pwr": 15, "skl": 10, "spd": 6, "dfn": 18, "res": 4, "mov": 4,
		"weapons": ["steel_lance", "javelin"], "items": ["vulnerary"], "wexp": {"lance": 121},
		"growths": {"hp": 80, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(19, 19), "color": Color(0.45, 0.48, 0.55),
		"hair": "short", "hair_color": Color(0.30, 0.25, 0.20), "armor": Color(0.50, 0.54, 0.62)},
	# 城门内：堵门的重甲
	{"id": "armor2", "pos": Vector2i(16, 17), "hold": true},
	{"id": "general1", "pos": Vector2i(17, 17), "hold": true},
	# 城下町
	{"id": "brodden1", "pos": Vector2i(10, 16)},
	{"id": "fighter1", "pos": Vector2i(22, 16), "weapons": ["steel_axe", "hand_axe"]},
	{"id": "archer1", "pos": Vector2i(13, 12), "hold": true},
	{"id": "armor1", "pos": Vector2i(16, 11), "hold": true},
	{"id": "knight1", "pos": Vector2i(6, 14), "hold": true},
	{"id": "knight2", "pos": Vector2i(27, 14), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(20, 13), "hold": true, "items": ["vulnerary"]},
	{"id": "fighter2", "pos": Vector2i(8, 11), "hold": true},
	{"id": "brodden2", "pos": Vector2i(25, 10), "hold": true, "items": ["door_key"]},
	{"id": "cleric1", "pos": Vector2i(18, 11)},
	{"id": "sniper1", "pos": Vector2i(24, 15), "hold": true},
	# 城堡前庭
	{"id": "paladin1", "pos": Vector2i(10, 8), "hold": true},
	{"id": "paladin2", "pos": Vector2i(23, 8), "hold": true, "items": ["elixir"]},
	{"id": "archer2", "pos": Vector2i(14, 7), "hold": true},
	{"id": "archer3", "pos": Vector2i(19, 7), "hold": true},
	# 王座间
	{"id": "general2", "pos": Vector2i(15, 3), "hold": true},
	{"id": "sage1", "pos": Vector2i(18, 3), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(14, 5), "hold": true, "weapons": ["nosferatu"]},
	# 东翼兵营
	{"id": "brodden3", "pos": Vector2i(26, 3), "hold": true},
	{"id": "fighter3", "pos": Vector2i(29, 4), "hold": true},
	{"id": "sniper2", "pos": Vector2i(27, 5), "hold": true},
	# 奥斯瓦尔德：宰相，坐在王座上（我方进入他的射程才离开王座）
	{"id": "oswald", "name": "奥斯瓦尔德", "class": "德鲁伊", "faction": "enemy", "level": 10,
		"hp": 48, "pwr": 19, "skl": 15, "spd": 12, "dfn": 10, "res": 18, "mov": 6,
		"weapons": ["fenrir", "nosferatu"], "items": ["sage_crest"], "boss": true, "hold": true,
		"sprite": "mage", "pos": Vector2i(16, 2), "color": Color(0.35, 0.30, 0.40),
		"hair": "hood", "armor": Color(0.40, 0.32, 0.45)},
]

## 第 4 回合西边大路追来骑兵；第 6 回合东边大路再来近卫
const WAVES := {
	4: [{"id": "knight_r1", "pos": Vector2i(0, 21)}, {"id": "knight_r2", "pos": Vector2i(0, 22)}],
	6: [{"id": "paladin_r1", "pos": Vector2i(33, 21)}, {"id": "fighter_r1", "pos": Vector2i(33, 22)}],
}

const DEPLOY := [Vector2i(14, 22), Vector2i(19, 22), Vector2i(14, 23), Vector2i(19, 23), Vector2i(15, 24),
	Vector2i(18, 24), Vector2i(14, 24), Vector2i(19, 24)]


func chapter_id() -> String:
	return "ch21"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 10


func forced_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_deploy_slots() -> Array:
	return DEPLOY


func templates() -> Dictionary:
	return {"brodden": _BRODDEN, "fighter": _FIGHTER, "armor": _ARMOR, "general": _GENERAL, "knight": _KNIGHT,
		"paladin": _PALADIN, "archer": _ARCHER, "sniper": _SNIPER, "darkmage": _DARKMAGE, "sage": _SAGE, "cleric": _CLERIC}


func lose_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_slots() -> Array:
	return DEPLOY


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "steel_lance", "steel_axe", "killer_axe", "steel_bow", "elfire", "mend_staff"]


func shops() -> Dictionary:
	return {SHOP_VENDOR: ["vulnerary", "elixir", "door_key", "mend_staff"],
		SHOP_ARMORY: ["steel_sword", "steel_lance", "steel_axe", "killer_axe", "killer_lance", "armorslayer", "steel_bow", "longbow"]}


func chests() -> Dictionary:
	return CHESTS


func goal_label() -> String:
	return "王座"


func goal_tiles() -> Array:
	return [THRONE]


func is_won() -> bool:
	if flags.get("throne_taken", false):
		return true
	var b = battle.get_unit("oswald")
	return b == null or not b.is_alive()


func win_condition() -> String:
	return tr("加雷斯坐上王座，或击败宰相奥斯瓦尔德")


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
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		if t == 4:
			await battle.play_dialogue(_wave4())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


## 加雷斯坐上王座：城里的守军认出了王子，宰相的人马军心大乱（压制胜利）
func on_action_end(u) -> void:
	if u.unit_id == "gareth" and u.is_alive() and u.grid_pos == THRONE and not flags.get("throne_taken", false):
		flags["throne_taken"] = true
		await battle.play_dialogue(_throne_taken())


func on_before_combat(att, def) -> void:
	if "oswald" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var foe = def if att.unit_id == "oswald" else att
		await battle.play_dialogue(_boss(foe.unit_id))


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("oswald")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_SMITH:
		await battle.play_dialogue(_visit_smith())
		u.receive("killer_axe")
		battle.notify(tr("获得 锐锋斧"))
	elif pos == VISIT_WIDOW:
		await battle.play_dialogue(_visit_widow())
		battle.add_gold(3000)
		battle.notify(tr("获得 3000G"))


func on_door(_u, _pos: Vector2i) -> void:
	if not flags.get("vault_told", false):
		flags["vault_told"] = true
		await battle.play_dialogue(_vault_opened())


func recruits() -> Dictionary:
	return {"rock": ["gareth"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return [
		_l("洛克", C_ROCK, "殿下。陛下的密令是：「带加雷斯离开布罗登，越远越好。」"),
		_l("加雷斯", C_GARETH, "离开？父王被关在自己的城里，你让我走？"),
		_l("洛克", C_ROCK, "陛下说，宰相背后是整个教会。殿下留下，只会白白送命。"),
		_l("加雷斯", C_GARETH, "洛克，铁卫的誓言是什么？"),
		_l("洛克", C_ROCK, "……「以身为盾，护王与国」。"),
		_l("加雷斯", C_GARETH, "那现在，王在城里，国也在城里。你的盾，该朝哪边？"),
		_l("洛克", C_ROCK, "……朝城门。殿下，铁卫洛克，听候差遣。"),
	]


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false


func talks() -> Array:
	return [["liss", "hagen", "liss_hagen"], ["gareth", "hagen", "gareth_hagen"]]


func talk_lines(key: String) -> Array:
	if key == "liss_hagen":
		return [
			_l("莉丝", C_LISS, "哈根，到家了，脸还绷着？"),
			_l("哈根", C_HAGEN, "……城头的旗。"),
			_l("莉丝", C_LISS, "看见了。苍狼旗被扯下来，换成一块白布。宰相那老狐狸，品味差得要命。"),
			_l("哈根", C_HAGEN, "……拔下来。"),
			_l("莉丝", C_LISS, "当然。等打完了，你扛旗，我射绳子。分工明确。"),
			_l("哈根", C_HAGEN, "……嗯。"),
		]
	return [
		_l("加雷斯", C_GARETH, "哈根，你跟了我多少年了？"),
		_l("哈根", C_HAGEN, "……十一年。"),
		_l("加雷斯", C_GARETH, "十一年，你说的话加起来不到一百句。"),
		_l("哈根", C_HAGEN, "……够用。"),
		_l("加雷斯", C_GARETH, "哈哈！……要是今天我倒在王座前，你就带着莉丝回北边的山里，别管什么王国了。"),
		_l("哈根", C_HAGEN, "……不行。"),
		_l("加雷斯", C_GARETH, "为什么？"),
		_l("哈根", C_HAGEN, "王子，不会倒。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	var r: Array = Campaign.flags.get("relics", [])
	if not "earth_axe" in r:
		r.append("earth_axe")
	Campaign.flags["relics"] = r
	Campaign.flags["rock_recruited"] = _here("rock")
	var b = battle.get_unit("oswald")
	Campaign.flags["oswald_fled"] = b != null and b.is_alive()


func on_defeat() -> void:
	await battle.play_dialogue(_defeat())


# ==================== 小工具 ====================

func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


func _has_thief() -> bool:
	for u in battle.units:
		if u.is_alive() and u.is_player() and u.class_label in ["盗贼", "刺客"]:
			return true
	return false


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "布罗登王城。北方的铁之国，城墙比任何地方都厚。"),
		_l("", C_NARR, "可城门紧闭，城头上飘着的，是圣焰教会的白旗。"),
		_l("加雷斯", C_GARETH, "……那是什么旗？布罗登的城头，只挂苍狼旗！"),
		_l("奥斯瓦尔德", C_BOSS, "王子殿下，欢迎回家。可惜，您是以「异端同党」的身份回来的。"),
		_l("加雷斯", C_GARETH, "奥斯瓦尔德！父王呢？"),
		_l("奥斯瓦尔德", C_BOSS, "陛下身体不适，在寝宫静养。王国的事，暂由我代劳。……地之斧，也将由教会代为保管。"),
		_l("加雷斯", C_GARETH, "你这个……！"),
		_l("艾德里克", C_EDRIC, "加雷斯，冷静。王座间在城堡最深处，要过两道城门。"),
		_l("加雷斯", C_GARETH, "那就一道一道砸开。……只要我坐上那张王座，城里的兵就知道该听谁的。"),
		_l("艾德里克", C_EDRIC, "好。加雷斯一坐上王座，这座城就是我们的——或者，直接打倒奥斯瓦尔德。"),
		_l("洛克", C_ROCK, "……王子殿下？"),
		_l("加雷斯", C_GARETH, "洛克！铁卫的洛克！你怎么在城外？"),
		_l("洛克", C_ROCK, "奉陛下密令，出城接殿下。……可城门在我身后关上了。"),
		_l("加雷斯", C_GARETH, "哈，正好。等着，铁卫——我这就过去！"),
	]
	if _has_thief():
		lines.append(_l("缇娅", C_TIA, "城堡西翼是宝库，门上了锁。……让会开锁的人去看看。"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "加雷斯，洛克还在城门边等你。走到他身边，选【对话】。"),
		_l("加雷斯", C_GARETH, "知道了！一个铁卫，顶得上半座城墙！"),
	]


func _wave4() -> Array:
	return [
		_l("奥斯瓦尔德", C_BOSS, "城外的骑兵，从背后包抄。王子殿下既然回来了，就别再让他出去。"),
	]


func _vault_opened() -> Array:
	return [
		_l("", C_NARR, "宝库的铁门吱呀一声打开了。架子上空了一大片——地之斧不在这里。"),
		_l("加雷斯", C_GARETH, "宰相把斧头挪走了？……箱子里的东西倒还在，拿上！"),
	]


func _throne_taken() -> Array:
	return [
		_l("加雷斯", C_GARETH, "布罗登的士兵们！看清楚，坐在王座上的是谁！"),
		_l("王城重甲兵", C_ENEMY, "是……是王子殿下！"),
		_l("加雷斯", C_GARETH, "苍狼旗还在你们心里吗？那就放下武器——你们效忠的是布罗登，不是宰相！"),
		_l("", C_NARR, "王城的守军一个接一个放下了枪。宰相的私兵见势不妙，四散而逃。"),
		_l("奥斯瓦尔德", C_BOSS, "……一群蠢货！"),
		_l("", C_NARR, "奥斯瓦尔德趁乱钻进了王座后的密道。"),
	]


func _boss(foe_id: String) -> Array:
	if foe_id == "gareth":
		return [
			_l("奥斯瓦尔德", C_BOSS, "殿下，您的父王老了。布罗登需要的，是一个懂得低头的王。"),
			_l("加雷斯", C_GARETH, "布罗登的王，只对子民低头。"),
		]
	return [
		_l("奥斯瓦尔德", C_BOSS, "异端的走狗，也配踏进布罗登的王座间？"),
		_l("奥斯瓦尔德", C_BOSS, "大司祭许诺过我：新的大陆，需要新的王。……挡路的，都会变成灰。"),
	]


func _boss_death() -> Array:
	return [
		_l("奥斯瓦尔德", C_BOSS, "大司祭……您许诺过的……新的王……"),
	]


func _visit_smith() -> Array:
	return [
		_l("铁匠", C_NPC, "王子回来了？好！宰相那伙人把我的炉子都封了，说铁器只许卖给教会。"),
		_l("铁匠", C_NPC, "这把斧头是给王子打的，一直没机会送。拿去，劈开那扇门！"),
	]


func _visit_widow() -> Array:
	return [
		_l("寡妇", C_NPC, "我丈夫是铁卫，上个月替国王说了一句话，就再也没回来。"),
		_l("寡妇", C_NPC, "这些钱是他攒下的。……替他把国王救出来吧。"),
	]


func _post_battle() -> Array:
	var lines: Array = []
	if flags.get("throne_taken", false) and not flags.get("boss_down", false):
		lines.append(_l("", C_NARR, "宰相逃了。王城的守军打开了寝宫的门。"))
	else:
		lines.append(_l("", C_NARR, "宰相倒下了。王城的守军打开了寝宫的门。"))
	lines.append_array([
		_l("布罗登国王", C_KING, "加雷斯。"),
		_l("加雷斯", C_GARETH, "父王！您没事——"),
		_l("布罗登国王", C_KING, "我让洛克带你走，你却带着一群人杀了回来。……和你母亲一样，从来不听话。"),
		_l("加雷斯", C_GARETH, "……对不起。"),
		_l("布罗登国王", C_KING, "不必。我指望你的，从来不是听话。"),
		_l("布罗登国王", C_KING, "宰相把地之斧藏在了我的寝宫里，说是等教会的人来取。……带走吧。布罗登守了它几百年，今天起，交给你守。"),
		_l("", C_NARR, "得到了圣器「地之斧」。"),
		_l("艾德里克", C_EDRIC, "风之弓、地之斧……剩下的，都在圣焰神殿。"),
		_l("加雷斯", C_GARETH, "星之杖、日之剑，还有教会偷走的那几件。……去神殿，一次拿个干净！"),
	])
	if _here("rock"):
		lines.append(_l("洛克", C_ROCK, "殿下去哪，铁卫就去哪。"))
	if _here("vera"):
		lines.append(_l("薇拉", C_VERA, "神殿啊。……那可是教会的心脏。这一单，够刺激。"))
	lines.append(_l("缇娅", C_TIA, "……不知道为什么，越靠近神殿，手心就越烫。"))
	return lines


func _defeat() -> Array:
	for id in ["edric", "tia", "gareth"]:
		var u = battle.get_unit(id)
		if u != null and not u.is_alive():
			if id == "edric":
				return [_l("艾德里克", C_EDRIC, "加雷斯……抱歉……我……"),
					_l("", C_NARR, "艾德里克倒下了。布罗登的城门再没有打开。")]
			if id == "tia":
				return [_l("缇娅", C_TIA, "手心……好烫……"),
					_l("", C_NARR, "缇娅倒下了。宰相把红发的少女送去了圣都。")]
			return [_l("加雷斯", C_GARETH, "父王……我……回来晚了……"),
				_l("", C_NARR, "加雷斯倒在了自己的王城里。苍狼旗再也没有升起。")]
	return []


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "brodden", "from": "peak", "lines": [
		_l("", CB_NARR, "风之弓到手。一行人往东，回到加雷斯的故乡——北方的铁之国，布罗登。"),
		_l("", CB_NARR, "八圣器之一「地之斧」，就供在王城的宝库里。"),
	]}


func epilogue() -> Array:
	var spared: bool = Campaign.flags.get("seven_16_spared", false)
	var lines: Array = [
		_l("七号", CB_SEVEN, "……他们来了。菲恩家的、布罗登的王子……还有那团火。"),
		_l("莫尔甘", CB_MORGAN, "很好。门开着，让他们进来。"),
		_l("莫尔甘", CB_MORGAN, "七号，那团火……你还记得吗？"),
		_l("七号", CB_SEVEN, "……记得。"),
	]
	if spared:
		lines.append(_l("莫尔甘", CB_MORGAN, "上次，你让她活着回去了。"))
		lines.append(_l("七号", CB_SEVEN, "……命令里，没有杀她。"))
	lines.append(_l("莫尔甘", CB_MORGAN, "那这一次的命令是：把她带到封印台前——活着。"))
	lines.append(_l("七号", CB_SEVEN, "……是。"))
	return [{"title": "圣焰神殿 · 封印之间", "mood": "church", "lines": lines}]
