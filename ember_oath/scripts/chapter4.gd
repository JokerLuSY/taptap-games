class_name Chapter4
extends ChapterBase
## 第四章「圣焰审判官」：教会以「私藏火种」的异端罪名来灰岩村废墟缉拿缇娅。
## 撤离关：缇娅走到东南角的撤离点即通关；巴尔托断后重伤，章末离队（第 23 章回归）。
## 随审判官出征的见习修女诺雅（敌方治疗者）可由缇娅说得入队。审判官塞拉斯第 4 回合率骑士赶到。

const CHAPTER_TITLE := "第四章 · 圣焰审判官"
const VICTORY_TITLE := "第四章 · 完"
const VICTORY_SUB := "巴尔托留在了桥头。"
const DEFEAT_SUB := "异端的火，被押往圣都……"
const BG := ""

## 38×20。西北是灰岩村废墟（我方开局，老奶奶的地窖屋可访问），中间一条河：
## 西桥接南岸大路（教会兵沿路设卡、路边有流动商人的道具店、路南一座堡垒），中间浅滩、东桥接北岸丘陵小道（北堡上有魔道士、猎人小屋）。
## 撤离点在东南角大路尽头，三名骑士守着。审判官塞拉斯第 4 回合从西北林子追来，第 6 回合东边再来一队堵路。
const MAP := [
	"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF",
	"...CC..RCZZFFF.h............F.....F.F.",
	"..CH..WRZ.CF.hhhhh...AA..FFH......FF.F",
	".FCC......C.F.....F.....RRRRRRRR..FFF.",
	".FC...ZRRRRRRR..........R......R..FF..",
	".ZFZ......C..RF...TF....R......RF.AF..",
	".F.....R..Z..RRRRRRRRRRRRM.hhh.R....FF",
	".......RCC.F.....FFFFF..MM..h..R......",
	".......R...........F...F.M.....R.....F",
	"~~~~~~~B~~~~~~~~~~~~ww~~~~~~~~~B~~~~~~",
	".......R.........h......F....F.R....h.",
	"..ff...R.....h..hhhh...FFFF....R.h..h.",
	"..f.F..R.........h..h..........R.F..hh",
	".FFFF..R...................F...R....h.",
	"...FF..RRRRRRRRRRRRRRRRRRRRRRRRRRRR..F",
	"...F......F..VF.....T.........F...R...",
	"...........F....F........F...FFFF.R...",
	"...hF......F..F.........MMM.MFFF.FR...",
	"...h..h..FFFFF......FhF......FFF..RRRR",
	"..................F...........F......R",
]

const LEVELS := [
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"00000001000000000000110000000001000000",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
	"11111111111111111111111111111111111111",
]

const GOAL := [Vector2i(36, 18), Vector2i(37, 18), Vector2i(37, 19)]
const VISIT_GRANNY := Vector2i(3, 2)
const VISIT_HUNTER := Vector2i(27, 2)
const SHOP_VENDOR := Vector2i(13, 15)

const C_TIA := Color(1.0, 0.62, 0.45)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_HARLO := Color(0.85, 0.95, 0.6)
const C_TOBY := Color(0.95, 0.75, 0.55)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _CHURCH := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 5,
	"hp": 24, "pwr": 7, "skl": 5, "spd": 5, "dfn": 5, "mov": 5,
	"weapons": ["iron_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _KNIGHT := {"name": "圣焰骑士", "class": "骑士", "faction": "enemy", "level": 6,
	"hp": 27, "pwr": 8, "skl": 6, "spd": 6, "dfn": 7, "mov": 7,
	"weapons": ["iron_lance"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 5,
	"hp": 21, "pwr": 6, "skl": 7, "spd": 6, "dfn": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}

const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 5,
	"hp": 19, "pwr": 6, "skl": 5, "spd": 5, "dfn": 2, "res": 6, "mov": 5,
	"weapons": ["fire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}

const UNITS := [
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 5,
		"hp": 24, "pwr": 7, "skl": 8, "spd": 9, "dfn": 4, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(5, 4), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "balto", "name": "巴尔托", "class": "圣骑士", "faction": "player", "level": 8,
		"hp": 26, "pwr": 8, "skl": 9, "spd": 8, "dfn": 7, "mov": 7,
		"weapons": ["silver_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 40, "pwr": 20, "skl": 25, "spd": 25, "dfn": 20},
		"pos": Vector2i(6, 5), "color": Color(0.45, 0.55, 0.75),
		"hair": "short", "hair_color": Color(0.75, 0.75, 0.78), "armor": Color(0.70, 0.73, 0.82)},
	{"id": "harlo", "pos": Vector2i(4, 5), "name": "哈洛", "class": "战士", "faction": "player", "level": 3,
		"hp": 25, "pwr": 8, "skl": 4, "spd": 5, "dfn": 4, "mov": 5, "weapons": ["iron_axe"],
		"growths": {"hp": 85, "pwr": 55, "skl": 35, "spd": 40, "dfn": 30}},
	{"id": "nina", "pos": Vector2i(4, 4), "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 3,
		"hp": 19, "pwr": 5, "skl": 8, "spd": 7, "dfn": 2, "mov": 5, "weapons": ["iron_bow"],
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15}},
	{"id": "kain", "pos": Vector2i(6, 3), "name": "凯因", "class": "佣兵", "faction": "player", "level": 4,
		"hp": 23, "pwr": 6, "skl": 9, "spd": 10, "dfn": 3, "mov": 5, "weapons": ["iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25}},
	# 敌方
	# 村口追进来的
	{"id": "church2", "pos": Vector2i(11, 3)},
	{"id": "church7", "pos": Vector2i(10, 7)},
	# 南岸大路上的关卡
	{"id": "church3", "pos": Vector2i(9, 12)},
	{"id": "church4", "pos": Vector2i(4, 12)},
	{"id": "archer2", "pos": Vector2i(14, 12)},
	{"id": "church5", "pos": Vector2i(19, 14)},
	{"id": "mage2", "pos": Vector2i(20, 15)},
	{"id": "archer4", "pos": Vector2i(25, 16)},
	{"id": "church9", "pos": Vector2i(28, 13)},
	# 北岸小道
	{"id": "archer1", "pos": Vector2i(15, 2)},
	{"id": "church6", "pos": Vector2i(23, 6)},
	{"id": "church8", "pos": Vector2i(25, 2), "hold": true},
	{"id": "archer3", "pos": Vector2i(28, 7)},
	# 撤离点前守着的骑士
	{"id": "knight1", "pos": Vector2i(33, 16), "hold": true},
	{"id": "knight2", "pos": Vector2i(35, 15), "hold": true},
	{"id": "knight3", "pos": Vector2i(32, 18), "hold": true},
	# 教会魔道士：火焰打魔防，守备高的骑士也挡不住
	{"id": "mage1", "pos": Vector2i(18, 5)},
	# 诺雅：随军的见习修女，给教会兵治疗；缇娅可说得
	{"id": "noya", "name": "诺雅", "class": "修女", "faction": "enemy", "level": 2,
		"hp": 16, "pwr": 3, "skl": 4, "spd": 6, "dfn": 1, "mov": 5,
		"weapons": ["heal_staff"], "items": ["vulnerary"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15},
		"pos": Vector2i(20, 7), "color": Color(0.92, 0.90, 0.84),
		"hair": "hood", "hair_color": Color(0.78, 0.66, 0.40), "armor": Color(0.90, 0.88, 0.82)},
]

## 第 4 回合：审判官塞拉斯率骑士从西北赶到
const REINFORCEMENTS := [
	{"id": "silas", "name": "塞拉斯", "class": "圣焰审判官", "faction": "enemy", "level": 10,
		"hp": 38, "pwr": 12, "skl": 11, "spd": 10, "dfn": 10, "mov": 5,
		"weapons": ["silver_lance"], "boss": true,
		"pos": Vector2i(0, 2), "color": Color(0.92, 0.90, 0.95),
		"hair": "short", "hair_color": Color(0.85, 0.80, 0.60), "armor": Color(0.95, 0.92, 0.85)},
	{"id": "knight_r1", "pos": Vector2i(1, 1)},
	{"id": "knight_r2", "pos": Vector2i(0, 3)},
]


func chapter_id() -> String:
	return "ch4"


## 出击准备：选人 + 布阵 + 物品 + 商店
func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 5


func extra_deploy_slots() -> Array:
	return [Vector2i(5, 5), Vector2i(7, 4), Vector2i(5, 3)]


func templates() -> Dictionary:
	return {"church": _CHURCH, "knight": _KNIGHT, "archer": _ARCHER, "mage": _MAGE}


## 第 6 回合：东边又来一队教会兵堵撤离的路
const LATE_WAVE := [
	{"id": "church_r1", "pos": Vector2i(37, 13)},
	{"id": "church_r2", "pos": Vector2i(37, 14)},
]


## 流动商人：路边的道具店
func shops() -> Dictionary:
	return {SHOP_VENDOR: ["vulnerary", "elixir", "javelin", "hand_axe"]}


func extra_slots() -> Array:
	return [Vector2i(7, 5), Vector2i(3, 4), Vector2i(7, 3), Vector2i(5, 6)]


func goal_tiles() -> Array:
	return GOAL


## 巴尔托断后重伤：第 5 章起留在村里养伤
func after_victory_status() -> Dictionary:
	return {"balto": "away"}


## 缇娅踏上撤离点即通关（敌人全灭也算）
func is_won() -> bool:
	var tia = battle.get_unit("tia")
	if tia != null and tia.is_alive() and tia.grid_pos in GOAL:
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("缇娅抵达东南角的撤离点")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if t == 2 and not flags.get("noya_hint", false):
		flags["noya_hint"] = true
		await battle.play_dialogue(_turn2_noya())
	elif t == 4 and not flags.get("silas", false):
		flags["silas"] = true
		battle.spawn_units(REINFORCEMENTS)
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("审判官来袭！"), Color(1.0, 0.85, 0.5))
		await battle.play_dialogue(_turn3_silas())
	elif t == 6 and not flags.get("late_wave", false):
		flags["late_wave"] = true
		battle.spawn_units(LATE_WAVE)
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))


func on_before_combat(att, def) -> void:
	if "silas" in [att.unit_id, def.unit_id] and not flags.get("silas_met", false):
		flags["silas_met"] = true
		var other = def if att.unit_id == "silas" else att
		if other.unit_id == "balto":
			await battle.play_dialogue(_silas_balto())
		else:
			await battle.play_dialogue(_silas_met())


## 塞拉斯不会死在这里：HP 归零时撤退（第 24 章他还要出场）
func on_after_combat(att, def, _def_died: bool) -> void:
	for u in [att, def]:
		if u.unit_id == "silas" and not u.is_alive() and not flags.get("silas_retreat", false):
			flags["silas_retreat"] = true
			await battle.play_dialogue(_silas_retreat())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_GRANNY:
		await battle.play_dialogue(_visit_granny())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))
	elif pos == VISIT_HUNTER:
		await battle.play_dialogue(_visit_hunter())
		u.receive("steel_bow")
		battle.notify(tr("获得 钢弓"))


func talks() -> Array:
	return [["nina", "kain", "nina_kain"], ["tia", "balto", "tia_balto_ch4"]]


func talk_lines(key: String) -> Array:
	if key == "nina_kain":
		return [
			_l("妮娜", C_NINA, "你也是黑烬的人。我爹……就是被穿你那身衣服的人杀的。"),
			_l("凯因", C_KAIN, "……我知道。我不会求你原谅。"),
			_l("凯因", C_KAIN, "但杀你父亲的人，我会帮你找出来。我欠这一身衣服一个交代。"),
			_l("妮娜", C_NINA, "……那你最好别死在我前面。"),
		]
	return [
		_l("缇娅", C_TIA, "巴尔托，「私藏火种」是什么意思？我从来没碰过火种。"),
		_l("巴尔托", C_BALTO, "教会眼里，火种不是一盏灯。……是你。"),
		_l("缇娅", C_TIA, "我？"),
		_l("巴尔托", C_BALTO, "先活着出去。剩下的，老夫以后慢慢说。"),
	]


func recruits() -> Dictionary:
	return {"noya": ["tia"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return [
		_l("诺雅", C_NOYA, "别过来……审判官大人说，你是异端，是会烧掉一切的火。"),
		_l("缇娅", C_TIA, "我烧的是放火的人。你看看那边——是谁在烧村子？"),
		_l("诺雅", C_NOYA, "……刚才，他们要把一整间屋子连人一起烧掉。里面还有孩子。"),
		_l("诺雅", C_NOYA, "圣典上说，圣焰是用来照亮的，不是用来烧人的……"),
		_l("缇娅", C_TIA, "跟我们走吧。你的手是用来治人的。"),
		_l("诺雅", C_NOYA, "……嗯。我叫诺雅。圣焰在上，请原谅我。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	var tia = battle.get_unit("tia")
	if tia == null or not tia.is_alive():
		await battle.play_dialogue(_defeat_tia())
	else:
		await battle.play_dialogue(_defeat_balto())


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "第三天夜里。缇娅一行回到灰岩村的废墟，想替死去的人收殓。"),
		_l("", C_NARR, "村口亮起了一排白色的火把。"),
		_l("圣焰教会兵", C_ENEMY, "圣焰教会奉审判官之命，缉拿异端！红发的女人，出来！"),
		_l("缇娅", C_TIA, "异端？我做了什么？"),
		_l("巴尔托", C_BALTO, "……教会的狗，来得真快。"),
		_l("巴尔托", C_BALTO, "缇娅，带大家往东南走。过了河就是去王都的大路。老夫断后。"),
		_l("缇娅", C_TIA, "要走一起走！"),
		_l("巴尔托", C_BALTO, "听话！……你走到东南角的大路上，我们就一起撤。"),
	]
	if battle.get_unit("kain") != null:
		lines.append(_l("凯因", C_KAIN, "教会的白袍……和那封密信上的火漆一样。原来出钱的是他们。"))
	return lines


func _turn2_noya() -> Array:
	return [
		_l("妮娜", C_NINA, "那个穿白衣服的女孩子在给他们治伤！不先解决她，打不完的。"),
		_l("巴尔托", C_BALTO, "她手里只有杖，不会还手。……缇娅，去跟她说说话。"),
	]


func _turn3_silas() -> Array:
	return [
		_l("", C_NARR, "西北的林子里，又一队骑士冲了出来。领头的人披着白色的长袍。"),
		_l("塞拉斯", C_BOSS, "圣焰教会审判官塞拉斯。异端缇娅，以「私藏火种」之罪，随我回圣都受审。"),
		_l("巴尔托", C_BALTO, "塞拉斯……二十年了，教会的鼻子还是这么灵。"),
		_l("塞拉斯", C_BOSS, "退役的老骑士巴尔托。你把她藏了十七年。"),
		_l("巴尔托", C_BALTO, "缇娅，快走！别回头！"),
	]


func _silas_met() -> Array:
	return [
		_l("塞拉斯", C_BOSS, "抵抗只会加重你的罪。"),
	]


func _silas_balto() -> Array:
	return [
		_l("塞拉斯", C_BOSS, "让开，老骑士。你拦不住圣焰。"),
		_l("巴尔托", C_BALTO, "老夫拦得住你，就够了。"),
	]


func _silas_retreat() -> Array:
	return [
		_l("塞拉斯", C_BOSS, "……今天到此为止。异端，圣焰不会放过你。"),
		_l("", C_NARR, "塞拉斯捂着伤口退进了林子。"),
	]


func _visit_granny() -> Array:
	return [
		_l("老奶奶", C_NPC, "缇娅……你还活着。老婆子我躲在地窖里，捡回一条命。"),
		_l("老奶奶", C_NPC, "这是最后一瓶伤药了。快走，那些白袍子比山贼还狠。"),
	]


func _visit_hunter() -> Array:
	return [
		_l("猎人", C_NPC, "嘘——白袍子刚从这儿过去。……你是巴尔托家的丫头？"),
		_l("猎人", C_NPC, "这张钢弓我用不上了，拿去。过了浅滩往南，就是去王都的大路。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "缇娅冲上了东南的大路。回头望去，巴尔托的白马还停在桥头。"),
		_l("巴尔托", C_BALTO, "（咳）……走吧，孩子。老骨头还拦得住几个。"),
		_l("缇娅", C_TIA, "巴尔托——！"),
		_l("", C_NARR, "黎明时，追兵退了。大家在桥下找到了巴尔托。他还活着，但伤得很重。"),
		_l("缇娅", C_TIA, "……都是因为我。"),
		_l("巴尔托", C_BALTO, "傻丫头。错的是那些想要你的火的人。"),
	]
	if battle.get_unit("noya") != null and battle.get_unit("noya").is_player():
		lines.append(_l("诺雅", C_NOYA, "让我看看伤口……还好，没伤到要害。可是三个月之内，他不能再骑马了。"))
	lines.append(_l("巴尔托", C_BALTO, "（……这一刀，换她走出这座村子。值了。）"))
	return lines


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "巴尔托……我走不动了……"),
		_l("", C_NARR, "缇娅倒下了。白袍骑士把她押上了去圣都的囚车。"),
	]


func _defeat_balto() -> Array:
	return [
		_l("巴尔托", C_BALTO, "缇娅……别回头……"),
		_l("", C_NARR, "巴尔托倒在桥头。再没有人挡在缇娅和圣焰之间。"),
	]
