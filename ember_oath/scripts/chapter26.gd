class_name Chapter26
extends Part3Chapter
## 第二十六章「傀儡工坊」：黑石地牢最底层，造灰烬傀儡的地方。
## 莉莉丝（没被改造完的实验体，暗法师）关在东边最北的牢房：盗贼 / 钥匙开门 → 任何我方【对话】→ 她转为我方，并拉响警报（身边刷出傀儡）。
## 她要活到章末：倒下就阵亡（不卡关，只是没救下来）。没带盗贼：开场给 2 把钥匙。
## 七号第 3 回合出现（敌方，这一章打得死）：缇娅【对话】→ 七号条件第 3 步，七号撤退；被击杀 → 第 3 步失败。第 9 回合还在就自己撤走。
## 胜利：击败工坊主马库斯。败北：三主角阵亡。

const CHAPTER_TITLE := "第二十六章 · 傀儡工坊"
const VICTORY_TITLE := "第二十六章 · 完"
const VICTORY_SUB := "培养槽里的灰，终于不再往人身上爬了。"
const DEFEAT_SUB := "熔炉的火没有熄。又一具傀儡，从灰里站了起来……"
const BG := ""

## 34×24。黑石地牢最底层的傀儡工坊。南边进口大厅 → 中央熔炉大厅（火焰 E 挡在中间）；西边是培养槽大厅（碎槽 Z），
## 东边一条走廊连着三间牢房（牢门 O，最北那间关着莉莉丝，另两间有宝箱）；北边是工坊主马库斯的王座间，东西两侧各有一条小路绕过去。
const MAP := [
	"##################################",
	"###########ZSSSSSSSSSSZ###########",
	"######SSSSSSSISSKSSSISSS##########",
	"######S####SSSSSSSSSSSSS##########",
	"######S####SSISSSSSSISSS##########",
	"######S####SSSSSSSSSSSSS##########",
	"######S#########SS####SS##########",
	"######S#########SS####SS#SISSSSS##",
	"##SSSSSSSSS##ISSSSSSI#SSOSSSSSSS##",
	"##SZSZSZSZS##SSSSSSSS#SS#SISSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSS##########",
	"##SSSSSSSSS##SSEEEESS#SS#SSSSSSS##",
	"##SZSSSZSSS##SSEEEESS#SSOSSSSSSQ##",
	"##SSSSSSSSS##SSEEEESS#SS#SSSSSSS##",
	"##SSSISSSIS##SSSSSSSS#SS##########",
	"##SSSSSSSSS##SSSSSSSS#SS#SSSSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSSOSSSSSSQ##",
	"##SZSZSZSSS##SSSSSSSS#SS#SSSSSSS##",
	"##SSSSSSSSS##ISSSSSSI#SS##########",
	"###########SSSSSSSSSSSS###########",
	"###########SSSSSSSSSSSS###########",
	"###########SSSSSSSSSSSS###########",
	"###########SSSSSSSSSSSS###########",
	"################GG################",
]

const LEVELS := []                # 全图同一高度

const LILITH_DOOR := Vector2i(24, 8)
const CHESTS := {Vector2i(31, 12): "hero_crest", Vector2i(31, 16): "elixir"}
const SEVEN_LEAVES := 9
const ALARM := [{"id": "puppet_a1", "pos": Vector2i(23, 7)}, {"id": "puppet_a2", "pos": Vector2i(23, 9)},
	{"id": "puppet_a3", "pos": Vector2i(22, 11)}]

## 七号：这一章是普通的敌将（打得死）
const SEVEN := {"id": "seven", "name": "七号", "class": "灰烬傀儡", "faction": "enemy", "level": 18, "boss": true,
	"hp": 52, "pwr": 18, "skl": 18, "spd": 24, "dfn": 15, "res": 12, "mov": 6,
	"weapons": ["ash_claw"], "pos": Vector2i(17, 7), "color": Color(0.55, 0.52, 0.56),
	"hair": "ponytail", "hair_color": Color(0.80, 0.80, 0.84), "armor": Color(0.42, 0.40, 0.44)}

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "faction": "player", "pos": Vector2i(16, 21)},
	{"id": "tia", "faction": "player", "pos": Vector2i(17, 21)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(15, 21)},
	{"id": "vera", "faction": "player", "pos": Vector2i(18, 21)},
	{"id": "silas", "faction": "player", "pos": Vector2i(15, 22)},
	{"id": "owen", "faction": "player", "pos": Vector2i(16, 22)},
	{"id": "balto", "faction": "player", "pos": Vector2i(17, 22)},
	{"id": "orion", "faction": "player", "pos": Vector2i(18, 22)},
	{"id": "noya", "faction": "player", "pos": Vector2i(14, 21)},
	{"id": "kain", "faction": "player", "pos": Vector2i(19, 21)},
	# 莉莉丝：关在东边最北的牢房里（中立）
	{"id": "lilith", "faction": "npc", "stationary": true, "pos": Vector2i(30, 8)},
	# 中央熔炉大厅
	{"id": "puppet1", "pos": Vector2i(15, 17)},
	{"id": "puppet2", "pos": Vector2i(18, 17)},
	{"id": "darkmage1", "pos": Vector2i(13, 9), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(20, 9), "hold": true},
	{"id": "general1", "pos": Vector2i(16, 14), "hold": true},
	{"id": "sage1", "pos": Vector2i(14, 15), "hold": true},
	{"id": "cleric1", "pos": Vector2i(19, 15)},
	# 西边培养槽大厅
	{"id": "puppet3", "pos": Vector2i(4, 10), "hold": true},
	{"id": "puppet4", "pos": Vector2i(8, 16)},
	{"id": "sniper1", "pos": Vector2i(3, 15), "hold": true},
	{"id": "myrm1", "pos": Vector2i(9, 10), "hold": true},
	{"id": "darkmage3", "pos": Vector2i(5, 13), "hold": true},
	# 东边走廊与牢房
	{"id": "graycloak1", "pos": Vector2i(22, 9), "hold": true, "items": ["door_key"]},
	{"id": "paladin1", "pos": Vector2i(23, 14)},
	{"id": "general2", "pos": Vector2i(22, 17), "hold": true},
	{"id": "puppet5", "pos": Vector2i(27, 12), "hold": true},
	{"id": "darkmage4", "pos": Vector2i(27, 16), "hold": true},
	# 北边王座间与两侧小路
	{"id": "sage2", "pos": Vector2i(12, 2), "hold": true},
	{"id": "sniper2", "pos": Vector2i(21, 2), "hold": true},
	{"id": "general3", "pos": Vector2i(15, 4), "hold": true},
	{"id": "paladin2", "pos": Vector2i(18, 4), "hold": true},
	{"id": "myrm2", "pos": Vector2i(6, 4), "hold": true},
	{"id": "graycloak2", "pos": Vector2i(23, 4), "hold": true},
	# 工坊主马库斯：坐在王座上
	{"id": "marcus", "name": "马库斯", "class": "德鲁伊", "faction": "enemy", "level": 14,
		"hp": 52, "pwr": 23, "skl": 17, "spd": 15, "dfn": 13, "res": 22, "mov": 5,
		"weapons": ["fenrir", "nosferatu"], "items": ["elixir"], "boss": true, "stationary": true,
		"pos": Vector2i(16, 2), "color": Color(0.36, 0.30, 0.40),
		"hair": "hood", "hair_color": Color(0.60, 0.58, 0.62), "armor": Color(0.32, 0.26, 0.36)},
]

## 第 3 回合七号从王座间走出来；第 4 回合西边的培养槽裂开；第 6 回合熔炉边又醒来一批
const WAVES := {
	3: [],
	4: [{"id": "puppet_r1", "pos": Vector2i(3, 10)}, {"id": "puppet_r2", "pos": Vector2i(9, 17)}],
	6: [{"id": "puppet_r3", "pos": Vector2i(14, 9)}, {"id": "puppet_r4", "pos": Vector2i(19, 9)}, {"id": "darkmage_r1", "pos": Vector2i(16, 9)}],
}

const DEPLOY := [Vector2i(14, 22), Vector2i(19, 22), Vector2i(13, 21), Vector2i(20, 21), Vector2i(13, 22), Vector2i(20, 22),
	Vector2i(12, 21), Vector2i(21, 21), Vector2i(12, 22), Vector2i(21, 22), Vector2i(16, 20), Vector2i(17, 20)]


func chapter_id() -> String:
	return "ch26"


func stage() -> int:
	return 3


func deploy_limit() -> int:
	return 11


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func chests() -> Dictionary:
	return CHESTS


func foes() -> Dictionary:
	return {
		"puppet": foe("puppet", 20), "darkmage": foe("darkmage", 20),
		"general": foe("general", 9), "sage": foe("sage", 9), "cleric": foe("cleric", 8),
		"sniper": foe("sniper", 8), "myrm": foe("myrm", 9), "graycloak": foe("graycloak", 8, {"weapons": ["steel_sword"]}), "paladin": foe("paladin", 9),
	}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "silver_sword", "armorslayer", "silver_lance", "silver_axe", "silver_bow",
		"bolganone", "divine", "fenrir", "mend_staff"]


func is_won() -> bool:
	var b = battle.get_unit("marcus")
	return b != null and not b.is_alive()


func win_condition() -> String:
	return tr("击败工坊主马库斯")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if t == 1 and not flags.get("keys_given", false):
		flags["keys_given"] = true
		if not _has_thief():
			await battle.play_dialogue(_keys())
			_give_keys(2)
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


func on_door(_u, pos: Vector2i) -> void:
	if pos == LILITH_DOOR and _npc("lilith"):
		await battle.play_dialogue(_lilith_door())
		battle.hint(tr("走到莉莉丝身边【对话】，带她出来"))


## 莉莉丝：开门后谁都能【对话】；七号：缇娅【对话】（不改阵营，谈完撤退）
func recruits() -> Dictionary:
	if battle == null or battle.state == battle.S.PREP:
		return {}
	var out := {}
	if _npc("lilith") and battle.board.tile_at(LILITH_DOOR) != "O":
		out["lilith"] = _player_ids()
	if _seven_on_map():
		out["seven"] = ["tia"]
	return out


func recruit_lines(target_id: String, by_id: String) -> Array:
	if target_id == "lilith":
		return _lilith_freed(by_id)
	return []


func on_recruit(u) -> void:
	var t = get_recruit_target(u)
	if t == null:
		return
	if t.unit_id == "seven":
		await battle.play_dialogue(_seven_talk())
		flags["seven_talked"] = true
		Campaign.flags["seven_26_talked"] = true
		await _seven_leave(true)
		return
	await super.on_recruit(u)


func on_recruited(t, _by) -> void:
	if t.unit_id != "lilith":
		return
	t.stationary = false
	t.hold = false
	flags["lilith_freed"] = true
	# 警报：她身边的走廊里醒来三具傀儡
	battle.spawn_units(ALARM)
	Audio.play_sfx("reinforce")
	battle.show_banner(tr("警报！傀儡醒了！"), Color(1.0, 0.45, 0.35))
	await battle.play_dialogue(_alarm())
	battle.hint(tr("莉莉丝要活到章末！"))


func on_before_combat(att, def) -> void:
	var ids := [att.unit_id, def.unit_id]
	if "marcus" in ids and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "marcus" else att
		await battle.play_dialogue(_boss(other.unit_id))
	if "seven" in ids and "tia" in ids and not flags.get("seven_tia", false):
		flags["seven_tia"] = true
		await battle.play_dialogue(_seven_vs_tia())


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("marcus")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())
	var s = battle.get_unit("seven")
	if s != null and not s.is_alive() and not s.is_player() and not flags.get("seven_killed", false):
		flags["seven_killed"] = true
		flags["seven_gone"] = true
		Campaign.flags["seven_26_killed"] = true
		await battle.play_dialogue(_seven_falls())
	var l = battle.get_unit("lilith")
	if l != null and not l.is_alive() and l.is_player() and not flags.get("lilith_dead", false) and not Campaign.casual():
		flags["lilith_dead"] = true
		await battle.play_dialogue(_lilith_dies())


func _seven_on_map() -> bool:
	var s = battle.get_unit("seven")
	return s != null and s.is_alive() and s.on_map() and not s.is_player() and not s.is_npc()


func _seven_leave(talked: bool) -> void:
	var s = battle.get_unit("seven")
	if s == null or flags.get("seven_gone", false):
		return
	flags["seven_gone"] = true
	if not talked:
		await battle.play_dialogue(_seven_leaves())
	_leave_map(s)
	battle.notify(tr("七号撤退了"))


func talks() -> Array:
	return [["lilith", "owen", "lilith_owen_26"], ["tia", "lilith", "tia_lilith_26"]]


func talk_lines(key: String) -> Array:
	if key == "lilith_owen_26":
		return [
			_l("欧文", C_OWEN, "你身上的灰……还在往上爬吗？"),
			_l("莉莉丝", C_LILITH, "停在肩膀这里了。马库斯说，再泡三天培养槽，就能爬满全身。"),
			_l("欧文", C_OWEN, "我的先祖「持杖者」留下过一个方子，能让灰退回去一点。……不保证有用。"),
			_l("莉莉丝", C_LILITH, "退回去一点就够了。……一点点，也是我自己的。"),
		]
	return [
		_l("缇娅", C_TIA, "莉莉丝……那个「十二号」，是你以前的编号？"),
		_l("莉莉丝", C_LILITH, "嗯。七号是第七个「成功」的，我是第十二个「失败」的。"),
		_l("莉莉丝", C_LILITH, "可是你知道吗？她每次路过我门口，都会停一下。成功的那个，好像比失败的这个还冷。"),
		_l("缇娅", C_TIA, "……那我们得把她也带出来。"),
		_l("莉莉丝", C_LILITH, "（笑）你说得好像她是被关着的一样。……不过，也许是吧。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["lilith_saved"] = _here("lilith")
	Campaign.flags["seven_26_talked"] = flags.get("seven_talked", false)
	Campaign.flags["seven_26_killed"] = flags.get("seven_killed", false)


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "黑石地牢的最底层。比第一次来的时候更深，更热。"),
		_l("", C_NARR, "熔炉在大厅中央烧着，培养槽一排一排地立在两边。槽里泡着灰色的人影。"),
		_l("加雷斯", C_GARETH, "……这些，原来都是人？"),
	]
	if _here("victor"):
		lines.append(_l("维克多", C_VICTOR, "这里就是工坊。我在研究所的时候，只见过它的图纸。……图纸上没画这些人的脸。"))
	elif _here("owen"):
		lines.append(_l("欧文", C_OWEN, "持杖者的笔记里写过：「以灰塑身，以魂为芯。」……八百年前就有人在做这种事。"))
	lines.append_array([
		_l("马库斯", C_BOSS, "客人？真少见。工坊主马库斯，欢迎参观。"),
		_l("马库斯", C_BOSS, "东边的牢房里还有一件「次品」。你们要的话，就带走吧——要是带得走的话。"),
		_l("缇娅", C_TIA, "次品……？"),
		_l("艾德里克", C_EDRIC, "东边的牢房里有人。先把人救出来，再找他算账。"),
	])
	return lines


func _keys() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "没有会开锁的人……还好在上面的看守室里搜到了两把钥匙。"),
	]


func _turn2_hint() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "东边走廊尽头的牢房里关着人。开了门，谁走过去【对话】都行。"),
		_l("艾德里克", C_EDRIC, "救出来之后得护着她——她倒下的话，就再也救不回来了。"),
	]


func _lilith_door() -> Array:
	return [
		_l("", C_NARR, "牢门开了。角落里蜷着一个少女——右半边身子是人，左半边，是灰。"),
		_l("莉莉丝", C_LILITH, "……不是马库斯的脚步声。你们是谁？"),
	]


func _lilith_freed(by_id: String) -> Array:
	var lines: Array = []
	if by_id == "tia":
		lines.append(_l("缇娅", C_TIA, "别怕，我们是来带你出去的。我叫缇娅。"))
		lines.append(_l("莉莉丝", C_LILITH, "缇娅……红头发。七号说的「火」，就是你吧。"))
	else:
		lines.append(_l("莉莉丝", C_LILITH, "带我出去？……我这个样子，出去了也是怪物。"))
		lines.append(_l("艾德里克", C_EDRIC, "怪物不会问「我这个样子」。走吧。"))
	lines.append_array([
		_l("莉莉丝", C_LILITH, "我叫莉莉丝。在这里，他们叫我十二号。……改造做到一半，灰爬到肩膀就停了。马库斯说我是「次品」。"),
		_l("莉莉丝", C_LILITH, "我会用一点暗魔法。是灰教我的。……用它来打马库斯，正好。"),
	])
	return lines


func _alarm() -> Array:
	return [
		_l("马库斯", C_BOSS, "哎呀，次品跑出来了。把她装回去——零件坏了也没关系。"),
		_l("莉莉丝", C_LILITH, "……我不回去。死也不回去。"),
	]


func _lilith_dies() -> Array:
	return [
		_l("", C_NARR, "莉莉丝倒在了走廊上。灰从她的肩膀，慢慢爬满了全身。"),
		_l("缇娅", C_TIA, "……对不起。说好要带你出去的。"),
	]


func _seven_appears() -> Array:
	var lines: Array = [
		_l("", C_NARR, "王座间的门里，七号走了出来。裂开的面具已经换了一副新的。"),
		_l("七号", C_SEVEN, "……命令：保护工坊。排除入侵者。"),
	]
	if Campaign.flags.get("seven_24_talked", false):
		lines.append(_l("缇娅", C_TIA, "七号！上次你问我火是什么……我想好答案了。"))
		lines.append(_l("七号", C_SEVEN, "……"))
	else:
		lines.append(_l("缇娅", C_TIA, "七号……又是你。"))
	lines.append(_l("艾德里克", C_EDRIC, "这次她没有退路了。……缇娅，你想和她说话，就走到她身边去。别让别人下杀手。"))
	return lines


func _seven_vs_tia() -> Array:
	return [
		_l("七号", C_SEVEN, "……为什么。你的剑，为什么不砍要害。"),
		_l("缇娅", C_TIA, "因为我想听你说话。"),
	]


func _seven_talk() -> Array:
	var lines: Array = [
		_l("缇娅", C_TIA, "七号。你问过我，火是什么。"),
		_l("七号", C_SEVEN, "……"),
		_l("缇娅", C_TIA, "火会烧东西。会烧掉村子，会把人烧成灰。……可冬天的晚上，大家也会围着火坐在一起。"),
		_l("缇娅", C_TIA, "火本身没有好坏。看它为什么而烧。……巴尔托是这么教我的。"),
		_l("七号", C_SEVEN, "……为什么而烧。"),
		_l("七号", C_SEVEN, "我是灰。灰，是火烧完了剩下的东西。……灰，还能为什么而烧吗？"),
		_l("缇娅", C_TIA, "能。灰里面，还藏着一点没熄的火。我见过。"),
		_l("", C_NARR, "七号的手指颤了一下。灰烬之爪，一点一点地散开了。"),
		_l("七号", C_SEVEN, "……命令，保护工坊。可是……我不想保护这里。"),
		_l("七号", C_SEVEN, "缇娅。下一次……如果下一次，他让我杀你——"),
		_l("", C_NARR, "七号没有说完。她转过身，消失在了熔炉的火光后面。"),
	]
	return lines


func _seven_leaves() -> Array:
	return [
		_l("七号", C_SEVEN, "……时间到了。"),
		_l("", C_NARR, "七号退进了熔炉后面的暗处。"),
	]


func _seven_falls() -> Array:
	var lines: Array = [
		_l("七号", C_SEVEN, "……火……是……"),
		_l("", C_NARR, "七号碎成了一地的灰。"),
	]
	if _here("tia"):
		lines.append(_l("缇娅", C_TIA, "七号……！"))
	lines.append(_l("", C_NARR, "可那堆灰，像被什么东西牵着一样，慢慢流向了地牢更深的地方。"))
	return lines


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	if foe_id == "lilith":
		lines.append(_l("马库斯", C_BOSS, "十二号。你的灰，还是我亲手调的配方。"))
		lines.append(_l("莉莉丝", C_LILITH, "那你尝尝自己的配方。"))
	elif foe_id == "tia":
		lines.append(_l("马库斯", C_BOSS, "巫女的血……要是能拿来泡一泡培养槽，一定能做出比七号更好的东西。"))
	else:
		lines.append(_l("马库斯", C_BOSS, "人会老、会怕、会背叛。灰不会。……我只是在帮人类进步。"))
	return lines


func _boss_death() -> Array:
	return [
		_l("马库斯", C_BOSS, "我的……作品……七号……是我最好的……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "熔炉的火被浇灭了。培养槽一个个打开，里面的人影，大多已经没有了呼吸。"),
	]
	if _here("lilith"):
		lines.append_array([
			_l("莉莉丝", C_LILITH, "……谢谢。我以为我会在这里，一直被叫作「十二号」。"),
			_l("莉莉丝", C_LILITH, "我听马库斯说过。灰烬傀儡的技术，最早不是用来造士兵的——是大司祭给自己造身体用的。"),
			_l("艾德里克", C_EDRIC, "给自己……造身体？"),
			_l("莉莉丝", C_LILITH, "他说大司祭大人的身体，八百年来换了很多具。每一具，都是灰做的。"),
		])
	elif _here("victor"):
		lines.append_array([
			_l("维克多", C_VICTOR, "马库斯的笔记……「灰烬塑身，最早为大司祭本人所用」。"),
			_l("维克多", C_VICTOR, "大司祭的身体，是灰做的。……八百年来，他一直在给自己换身体。"),
		])
	elif _here("owen"):
		lines.append_array([
			_l("欧文", C_OWEN, "工坊主的笔记上写着：「灰烬塑身，最早为大司祭本人所用」。"),
			_l("欧文", C_OWEN, "大司祭的身体是灰做的。……刮掉的那个名字，和今天的大司祭，也许是同一个人。"),
		])
	else:
		lines.append_array([
			_l("艾德里克", C_EDRIC, "工坊主的笔记上写着：「灰烬塑身，最早为大司祭本人所用」。"),
			_l("艾德里克", C_EDRIC, "大司祭的身体是灰做的。……英灵廊上被刮掉的那个名字，和今天的大司祭，也许是同一个人。"),
		])
	if flags.get("seven_talked", false):
		lines.append(_l("缇娅", C_TIA, "……七号最后想说什么呢。「如果他让我杀你」——然后呢？"))
	elif flags.get("seven_killed", false):
		lines.append(_l("缇娅", C_TIA, "七号的灰……流到地牢更深的地方去了。她还会回来吗？"))
	lines.append(_l("艾德里克", C_EDRIC, "地牢最深处有一条通往神殿的路。灰烬回廊——莫尔甘一定在那头等着。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "prison", "from": "hero_hall", "lines": [
		_moon(4),
		_l("", CB_NARR, "从英灵廊下山，一行人再一次走进了黑石地牢。"),
		_l("", CB_NARR, "这一次，他们要去的是比埃德蒙的石室更深的地方。"),
	]}


func epilogue() -> Array:
	var lines: Array = [
		_l("莫尔甘", CB_MORGAN, "工坊没了。……马库斯是个好工匠，可惜。"),
	]
	if Campaign.flags.get("seven_26_killed", false):
		lines.append_array([
			_l("", CB_NARR, "封印台下，一堆灰慢慢聚拢，重新站成了人形。"),
			_l("莫尔甘", CB_MORGAN, "七号。这次碎得很干净——连多余的东西也一起碎掉了。"),
			_l("七号", CB_SEVEN, "……命令。"),
			_l("莫尔甘", CB_MORGAN, "很好。这才是我要的七号。"),
		])
	else:
		lines.append_array([
			_l("莫尔甘", CB_MORGAN, "七号。你又一次放走了巫女。"),
			_l("七号", CB_SEVEN, "……"),
			_l("莫尔甘", CB_MORGAN, "再迟疑一次，我就烧掉你的核。你会变回一捧普通的灰——连「七号」都不是。"),
			_l("", CB_NARR, "莫尔甘走后，七号独自站在封印台下。"),
			_l("七号", CB_SEVEN, "……名字。"),
			_l("七号", CB_SEVEN, "她叫缇娅。莉莉丝叫莉莉丝。……我，叫什么？"),
		])
	return [
		{"title": "圣焰神殿 · 封印台", "mood": "dungeon", "lines": lines},
	]
