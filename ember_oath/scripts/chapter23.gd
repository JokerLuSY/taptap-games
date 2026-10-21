class_name Chapter23
extends Part3Chapter
## 第二十三章「灰岩的义勇兵」（第三篇开篇）：缇娅被关在圣都西门外的净火塔，教会每天用圣火「净化」她的血，等满月。
## 盗贼或带钥匙的人打开塔顶牢门，任何我方走到缇娅身边【对话】→ 缇娅回队（rejoin_unit，自动补等级）。
## 第 2 回合巴尔托、哈洛、托比带着灰岩村义勇兵从西边山路赶来（不占出击名额），老弓手奥瑞恩随行入队。
## 胜利：救出缇娅，并击败城防司令赫克托。败北：艾德里克、加雷斯阵亡（救出后缇娅也算）。

const CHAPTER_TITLE := "第二十三章 · 灰岩的义勇兵"
const VICTORY_TITLE := "第二十三章 · 完"
const VICTORY_SUB := "灰岩村的人，从来不丢下自己人。"
const DEFEAT_SUB := "净火塔的圣火，烧到了满月……"
const BG := ""

## 34×24。西南城郊出发，运河（~）横穿，西桥 / 中桥 / 东桥三座桥（中间还有一处浅滩）；北岸大路通向东边的圣都西门。
## 北边是净火塔的院子（院门 G，赫克托守着），塔顶牢房的牢门 O 后面关着缇娅。巴尔托一行第 2 回合从西边山路赶来。
const MAP := [
	"....F......###############.....#SS",
	"......FF...#SSS#ISSSI#SSS#..F..#SS",
	"...h.FFFFFF#SIS#SSSSS#SIS#.FFF.#SS",
	"..hhhhFF...#SSS#SSSSS#SSS#.FFF.#SS",
	"..hhhhFF...#SSS###O###SSS#.FF.F#SS",
	".hhhh......#SSSSSSSSSSSSS#..FF.#SS",
	".F.F.......#SISSSSSSSSSIS#.FFF.#SS",
	"...........#SSSISSSSSISSS#..F..#SS",
	"......F....#SSSSSSSSSSSSS#.....#SS",
	"...........#######G#######.....#SS",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR#SS",
	"....F.RFFh......RR........R...RGSS",
	"......Rhhhhh....RR...hhh..R...RGSS",
	"......R.........RR....h...R.F..#SS",
	"~~~~~~B~~~~w~~~~BB~~~~~~~~B~~~~#SS",
	"......RF.F.F....RR......F.R....#SS",
	"...H..R.FF......RR........Rfff.#SS",
	"......RFD....D..RR..D.....RfffF#SS",
	"......R.FY..V.F.RR........Rfff.#SS",
	".F..RRRRRRRRRRRRRRRRRRRRRRR...F#SS",
	".FF.R.F.ffffff.....ffff.H.F..DF#SS",
	"FF.FR.FFffffff...FFffff...F..FF#SS",
	"FFF.R...ffffff.....ffff.F....FF#SS",
	".F..R................FF.......F#SS",
]

const LEVELS := []                # 全图同一高度

const TIA_CELL := Vector2i(18, 2)
const CELL_DOOR := Vector2i(18, 4)
const VISIT_WEST := Vector2i(3, 16)
const VISIT_EAST := Vector2i(24, 20)
const ARRIVE := [Vector2i(0, 9), Vector2i(0, 10), Vector2i(1, 9), Vector2i(1, 10)]

const UNITS := [
	# 我方（名单为空的单章测试用；缇娅不在这里——她关在塔里）
	{"id": "edric", "faction": "player", "pos": Vector2i(4, 21)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(5, 21)},
	{"id": "vera", "faction": "player", "pos": Vector2i(3, 21)},
	{"id": "kain", "faction": "player", "pos": Vector2i(4, 22)},
	{"id": "noya", "faction": "player", "pos": Vector2i(5, 22)},
	{"id": "selene", "faction": "player", "pos": Vector2i(3, 22)},
	{"id": "liss", "faction": "player", "pos": Vector2i(5, 20)},
	{"id": "ivy", "faction": "player", "pos": Vector2i(3, 20)},
	{"id": "rock", "faction": "player", "pos": Vector2i(4, 20)},
	# 南岸
	{"id": "soldier1", "pos": Vector2i(10, 19)},
	{"id": "knight1", "pos": Vector2i(14, 18)},
	{"id": "archer1", "pos": Vector2i(12, 16), "hold": true},
	# 三座桥
	{"id": "armor1", "pos": Vector2i(16, 13), "hold": true},
	{"id": "armor2", "pos": Vector2i(17, 13), "hold": true},
	{"id": "archer2", "pos": Vector2i(15, 12), "hold": true},
	{"id": "mage1", "pos": Vector2i(19, 12), "hold": true},
	{"id": "soldier2", "pos": Vector2i(6, 13), "hold": true},
	{"id": "knight2", "pos": Vector2i(7, 12)},
	{"id": "soldier3", "pos": Vector2i(26, 13), "hold": true},
	{"id": "archer3", "pos": Vector2i(27, 12), "hold": true},
	# 北岸大路
	{"id": "paladin1", "pos": Vector2i(10, 10)},
	{"id": "knight3", "pos": Vector2i(23, 11)},
	{"id": "sniper1", "pos": Vector2i(13, 11), "hold": true},
	{"id": "general1", "pos": Vector2i(17, 10), "hold": true},
	# 净火塔院内
	{"id": "puppet1", "pos": Vector2i(14, 6), "hold": true},
	{"id": "puppet2", "pos": Vector2i(22, 6), "hold": true},
	{"id": "sage1", "pos": Vector2i(16, 7), "hold": true},
	{"id": "cleric1", "pos": Vector2i(20, 7)},
	{"id": "darkmage1", "pos": Vector2i(13, 3), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(23, 3), "hold": true, "items": ["door_key"]},
	# 西门
	{"id": "paladin2", "pos": Vector2i(29, 11), "hold": true},
	{"id": "soldier4", "pos": Vector2i(29, 13), "hold": true, "items": ["vulnerary"]},
	# 赫克托：圣都城防司令，守在净火塔院门
	{"id": "hector", "name": "赫克托", "class": "将军", "faction": "enemy", "level": 11,
		"hp": 58, "pwr": 22, "skl": 15, "spd": 10, "dfn": 25, "res": 11, "mov": 5,
		"weapons": ["silver_lance", "steel_axe"], "items": ["elixir"], "boss": true, "stationary": true,
		"pos": Vector2i(18, 9), "color": Color(0.80, 0.78, 0.84),
		"hair": "short", "hair_color": Color(0.40, 0.34, 0.28), "armor": Color(0.86, 0.84, 0.90)},
]

## 第 3 回合西门里冲出骑兵；第 5 回合塔里醒来两具傀儡；第 7 回合城墙上来了魔道士和狙击手
const WAVES := {
	3: [{"id": "paladin_r1", "pos": Vector2i(33, 11)}, {"id": "paladin_r2", "pos": Vector2i(33, 12)}, {"id": "knight_r1", "pos": Vector2i(33, 13)}],
	5: [{"id": "puppet_r1", "pos": Vector2i(16, 6)}, {"id": "puppet_r2", "pos": Vector2i(20, 6)}],
	7: [{"id": "mage_r1", "pos": Vector2i(33, 11)}, {"id": "mage_r2", "pos": Vector2i(33, 12)}, {"id": "sniper_r1", "pos": Vector2i(32, 10)}],
}

const DEPLOY := [Vector2i(6, 21), Vector2i(2, 21), Vector2i(6, 22), Vector2i(2, 22), Vector2i(6, 20), Vector2i(2, 20),
	Vector2i(7, 21), Vector2i(7, 22), Vector2i(1, 21), Vector2i(1, 22), Vector2i(3, 23), Vector2i(5, 23)]


func chapter_id() -> String:
	return "ch23"


func stage() -> int:
	return 0


func deploy_limit() -> int:
	return 10


## 缇娅还关在塔里：开场只强制艾德里克、加雷斯
func forced_ids() -> Array:
	return ["edric", "gareth"]


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func foes() -> Dictionary:
	return {
		"soldier": foe("soldier", 19), "knight": foe("knight", 20), "armor": foe("armor", 20), "archer": foe("archer", 19),
		"mage": foe("mage", 19), "darkmage": foe("darkmage", 19), "cleric": foe("cleric", 7), "puppet": foe("puppet", 19),
		"paladin": foe("paladin", 8), "general": foe("general", 8), "sage": foe("sage", 8), "sniper": foe("sniper", 7),
	}


func lose_ids() -> Array:
	if flags.get("tia_freed", false):
		return ["edric", "tia", "gareth"]
	return ["edric", "gareth"]


func lose_condition() -> String:
	if flags.get("tia_freed", false):
		return tr("艾德里克、缇娅或加雷斯阵亡")
	return tr("艾德里克或加雷斯阵亡")


func shops() -> Dictionary:
	return {
		Vector2i(9, 18): ["steel_sword", "silver_sword", "steel_lance", "silver_lance", "steel_axe", "silver_axe", "steel_bow", "silver_bow", "killer_lance"],
		Vector2i(12, 18): ["vulnerary", "elixir", "door_key", "elfire", "bolganone", "nosferatu", "shine", "mend_staff"],
	}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "silver_sword", "steel_lance", "silver_lance", "steel_axe",
		"steel_bow", "silver_bow", "elfire", "bolganone", "mend_staff"]


func is_won() -> bool:
	if not flags.get("tia_freed", false):
		return false
	var b = battle.get_unit("hector")
	return b == null or not b.is_alive()


func win_condition() -> String:
	if flags.get("tia_freed", false):
		return tr("击败城防司令赫克托")
	return tr("打开塔顶牢门救出缇娅，并击败城防司令赫克托")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())
	# 缇娅关在塔顶的牢房里（中立）：开门后谁走过去【对话】都能救出
	if battle.get_unit("tia") == null:
		battle.rejoin_unit("tia", TIA_CELL, "npc", member("tia", 0))


func on_turn_start(t: int) -> void:
	# 没带盗贼：开场把一把钥匙交给艾德里克（整备之后，按实际出击的人判断）
	if t == 1 and not flags.get("keys_given", false):
		flags["keys_given"] = true
		if not _has_thief() and not flags.get("tia_freed", false):
			await battle.play_dialogue(_keys())
			_give_keys(1)
	if t == 2 and not flags.get("volunteers", false):
		flags["volunteers"] = true
		await _volunteers_arrive()
	if _wave(t, WAVES):
		if t == 5:
			await battle.play_dialogue(_wave5())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


## 巴尔托一行从西边山路赶来：从名单回队（转幕后 / 阵亡的来不了，换替代台词），奥瑞恩随行入队
func _volunteers_arrive() -> void:
	Audio.play_sfx("reinforce")
	battle.show_banner(tr("灰岩村的义勇兵赶到了！"), Color(0.55, 0.85, 1.0))
	var slots: Array = ARRIVE.duplicate()
	var came: Array = []
	var fresh := Campaign.roster.is_empty()
	for id in ["balto", "harlo", "bandit6"]:
		var u = battle.rejoin_unit(id, slots.pop_front(), "player", member(id, 0) if fresh else {})
		if u != null:
			u.has_acted = false
			u.queue_redraw()
			came.append(id)
	var od: Dictionary = member("orion", 0)
	od["id"] = "orion"
	var o = battle.join_unit(od, slots.pop_front())
	if o != null:
		o.has_acted = false
		o.queue_redraw()
	flags["balto_back"] = "balto" in came
	flags["harlo_back"] = "harlo" in came
	await battle.play_dialogue(_volunteer_lines(came))


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_WEST:
		await battle.play_dialogue([
			_l("老人", C_NPC, "你们是去救那个红头发姑娘的？……塔里每天夜里都有火光，烧得人心里发慌。"),
			_l("老人", C_NPC, "拿着。我儿子当年是圣焰骑士，死在了教会的「圣战」里。这药，他没用上。"),
		])
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))
	elif pos == VISIT_EAST:
		await battle.play_dialogue([
			_l("铁匠", C_NPC, "这块牌子，是我年轻时候在神殿当学徒偷出来的。据说能让人「更上一层」。"),
			_l("铁匠", C_NPC, "教会的东西，拿去砸教会的门——这才叫物尽其用。"),
		])
		u.receive("hero_crest")
		battle.notify(tr("获得 勇者之证"))


func on_door(_u, pos: Vector2i) -> void:
	if pos == CELL_DOOR and _npc("tia"):
		await battle.play_dialogue(_door_open())
		battle.hint(tr("走到缇娅身边【对话】，带她出来"))


## 缇娅：开了牢门，谁走过去都能【对话】（整备界面不提示「需要谁出击」）
func recruits() -> Dictionary:
	if battle == null or battle.state == battle.S.PREP or flags.get("tia_freed", false):
		return {}
	if battle.board.tile_at(CELL_DOOR) == "O":
		return {}
	return {"tia": _player_ids()}


func recruit_lines(_target_id: String, by_id: String) -> Array:
	return _tia_freed(by_id)


func on_recruited(t, _by) -> void:
	flags["tia_freed"] = true
	t.stationary = false
	t.hold = false
	Campaign.set_status("tia", "active")
	battle._refresh_objectives()
	battle.hint(tr("救出了缇娅！击败守在院门的赫克托"))


func on_before_combat(att, def) -> void:
	if "hector" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var foe_u = def if att.unit_id == "hector" else att
		await battle.play_dialogue(_boss(foe_u.unit_id))


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "hector" and def_died:
		await battle.play_dialogue(_boss_death())
		if not flags.get("tia_freed", false):
			battle.hint(tr("还没救出缇娅！打开塔顶的牢门"))


func talks() -> Array:
	return [["balto", "tia", "balto_tia_23"], ["harlo", "tia", "harlo_tia_23"], ["orion", "balto", "orion_balto_23"]]


func talk_lines(key: String) -> Array:
	match key:
		"harlo_tia_23":
			var lines: Array = [
				_l("哈洛", C_HARLO, "缇娅姐！村子……村子重建好了！房子盖了十七间，井也挖好了！"),
				_l("缇娅", C_TIA, "十七间？……哈洛，你长高了好多。"),
			]
			if _in_story("bandit6"):
				lines.append(_l("哈洛", C_HARLO, "托比也长了！就是还那么怕疼。……我们说好了，这次要把你接回去，一起看新房子。"))
			else:
				lines.append(_l("哈洛", C_HARLO, "……托比没能等到这一天。所以这次，我一定要把你接回去，一起看新房子。"))
			lines.append(_l("缇娅", C_TIA, "嗯。一起回去。"))
			return lines
		"balto_tia_23":
			return [
				_l("缇娅", C_TIA, "……巴尔托。"),
				_l("巴尔托", C_BALTO, "瘦了。脸色也差。……那帮人没给你饭吃？"),
				_l("缇娅", C_TIA, "第一句话就是这个？你的伤呢？渡口分开的时候，你连马都上不去。"),
				_l("巴尔托", C_BALTO, "早好了。……好吧，没全好。可你被人关在塔里，老夫还在村里劈柴，那才叫要命。"),
				_l("缇娅", C_TIA, "……笨蛋。"),
				_l("巴尔托", C_BALTO, "嗯。一辈子都改不了的那种。……走吧，丫头。这次，老夫站在你后面。"),
			]
	return [
		_l("奥瑞恩", C_ORION, "老伙计，你的枪尖抖了。"),
		_l("巴尔托", C_BALTO, "是你的眼睛花了。……奥瑞恩，你本来不用来的。"),
		_l("奥瑞恩", C_ORION, "十七年前那座城，我们俩守到了最后一个人。这次换成一个丫头，我总不能缺席。"),
		_l("巴尔托", C_BALTO, "……谢了。"),
		_l("奥瑞恩", C_ORION, "等打完了，请我喝酒。灰岩村的麦酒，我在山路上听村里人吹了一路。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["tia_rescued"] = true
	Campaign.flags["tia_taken"] = false
	Campaign.flags["balto_back"] = flags.get("balto_back", false)
	Campaign.flags["harlo_back"] = flags.get("harlo_back", false)


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "圣都西门外。城郊的农田边，立着一座白色的塔——净火塔。"),
		_l("", C_NARR, "塔顶的窗口里，每天夜里都会亮起白色的火。"),
	]
	if _here("vera"):
		lines.append(_l("薇拉", C_VERA, "我的人确认过了。缇娅就关在塔顶。教会每天用圣火「净化」她的血——说是要等到满月。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "城里的线人确认过了。缇娅就关在塔顶。教会每天用圣火「净化」她的血——说是要等到满月。"))
	lines.append_array([
		_l("加雷斯", C_GARETH, "净化？说得好听。不就是放血吗。"),
		_l("艾德里克", C_EDRIC, "……还有七天。我们不等满月。现在就去把她带回来。"),
		_l("赫克托", C_BOSS, "菲恩家的小子，果然来了。大司祭大人说过，你会像飞蛾一样扑过来。"),
		_l("赫克托", C_BOSS, "圣都城防司令赫克托在此。这扇院门，你一步也过不来。"),
		_l("加雷斯", C_GARETH, "那就把门连你一起劈开。"),
	])
	return lines


func _keys() -> Array:
	if _in_story("sparrow"):
		return [
			_l("艾德里克", C_EDRIC, "没有会开锁的人……对了，小雀上次塞给我的钥匙，还剩一把。"),
			_l("艾德里克", C_EDRIC, "「教会的锁都是一个铁匠打的。」——但愿她说的是真的。"),
		]
	return [
		_l("加雷斯", C_GARETH, "塔顶的牢门没人开得了？拿着。布罗登的密探从狱卒那儿弄来的。"),
		_l("艾德里克", C_EDRIC, "……只有一把。够了。"),
	]


func _turn2_hint() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "缇娅在塔顶的牢房里。盗贼或者带钥匙的人站到牢门旁边就能【开门】。"),
		_l("艾德里克", C_EDRIC, "门开了，谁走到她身边【对话】都行。然后——打倒院门口的赫克托。"),
	]


func _volunteer_lines(came: Array) -> Array:
	var lines: Array = [
		_l("", C_NARR, "西边的山路上，扬起了一阵尘土。是一群举着农具和旧刀枪的人——灰岩村的义勇兵。"),
	]
	if "balto" in came:
		lines.append_array([
			_l("巴尔托", C_BALTO, "灰岩村的巴尔托，带着村里的人来了！"),
			_l("艾德里克", C_EDRIC, "巴尔托……缇娅的养父！听说您为她挡了一刀，伤得那么重——"),
			_l("巴尔托", C_BALTO, "你就是北山道那个小子。……长成骑士的样子了。缇娅在哪？"),
			_l("艾德里克", C_EDRIC, "塔顶。……对不起，是我没护住她。"),
			_l("巴尔托", C_BALTO, "道歉留着以后说。现在，把她带回来。"),
		])
	elif _in_story("balto"):
		if "harlo" in came:
			lines.append(_l("哈洛", C_HARLO, "巴尔托先生的伤还没好，留在山路口指挥义勇兵！他让我们先来！"))
		else:
			lines.append(_l("", C_NARR, "巴尔托的伤还没好，留在山路口指挥义勇兵。"))
	if "harlo" in came:
		lines.append(_l("哈洛", C_HARLO, "哈洛也来了！斧头磨了一整个冬天！"))
	if "bandit6" in came:
		lines.append(_l("托比", C_TOBY, "托、托比也来了！……这次我不会再躲到后面了！"))
	if came.is_empty():
		lines.append(_l("奥瑞恩", C_ORION, "灰岩村的人让我先来。……他们说，缇娅是村里的孩子，村里的人不会不管。"))
	lines.append(_l("奥瑞恩", C_ORION, "奥瑞恩。巴尔托的老战友，退役的弓手。……眼睛还没花，射得中那座塔的窗户。"))
	return lines


func _wave5() -> Array:
	return [
		_l("", C_NARR, "塔里传来锁链崩断的声音。两具灰烬傀儡从地下室走了出来。"),
		_l("赫克托", C_BOSS, "大司祭大人的「守卫」醒了。……你们的时间不多了。"),
	]


func _door_open() -> Array:
	return [
		_l("", C_NARR, "牢门开了。白色的火盆中间，红头发的少女抬起了头。"),
		_l("缇娅", C_TIA, "……这次，又是谁来了？"),
	]


func _tia_freed(by_id: String) -> Array:
	var lines: Array = []
	match by_id:
		"edric":
			lines.append_array([
				_l("艾德里克", C_EDRIC, "缇娅！"),
				_l("缇娅", C_TIA, "艾德里克……你来得太慢了。我都快被烤熟了。"),
				_l("艾德里克", C_EDRIC, "……对不起。"),
				_l("缇娅", C_TIA, "笨蛋，我开玩笑的。……谢谢你来。"),
			])
		"balto":
			lines.append_array([
				_l("缇娅", C_TIA, "巴……巴尔托？！你怎么会在这儿——你的伤！"),
				_l("巴尔托", C_BALTO, "闭嘴，跟老夫走。……教你的东西你一样没忘吧？握剑的手往下压半寸。"),
				_l("缇娅", C_TIA, "……嗯。没忘。"),
			])
		"gareth":
			lines.append_array([
				_l("加雷斯", C_GARETH, "巫女！还活着吗？"),
				_l("缇娅", C_TIA, "加雷斯……你那声音，整座塔都听见了。"),
				_l("加雷斯", C_GARETH, "那正好，让他们知道布罗登的王子来劫狱了！"),
			])
		_:
			lines.append_array([
				_l("缇娅", C_TIA, "……是你们！你们来救我了？"),
				_l("缇娅", C_TIA, "艾德里克他们也在吗？……好。那我也得出点力。"),
			])
	lines.append_array([
		_l("缇娅", C_TIA, "那个七号……每天夜里都来。站在铁栏外面，一句话也不说，就那么看着我。"),
		_l("缇娅", C_TIA, "昨天，她终于开口了。问我：「火，烫吗？」"),
		_l("缇娅", C_TIA, "……走吧。这座塔，我一刻也不想多待。"),
	])
	return lines


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	if foe_id == "tia":
		lines.append(_l("赫克托", C_BOSS, "巫女自己跑出来了？也好，省得我上楼。"))
		lines.append(_l("缇娅", C_TIA, "你每天在楼下烧火。今天，换我来烧。"))
	elif foe_id == "balto":
		lines.append(_l("赫克托", C_BOSS, "老头子，你这把年纪，不在村里等死，跑来送死？"))
		lines.append(_l("巴尔托", C_BALTO, "老夫年轻的时候，守过比这结实十倍的门。"))
	else:
		lines.append(_l("赫克托", C_BOSS, "城防司令的盾，八年来没让任何人过去。"))
	return lines


func _boss_death() -> Array:
	return [
		_l("赫克托", C_BOSS, "满月……还是会来的……你们……救不了她……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "净火塔的白火熄灭了。"),
		_l("缇娅", C_TIA, "……外面的风，原来这么冷。"),
		_l("艾德里克", C_EDRIC, "冷就对了。塔里那种火，不是你的火。"),
	]
	if _here("balto"):
		lines.append(_l("巴尔托", C_BALTO, "丫头，回去吗？村子盖好了。"))
		lines.append(_l("缇娅", C_TIA, "……还不行。莫尔甘说过，满月那天，不灭之火会醒过来。我得去看看，那团火到底想要什么。"))
		lines.append(_l("巴尔托", C_BALTO, "……就知道你会这么说。那老夫跟着。"))
	if _here("orion"):
		lines.append(_l("奥瑞恩", C_ORION, "我也跟着。巴尔托的酒还没请。"))
	lines.append_array([
		_l("加雷斯", C_GARETH, "下一站是哪？"),
		_l("艾德里克", C_EDRIC, "圣都内城，审判所。……莫尔甘在那里留了一个人看门。"),
		_l("缇娅", C_TIA, "塞拉斯。"),
	])
	if _here("noya"):
		lines.append(_l("诺雅", C_NOYA, "……塞拉斯大人。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "holy", "from": "grayrock", "lines": [
		_moon(7),
		_l("", CB_NARR, "缇娅被七号带走之后，一行人退到了圣都西边的山里。"),
		_l("", CB_NARR, "与此同时，一封信从灰岩村寄了出来。信上只有一句话：「我们来了。」"),
	]}


func epilogue() -> Array:
	return [
		{"title": "圣焰神殿 · 最深处", "mood": "dungeon", "lines": [
			_l("莫尔甘", CB_MORGAN, "巫女逃了。……七号，那天夜里你站在塔下，看见他们来了吗？"),
			_l("七号", CB_SEVEN, "……看见了。"),
			_l("莫尔甘", CB_MORGAN, "那你为什么没有动？"),
			_l("七号", CB_SEVEN, "……命令里，没有。"),
			_l("莫尔甘", CB_MORGAN, "是吗。……不要紧。七天里取的血，已经够了。"),
		]},
		{"title": "圣都 · 审判所", "mood": "church", "lines": [
			_l("", CB_NARR, "审判所的书库里，一盏灯点了一整夜。"),
			_l("塞拉斯", CB_SILAS, "「焚世之灾，起于巫女失控」……这一页的墨，比前后都新。"),
			_l("塞拉斯", CB_SILAS, "八百年前的卷宗，为什么会有人重抄过这一页？"),
			_l("", CB_NARR, "门外传来脚步声。塞拉斯合上卷宗，拿起了枪。"),
		]},
	]
