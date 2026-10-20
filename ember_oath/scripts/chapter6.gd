class_name Chapter6
extends ChapterBase
## 第六章「私藏的火种」：南下翻山，在雪夜的山间旅店撞见教会追捕私藏火种的流浪法师西里尔。
## 西里尔开场就在我方（客串式加入）：护住他、击败教会督察奥古斯特即通关，章末正式入队。
## 败北：缇娅或西里尔阵亡。

const CHAPTER_TITLE := "第六章 · 私藏的火种"
const VICTORY_TITLE := "第六章 · 完"
const VICTORY_SUB := "雪停了。队伍里多了一本烧焦了边的书。"
const DEFEAT_SUB := "雪把山路埋住了，也把那团火种埋住了……"
const BG := ""
const THEME := "snow"

## 34×22，三层台地（山脚 1、半山腰 2、山口 3，往上爬每层多花 2 点移动力）。
## 我方从半山腰的盘山路口出发（身后的山脚小村有铁匠铺和杂货铺，可以回头去买）；石墙围着的山间旅店里困着西里尔（西门、北门、东门）；
## 东边是结冰的山湖，东侧山道会上来增援；最北的山口堡垒上守着教会督察奥古斯特。西北有猎人木屋。
const MAP := [
	"MMMMMMMMMMMMMMMMMM...MMMMMMMMMMMMM",
	".M.MMMMMMMM..F.....R......MMMMMMF.",
	"M.MMMMMMMMM.M..hA.FTF.AhMMMMM..MMM",
	".MMMMMMMMMMM..hh...R..hhMMMMM.MMMF",
	"......M.F..........R...h.F..M.....",
	"....F...FFF........R.....FF....FF.",
	"...F...FFFFF..#####G#####.FFF.....",
	"...H.....F....#.W...DDDH#.F.......",
	".............F#.........#..~~~~~~.",
	"..F.F......RRRR.........GR~~~~~~~.",
	"FF.FFFF....R..#ff......D#R~~~~~~~~",
	".FFFFF.....R..###########R.~~~~~~.",
	".F.F..h....R.F...........R.~~~~~~.",
	"....hhhhh..R..........h..R..~~~.F.",
	"......h....R.........h...R...F....",
	".......F.F.R.........hh..R........",
	"...........R......F..hFF.RRRRRRRRR",
	"..h..DV..F.R....h........R......F.",
	"...RRRRRRRRRRRRRRRRRRRRRRR.FFFF...",
	"...R.h..YD......F..........FFFF...",
	"...R...D.h...FFFFF.F.......F.FFF..",
	"...R.........................F....",
]

const LEVELS := [
	"3333333333333333333333333333333333",
	"3333333333333333333333333333333333",
	"3333333333333333333333333333333333",
	"3333333333333333333333333333333333",
	"3333333333333333333333333333333333",
	"2222222222222222222222222222222222",
	"2222222222222222222222222222222222",
	"2222222222222222222222222222222222",
	"2222222222222222222222222220000002",
	"2222222222222222222222222200000002",
	"2222222222222222222222222200000000",
	"2222222222222222222222222220000002",
	"2222222222222222222222222220000002",
	"2222222222222222222222222222000222",
	"2222222222222222222222222222222222",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
]

const VISIT_INN := Vector2i(23, 7)
const VISIT_HUNTER := Vector2i(3, 7)
const SHOP_ARMORY := Vector2i(8, 19)
const SHOP_VENDOR := Vector2i(6, 17)

const C_TIA := Color(1.0, 0.62, 0.45)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_CYRIL := Color(1.0, 0.72, 0.42)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _CHURCH := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 6,
	"hp": 25, "pwr": 8, "skl": 6, "spd": 6, "dfn": 6, "mov": 5,
	"weapons": ["iron_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _KNIGHT := {"name": "圣焰骑士", "class": "骑士", "faction": "enemy", "level": 7,
	"hp": 28, "pwr": 9, "skl": 6, "spd": 6, "dfn": 8, "mov": 7,
	"weapons": ["iron_lance"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 6,
	"hp": 22, "pwr": 7, "skl": 7, "spd": 6, "dfn": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 6,
	"hp": 20, "pwr": 7, "skl": 6, "spd": 5, "dfn": 2, "res": 7, "mov": 5,
	"weapons": ["fire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}

const UNITS := [
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 9,
		"hp": 28, "pwr": 9, "skl": 11, "spd": 12, "dfn": 6, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(11, 13), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "nina", "pos": Vector2i(10, 13), "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 5,
		"hp": 21, "pwr": 7, "skl": 10, "spd": 9, "dfn": 3, "mov": 5, "weapons": ["iron_bow"],
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15}},
	{"id": "kain", "pos": Vector2i(12, 13), "name": "凯因", "class": "佣兵", "faction": "player", "level": 6,
		"hp": 26, "pwr": 8, "skl": 11, "spd": 12, "dfn": 5, "mov": 5, "weapons": ["iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25}},
	{"id": "noya", "pos": Vector2i(11, 14), "name": "诺雅", "class": "修女", "faction": "player", "level": 4,
		"hp": 18, "pwr": 5, "skl": 5, "spd": 8, "dfn": 1, "mov": 5, "weapons": ["heal_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15}},
	# 西里尔：被困在旅店院里的流浪法师。开场就归我方指挥，倒下即败北，章末正式入队
	{"id": "cyril", "name": "西里尔", "class": "魔道士", "faction": "player", "level": 6, "join": true,
		"hp": 23, "pwr": 7, "skl": 7, "spd": 7, "dfn": 3, "res": 7, "mov": 5,
		"weapons": ["fire"], "items": ["vulnerary"],
		"growths": {"hp": 50, "pwr": 55, "skl": 45, "spd": 50, "dfn": 15, "res": 45},
		"pos": Vector2i(17, 9), "color": Color(0.55, 0.35, 0.25),
		"hair": "short", "hair_color": Color(0.30, 0.34, 0.48), "armor": Color(0.50, 0.38, 0.26)},
	# 敌方：山脚、半山腰西坡、旅店北门外、山口、东侧山道
	{"id": "church4", "pos": Vector2i(10, 20)},
	{"id": "archer2", "pos": Vector2i(14, 17)},
	{"id": "church5", "pos": Vector2i(20, 18)},
	{"id": "church3", "pos": Vector2i(9, 11)},
	{"id": "mage2", "pos": Vector2i(7, 9), "hold": true},
	{"id": "church1", "pos": Vector2i(19, 5)},
	{"id": "church2", "pos": Vector2i(21, 4)},
	{"id": "mage1", "pos": Vector2i(22, 5)},
	{"id": "church6", "pos": Vector2i(8, 9)},
	{"id": "archer1", "pos": Vector2i(15, 3), "hold": true},
	{"id": "archer3", "pos": Vector2i(25, 5), "hold": true},
	{"id": "church7", "pos": Vector2i(18, 3), "hold": true},
	{"id": "church8", "pos": Vector2i(20, 3), "hold": true},
	{"id": "knight1", "pos": Vector2i(30, 16)},
	{"id": "knight2", "pos": Vector2i(32, 17)},
	# 教会督察奥古斯特：重甲，守在山口内侧的堡垒上不动
	{"id": "august", "name": "奥古斯特", "class": "重甲兵", "faction": "enemy", "level": 9,
		"hp": 32, "pwr": 10, "skl": 6, "spd": 3, "dfn": 12, "res": 3, "mov": 4,
		"weapons": ["steel_lance"], "items": ["vulnerary"], "boss": true, "stationary": true,
		"pos": Vector2i(19, 2), "color": Color(0.74, 0.70, 0.64),
		"hair": "short", "hair_color": Color(0.36, 0.30, 0.24), "armor": Color(0.70, 0.68, 0.64)},
]

## 增援：第 3 回合从山口下来，第 5 回合沿东侧山道上来
const WAVES := {
	3: [{"id": "church_r1", "pos": Vector2i(18, 0)}, {"id": "archer_r1", "pos": Vector2i(20, 0)}],
	5: [{"id": "knight_r1", "pos": Vector2i(33, 16)}, {"id": "church_r2", "pos": Vector2i(33, 15)}],
}


func chapter_id() -> String:
	return "ch6"


## 出击准备：选人 + 布阵 + 物品 + 商店
func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 5


func extra_deploy_slots() -> Array:
	return [Vector2i(10, 14), Vector2i(12, 14), Vector2i(12, 12)]


## 山脚小村的铁匠铺、杂货铺
func shops() -> Dictionary:
	return {SHOP_ARMORY: ["iron_sword", "steel_sword", "iron_lance", "iron_bow", "steel_bow", "fire", "thunder"],
		SHOP_VENDOR: ["vulnerary", "elixir", "heal_staff"]}


func templates() -> Dictionary:
	return {"church": _CHURCH, "knight": _KNIGHT, "archer": _ARCHER, "mage": _MAGE}


func lose_ids() -> Array:
	return ["tia", "cyril"]


func extra_slots() -> Array:
	return [Vector2i(10, 14), Vector2i(12, 14), Vector2i(12, 12), Vector2i(10, 12)]


func shop_items() -> Array:
	return ["vulnerary", "iron_sword", "steel_sword", "iron_lance", "iron_bow", "steel_bow", "fire", "thunder", "heal_staff"]


func is_won() -> bool:
	var a = battle.get_unit("august")
	if a != null and not a.is_alive():
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("击败教会督察奥古斯特")


func lose_condition() -> String:
	return tr("缇娅或西里尔阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


func on_before_combat(att, def) -> void:
	if "august" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "august" else att
		await battle.play_dialogue(_boss_cyril() if other.unit_id == "cyril" else _boss())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "august" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_INN:
		await battle.play_dialogue(_visit_inn())
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))
	elif pos == VISIT_HUNTER:
		await battle.play_dialogue(_visit_hunter())
		u.receive("thunder")
		battle.notify(tr("获得 雷霆"))


func talks() -> Array:
	return [["tia", "cyril", "tia_cyril"], ["noya", "cyril", "noya_cyril"]]


func talk_lines(key: String) -> Array:
	if key == "tia_cyril":
		return [
			_l("西里尔", C_CYRIL, "……你。你身上有火的味道。"),
			_l("缇娅", C_TIA, "火的味道？"),
			_l("西里尔", C_CYRIL, "不是火种。火种是装在书里、灯里的。你身上的……是火本身。"),
			_l("缇娅", C_TIA, "……你知道些什么？"),
			_l("西里尔", C_CYRIL, "我读过教会烧剩下的旧文献。上面说，八百年前那场大火里，巫女是最后一个走进火里的人。"),
			_l("西里尔", C_CYRIL, "可教典上写的是「巫女纵火焚世」。……同一件事，两种写法。我想知道哪一种是真的。"),
			_l("缇娅", C_TIA, "……等打完了，你得把这些都讲给我听。"),
		]
	return [
		_l("诺雅", C_NOYA, "你……一直带着那本火之书吗？教会说，私藏火种的人会把火带进千家万户。"),
		_l("西里尔", C_CYRIL, "修女小姐，冬天的山里，哪家的炉子里没有火？"),
		_l("诺雅", C_NOYA, "那、那不一样……"),
		_l("西里尔", C_CYRIL, "是不一样。炉子里的火是教会准许的，书里的火是教会没准许的。火本身，可从来没问过谁准不准。"),
		_l("诺雅", C_NOYA, "……这话，审判官大人听见了会生气的。"),
		_l("西里尔", C_CYRIL, "（笑）所以我只说给你听。"),
	]


func on_talked(key: String, _u, _partner) -> void:
	if key == "tia_cyril":
		var c = battle.get_unit("cyril")
		if c != null:
			c.receive("vulnerary")
			battle.notify(tr("西里尔 获得 伤药"))


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	var tia = battle.get_unit("tia")
	if tia == null or not tia.is_alive():
		await battle.play_dialogue(_defeat_tia())
	else:
		await battle.play_dialogue(_defeat_cyril())


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "渡过大河后的第五天。往王都去的山路上，下起了雪。"),
		_l("", C_NARR, "天黑前，一行人望见了山口下的旅店。院墙里亮着灯，院门外却插满了白色的火把。"),
		_l("圣焰教会兵", C_ENEMY, "私藏火种的西里尔！旅店已经被围住了，出来受审！"),
		_l("西里尔", C_CYRIL, "受审？上回你们审的那个老学者，审完就只剩一把灰了。"),
		_l("奥古斯特", C_BOSS, "教会督察奥古斯特在此。火种只属于圣焰，私藏者与异端同罪——给我把院子烧了。"),
		_l("妮娜", C_NINA, "又是教会。……他们要烧的那个人，是什么人？"),
		_l("诺雅", C_NOYA, "私藏火种的人……教会说，是会把火带给不该拿火的人。"),
		_l("缇娅", C_TIA, "被教会追着跑、因为火被定罪……这不就是我吗。"),
	]
	if battle.get_unit("kain") != null:
		lines.append(_l("凯因", C_KAIN, "要插手？那个督察身上是全副重甲，剑砍上去跟砍铁砧差不多。"))
		lines.append(_l("缇娅", C_TIA, "那就让会用火的人去对付他。……先冲进院子，把那个人护住！"))
	else:
		lines.append(_l("缇娅", C_TIA, "先冲进院子，把那个人护住！"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("西里尔", C_CYRIL, "……你们是谁？不像教会的人。"),
		_l("缇娅", C_TIA, "路过的。也被教会追着。你别乱跑，我们过去接你！"),
		_l("西里尔", C_CYRIL, "那就听好：山口上那个铁罐子，剑和枪都不好使，得用魔法烧他。"),
		_l("诺雅", C_NOYA, "店主还在主屋门口……站到门口那一格【访问】，问问他有没有事。"),
	]


func _boss() -> Array:
	return [
		_l("奥古斯特", C_BOSS, "红发……剑上有火光。审判官大人在找的人，竟然自己送上门来了。"),
		_l("缇娅", C_TIA, "你们找我做什么？"),
		_l("奥古斯特", C_BOSS, "那是审判官大人的事。我的事，是把你和那个火种贩子一起绑回去。"),
	]


func _boss_cyril() -> Array:
	return [
		_l("奥古斯特", C_BOSS, "西里尔。你偷藏的那些书，教会会一页一页替你烧干净。"),
		_l("西里尔", C_CYRIL, "烧书的人我见多了。……可书里写过的东西，你烧不掉。"),
	]


func _boss_death() -> Array:
	return [
		_l("奥古斯特", C_BOSS, "火……竟然能烧穿圣焰的铠甲……审判官大人……会亲自来的……"),
	]


func _visit_inn() -> Array:
	return [
		_l("店主", C_NPC, "外面打成这样……你们是来救西里尔先生的？"),
		_l("店主", C_NPC, "他在我这儿住了一冬，夜里替村里孩子点灯讲故事，从没害过谁。这瓶万灵药，你们拿去。"),
	]


func _visit_hunter() -> Array:
	return [
		_l("猎人", C_NPC, "教会的人上山了？……这本书，是那位法师先生换我一冬柴火的。"),
		_l("猎人", C_NPC, "我又不会念，还是还给会用的人吧。听说念对了，天上会落雷。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "督察倒下后，教会兵退回了山口。雪还在下，旅店院里的灯没灭。"),
		_l("西里尔", C_CYRIL, "……谢了。我叫西里尔，一个到处找旧书的穷法师。"),
		_l("缇娅", C_TIA, "我叫缇娅。教会说我是异端。"),
		_l("西里尔", C_CYRIL, "巧了，教会也这么说我。……你们要去王都？"),
		_l("缇娅", C_TIA, "嗯。去找出是谁想要我的火，为什么。"),
		_l("西里尔", C_CYRIL, "王都的大书库里，压着教会八百年来不让人看的书。我想去看，可一个人去就是送死。"),
		_l("西里尔", C_CYRIL, "带上我吧。我替你们烧铁罐子，你们替我挡长枪。"),
	]
	if battle.get_unit("noya") != null and battle.get_unit("noya").is_player():
		lines.append(_l("诺雅", C_NOYA, "……教会的人，好像越来越多了。"))
	lines.append(_l("", C_NARR, "第二天一早，雪停了。一行人翻过山口，王都只剩几天的路程。"))
	return lines


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "火……怎么……这么冷……"),
		_l("", C_NARR, "缇娅倒在了雪里。白色的火把围了上来。"),
	]


func _defeat_cyril() -> Array:
	return [
		_l("西里尔", C_CYRIL, "那些书……还没……读完……"),
		_l("", C_NARR, "西里尔倒下了。他怀里那本书，被教会兵扔进了火里。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "inn", "from": "ferry", "lines": [
		_l("", CB_NARR, "渡过大河后的第五天。往王都去的山路，要翻过一道雪岭。"),
		_l("", CB_NARR, "山腰上有一家旅店，是过路人翻山前最后歇脚的地方。"),
	]}


func epilogue() -> Array:
	return [{"title": "圣都 · 大圣堂地下", "mood": "dungeon", "lines": [
		_l("", CB_NARR, "圣都，大圣堂地下。没有窗的长廊里，一排排铁笼静静立着。"),
		_l("塞拉斯", CB_SILAS, "督察奥古斯特战死。火种贩子西里尔，跟巫女走到了一起。"),
		_l("莫尔甘", CB_MORGAN, "一个读旧书的，一个拿柴斧的，一个哭鼻子的修女……她身边的人，越来越像样了。"),
		_l("塞拉斯", CB_SILAS, "……要属下再带人上山？"),
		_l("莫尔甘", CB_MORGAN, "不必。去王都，必经白垣镇。把笼子运过去，让镇子等她。"),
		_l("塞拉斯", CB_SILAS, "笼子？大人，那孩子她——"),
		_l("莫尔甘", CB_MORGAN, "塞拉斯。你在怜悯她？"),
		_l("塞拉斯", CB_SILAS, "……不敢。"),
		_l("莫尔甘", CB_MORGAN, "那就去吧。这一次，我要她活着走进圣都。"),
	]}]
