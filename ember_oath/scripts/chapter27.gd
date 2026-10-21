class_name Chapter27
extends Part3Chapter
## 第二十七章「灰烬之心」：从黑石地牢最深处通往神殿的灰烬回廊。七号守在熔岩裂谷的桥头，零号守着出口。
## 开场判定七号的三步条件（第 16 章不击杀 / 第 24 章对话 / 第 26 章对话且未击杀，见 Part3Chapter.seven_ready）：
##   - 都达成：第 2 回合开始，莫尔甘命令七号杀了巫女，七号转身倒戈，入队（seven_joined）。
##   - 否则：七号是敌将，被击败就死去；章末还活着的话，莫尔甘烧掉她的核（seven_dead）。
## 胜利：击败零号。败北：三主角阵亡。

const CHAPTER_TITLE := "第二十七章 · 灰烬之心"
const VICTORY_TITLE := "第二十七章 · 完"
const VICTORY_SUB := "灰是火烧完剩下的东西。可灰里面，还藏着一点火。"
const DEFEAT_SUB := "灰烬回廊里，又多了一捧灰……"
const BG := ""

## 36×22。从黑石地牢最深处通往圣焰神殿的地下长廊。西边出发；中路过熔岩裂谷上的石桥（七号守在桥头），进中段大厅；
## 北边上层、南边下层各有一条绕远的长廊。东边是出口大厅，零号守在通往神殿的门前。
const MAP := [
	"####################################",
	"####################################",
	"####SSSSSZSSSSSSSSSSSZSSSSSSSSSS####",
	"####SSSSSSSSSZSSSSSSSSSSSSSZSSSS####",
	"####SS##################S#####SS####",
	"####SS#########EEEEESSSSSSSSSSSSSSS#",
	"####SS#########EEEEESSSSSSSSSSSSSSS#",
	"####SS#########EEEEESSISSISSSSISSIS#",
	"#SSSSSSSS######EEEEESSSSSSSSSSSSSSS#",
	"#SSSSSSSS######EEEEESSSSSSZSSSSSSSS#",
	"#SSSSSSSSSSSSSSBBBBBSSSSSSSSSESSSSSG",
	"#SSSSSSSSSSSSSSBBBBBSSSESSSSSSSSSSSG",
	"#SSSSSSSSSSSSSSEEEEESSSSSSSSSESSSSS#",
	"#SSSSSSSS######EEEEESZSSSSSSSSSSSSS#",
	"#SSSSSSSS######EEEEESSSSSSSSSSISSIS#",
	"####SS#########EEEEESSISSISSSSSSSSS#",
	"####SS#########EEEEESSSSZSSSSSSSSSS#",
	"####SS##############SSSSSSSSSSSSSSS#",
	"####SSSSSSSSSSZSSSSSSSSSSSSSZSSS####",
	"####SSSSSSZSSSSSSSSSSSZSSSSSSSSS####",
	"####################################",
	"####################################",
]

const LEVELS := []                # 全图同一高度

const SEVEN_POS := Vector2i(21, 10)

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "faction": "player", "pos": Vector2i(4, 11)},
	{"id": "tia", "faction": "player", "pos": Vector2i(4, 10)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(4, 12)},
	{"id": "silas", "faction": "player", "pos": Vector2i(3, 10)},
	{"id": "owen", "faction": "player", "pos": Vector2i(3, 11)},
	{"id": "balto", "faction": "player", "pos": Vector2i(3, 12)},
	{"id": "orion", "faction": "player", "pos": Vector2i(2, 11)},
	{"id": "lilith", "faction": "player", "pos": Vector2i(2, 10)},
	{"id": "vera", "faction": "player", "pos": Vector2i(2, 12)},
	{"id": "noya", "faction": "player", "pos": Vector2i(5, 11)},
	# 七号：守在石桥东头（分支在 on_battle_start 里定）
	{"id": "seven", "name": "七号", "class": "灰烬傀儡", "faction": "enemy", "level": 18, "boss": true, "hold": true,
		"hp": 55, "pwr": 20, "skl": 20, "spd": 24, "dfn": 16, "res": 12, "mov": 6,
		"weapons": ["ash_claw"], "pos": Vector2i(21, 10)},
	# 中路
	{"id": "puppet1", "pos": Vector2i(10, 11), "hold": true},
	{"id": "puppet2", "pos": Vector2i(13, 10), "hold": true},
	{"id": "puppet3", "pos": Vector2i(13, 12), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(12, 11), "hold": true},
	{"id": "sniper1", "pos": Vector2i(20, 8), "hold": true},
	{"id": "sniper2", "pos": Vector2i(20, 14), "hold": true},
	{"id": "general1", "pos": Vector2i(23, 6), "hold": true},
	{"id": "sage1", "pos": Vector2i(26, 12), "hold": true},
	{"id": "puppet4", "pos": Vector2i(24, 13), "hold": true},
	# 北路、南路
	{"id": "myrm1", "pos": Vector2i(8, 3), "hold": true},
	{"id": "puppet5", "pos": Vector2i(18, 2), "hold": true},
	{"id": "graycloak1", "pos": Vector2i(28, 2), "hold": true},
	{"id": "myrm2", "pos": Vector2i(8, 18), "hold": true},
	{"id": "puppet6", "pos": Vector2i(18, 19), "hold": true},
	{"id": "graycloak2", "pos": Vector2i(28, 19), "hold": true},
	# 出口大厅
	{"id": "paladin1", "pos": Vector2i(30, 9), "hold": true},
	{"id": "paladin2", "pos": Vector2i(30, 13), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(32, 6), "hold": true},
	{"id": "cleric1", "pos": Vector2i(32, 16)},
	{"id": "general2", "pos": Vector2i(34, 9), "hold": true},
	{"id": "general3", "pos": Vector2i(34, 12), "hold": true},
	# 零号：莫尔甘造的第一具傀儡
	{"id": "zero", "name": "零号", "class": "灰烬傀儡", "faction": "enemy", "level": 20,
		"hp": 70, "pwr": 24, "skl": 16, "spd": 14, "dfn": 22, "res": 10, "mov": 5,
		"weapons": ["ash_claw", "tomahawk"], "items": ["elixir"], "boss": true, "stationary": true,
		"pos": Vector2i(33, 11), "color": Color(0.30, 0.28, 0.30),
		"hair": "hood", "hair_color": Color(0.20, 0.20, 0.22), "armor": Color(0.26, 0.24, 0.28)},
]

## 第 3、5、7 回合：裂缝里爬出傀儡（北路、南路、中段大厅）
const WAVES := {
	3: [{"id": "puppet_r1", "pos": Vector2i(6, 2)}, {"id": "puppet_r2", "pos": Vector2i(6, 19)}],
	5: [{"id": "puppet_r3", "pos": Vector2i(31, 2)}, {"id": "puppet_r4", "pos": Vector2i(31, 19)}, {"id": "darkmage_r1", "pos": Vector2i(24, 4)}],
	7: [{"id": "puppet_r5", "pos": Vector2i(20, 6)}, {"id": "puppet_r6", "pos": Vector2i(20, 16)}, {"id": "sniper_r1", "pos": Vector2i(24, 17)}],
}

const DEPLOY := [Vector2i(2, 9), Vector2i(2, 13), Vector2i(3, 9), Vector2i(3, 13), Vector2i(4, 9), Vector2i(4, 13),
	Vector2i(5, 10), Vector2i(5, 12), Vector2i(1, 10), Vector2i(1, 11), Vector2i(1, 12), Vector2i(6, 11)]


func chapter_id() -> String:
	return "ch27"


func stage() -> int:
	return 4


func deploy_limit() -> int:
	return 11


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func foes() -> Dictionary:
	return {
		"puppet": foe("puppet", 20, {"hp": 48}), "darkmage": foe("darkmage", 20, {"weapons": ["nosferatu"]}),
		"sniper": foe("sniper", 9), "general": foe("general", 10), "sage": foe("sage", 10),
		"myrm": foe("myrm", 10), "graycloak": foe("graycloak", 9, {"weapons": ["steel_sword"]}), "paladin": foe("paladin", 10), "cleric": foe("cleric", 9),
	}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "silver_sword", "killing_edge", "silver_lance", "silver_axe", "silver_bow", "bolganone",
		"divine", "fenrir", "mend_staff"]


func is_won() -> bool:
	var z = battle.get_unit("zero")
	return z != null and not z.is_alive()


func win_condition() -> String:
	return tr("击败零号")


func _joining() -> bool:
	return flags.get("seven_path", "") == "join"


# ==================== 事件 ====================

func on_battle_start() -> void:
	flags["seven_path"] = "join" if seven_ready() else "foe"
	# 会倒戈的七号：第 1 回合先站在一边（中立，打不到），第 2 回合开始的剧情里转为我方
	var s = battle.get_unit("seven")
	if _joining() and s != null:
		s.faction = "npc"
		s.queue_redraw()
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if t == 2 and _joining() and not flags.get("seven_turned", false):
		await _seven_turns()
	if _wave(t, WAVES):
		if t == 3:
			await battle.play_dialogue(_wave3())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


## 七号倒戈：敌方的七号退场，换成同伴数值的七号站在原地
func _seven_turns() -> void:
	flags["seven_turned"] = true
	await battle.play_dialogue(_awakening())
	var old = battle.get_unit("seven")
	var pos: Vector2i = SEVEN_POS
	if old != null:
		pos = old.grid_pos
		battle.units.erase(old)
		old.queue_free()
	var d: Dictionary = member("seven", 0)
	d["id"] = "seven"
	var s = battle.join_unit(d, pos)
	if s != null:
		s.has_acted = false
		s.queue_redraw()
	Campaign.flags["seven_joined"] = true
	Audio.play_sfx("awaken")
	battle.show_banner(tr("七号 成为同伴了！"), Color(0.85, 0.8, 0.9))
	await battle.play_dialogue(_after_turn())


func on_before_combat(att, def) -> void:
	var ids := [att.unit_id, def.unit_id]
	if "zero" in ids and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "zero" else att
		await battle.play_dialogue(_boss(other.unit_id))
	if "seven" in ids and not _joining() and not (att.is_player() and def.is_player()):
		var other2 = def if att.unit_id == "seven" else att
		if other2.unit_id == "tia" and not flags.get("seven_tia", false):
			flags["seven_tia"] = true
			await battle.play_dialogue(_seven_vs_tia())
		elif not flags.get("seven_first", false):
			flags["seven_first"] = true
			await battle.play_dialogue(_seven_foe_first())


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var z = battle.get_unit("zero")
	if z != null and not z.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())
	var s = battle.get_unit("seven")
	if not _joining() and s != null and not s.is_alive() and not s.is_player() and not flags.get("seven_dead", false):
		flags["seven_dead"] = true
		await battle.play_dialogue(_seven_dies(false))


func talks() -> Array:
	return [["tia", "seven", "tia_seven_27"], ["lilith", "seven", "lilith_seven_27"]]


func talk_lines(key: String) -> Array:
	if key == "tia_seven_27":
		return [
			_l("缇娅", C_TIA, "七号。……你的手，还在抖吗？"),
			_l("七号", C_SEVEN, "不抖了。……可是这里，在响。"),
			_l("", C_NARR, "七号把手按在胸口。灰烬下面，有什么东西一下一下地跳着。"),
			_l("缇娅", C_TIA, "那叫心跳。……欢迎回来。"),
			_l("七号", C_SEVEN, "我没有来过。怎么会是「回来」。"),
			_l("缇娅", C_TIA, "回到你自己这里来。"),
		]
	return [
		_l("莉莉丝", C_LILITH, "七号。你从我的门口路过了一百多次。"),
		_l("七号", C_SEVEN, "……一百三十一次。"),
		_l("莉莉丝", C_LILITH, "你数了？"),
		_l("七号", C_SEVEN, "每次路过，都想问你冷不冷。……第一百三十一次，才问出口。"),
		_l("莉莉丝", C_LILITH, "那我现在回答你：不冷了。……你呢？"),
		_l("七号", C_SEVEN, "……我也是。"),
	]


func on_victory() -> void:
	if not _joining():
		var s = battle.get_unit("seven")
		if s != null and s.is_alive() and not s.is_player():
			# 章末还活着：莫尔甘烧掉她的核，她在缇娅怀里化成灰
			await battle.play_dialogue(_seven_dies(true))
			battle.units.erase(s)
			s.queue_free()
		flags["seven_dead"] = true
	await battle.play_dialogue(_post_battle())
	Campaign.flags["seven_joined"] = _joining()
	Campaign.flags["seven_dead"] = not _joining()


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "灰烬回廊。从黑石地牢的最深处，一直通到圣焰神殿的地底。"),
		_l("", C_NARR, "两边的石壁里渗着熔岩的光。脚下的灰，踩上去是温的。"),
		_l("", C_NARR, "裂谷上的石桥那头，一个灰色的身影静静地站着。"),
		_l("缇娅", C_TIA, "……七号。"),
		_l("七号", C_SEVEN, "……"),
		_l("零号", C_BOSS, "……七……号……排除……入侵者……"),
		_l("艾德里克", C_EDRIC, "回廊尽头那个巨大的……也是傀儡？"),
	]
	if _here("lilith"):
		lines.append(_l("莉莉丝", C_LILITH, "零号。大司祭造的第一具傀儡。……听说他最早，是想给自己用的。"))
	elif _here("owen"):
		lines.append(_l("欧文", C_OWEN, "持杖者的笔记里画过它。「最初之灰」——大司祭的第一具身体。"))
	if _joining():
		lines.append(_l("缇娅", C_TIA, "七号……这次，你会怎么做？"))
	else:
		lines.append(_l("七号", C_SEVEN, "命令：排除。……排除。"))
		lines.append(_l("缇娅", C_TIA, "七号，你的声音……和之前不一样了。"))
	return lines


func _awakening() -> Array:
	return [
		_l("", C_NARR, "回廊里忽然响起一个声音。不是从哪里传来的——是从灰里，从每一粒灰里。"),
		_l("莫尔甘", C_MORGAN, "七号。杀了巫女。"),
		_l("七号", C_SEVEN, "……"),
		_l("莫尔甘", C_MORGAN, "这是最后一次命令。杀了她，把她的血带到封印台来。"),
		_l("七号", C_SEVEN, "……缇娅。你说过，火本身没有好坏。看它为什么而烧。"),
		_l("缇娅", C_TIA, "……嗯。"),
		_l("七号", C_SEVEN, "那我也想知道，我这堆灰……还能为什么而烧。"),
		_l("", C_NARR, "七号转过身。灰烬之爪，对准了身后的傀儡。"),
		_l("莫尔甘", C_MORGAN, "……你想清楚了？背叛我，你的核撑不过三天。"),
		_l("七号", C_SEVEN, "三天，够了。……命令，拒绝。"),
	]


func _after_turn() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "七号……！"),
		_l("七号", C_SEVEN, "桥那头的傀儡交给我。……你们去打零号。"),
		_l("加雷斯", C_GARETH, "哈！这下好了，敌人的王牌跑到我们这边来了！"),
	]


func _turn2_hint() -> Array:
	if _joining():
		return [_l("艾德里克", C_EDRIC, "目标是回廊尽头的零号。北边、南边的长廊绕得远，但敌人少。")]
	return [
		_l("艾德里克", C_EDRIC, "目标是回廊尽头的零号。七号守在桥头……北边、南边的长廊可以绕过去。"),
		_l("缇娅", C_TIA, "……七号的事，交给我。"),
	]


func _wave3() -> Array:
	return [
		_l("", C_NARR, "石壁上的裂缝里，灰色的手一只一只地伸了出来。"),
	]


func _seven_vs_tia() -> Array:
	if Campaign.flags.get("seven_26_killed", false):
		return [
			_l("缇娅", C_TIA, "七号！是我，缇娅！你还记得吗——塔下面，你问我火烫不烫！"),
			_l("七号", C_SEVEN, "……不认识。排除。"),
			_l("缇娅", C_TIA, "……碎掉的时候，连记得的东西也一起碎了吗。"),
		]
	return [
		_l("七号", C_SEVEN, "缇娅……躲开。我……停不下来。"),
		_l("缇娅", C_TIA, "那就让我来停下你。"),
	]


func _seven_foe_first() -> Array:
	return [
		_l("七号", C_SEVEN, "……排除。"),
	]


func _seven_dies(by_morgan: bool) -> Array:
	var lines: Array = []
	if by_morgan:
		lines.append_array([
			_l("", C_NARR, "零号倒下的同时，七号的身体里亮起了白色的火。"),
			_l("莫尔甘", C_MORGAN, "没用的东西，就该回到灰里去。"),
		])
	lines.append_array([
		_l("", C_NARR, "七号的身体，从指尖开始，一点一点地散成了灰。"),
		_l("缇娅", C_TIA, "七号！"),
	])
	if Campaign.flags.get("seven_26_killed", false):
		lines.append(_l("七号", C_SEVEN, "……火。好暖。……我好像……见过……"))
	else:
		lines.append(_l("七号", C_SEVEN, "缇娅……火，到底是什么……我还是……不知道……"))
	lines.append_array([
		_l("缇娅", C_TIA, "是暖的东西。……是暖的东西啊。"),
		_l("", C_NARR, "缇娅伸出手，只接住了一捧温热的灰。"),
	])
	return lines


func _boss(foe_id: String) -> Array:
	var lines: Array = [
		_l("零号", C_BOSS, "……我……是……最初的……灰……"),
	]
	if foe_id == "seven":
		lines.append(_l("七号", C_SEVEN, "……零号。你也曾经，有过名字吗？"))
	return lines


func _boss_death() -> Array:
	return [
		_l("零号", C_BOSS, "……大……司……祭……我……不是……你的……身体……"),
		_l("", C_NARR, "巨大的傀儡塌成了一座灰山。灰山下面，露出了通往神殿的门。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "灰烬回廊安静了下来。神殿的门，就在眼前。"),
	]
	if _joining():
		lines.append_array([
			_l("七号", C_SEVEN, "莫尔甘说，我的核撑不过三天。"),
			_l("缇娅", C_TIA, "那就在三天里打倒他。……然后，再想办法让你撑下去。"),
			_l("七号", C_SEVEN, "……为什么，你们会为了一堆灰想办法。"),
			_l("加雷斯", C_GARETH, "因为你刚才救了我两次。布罗登人欠的情，从来不赖账。"),
		])
		if _here("lilith"):
			lines.append(_l("莉莉丝", C_LILITH, "我的灰停在肩膀，你的灰装着一颗心。……我们两个次品，凑一起刚好一个人。"))
	else:
		lines.append(_l("缇娅", C_TIA, "……"))
		if _here("balto"):
			lines.append(_l("巴尔托", C_BALTO, "丫头。"))
		lines.append_array([
			_l("缇娅", C_TIA, "我没事。……我只是在想，要是我早一点，再早一点和她说话……"),
			_l("艾德里克", C_EDRIC, "缇娅。她最后，是看着你的。"),
		])
	lines.append(_l("艾德里克", C_EDRIC, "门后面是神殿的外环——书库。被刮掉的名字，一定在那里。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "temple", "from": "prison", "lines": [
		_moon(3),
		_l("", CB_NARR, "黑石地牢的最深处，有一条灰铺成的路，一直通到圣焰神殿的地底。"),
		_l("", CB_NARR, "路上守着的，是莫尔甘最好的作品——还有他最早的作品。"),
	]}


func epilogue() -> Array:
	if Campaign.flags.get("seven_joined", false):
		return [
			{"title": "灰烬回廊 · 营火", "mood": "camp", "lines": [
				_l("", CB_NARR, "回廊出口的岩洞里，一行人点起了营火。"),
				_l("", CB_NARR, "七号坐得离火最远。缇娅端着一碗汤，坐到了她旁边。"),
				_l("缇娅", C_TIA, "喝吗？"),
				_l("七号", CB_SEVEN, "……傀儡不用吃东西。"),
				_l("缇娅", C_TIA, "那就捧着。暖手。"),
				_l("七号", CB_SEVEN, "……"),
				_l("七号", CB_SEVEN, "我的心，是灰做的。……可它在跳。"),
			]},
		]
	return [
		{"title": "灰烬回廊 · 营火", "mood": "camp", "lines": [
			_l("", CB_NARR, "回廊出口的岩洞里，一行人点起了营火。"),
			_l("", CB_NARR, "缇娅把一个小布袋挂在了脖子上。里面装着一捧灰。"),
			_l("缇娅", C_TIA, "……一起去吧。去看看，火到底是什么。"),
		]},
	]
