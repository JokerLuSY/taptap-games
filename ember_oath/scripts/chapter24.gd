class_name Chapter24
extends Part3Chapter
## 第二十四章「审判官的剑」：攻进圣都内城的审判所。审判官塞拉斯守在护城河的中央石桥上（敌方，hold）：
## 诺雅【说得】入队（师徒）；诺雅不在时缇娅也能说得（台词不同）。被击杀就阵亡。
## 七号第 3 回合从审判所里出来，要把缇娅带回去：打不死（HP 降到四成以下撤退），缇娅走到身边【对话】→ 七号条件第 2 步，七号撤退。
## 胜利：击败主教维尔纳。败北：三主角阵亡。

const CHAPTER_TITLE := "第二十四章 · 审判官的剑"
const VICTORY_TITLE := "第二十四章 · 完"
const VICTORY_SUB := "八百年前抄错的那一页，有人终于读出了声。"
const DEFEAT_SUB := "审判所的钟声，为异端敲响了……"
const BG := ""

## 34×24。南边是圣都内城的街区（民宅成片，中间一条大道），护城河横贯东西：中央两格宽的石桥（塞拉斯守着），东西各一座窄桥。
## 北边是审判所：大门 G → 前庭 → 两侧回廊 → 王座间，主教维尔纳坐在王座 K 上；东西两座小塔里有弓兵。七号第 3 回合从审判所里出来。
const MAP := [
	"##################################",
	"S#####S#SSSSSSSSSSSSSSSSSS#S#####S",
	"S#SSS#S#SSSSSSISSKSSISSSSS#S#SSS#S",
	"S#SSS#S#SSSSSSSSSSSSSSSSSS#S#SSS#S",
	"S#SSS#S###S###SSSSSS###S###S#SSS#S",
	"S#SSS#S#SSSSSSSSSSSSSSSSSS#S#SSS#S",
	"S#SSS#S#SSSSSSISSSSISSSSSS#S#SSS#S",
	"S##S##S#SSSISSSSSSSSSSISSS#S##S##S",
	"SSSSSSS#SSSSSSSSSSSSSSSSSS#SSSSSSS",
	"SSSSSSS#SSSSSSSSSSSSSSSSSS#SSSSSSS",
	"SSSSSSS#########GG#########SSSSSSS",
	"SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
	"~~~~~B~~~~~~~~~~BB~~~~~~~~~~B~~~~~",
	"~~~~~B~~~~~~~~~~BB~~~~~~~~~~B~~~~~",
	"SSSZSSSDDDDSDDDSRRSDDDSDDDDSSSSZSS",
	"SDDDSSSDDDDSDDDSRRSDDDSDDDDSSSDDDS",
	"SDDDSSSSSSSSSSSSRRSSSSSSSSSSSSDDDS",
	"SSRRRRRRRRRIRRRRRRRRRRIRRRRRRRRRSS",
	"SSSSSSSSSSSSSSSSRRSSSSSSSSSSSSSSSS",
	"SDDDDSSDDDSSDDDSRRSDDDSSDDDSSDDDDS",
	"SDDDDSSDDDSSDDDSRRSDDDSSDDDSSDDDDS",
	"SSSSSSSDDDSSSSSSRRSSSSSSDDDSSSSSSS",
	"SSSSSZSSHSSSSSSSRRSSSSSSSHSSZSSSSS",
	"SSSSSSSSSSSSSSSSRRSSSSSSSSSSSSSSSS",
]

const LEVELS := []                # 全图同一高度

const SEVEN_RETREAT_PCT := 0.4
const SEVEN_LEAVES := 8

## 七号：从审判所里走出来。HP、守备很高，打不倒；受伤到四成以下就撤退
const SEVEN := {"id": "seven", "name": "七号", "class": "灰烬傀儡", "faction": "enemy", "level": 18, "boss": true,
	"hp": 80, "pwr": 16, "skl": 14, "spd": 24, "dfn": 18, "res": 14, "mov": 6,
	"weapons": ["ash_claw"], "pos": Vector2i(17, 6), "color": Color(0.55, 0.52, 0.56),
	"hair": "ponytail", "hair_color": Color(0.80, 0.80, 0.84), "armor": Color(0.42, 0.40, 0.44)}

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "faction": "player", "pos": Vector2i(16, 22)},
	{"id": "tia", "faction": "player", "pos": Vector2i(17, 22)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(15, 22)},
	{"id": "noya", "faction": "player", "pos": Vector2i(18, 22)},
	{"id": "balto", "faction": "player", "pos": Vector2i(16, 23)},
	{"id": "orion", "faction": "player", "pos": Vector2i(17, 23)},
	{"id": "vera", "faction": "player", "pos": Vector2i(15, 23)},
	{"id": "kain", "faction": "player", "pos": Vector2i(18, 23)},
	{"id": "ivy", "faction": "player", "pos": Vector2i(15, 21)},
	{"id": "rock", "faction": "player", "pos": Vector2i(18, 21)},
	# 南边街区
	{"id": "soldier1", "pos": Vector2i(10, 17)},
	{"id": "soldier2", "pos": Vector2i(24, 17)},
	{"id": "knight1", "pos": Vector2i(5, 17), "hold": true},
	{"id": "knight2", "pos": Vector2i(29, 17), "hold": true},
	{"id": "myrm1", "pos": Vector2i(17, 16), "hold": true},
	{"id": "fighter1", "pos": Vector2i(14, 18), "hold": true},
	# 中央石桥北头：塞拉斯（敌方，hold）
	{"id": "silas", "name": "塞拉斯", "class": "圣骑士", "faction": "enemy", "boss": true, "hold": true, "pos": Vector2i(16, 11)},
	{"id": "armor1", "pos": Vector2i(17, 11), "hold": true},
	{"id": "armor2", "pos": Vector2i(15, 11), "hold": true},
	{"id": "archer1", "pos": Vector2i(18, 11), "hold": true},
	# 东西窄桥
	{"id": "soldier3", "pos": Vector2i(5, 11), "hold": true},
	{"id": "archer2", "pos": Vector2i(4, 11), "hold": true},
	{"id": "soldier4", "pos": Vector2i(28, 11), "hold": true},
	{"id": "mage1", "pos": Vector2i(29, 11), "hold": true},
	# 审判所前庭、两座小塔
	{"id": "paladin1", "pos": Vector2i(11, 9), "hold": true},
	{"id": "paladin2", "pos": Vector2i(22, 9), "hold": true},
	{"id": "sniper1", "pos": Vector2i(3, 4), "hold": true},
	{"id": "sniper2", "pos": Vector2i(30, 4), "hold": true},
	{"id": "general1", "pos": Vector2i(16, 8), "hold": true},
	{"id": "general2", "pos": Vector2i(17, 8), "hold": true, "items": ["vulnerary"]},
	{"id": "darkmage1", "pos": Vector2i(12, 6), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(21, 6), "hold": true},
	# 王座间
	{"id": "sage1", "pos": Vector2i(10, 2), "hold": true},
	{"id": "cleric1", "pos": Vector2i(23, 2)},
	# 主教维尔纳：坐在审判所的王座上
	{"id": "werner", "name": "维尔纳", "class": "贤者", "faction": "enemy", "level": 12,
		"hp": 48, "pwr": 21, "skl": 18, "spd": 16, "dfn": 12, "res": 22, "mov": 6,
		"weapons": ["bolganone", "divine"], "items": ["elixir"], "boss": true, "stationary": true,
		"pos": Vector2i(17, 2), "color": Color(0.96, 0.94, 0.86),
		"hair": "hood", "hair_color": Color(0.80, 0.78, 0.74), "armor": Color(0.98, 0.94, 0.80)},
]

## 第 3 回合七号带着两具傀儡从审判所里出来；第 5 回合东西两头来骑兵；第 7 回合小塔上又来了狙击手
const WAVES := {
	3: [{"id": "puppet_r1", "pos": Vector2i(16, 7)}, {"id": "puppet_r2", "pos": Vector2i(18, 7)}],
	5: [{"id": "paladin_r1", "pos": Vector2i(0, 17)}, {"id": "paladin_r2", "pos": Vector2i(33, 17)},
		{"id": "knight_r1", "pos": Vector2i(0, 16)}, {"id": "knight_r2", "pos": Vector2i(33, 16)}],
	7: [{"id": "sniper_r1", "pos": Vector2i(3, 3)}, {"id": "sniper_r2", "pos": Vector2i(30, 3)}],
}

const DEPLOY := [Vector2i(14, 22), Vector2i(19, 22), Vector2i(14, 23), Vector2i(19, 23), Vector2i(14, 21), Vector2i(19, 21),
	Vector2i(16, 21), Vector2i(17, 21), Vector2i(13, 22), Vector2i(20, 22), Vector2i(13, 23), Vector2i(20, 23)]


func chapter_id() -> String:
	return "ch24"


func stage() -> int:
	return 1


func deploy_limit() -> int:
	return 10


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func foes() -> Dictionary:
	return {
		"soldier": foe("soldier", 20), "knight": foe("knight", 19),
		"armor": foe("armor", 20, {"name": "审判所重甲兵"}), "archer": foe("archer", 19), "mage": foe("mage", 19),
		"darkmage": foe("darkmage", 19), "cleric": foe("cleric", 7), "puppet": foe("puppet", 19),
		"paladin": foe("paladin", 8), "general": foe("general", 8), "sage": foe("sage", 8, {"weapons": ["elfire"]}),
		"sniper": foe("sniper", 7), "myrm": foe("myrm", 8), "fighter": foe("fighter", 7),
	}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "silver_sword", "killing_edge", "steel_lance", "silver_lance",
		"steel_axe", "silver_axe", "silver_bow", "elfire", "bolganone", "divine", "mend_staff"]


func is_won() -> bool:
	var b = battle.get_unit("werner")
	return b != null and not b.is_alive()


func win_condition() -> String:
	return tr("击败主教维尔纳")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if _wave(t, WAVES):
		if t == 3:
			battle.spawn_units([SEVEN])
			battle.show_banner(tr("七号出现了！"), Color(0.85, 0.8, 0.9))
			await battle.play_dialogue(_seven_appears())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t >= SEVEN_LEAVES and _seven_on_map():
		await _seven_leave(false)


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == Vector2i(8, 22):
		await battle.play_dialogue([
			_l("村妇", C_NPC, "审判所的人抓走了我丈夫，说他「私藏火种」。……其实只是一盏油灯。"),
			_l("村妇", C_NPC, "这瓶药你们拿着。要是见到被关着的人，替我说一句：我还在等。"),
		])
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))
	elif pos == Vector2i(25, 22):
		await battle.play_dialogue([
			_l("老学者", C_NPC, "我在审判所书库抄了四十年的书。……这枚徽章，是给「抄得最好的人」的。"),
			_l("老学者", C_NPC, "可我抄的都是谎话。拿去吧，给一个会说真话的人。"),
		])
		u.receive("sage_crest")
		battle.notify(tr("获得 贤者之证"))


## 塞拉斯：诺雅或缇娅【说得】；七号：缇娅【对话】（不改阵营，谈完撤退）
func recruits() -> Dictionary:
	var out := {"silas": ["noya", "tia"]}
	if battle != null and battle.state != battle.S.PREP and _seven_on_map():
		out["seven"] = ["tia"]
	return out


func recruit_lines(target_id: String, by_id: String) -> Array:
	if target_id == "silas":
		return _silas_recruit(by_id)
	return []


func on_recruit(u) -> void:
	var t = get_recruit_target(u)
	if t == null:
		return
	if t.unit_id == "seven":
		await battle.play_dialogue(_seven_talk())
		Campaign.flags["seven_24_talked"] = true
		flags["seven_talked"] = true
		await _seven_leave(true)
		return
	await super.on_recruit(u)


func on_recruited(t, _by) -> void:
	if t.unit_id == "silas":
		t.is_boss = false
		t.hold = false
		flags["silas_joined"] = true
		Campaign.flags["silas_joined"] = true


func on_before_combat(att, def) -> void:
	var ids := [att.unit_id, def.unit_id]
	if "werner" in ids and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())
	if "silas" in ids and not flags.get("silas_fight", false) and not (att.is_player() and def.is_player()):
		flags["silas_fight"] = true
		var other = def if att.unit_id == "silas" else att
		await battle.play_dialogue(_silas_fight(other.unit_id))
	if "seven" in ids and "tia" in ids and not flags.get("seven_tia", false):
		flags["seven_tia"] = true
		await battle.play_dialogue(_seven_vs_tia())


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("werner")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())
	var s = battle.get_unit("silas")
	if s != null and not s.is_alive() and not s.is_player() and not flags.get("silas_dead", false):
		flags["silas_dead"] = true
		Campaign.flags["silas_dead"] = true
		await battle.play_dialogue(_silas_death())
	await _check_seven()


func _seven_on_map() -> bool:
	var s = battle.get_unit("seven")
	return s != null and s.is_alive() and s.on_map() and not s.is_player() and not s.is_npc()


## 七号打不死：HP 降到四成以下就撤退
func _check_seven() -> void:
	if not _seven_on_map():
		return
	var s = battle.get_unit("seven")
	if s.hp > int(s.max_hp * SEVEN_RETREAT_PCT):
		return
	await _seven_leave(false)


func _seven_leave(talked: bool) -> void:
	var s = battle.get_unit("seven")
	if s == null or flags.get("seven_gone", false):
		return
	flags["seven_gone"] = true
	if not talked:
		await battle.play_dialogue(_seven_retreats())
	_leave_map(s)
	battle.notify(tr("七号撤退了"))


func talks() -> Array:
	return [["noya", "silas", "noya_silas_24"], ["tia", "balto", "tia_balto_24"]]


func talk_lines(key: String) -> Array:
	if key == "noya_silas_24":
		return [
			_l("诺雅", C_NOYA, "塞拉斯大人……您还会叫我「见习修女」吗？"),
			_l("塞拉斯", C_SILAS, "你早就不是见习了。……那次出征，你挡在村民的火把前面的时候，就不是了。"),
			_l("诺雅", C_NOYA, "那时候您没有拦我。"),
			_l("塞拉斯", C_SILAS, "那时候我想，也许教会是对的，是我软弱。……现在我知道了，软弱的是教会。"),
		]
	return [
		_l("巴尔托", C_BALTO, "丫头，你刚才看那个七号的眼神……不像在看敌人。"),
		_l("缇娅", C_TIA, "……她在塔外面站了七个晚上。巴尔托，你说一个只会听命令的傀儡，会问「火烫不烫」吗？"),
		_l("巴尔托", C_BALTO, "老夫年轻的时候也被人当成只会听命令的东西。……后来有人问了老夫一句「你冷不冷」。就那一句。"),
		_l("缇娅", C_TIA, "后来呢？"),
		_l("巴尔托", C_BALTO, "后来老夫抱着一个婴儿，从城里逃了出来。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["seven_24_talked"] = flags.get("seven_talked", false)


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "圣都内城。护城河对岸，就是审判所——教会审判「异端」的地方。"),
		_l("", C_NARR, "石桥的北头，一个白色铠甲的骑士独自立马，像是等了很久。"),
		_l("塞拉斯", C_SILAS, "……巫女，又见面了。上一次，是在神殿里。"),
		_l("缇娅", C_TIA, "塞拉斯。白垣镇的笼子是你布下的，神殿里你又一直站在莫尔甘身后。……这次呢？"),
		_l("塞拉斯", C_SILAS, "这座桥后面是主教维尔纳大人。我的职责，是守住这座桥。"),
		_l("塞拉斯", C_SILAS, "……至于这职责还值不值得守，我还没有想清楚。"),
	]
	if _here("noya"):
		lines.append(_l("诺雅", C_NOYA, "塞拉斯大人……！"))
		lines.append(_l("塞拉斯", C_SILAS, "诺雅。……你也来了。"))
	lines.append_array([
		_l("艾德里克", C_EDRIC, "他在犹豫。……神殿里他也没有拔剑。"),
		_l("加雷斯", C_GARETH, "犹豫的人站在敌人那边，照样是敌人。"),
		_l("艾德里克", C_EDRIC, "那就让他站过来。"),
	])
	return lines


func _turn2_hint() -> Array:
	var lines: Array = []
	if _here("noya"):
		lines.append(_l("艾德里克", C_EDRIC, "诺雅，塞拉斯就在石桥北头。你去和他谈谈——【说得】。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "缇娅，塞拉斯就在石桥北头。他追过你，也许也只有你能说动他——【说得】。"))
	lines.append(_l("艾德里克", C_EDRIC, "目标是审判所王座上的主教维尔纳。"))
	return lines


func _silas_recruit(by_id: String) -> Array:
	var lines: Array = []
	if by_id == "noya":
		lines.append_array([
			_l("诺雅", C_NOYA, "塞拉斯大人，请把枪放下。"),
			_l("塞拉斯", C_SILAS, "诺雅。你跟着我出征的那年，才十四岁。我教过你，审判官的枪要对准异端。"),
			_l("诺雅", C_NOYA, "您还教过我，要先看清楚谁才是异端。……大人，您一定也看清楚了。神殿里，您一直没拔剑。"),
			_l("塞拉斯", C_SILAS, "……我读了审判所书库里八百年前的卷宗。「焚世之灾，起于巫女失控」——那一页的墨，比前后都新。"),
			_l("塞拉斯", C_SILAS, "有人重抄过那一页。教会用了八百年的「真理」，是被人改过的。"),
			_l("诺雅", C_NOYA, "那就请您和我们一起，去找回被改掉的东西。"),
			_l("塞拉斯", C_SILAS, "……我这把枪，追过巫女，烧过村子。还配拿来做这件事吗？"),
			_l("诺雅", C_NOYA, "配不配，用以后来证明。"),
			_l("塞拉斯", C_SILAS, "……你长大了，诺雅。好。审判官塞拉斯——今天起，审判教会。"),
		])
	else:
		lines.append_array([
			_l("缇娅", C_TIA, "塞拉斯。在白垣镇，你亲手把我关进了笼子。那个人，现在就站在你面前。"),
			_l("塞拉斯", C_SILAS, "……是。我奉命追捕「巫女」。我以为我在守护世界。"),
			_l("缇娅", C_TIA, "那现在呢？你守着这座桥，是在守护什么？"),
			_l("塞拉斯", C_SILAS, "我读了审判所书库里八百年前的卷宗。「焚世之灾，起于巫女失控」——那一页的墨，比前后都新。"),
			_l("塞拉斯", C_SILAS, "教会用了八百年的「真理」，是被人改过的。……我追了你那么久，却从没想过要读一读你们的历史。"),
			_l("缇娅", C_TIA, "现在读也不晚。跟我们来，去把被改掉的那一页找回来。"),
			_l("塞拉斯", C_SILAS, "……被我追过的人，向我伸出手。好。审判官塞拉斯——今天起，审判教会。"),
		])
	if _here("noya") and by_id != "noya":
		lines.append(_l("诺雅", C_NOYA, "塞拉斯大人……！"))
	return lines


func _silas_fight(foe_id: String) -> Array:
	if foe_id == "noya":
		return [_l("塞拉斯", C_SILAS, "诺雅，退下。……我不想对你举枪。")]
	if foe_id == "tia":
		return [_l("塞拉斯", C_SILAS, "巫女。……如果你能打赢我，也许你说的是对的。")]
	return [_l("塞拉斯", C_SILAS, "审判官的职责，是守住这座桥。……来吧。")]


func _silas_death() -> Array:
	var lines: Array = [
		_l("塞拉斯", C_SILAS, "……这样也好。追了一辈子异端……最后……"),
		_l("塞拉斯", C_SILAS, "审判所书库……第三排……八百年前的卷宗……去读……"),
	]
	if _here("noya"):
		lines.append(_l("诺雅", C_NOYA, "塞拉斯大人——！"))
	return lines


func _seven_appears() -> Array:
	var spared: bool = Campaign.flags.get("seven_16_spared", false)
	var lines: Array = [
		_l("", C_NARR, "审判所的大门里，灰色的身影走了出来。"),
		_l("七号", C_SEVEN, "……巫女。回来。"),
		_l("缇娅", C_TIA, "七号……！"),
	]
	if spared:
		lines.append(_l("缇娅", C_TIA, "地牢里你没有杀我，塔下你站了七个晚上。……这次，你是来抓我的吗？"))
	else:
		lines.append(_l("缇娅", C_TIA, "塔下你站了七个晚上。……这次，你是来抓我的吗？"))
	lines.append(_l("七号", C_SEVEN, "……命令。"))
	lines.append(_l("艾德里克", C_EDRIC, "她和神殿那次一样，伤得重了就会退。……缇娅，你想和她说话的话，走到她旁边去。"))
	return lines


func _seven_vs_tia() -> Array:
	return [
		_l("七号", C_SEVEN, "……为什么不躲。"),
		_l("缇娅", C_TIA, "因为你的爪子，每次都慢半拍。"),
	]


func _seven_talk() -> Array:
	var lines: Array = [
		_l("缇娅", C_TIA, "七号。……你想让我回去吗？"),
		_l("七号", C_SEVEN, "……命令是，带你回去。"),
		_l("缇娅", C_TIA, "我没问命令。我问的是你。"),
		_l("七号", C_SEVEN, "……"),
		_l("", C_NARR, "七号的面具上，「咔」地裂开一道缝。灰烬从缝里簌簌地往下落。"),
		_l("", C_NARR, "面具下面，是一张和缇娅差不多年纪的、少女的脸。"),
		_l("七号", C_SEVEN, "……不知道。"),
		_l("七号", C_SEVEN, "塔下面……你在里面的时候，火很亮。我站在外面，觉得……不冷。"),
		_l("缇娅", C_TIA, "那你就是「想」。傀儡不会觉得冷，也不会觉得不冷。"),
		_l("七号", C_SEVEN, "……想。"),
		_l("", C_NARR, "七号捂住裂开的面具，后退了一步，又一步。"),
		_l("七号", C_SEVEN, "……下次见面之前，告诉我。火，到底是什么。"),
	]
	return lines


func _seven_retreats() -> Array:
	if flags.get("seven_tia", false):
		return [
			_l("七号", C_SEVEN, "……又是这团火。为什么……打不下去……"),
			_l("", C_NARR, "七号退回了审判所的阴影里。"),
		]
	return [
		_l("七号", C_SEVEN, "……任务，中止。"),
		_l("", C_NARR, "七号退回了审判所的阴影里。"),
	]


func _boss() -> Array:
	return [
		_l("维尔纳", C_BOSS, "审判所里，只有一种声音——教会的声音。"),
		_l("维尔纳", C_BOSS, "八百年来，所有质疑这声音的人，都在这里认了罪。你们也会。"),
	]


func _boss_death() -> Array:
	return [
		_l("维尔纳", C_BOSS, "大司祭大人……八百年的……圣典……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "审判所的王座空了。钟楼上的钟，再也没有响起。"),
	]
	if flags.get("silas_joined", false):
		lines.append_array([
			_l("塞拉斯", C_SILAS, "审判所书库里的卷宗，只是抄本。真正的历史……刻在北方雪山的英灵廊。"),
			_l("塞拉斯", C_SILAS, "八英雄的墓碑上，刻着当年的事。守墓人是八英雄的后裔——欧文。"),
		])
	elif _here("victor"):
		lines.append_array([
			_l("维克多", C_VICTOR, "塞拉斯桌上的卷宗……有一页被人重抄过。旁边批着一行字：「原文见英灵廊」。"),
			_l("维克多", C_VICTOR, "英灵廊——北方雪山，八英雄的墓。真正的历史，刻在那里的墓碑上。"),
		])
	else:
		lines.append_array([
			_l("艾德里克", C_EDRIC, "审判官的桌上，摊着一本卷宗。旁边批着一行字：「原文见英灵廊」。"),
			_l("艾德里克", C_EDRIC, "英灵廊——北方雪山，八英雄的墓。真正的历史，就刻在那里。"),
		])
	lines.append_array([
		_l("加雷斯", C_GARETH, "往北走？满月只剩六天了。"),
		_l("缇娅", C_TIA, "……去。莫尔甘要用我的血开门。我至少得知道，那扇门后面关着的到底是什么。"),
	])
	if flags.get("seven_talked", false):
		lines.append(_l("缇娅", C_TIA, "（还有……下次见面之前，我得想好怎么回答她。火，到底是什么。）"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "holy", "from": "", "lines": [
		_moon(6),
		_l("", CB_NARR, "救回缇娅的第二天，一行人从西门攻进了圣都内城。"),
		_l("", CB_NARR, "审判所——教会审了八百年「异端」的地方。"),
	]}


func epilogue() -> Array:
	var seven: Array = [
		_l("", CB_NARR, "神殿最深处。七号对着一盆水，看着自己裂开的面具。"),
		_l("七号", CB_SEVEN, "……少女的脸。"),
		_l("七号", CB_SEVEN, "这是……谁的脸？"),
	]
	if Campaign.flags.get("seven_24_talked", false):
		seven.append(_l("七号", CB_SEVEN, "她说，那就是「想」。……想。"))
	return [
		{"title": "圣焰神殿 · 大司祭的书房", "mood": "church", "lines": [
			_l("莫尔甘", CB_MORGAN, "审判所丢了。……塞拉斯，你终究读了那一页。"),
			_l("渡鸦", C_ENEMY, "大司祭大人，灰袍众随时听候吩咐。"),
			_l("莫尔甘", CB_MORGAN, "渡鸦，去北方。英灵廊里那几块旧石头，烧干净。"),
			_l("莫尔甘", CB_MORGAN, "八百年前我没来得及刮掉的字，这次一个也别留下。"),
		]},
		{"title": "圣焰神殿 · 最深处", "mood": "dungeon", "lines": seven},
	]
