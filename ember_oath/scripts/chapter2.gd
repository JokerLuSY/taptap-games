class_name Chapter2
extends ChapterBase
## 第二章「燃烧的村庄」：灰岩村被焚。缇娅体内的火焰初醒，但不转职（转职须满 Lv10，炎刃使在第 5 章）。
## 报信的村里少年哈洛拿起柴斧入队。击破放火的敌人即可通关。

const CHAPTER_TITLE := "第二章 · 燃烧的村庄"
const VICTORY_TITLE := "第二章 · 完"
const VICTORY_SUB := "灰岩村燃尽了。火，却还在缇娅剑上。"
const DEFEAT_SUB := "灰岩村葬于火海……"

## 不用手绘底图：和第一章一样走 CC0 图块（MapTiles）。
const BG := ""

## 22×14。南边麦田是进村的路，村前一条小河（两座桥、东边浅滩）；
## 河北是烧着的村子：西边水井旁、东边各一户还能访问，正北望楼（堡垒）上是放火的头目马尔科。E 不可踏。
const MAP := [
	"FFFFFhhFFF.Z.Z.FFhhhFF",
	"FF..h..F..ZCTCZ.h..hFF",
	"F..D.E...CCCRCCC...hhF",
	"..DHC.ZD..E.R.ED.D.H.F",
	"..CCE..C....R...C.CC..",
	".F...W.ZC...R..ZE..D..",
	"..RRRRRRRRRRRRRRRRRR..",
	".D.E..ZC....R..D..E.F.",
	"FF..f.ff....R.....ffFF",
	"~~~~B~~~~~~~B~~~~ww~~~",
	"ff.....E....R..F....ff",
	"fH.ff......RR..FF..E.f",
	"ffEff....RRR........ff",
	"F.ff.....R.......FF..F",
]

const LEVELS := [
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"0000100000001000011000",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
	"1111111111111111111111",
]

const C_TIA := Color(1.0, 0.62, 0.45)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_HARLO := Color(0.85, 0.95, 0.6)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _BANDIT := {"name": "山贼", "class": "山贼", "faction": "enemy", "level": 3,
	"hp": 23, "pwr": 5, "skl": 3, "spd": 4, "dfn": 2, "mov": 5,
	"weapons": ["iron_axe"], "color": Color(0.55, 0.45, 0.35),
	"hair": "spiky", "hair_color": Color(0.25, 0.18, 0.12), "armor": Color(0.50, 0.40, 0.30)}
const _ARCHER := {"name": "弓箭手", "class": "弓箭手", "faction": "enemy", "level": 3,
	"hp": 19, "pwr": 5, "skl": 5, "spd": 5, "dfn": 2, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.45, 0.55, 0.40),
	"hair": "hood", "armor": Color(0.38, 0.55, 0.38)}

## 我方三人的默认数值（名单里有存档时用存档）
const UNITS := [
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 1,
		"hp": 20, "pwr": 5, "skl": 6, "spd": 7, "dfn": 3, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(11, 12), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "balto", "name": "巴尔托", "class": "圣骑士", "faction": "player", "level": 8,
		"hp": 26, "pwr": 8, "skl": 9, "spd": 8, "dfn": 7, "mov": 7,
		"weapons": ["silver_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 40, "pwr": 20, "skl": 25, "spd": 25, "dfn": 20},
		"pos": Vector2i(12, 12), "color": Color(0.45, 0.55, 0.75),
		"hair": "short", "hair_color": Color(0.75, 0.75, 0.78), "armor": Color(0.70, 0.73, 0.82)},
	# 河南岸两个先手冲上来的；河北村里分散放火的；东北丘陵上的弓手
	{"id": "bandit7", "pos": Vector2i(6, 10)},
	{"id": "bandit8", "pos": Vector2i(17, 11)},
	{"id": "bandit1", "pos": Vector2i(4, 7)},
	{"id": "bandit2", "pos": Vector2i(16, 7)},
	{"id": "bandit3", "pos": Vector2i(8, 4)},
	{"id": "bandit5", "pos": Vector2i(18, 4)},
	{"id": "bandit4", "pos": Vector2i(2, 1), "hold": true},
	{"id": "archer1", "pos": Vector2i(19, 1)},
	{"id": "archer2", "pos": Vector2i(5, 3)},
	# 探子：可击破的普通敌人，没有说得，不挡通关。立绘暂用山贼。
	{"id": "scout1", "name": "探子", "class": "探子", "faction": "enemy", "level": 2,
		"hp": 17, "pwr": 4, "skl": 5, "spd": 7, "dfn": 2, "mov": 5,
		"weapons": ["iron_sword"], "pos": Vector2i(20, 6), "color": Color(0.40, 0.42, 0.38),
		"hair": "hood", "hair_color": Color(0.25, 0.22, 0.18), "armor": Color(0.35, 0.38, 0.32)},
	{"id": "marco", "name": "马尔科", "class": "山贼头目", "faction": "enemy", "level": 4,
		"hp": 30, "pwr": 8, "skl": 5, "spd": 4, "dfn": 5, "mov": 5,
		"weapons": ["war_axe"], "stationary": true, "boss": true,
		"pos": Vector2i(12, 1), "color": Color(0.55, 0.28, 0.18),
		"hair": "spiky", "hair_color": Color(0.18, 0.10, 0.08), "armor": Color(0.42, 0.24, 0.18), "scar": true},
]

## 哈洛：第一章报信的村里少年，开场剧情入队
const HARLO := {"id": "harlo", "name": "哈洛", "class": "战士", "faction": "player", "level": 1,
	"hp": 22, "pwr": 6, "skl": 3, "spd": 4, "dfn": 3, "mov": 5,
	"weapons": ["iron_axe"], "items": [],
	"growths": {"hp": 85, "pwr": 55, "skl": 35, "spd": 40, "dfn": 30},
	"color": Color(0.70, 0.60, 0.40), "hair": "short", "hair_color": Color(0.50, 0.32, 0.18),
	"armor": Color(0.55, 0.48, 0.35)}


## 能访问的三户：井边人家、东头铁匠铺、河南岸的农舍
const VISIT_WELL := Vector2i(3, 3)
const VISIT_SMITH := Vector2i(19, 3)
const VISIT_FARM := Vector2i(1, 11)


func chapter_id() -> String:
	return "ch2"


func templates() -> Dictionary:
	return {"bandit": _BANDIT, "archer": _ARCHER}


## 第一章说得过来的托比等人站在缇娅身后
func extra_slots() -> Array:
	return [Vector2i(11, 13), Vector2i(12, 13), Vector2i(10, 12), Vector2i(13, 12)]


# ==================== 事件 ====================

func on_battle_start() -> void:
	# 地图 BGM 已由 battle 播放（复用第一章）。这里只叠火焰 loop。
	Audio.play_loop("fire")
	await battle.play_dialogue(_pre_battle())
	if battle.get_unit("harlo") == null:
		await battle.play_dialogue(_harlo_join())
		battle.join_unit(HARLO, Vector2i(10, 13))
		var h = battle.get_unit("harlo")
		if h != null:
			h.has_acted = false
			h.queue_redraw()
	await _first_flame()


func on_before_combat(_att, def) -> void:
	if def.unit_id == "marco" and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())
	elif def.unit_id == "scout1" and not flags.get("scout", false):
		flags["scout"] = true
		await battle.play_dialogue(_scout())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "marco" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_WELL:
		await battle.play_dialogue(_visit())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))
	elif pos == VISIT_SMITH:
		await battle.play_dialogue(_visit_smith())
		u.receive("hand_axe")
		battle.notify(tr("获得 手斧"))
	elif pos == VISIT_FARM:
		await battle.play_dialogue(_visit_farm())
		battle.add_gold(500)
		battle.notify(tr("获得 500G"))


func talks() -> Array:
	return [["tia", "harlo", "tia_harlo"]]


func talk_lines(_key: String) -> Array:
	return [
		_l("哈洛", C_HARLO, "缇娅姐……我家的房子也没了。"),
		_l("缇娅", C_TIA, "……对不起。是我把他们引来的。"),
		_l("哈洛", C_HARLO, "才不是！是那些放火的混蛋！……我会变强的，像你和巴尔托先生一样。"),
		_l("缇娅", C_TIA, "那就先活下去。拿着这个，别逞强。"),
	]


func on_talked(_key: String, _u, partner) -> void:
	var harlo = partner if partner.unit_id == "harlo" else battle.get_unit("harlo")
	if harlo != null:
		harlo.receive("vulnerary")
		battle.notify(tr("哈洛 获得 伤药"))


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	var tia = battle.get_unit("tia")
	if tia == null or not tia.is_alive():
		await battle.play_dialogue(_defeat_tia())
	else:
		await battle.play_dialogue(_defeat_balto())


## 火焰初醒：只演剧情，不转职（转职须满 Lv10，见大纲「转职规则」）
func _first_flame() -> void:
	if flags.get("first_flame", false):
		return
	Audio.play_sfx("awaken")
	await battle.play_dialogue(_flame_lines())
	flags["first_flame"] = true
	battle.show_banner(tr("火焰初醒"), Color(1.0, 0.55, 0.2))


# ==================== 台词 ====================

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


func _harlo_join() -> Array:
	return [
		_l("哈洛", C_HARLO, "缇娅姐！巴尔托先生！大家都躲进林子了！"),
		_l("缇娅", C_TIA, "哈洛？你怎么又跑回来了！"),
		_l("哈洛", C_HARLO, "我……我也要打！这把柴斧我天天用，砍人……应该也行！"),
		_l("巴尔托", C_BALTO, "……斧头重，先砍准再砍狠。跟紧我们，别一个人往前冲。"),
	]


func _flame_lines() -> Array:
	return [
		_l("", C_NARR, "一团火从倒塌的屋梁上扑下来，扑上了缇娅的剑。"),
		_l("缇娅", C_TIA, "热……这热是从我自己身上来的？"),
		_l("巴尔托", C_BALTO, "缇娅！把剑放下——！"),
		_l("缇娅", C_TIA, "……没事。它没有烧我。它好像……在听我的。"),
		_l("", C_NARR, "剑上的火停了一瞬，又散去了。"),
		_l("巴尔托", C_BALTO, "（……还太早了。现在的她，还握不住这团火。）"),
	]


func _visit() -> Array:
	return [
		_l("村民", C_NPC, "缇娅！井边的人都跑了……伤药给你，求你活着！"),
		_l("缇娅", C_TIA, "先活下去。火，我来挡。"),
	]


func _visit_smith() -> Array:
	return [
		_l("铁匠", C_NPC, "缇娅？！炉子都被他们砸了……这把手斧是我最后打的，拿去！扔出去也能砍着人。"),
		_l("缇娅", C_TIA, "谢谢大叔。快往林子里躲！"),
	]


func _visit_farm() -> Array:
	return [
		_l("农妇", C_NPC, "麦子全烧了……这些钱本来是攒着买种子的。你拿去，总比被山贼抢走强。"),
		_l("缇娅", C_TIA, "……等村子盖回来，我一定加倍还你。"),
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


func _boss_death() -> Array:
	return [
		_l("马尔科", C_BOSS, "咳……黑烬的人……会替我……讨回来……"),
	]


func _post_battle() -> Array:
	return [
		_l("", C_NARR, "火势终于被压住。灰岩村只剩下焦黑的梁。"),
		_l("缇娅", C_TIA, "人是打退了……村子却没了。"),
		_l("巴尔托", C_BALTO, "你体内的火，今天醒了一下。这不是结束。"),
		_l("缇娅", C_TIA, "我知道。谁让村子烧起来，我就去找谁。"),
		_l("巴尔托", C_BALTO, "那个探子说要「回报团里」。他们往北边山道去了。"),
		_l("哈洛", C_HARLO, "北边……是黑烬佣兵团扎营的地方。我爹去山里砍柴时见过他们的旗。"),
		_l("巴尔托", C_BALTO, "……天亮就出发。"),
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
