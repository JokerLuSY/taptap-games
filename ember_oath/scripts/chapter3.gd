class_name Chapter3
extends ChapterBase
## 第三章「佣兵团的影子」：追着放火的人进了北面山道，撞见黑烬佣兵团扎营的废弃边境要塞。
## 菲恩领主之子艾德里克在追查失踪的巡逻队，被佣兵围住（客串：他倒下即败北，章末离队）。
## 猎户女儿妮娜（访问山脚小屋）、动摇的佣兵凯因（缇娅说得）入队。击败佣兵队长霍克即通关。

const CHAPTER_TITLE := "第三章 · 佣兵团的影子"
const VICTORY_TITLE := "第三章 · 完"
const VICTORY_SUB := "佣兵的密信上，盖着圣焰教会的火漆。"
const DEFEAT_SUB := "山道上的营火，烧到了天明……"
const BG := ""

## 36×22。西南山道口出发：过西桥（或中间浅滩）上北岸，沿河往东，翻过凯因守着的山口，攻进东北角黑烬佣兵团占据的废弃边境要塞
## （南门 + 西侧小门 → 前院营帐 → 内堡门 → 王座上的霍克）。西北山脚是妮娜的猎户小屋；南岸山道边的废哨塔上，艾德里克正被佣兵围攻。
const MAP := [
	"MMMMMMMMMMMMMMMMMMMMMMMMMM##########",
	"M.MMMMM.M..MMMMMMM...MMM.F#ASA#IKI##",
	"...FM....MMMMM..MM...MMM..#SSS#SSSS#",
	".FFFFF.......M.......MMF.F#ASS#SSSS#",
	"...HFFF....FF........FM...#SSS##G###",
	"FF.R..FF.FFFFF..h.hFFFF..RGSSISSSSS#",
	"...RRRR....F.Fhh.hhhhFFF.R#SSSSSSSA#",
	"..FFF..........hhhhhFFF..R#SSSSSISS#",
	".F.......RRRRRR..h...F...R#ASSSSSAS#",
	".........R...FRRRRRRRRRRRR####G#####",
	"F........R...................RR.....",
	"~~~~~~~~~B~~~~~~~~ww~~~~~~~~~B~~~~~~",
	"F.F...F..R..h..F.........h...R......",
	"F....FF..R....FF....F.h......R..hT..",
	"F....FFFFR...FFFF.M.....RRRRRRF..h..",
	"F.F......R.h.FFFF.M............F....",
	".........R..FT....Mh....R......F.F..",
	"...RRRRRRRRRRRRRRRRRRRRRR....F.FFF..",
	"...R.........h......h.......FFFFFFF.",
	".ffRF......h.......hhhh..F....FF...F",
	".f.R.....FFFFFFF....h....h..........",
	"...R........F.......................",
]

const LEVELS := [
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"000000000100000000110000000001000000",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
	"111111111111111111111111111111111111",
]

const C_TIA := Color(1.0, 0.62, 0.45)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_HARLO := Color(0.85, 0.95, 0.6)
const C_TOBY := Color(0.95, 0.75, 0.55)
const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _MERC := {"name": "黑烬佣兵", "class": "佣兵", "faction": "enemy", "level": 4,
	"hp": 24, "pwr": 6, "skl": 7, "spd": 7, "dfn": 3, "mov": 5,
	"weapons": ["iron_sword"], "color": Color(0.30, 0.28, 0.30),
	"hair": "short", "hair_color": Color(0.18, 0.16, 0.16), "armor": Color(0.28, 0.26, 0.28)}
const _BANDIT := {"name": "山贼", "class": "山贼", "faction": "enemy", "level": 4,
	"hp": 26, "pwr": 7, "skl": 3, "spd": 4, "dfn": 3, "mov": 5,
	"weapons": ["iron_axe"], "color": Color(0.55, 0.45, 0.35),
	"hair": "spiky", "hair_color": Color(0.25, 0.18, 0.12), "armor": Color(0.50, 0.40, 0.30)}
const _ARCHER := {"name": "弓箭手", "class": "弓箭手", "faction": "enemy", "level": 4,
	"hp": 21, "pwr": 6, "skl": 6, "spd": 6, "dfn": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.45, 0.55, 0.40),
	"hair": "hood", "armor": Color(0.38, 0.55, 0.38)}

const UNITS := [
	# 我方：名单里有存档时用存档，这里只给位置和直接进本章时的默认数值
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 3,
		"hp": 22, "pwr": 6, "skl": 7, "spd": 8, "dfn": 4, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(3, 20), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "balto", "name": "巴尔托", "class": "圣骑士", "faction": "player", "level": 8,
		"hp": 26, "pwr": 8, "skl": 9, "spd": 8, "dfn": 7, "mov": 7,
		"weapons": ["silver_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 40, "pwr": 20, "skl": 25, "spd": 25, "dfn": 20},
		"pos": Vector2i(4, 20), "color": Color(0.45, 0.55, 0.75),
		"hair": "short", "hair_color": Color(0.75, 0.75, 0.78), "armor": Color(0.70, 0.73, 0.82)},
	{"id": "harlo", "name": "哈洛", "class": "战士", "faction": "player", "level": 2,
		"hp": 23, "pwr": 7, "skl": 3, "spd": 4, "dfn": 3, "mov": 5,
		"weapons": ["iron_axe"], "items": [],
		"growths": {"hp": 85, "pwr": 55, "skl": 35, "spd": 40, "dfn": 30},
		"pos": Vector2i(2, 20), "color": Color(0.70, 0.60, 0.40), "hair": "short",
		"hair_color": Color(0.50, 0.32, 0.18), "armor": Color(0.55, 0.48, 0.35)},
	# 客串：艾德里克在东南被佣兵追赶。开场是绿色的第三方（自己在友军阶段迎战），缇娅或巴尔托【对话】后才归我方指挥
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "npc", "fights": true, "level": 3,
		"hp": 30, "pwr": 6, "skl": 8, "spd": 8, "dfn": 8, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35},
		"pos": Vector2i(13, 16), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	# 敌方
	# 山道口附近
	{"id": "bandit1", "pos": Vector2i(8, 18)},
	{"id": "bandit2", "pos": Vector2i(7, 15)},
	{"id": "archer2", "pos": Vector2i(6, 14)},
	# 南岸：围着废哨塔上艾德里克的追兵
	{"id": "merc4", "pos": Vector2i(20, 15), "hold": true},
	{"id": "bandit3", "pos": Vector2i(15, 20), "hold": true},
	{"id": "archer3", "pos": Vector2i(17, 13), "hold": true},
	{"id": "merc5", "pos": Vector2i(25, 15), "hold": true},
	# 北岸：西桥头、猎户小屋一带的林子
	{"id": "merc2", "pos": Vector2i(10, 9)},
	{"id": "bandit5", "pos": Vector2i(7, 6), "hold": true},
	{"id": "archer5", "pos": Vector2i(5, 8), "hold": true},
	# 山口（凯因身边）
	{"id": "merc6", "pos": Vector2i(15, 7), "hold": true},
	{"id": "archer4", "pos": Vector2i(19, 7), "hold": true},
	{"id": "bandit4", "pos": Vector2i(23, 9)},
	# 要塞：营门、前院、内堡
	{"id": "merc1", "pos": Vector2i(30, 8)},
	{"id": "merc3", "pos": Vector2i(31, 6), "hold": true},
	{"id": "archer1", "pos": Vector2i(28, 2), "hold": true},
	# 凯因：动摇的佣兵新人，守着不动，等缇娅来说得
	{"id": "kain", "name": "凯因", "class": "佣兵", "faction": "enemy", "level": 3,
		"hp": 22, "pwr": 5, "skl": 8, "spd": 9, "dfn": 3, "mov": 5,
		"weapons": ["iron_sword"], "items": [], "hold": true,
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25},
		"pos": Vector2i(17, 6), "color": Color(0.45, 0.40, 0.55),
		"hair": "short", "hair_color": Color(0.20, 0.18, 0.24), "armor": Color(0.38, 0.34, 0.42)},
	# 佣兵队长霍克：坐在要塞内堡的王座上
	{"id": "hawk", "name": "霍克", "class": "佣兵队长", "faction": "enemy", "level": 7,
		"hp": 34, "pwr": 9, "skl": 10, "spd": 9, "dfn": 6, "mov": 5,
		"weapons": ["steel_sword"], "stationary": true, "boss": true,
		"pos": Vector2i(32, 1), "color": Color(0.30, 0.20, 0.22),
		"hair": "spiky", "hair_color": Color(0.10, 0.08, 0.08), "armor": Color(0.32, 0.18, 0.20), "scar": true},
]

const REINFORCEMENTS := [
	{"id": "merc_r1", "pos": Vector2i(34, 7)},
]

## 妮娜：访问山脚小屋后入队
const NINA := {"id": "nina", "name": "妮娜", "class": "弓箭手", "level": 2,
	"hp": 18, "pwr": 5, "skl": 7, "spd": 6, "dfn": 2, "mov": 5,
	"weapons": ["iron_bow"], "items": ["vulnerary"],
	"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15},
	"color": Color(0.45, 0.60, 0.35), "hair": "ponytail", "hair_color": Color(0.55, 0.36, 0.20),
	"armor": Color(0.42, 0.55, 0.32)}

const NINA_CABIN := Vector2i(3, 4)


func chapter_id() -> String:
	return "ch3"


## 出击准备：选人 + 布阵 + 物品 + 商店
func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 5


## 艾德里克开场是第三方，不在整备名单里
func forced_ids() -> Array:
	return ["tia", "balto"]


func must_join_on_victory() -> Array:
	return ["edric"]


func extra_deploy_slots() -> Array:
	return [Vector2i(3, 19), Vector2i(4, 21), Vector2i(2, 21)]


func templates() -> Dictionary:
	return {"merc": _MERC, "bandit": _BANDIT, "archer": _ARCHER}


func lose_ids() -> Array:
	return ["tia", "balto", "edric"]


func extra_slots() -> Array:
	return [Vector2i(3, 19), Vector2i(4, 21), Vector2i(2, 21), Vector2i(4, 19)]


## 艾德里克章末离队，第 8 章起正式在队
func after_victory_status() -> Dictionary:
	return {"edric": "away"}


func is_won() -> bool:
	var hawk = battle.get_unit("hawk")
	if hawk != null and not hawk.is_alive():
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("击败佣兵队长霍克")


func lose_condition() -> String:
	return tr("缇娅、巴尔托或艾德里克阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())
	await battle.play_dialogue(_edric_chased())


func on_turn_start(t: int) -> void:
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	elif t == 4 and not flags.get("reinforce", false):
		flags["reinforce"] = true
		battle.spawn_units(REINFORCEMENTS)
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		await battle.play_dialogue(_turn4_reinforce())


func on_before_combat(_att, def) -> void:
	if def.unit_id == "hawk" and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "hawk" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == NINA_CABIN and battle.get_unit("nina") == null:
		await battle.play_dialogue(_visit_nina())
		battle.join_unit(NINA, pos)
	else:
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))


func talks() -> Array:
	return [["balto", "edric", "balto_edric"]]


func talk_lines(key: String) -> Array:
	if key == "tia_edric":
		return [
			_l("艾德里克", C_EDRIC, "你是……灰岩村的人？那个红头发……"),
			_l("缇娅", C_TIA, "红头发怎么了？你也是来抓我的？"),
			_l("艾德里克", C_EDRIC, "不，不是！我是艾德里克，菲恩领主埃德蒙之子。父亲派出的巡逻队在这条山道上失踪了。"),
			_l("缇娅", C_TIA, "巡逻队……山贼来的那天，巡逻队一个都没出现。"),
			_l("艾德里克", C_EDRIC, "果然。有人提前把他们引开了。……拿着这个，领地发的伤药，比我更用得上的人是你。"),
		]
	return [
		_l("巴尔托", C_BALTO, "领主家的小子，剑握得太紧了。"),
		_l("艾德里克", C_EDRIC, "您是……退役的骑士？这身架势，不是普通的村民。"),
		_l("巴尔托", C_BALTO, "老夫只是个种麦子的。……专心打仗，别让你父亲白养你。"),
	]


func on_talked(key: String, _u, _partner) -> void:
	if key == "tia_edric":
		var tia = battle.get_unit("tia")
		if tia != null:
			tia.receive("vulnerary")
			battle.notify(tr("缇娅 获得 伤药"))


func recruits() -> Dictionary:
	return {"kain": ["tia"], "edric": ["tia", "balto"]}


func recruit_lines(target_id: String, by_id: String) -> Array:
	if target_id == "edric":
		return _edric_joins(by_id)
	return [
		_l("凯因", C_KAIN, "红头发……你就是团长要找的人？"),
		_l("缇娅", C_TIA, "你们烧了我的村子。你也有份吗？"),
		_l("凯因", C_KAIN, "我……我只是看营地的。入团那天，团长说我们「只杀该杀之人」。"),
		_l("凯因", C_KAIN, "可那个村子里，只有老人和孩子。"),
		_l("缇娅", C_TIA, "那就别再替他们干活了。"),
		_l("凯因", C_KAIN, "……好。我想弄清楚，到底是谁出的钱。我叫凯因。"),
	]


func on_recruited(t, _by) -> void:
	if t.unit_id == "edric":
		var tia = battle.get_unit("tia")
		if tia != null and tia.is_alive():
			tia.receive("vulnerary")
			battle.notify(tr("缇娅 获得 伤药"))


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	battle.add_gold(400)


func on_defeat() -> void:
	var edric = battle.get_unit("edric")
	var tia = battle.get_unit("tia")
	if edric != null and not edric.is_alive():
		await battle.play_dialogue(_defeat_edric())
	elif tia == null or not tia.is_alive():
		await battle.play_dialogue(_defeat_tia())
	else:
		await battle.play_dialogue(_defeat_balto())


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "灰岩村焚毁后的第二天。北面山道。"),
		_l("巴尔托", C_BALTO, "脚印、马蹄印……还有拖车的车辙。他们没打算藏。"),
		_l("", C_NARR, "山口上蹲着一座石砌的要塞。城墙塌了几处，城头却插着新旗。"),
		_l("巴尔托", C_BALTO, "王国守边的旧要塞，荒了快二十年了。……现在成了别人的窝。"),
		_l("缇娅", C_TIA, "营火的烟是从城墙里冒出来的。就是他们吧？"),
		_l("哈洛", C_HARLO, "旗子上画着黑色的火……和爹说的一样，黑烬佣兵团！"),
	]
	if battle.get_unit("bandit6") != null:
		lines.append(_l("托比", C_TOBY, "那、那边那个年轻的佣兵……我在营里见过他。他好像不太想干这活。"))
	lines.append(_l("巴尔托", C_BALTO, "佣兵不会白干活。一定有人出钱。……先拿下领头的。"))
	return lines


func _edric_chased() -> Array:
	return [
		_l("", C_NARR, "山道另一头，一名年轻骑士正被佣兵围住。"),
		_l("艾德里克", C_EDRIC, "菲恩领的巡逻队都在这条山道上失踪了……果然是你们！"),
		_l("黑烬佣兵", C_ENEMY, "领主家的小少爷？正好，一起埋了。"),
		_l("缇娅", C_TIA, "那个人被围住了！巴尔托，我们去帮他！"),
		_l("巴尔托", C_BALTO, "那小子是绿色的友军，会自己迎战。走到他身边【对话】，他才会听我们的调度。"),
	]


## 对话入队：缇娅（或巴尔托）走到艾德里克身边
func _edric_joins(by_id: String) -> Array:
	if by_id == "balto":
		return [
			_l("巴尔托", C_BALTO, "领主家的小子，一个人往佣兵堆里冲，你父亲知道吗？"),
			_l("艾德里克", C_EDRIC, "您是……？这身架势，不是普通的村民。"),
			_l("巴尔托", C_BALTO, "老夫只是个种麦子的。……别逞强，跟着我们走，后背交给我们。"),
			_l("艾德里克", C_EDRIC, "……好。菲恩领的艾德里克，听您调度。"),
		]
	return [
		_l("艾德里克", C_EDRIC, "你是……灰岩村的人？那个红头发……"),
		_l("缇娅", C_TIA, "红头发怎么了？你也是来抓我的？"),
		_l("艾德里克", C_EDRIC, "不，不是！我是艾德里克，菲恩领主埃德蒙之子。父亲派出的巡逻队在这条山道上失踪了。"),
		_l("缇娅", C_TIA, "巡逻队……山贼来的那天，巡逻队一个都没出现。"),
		_l("艾德里克", C_EDRIC, "果然。有人提前把他们引开了。……一个人打不过这么多，能让我跟你们一起走吗？"),
		_l("缇娅", C_TIA, "跟紧了。别拖后腿。"),
		_l("艾德里克", C_EDRIC, "哈……遵命。这个给你，领地发的伤药，比我更用得上的人是你。"),
	]


func _turn2_hint() -> Array:
	return [
		_l("巴尔托", C_BALTO, "西北山脚有间猎户的小屋。路过的话，进去【访问】看看，说不定还有人活着。"),
		_l("巴尔托", C_BALTO, "那个站着不动的年轻佣兵……缇娅，你走到他身边试试【说得】。能少杀一个，就少杀一个。"),
	]


func _turn4_reinforce() -> Array:
	return [
		_l("黑烬佣兵", C_ENEMY, "有人攻要塞！营房里的都出来！队长有令，红头发的丫头要活的！"),
		_l("艾德里克", C_EDRIC, "他们要抓的……是你？"),
		_l("缇娅", C_TIA, "先打完再说！"),
	]


func _visit_nina() -> Array:
	return [
		_l("妮娜", C_NINA, "……别过来！你们也是那伙佣兵的人？"),
		_l("缇娅", C_TIA, "不是！我们是来找他们算账的。我的村子被他们烧了。"),
		_l("妮娜", C_NINA, "……我爹昨天下山卖皮子，再也没回来。我在路边找到了他的弓。"),
		_l("妮娜", C_NINA, "我跟你们走。这把弓，正缺个靶子。"),
	]


func _boss() -> Array:
	return [
		_l("霍克", C_BOSS, "红头发的丫头……送上门来了。上头说了要活的，其他人，杀了。"),
		_l("缇娅", C_TIA, "「上头」是谁？谁让你们烧村子的！"),
		_l("霍克", C_BOSS, "想知道？赢了我再说。"),
	]


func _boss_death() -> Array:
	return [
		_l("霍克", C_BOSS, "咳……团长……这活，从一开始就不该接……"),
	]


func _post_battle() -> Array:
	return [
		_l("", C_NARR, "佣兵退走了。内堡王座后面，留下一只上锁的铁匣。"),
		_l("艾德里克", C_EDRIC, "一封密信……火漆上是圣焰的纹章。这是教会的印。"),
		_l("巴尔托", C_BALTO, "…………"),
		_l("缇娅", C_TIA, "教会？教会为什么要找我？"),
		_l("艾德里克", C_EDRIC, "我不知道。但巡逻队的失踪、佣兵、这封信……都连着。我得马上回去禀告父亲。"),
		_l("艾德里克", C_EDRIC, "缇娅，谢谢你们。我们一定还会再见。"),
		_l("", C_NARR, "艾德里克骑上马，消失在山道尽头。"),
		_l("巴尔托", C_BALTO, "（教会……他们终于找来了。）"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "还没……找到放火的人……"),
		_l("", C_NARR, "缇娅倒下了。黑烬佣兵团带走了红发的少女。"),
	]


func _defeat_balto() -> Array:
	return [
		_l("巴尔托", C_BALTO, "老夫……答应过她母亲的……"),
		_l("", C_NARR, "巴尔托倒下了。山道上再没有能护住缇娅的人。"),
	]


func _defeat_edric() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "父亲……对不起……"),
		_l("", C_NARR, "领主之子死在山道上。菲恩领的真相，被埋进了雪里。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "fortress", "from": "grayrock", "lines": [
		_l("", CB_NARR, "焚村后的第二天。缇娅一行顺着车辙，往北面山道追去。"),
		_l("", CB_NARR, "山口上，蹲着一座荒废了二十年的王国边境要塞。城头上，插着黑色火焰的旗。"),
	]}


func epilogue() -> Array:
	return [{"title": "菲恩城 · 领主书房", "mood": "castle", "lines": [
		_l("", CB_NARR, "两天后。菲恩领的主城，菲恩城。"),
		_l("艾德里克", CB_EDRIC, "父亲，这封密信……火漆上是圣焰教会的纹章。巡逻队就是在那条山道上失踪的。"),
		_l("埃德蒙", CB_EDMUND, "……巡逻队、佣兵、教会。艾德里克，你可知道，大圣堂里供着的八件圣器，如今只剩七件？"),
		_l("艾德里克", CB_EDRIC, "圣器……失窃了？可教会对外什么都没说。"),
		_l("埃德蒙", CB_EDMUND, "所以我要亲自去查。圣都那边，我还有几个信得过的老朋友。"),
		_l("艾德里克", CB_EDRIC, "我跟您一起去！"),
		_l("埃德蒙", CB_EDMUND, "你留下守城。领主不在的时候，菲恩城的门得有人看着。"),
		_l("埃德蒙", CB_EDMUND, "……还有，那个红头发的姑娘，叫缇娅？若她再遇险，替我还她这份人情。"),
		_l("艾德里克", CB_EDRIC, "……是，父亲。"),
	]}]
