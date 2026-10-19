class_name Chapter3
extends ChapterBase
## 第三章「佣兵团的影子」：追着放火的人进了北面山道，撞见黑烬佣兵团的营地。
## 菲恩领主之子艾德里克在追查失踪的巡逻队，被佣兵围住（客串：他倒下即败北，章末离队）。
## 猎户女儿妮娜（访问山脚小屋）、动摇的佣兵凯因（缇娅说得）入队。击败佣兵队长霍克即通关。

const CHAPTER_TITLE := "第三章 · 佣兵团的影子"
const VICTORY_TITLE := "第三章 · 完"
const VICTORY_SUB := "佣兵的密信上，盖着圣焰教会的火漆。"
const DEFEAT_SUB := "山道上的营火，烧到了天明……"
const BG := ""

## 西北山脚是妮娜的小屋，东北高台是佣兵营地；河上两座桥
const MAP := [
	"FFFFFMMMFFFFFFF",
	"F.H..FMM..f.ffF",
	"F....F..RRRRR.F",
	"..F..F..R.F....",
	"....FF..R..F...",
	"~~~B~~~~B~~~~~~",
	"........R...F..",
	"..F..F..R......",
	"....F...R...F..",
	"........R......",
]

## 东北营地在高台上（高度 2）
const LEVELS := [
	"222222222222222",
	"111111111122221",
	"111111111122221",
	"111111111111111",
	"111111111111111",
	"000100001000000",
	"111111111111111",
	"111111111111111",
	"111111111111111",
	"111111111111111",
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
		"pos": Vector2i(2, 8), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "balto", "name": "巴尔托", "class": "圣骑士", "faction": "player", "level": 8,
		"hp": 26, "pwr": 8, "skl": 9, "spd": 8, "dfn": 7, "mov": 7,
		"weapons": ["silver_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 40, "pwr": 20, "skl": 25, "spd": 25, "dfn": 20},
		"pos": Vector2i(3, 9), "color": Color(0.45, 0.55, 0.75),
		"hair": "short", "hair_color": Color(0.75, 0.75, 0.78), "armor": Color(0.70, 0.73, 0.82)},
	{"id": "harlo", "name": "哈洛", "class": "战士", "faction": "player", "level": 2,
		"hp": 23, "pwr": 7, "skl": 3, "spd": 4, "dfn": 3, "mov": 5,
		"weapons": ["iron_axe"], "items": [],
		"growths": {"hp": 85, "pwr": 55, "skl": 35, "spd": 40, "dfn": 30},
		"pos": Vector2i(1, 9), "color": Color(0.70, 0.60, 0.40), "hair": "short",
		"hair_color": Color(0.50, 0.32, 0.18), "armor": Color(0.55, 0.48, 0.35)},
	# 客串：艾德里克在东南被佣兵追赶
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 3, "join": true,
		"hp": 24, "pwr": 6, "skl": 8, "spd": 8, "dfn": 6, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35},
		"pos": Vector2i(10, 9), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	# 敌方
	{"id": "merc1", "pos": Vector2i(11, 1)},
	{"id": "merc2", "pos": Vector2i(9, 3)},
	{"id": "merc3", "pos": Vector2i(12, 4), "hold": true},
	{"id": "merc4", "pos": Vector2i(6, 6)},
	{"id": "bandit1", "pos": Vector2i(4, 3)},
	{"id": "bandit2", "pos": Vector2i(7, 8)},
	{"id": "bandit3", "pos": Vector2i(12, 7)},
	{"id": "archer1", "pos": Vector2i(10, 2)},
	{"id": "archer2", "pos": Vector2i(1, 3)},
	# 凯因：动摇的佣兵新人，守着不动，等缇娅来说得
	{"id": "kain", "name": "凯因", "class": "佣兵", "faction": "enemy", "level": 3,
		"hp": 22, "pwr": 5, "skl": 8, "spd": 9, "dfn": 3, "mov": 5,
		"weapons": ["iron_sword"], "items": [], "hold": true,
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25},
		"pos": Vector2i(6, 3), "color": Color(0.45, 0.40, 0.55),
		"hair": "short", "hair_color": Color(0.20, 0.18, 0.24), "armor": Color(0.38, 0.34, 0.42)},
	# 佣兵队长霍克：守在营地高台
	{"id": "hawk", "name": "霍克", "class": "佣兵队长", "faction": "enemy", "level": 7,
		"hp": 34, "pwr": 9, "skl": 10, "spd": 9, "dfn": 6, "mov": 5,
		"weapons": ["steel_sword"], "stationary": true, "boss": true,
		"pos": Vector2i(12, 2), "color": Color(0.30, 0.20, 0.22),
		"hair": "spiky", "hair_color": Color(0.10, 0.08, 0.08), "armor": Color(0.32, 0.18, 0.20), "scar": true},
]

const REINFORCEMENTS := [
	{"id": "merc_r1", "pos": Vector2i(13, 3)},
	{"id": "merc_r2", "pos": Vector2i(14, 4)},
]

## 妮娜：访问山脚小屋后入队
const NINA := {"id": "nina", "name": "妮娜", "class": "弓箭手", "level": 2,
	"hp": 18, "pwr": 5, "skl": 7, "spd": 6, "dfn": 2, "mov": 5,
	"weapons": ["iron_bow"], "items": ["vulnerary"],
	"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15},
	"color": Color(0.45, 0.60, 0.35), "hair": "ponytail", "hair_color": Color(0.55, 0.36, 0.20),
	"armor": Color(0.42, 0.55, 0.32)}

const NINA_CABIN := Vector2i(2, 1)


func chapter_id() -> String:
	return "ch3"


## 出击准备：选人 + 布阵 + 物品 + 商店
func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 5


func extra_deploy_slots() -> Array:
	return []


func templates() -> Dictionary:
	return {"merc": _MERC, "bandit": _BANDIT, "archer": _ARCHER}


func lose_ids() -> Array:
	return ["tia", "balto", "edric"]


func extra_slots() -> Array:
	return [Vector2i(4, 9), Vector2i(0, 8), Vector2i(1, 7), Vector2i(5, 9)]


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
	return [["tia", "edric", "tia_edric"], ["balto", "edric", "balto_edric"]]


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
	return {"kain": ["tia"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return [
		_l("凯因", C_KAIN, "红头发……你就是团长要找的人？"),
		_l("缇娅", C_TIA, "你们烧了我的村子。你也有份吗？"),
		_l("凯因", C_KAIN, "我……我只是看营地的。入团那天，团长说我们「只杀该杀之人」。"),
		_l("凯因", C_KAIN, "可那个村子里，只有老人和孩子。"),
		_l("缇娅", C_TIA, "那就别再替他们干活了。"),
		_l("凯因", C_KAIN, "……好。我想弄清楚，到底是谁出的钱。我叫凯因。"),
	]


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
		_l("缇娅", C_TIA, "前面有营火的烟。就是他们吧？"),
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
	]


func _turn2_hint() -> Array:
	return [
		_l("巴尔托", C_BALTO, "西北山脚有间猎户的小屋。路过的话，进去【访问】看看，说不定还有人活着。"),
		_l("巴尔托", C_BALTO, "那个站着不动的年轻佣兵……缇娅，你走到他身边试试【说得】。能少杀一个，就少杀一个。"),
	]


func _turn4_reinforce() -> Array:
	return [
		_l("黑烬佣兵", C_ENEMY, "营地被袭！队长有令，红头发的丫头要活的！"),
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
		_l("", C_NARR, "佣兵退走了。营地的帐篷里留下一只上锁的铁匣。"),
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
