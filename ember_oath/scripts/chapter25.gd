class_name Chapter25
extends Part3Chapter
## 第二十五章「英灵廊」（雪地）：北方雪山上八英雄的墓。灰袍众长老渡鸦奉莫尔甘之命来烧墓碑。
## 守墓人欧文（贤者，八英雄的后裔）第 1 回合在英灵廊里加入，本章他倒下即败北。
## 三块墓碑（王座 K，金框）：敌人站上去，那块墓碑就被烧毁（不败北，剧情少一句）。
## 胜利：守住 8 回合（第 9 回合开始），或击败渡鸦。败北：三主角或欧文阵亡。

const CHAPTER_TITLE := "第二十五章 · 英灵廊"
const VICTORY_TITLE := "第二十五章 · 完"
const VICTORY_SUB := "墓碑上的名字，被风雪磨了八百年，还在。"
const DEFEAT_SUB := "英灵廊的火，把八百年的字烧成了灰……"
const BG := ""
const THEME := "snow"

## 32×24（雪地）。北边是英灵廊（城堡，三块墓碑 = 王座 K，金框），廊门 G 前是台地和石阶，我方守在这里。
## 南边一条石阶路下山，中间横着一条结冰的溪（浅滩）；山脚是灰袍众的营地，长老渡鸦坐在堡垒上。敌人从南、西、东三路上来。
const MAP := [
	"MMMMMMMMM##############MMMMMMMMM",
	"MMMMMMM..#SSSSSKSSSSSS#....MMMMM",
	"MMMMMMMM.#SKSSSSSSSSKS#.MMMMMMMM",
	"MMMMMMM..#SSSISSSSISSS#....MMMMM",
	".........#SSSSSSSSSSSS#.....M...",
	".........#SISSSSSSSSIS#.........",
	".........#SSSISSSSISSS#.........",
	".........#SSSSSSSSSSSS#.........",
	".....F...######GG######...F.....",
	"...FFFFF....hhhRRhhh....FFFFF...",
	".FF.FF.F...FhhhRRhhh....FFFFFF..",
	"...FFFF........RR.......FF...F..",
	"...H.F....h....RR....h..........",
	"........hhhhh..RR...hhhh....H...",
	"..........h....RR.....F.........",
	"wwwwwwwww......RR..F...wwwwwwwww",
	"X.......wwwwwwwBBwwwwwww....FF.X",
	"X..F...........RR..............X",
	"X............F.RR.......F.....XX",
	"X..F.F.........RR.........FFFF.X",
	"XFF.FFFF.....P.RR.PF.F..FFFFF..X",
	"F.FFFFF.F...A..RR..A.....FFFFFF.",
	"....F..........TR...............",
	"...........A...RR.F.A...........",
]

const LEVELS := []                # 全图同一高度

const HOLD_TURNS := 8
const OWEN_POS := Vector2i(15, 4)
## 三块墓碑：巫女艾琳 / 「火不能被封印」/ 被刮掉的名字
const TOMBS := [Vector2i(11, 2), Vector2i(15, 1), Vector2i(20, 2)]
const VISIT_HERMIT := Vector2i(3, 12)
const VISIT_HUNTER := Vector2i(28, 13)

const UNITS := [
	# 我方：守在英灵廊门前的台地上（名单为空的单章测试用）
	{"id": "edric", "faction": "player", "pos": Vector2i(15, 10)},
	{"id": "tia", "faction": "player", "pos": Vector2i(16, 10)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(14, 9)},
	{"id": "silas", "faction": "player", "pos": Vector2i(17, 9)},
	{"id": "balto", "faction": "player", "pos": Vector2i(13, 10)},
	{"id": "orion", "faction": "player", "pos": Vector2i(18, 10)},
	{"id": "noya", "faction": "player", "pos": Vector2i(14, 11)},
	{"id": "kain", "faction": "player", "pos": Vector2i(17, 11)},
	{"id": "vera", "faction": "player", "pos": Vector2i(15, 11)},
	{"id": "rock", "faction": "player", "pos": Vector2i(16, 11)},
	# 南坡
	{"id": "graycloak1", "pos": Vector2i(8, 18)},
	{"id": "graycloak2", "pos": Vector2i(22, 18)},
	{"id": "fighter1", "pos": Vector2i(15, 19)},
	{"id": "myrm1", "pos": Vector2i(16, 19)},
	# 狙击手守着南坡不上来（长弓射程 3，追上台地就太难守了）
	{"id": "sniper1", "pos": Vector2i(11, 17), "hold": true},
	{"id": "sniper2", "pos": Vector2i(20, 17), "hold": true},
	{"id": "pegasus1", "pos": Vector2i(5, 14)},
	{"id": "pegasus2", "pos": Vector2i(26, 14)},
	{"id": "darkmage1", "pos": Vector2i(9, 21)},
	{"id": "darkmage2", "pos": Vector2i(22, 21)},
	{"id": "graycloak3", "pos": Vector2i(14, 21), "hold": true},
	{"id": "cleric1", "pos": Vector2i(17, 21)},
	# 绕后的两翼
	{"id": "graycloak4", "pos": Vector2i(3, 9)},
	{"id": "sage1", "pos": Vector2i(2, 16), "items": ["vulnerary"]},
	{"id": "myrm2", "pos": Vector2i(29, 16)},
	# 渡鸦：灰袍众长老，坐在山脚营地的堡垒上
	{"id": "raven", "name": "渡鸦", "class": "刺客", "faction": "enemy", "level": 13,
		# 数值按「主角满血吃一轮反击不会死」调：不追击 Lv20 的艾德里克，也不带高必杀的暗刃
		"hp": 50, "pwr": 18, "skl": 22, "spd": 20, "dfn": 14, "res": 12, "mov": 7,
		"weapons": ["silver_sword"], "items": ["elixir"], "boss": true, "stationary": true,
		"pos": Vector2i(15, 22), "color": Color(0.30, 0.30, 0.34),
		"hair": "hood", "hair_color": Color(0.10, 0.10, 0.12), "armor": Color(0.24, 0.24, 0.28)},
]

## 第 2 回合西边山路、第 4 回合东边、第 6 回合南边营地再出一批
const WAVES := {
	2: [{"id": "graycloak_r1", "pos": Vector2i(0, 12)}, {"id": "graycloak_r2", "pos": Vector2i(0, 13)}, {"id": "fighter_r1", "pos": Vector2i(0, 14)}],
	4: [{"id": "pegasus_r1", "pos": Vector2i(31, 11)}, {"id": "sniper_r1", "pos": Vector2i(31, 13)}],
	6: [{"id": "graycloak_r3", "pos": Vector2i(14, 23)}, {"id": "myrm_r1", "pos": Vector2i(17, 23)}, {"id": "sage_r1", "pos": Vector2i(16, 23)}],
}

const DEPLOY := [Vector2i(12, 10), Vector2i(19, 10), Vector2i(13, 9), Vector2i(18, 9), Vector2i(13, 11), Vector2i(18, 11),
	Vector2i(12, 9), Vector2i(19, 9), Vector2i(12, 11), Vector2i(19, 11), Vector2i(15, 9), Vector2i(16, 9)]


func chapter_id() -> String:
	return "ch25"


func stage() -> int:
	return 2


func deploy_limit() -> int:
	return 11


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func foes() -> Dictionary:
	return {
		"graycloak": foe("graycloak", 7, {"weapons": ["steel_sword"]}), "fighter": foe("fighter", 7), "myrm": foe("myrm", 7), "sniper": foe("sniper", 7),
		"pegasus": foe("pegasus", 6), "darkmage": foe("darkmage", 20), "cleric": foe("cleric", 8),
		"sage": foe("sage", 7),
	}


## 欧文加入后，他倒下也算败北
func lose_ids() -> Array:
	var out := ["edric", "tia", "gareth"]
	if battle != null and battle.get_unit("owen") != null and flags.get("owen_in", false):
		out.append("owen")
	return out


func lose_condition() -> String:
	return tr("艾德里克、缇娅、加雷斯或欧文阵亡")


## 还没被烧掉的墓碑（金框）
func goal_label() -> String:
	return "墓碑"


func goal_tiles() -> Array:
	var out: Array = []
	for p in TOMBS:
		if not flags.get("burned_%d_%d" % [p.x, p.y], false):
			out.append(p)
	return out


func _tombs_left() -> int:
	return goal_tiles().size()


func shop_items() -> Array:
	return ["vulnerary", "elixir", "steel_sword", "silver_sword", "silver_lance", "horseslayer", "silver_axe", "silver_bow",
		"killer_bow", "elfire", "bolganone", "divine", "mend_staff"]


func is_won() -> bool:
	var b = battle.get_unit("raven")
	if b != null and not b.is_alive():
		return true
	return battle.turn > HOLD_TURNS


func win_condition() -> String:
	return tr("守住英灵廊 %d 回合，或击败灰袍众长老渡鸦") % HOLD_TURNS


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_resume() -> void:
	for p in TOMBS:
		if flags.get("burned_%d_%d" % [p.x, p.y], false):
			battle.board.set_tile(p, "Z")


func on_turn_start(t: int) -> void:
	if t == 1 and not flags.get("owen_in", false):
		var od: Dictionary = member("owen", stage())
		od["id"] = "owen"
		var o = battle.join_unit(od, OWEN_POS)
		if o != null:
			o.has_acted = false
			o.queue_redraw()
			flags["owen_in"] = true
		await battle.play_dialogue(_owen_joins())
		battle._refresh_objectives()
	_burn_tombs()
	if _wave(t, WAVES):
		if t == 2:
			await battle.play_dialogue(_wave2())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t == HOLD_TURNS and not flags.get("last", false):
		flags["last"] = true
		battle.show_banner(tr("最后一回合！"), Color(1.0, 0.85, 0.4))


## 敌人站在墓碑上：那块墓碑被烧毁（每个我方回合开始结算一次）
func _burn_tombs() -> void:
	for p in TOMBS:
		var key := "burned_%d_%d" % [p.x, p.y]
		if flags.get(key, false):
			continue
		var u = battle.board.unit_at(p)
		if u != null and u.is_alive() and not u.is_player() and not u.is_npc():
			flags[key] = true
			battle.board.set_tile(p, "Z")
			battle.board.goal_tiles = goal_tiles()
			Audio.play_sfx("fire")
			battle.show_banner(tr("墓碑被烧毁了！"), Color(1.0, 0.45, 0.3))


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_HERMIT:
		await battle.play_dialogue([
			_l("老人", C_NPC, "又有人上山了？……上一次这么热闹，还是三十年前教会来「修缮」墓碑的时候。"),
			_l("老人", C_NPC, "他们刮掉了一块碑上的字。我偷偷捡了一块碎石——拿去吧，上面只剩一个「莫」字。"),
		])
		u.receive("overlord_crest")
		battle.notify(tr("获得 霸王之证"))
	elif pos == VISIT_HUNTER:
		await battle.play_dialogue([
			_l("猎户", C_NPC, "雪山上冻死过很多人。你们穿得太少了——这个，喝下去暖暖身子。"),
		])
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))


func on_before_combat(att, def) -> void:
	if "raven" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var foe_u = def if att.unit_id == "raven" else att
		await battle.play_dialogue(_boss(foe_u.unit_id))


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("raven")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())


func talks() -> Array:
	return [["owen", "tia", "owen_tia_25"], ["owen", "silas", "owen_silas_25"]]


func talk_lines(key: String) -> Array:
	if key == "owen_tia_25":
		return [
			_l("欧文", C_OWEN, "你就是巫女的血脉？……红头发，和墓碑上画的一样。"),
			_l("缇娅", C_TIA, "墓碑上画着巫女？"),
			_l("欧文", C_OWEN, "画着她的背影。她叫艾琳。八英雄的碑围着她的碑，像八个人围着一团火。"),
			_l("缇娅", C_TIA, "……围着火，是为了取暖吧。"),
			_l("欧文", C_OWEN, "（笑）我守了二十年墓，第一次听人这么说。……是啊，也许就是为了取暖。"),
		]
	return [
		_l("欧文", C_OWEN, "圣焰审判官。三十年前，你们的人上山来刮墓碑。"),
		_l("塞拉斯", C_SILAS, "……我知道。审判所的卷宗里，记着那次「修缮」。"),
		_l("欧文", C_OWEN, "那你来做什么？刮第二遍？"),
		_l("塞拉斯", C_SILAS, "来读。……然后，在圣都的广场上念出来。"),
		_l("欧文", C_OWEN, "……好。那你得先活着下山。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["owen_joined"] = _here("owen")
	Campaign.flags["hero_records"] = _tombs_left()
	Campaign.flags["oath_tomb_burned"] = flags.get("burned_%d_%d" % [TOMBS[1].x, TOMBS[1].y], false)


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "北方雪山，英灵廊。八百年前封印不灭之火的八位英雄，葬在这里。"),
		_l("", C_NARR, "一行人赶到的时候，山脚下已经扎满了灰色的帐篷。"),
		_l("渡鸦", C_BOSS, "来得正好。大司祭大人说，英灵廊的石头要烧，来的人也一起烧。"),
		_l("渡鸦", C_BOSS, "灰袍众长老，渡鸦。……卡斯帕那个蠢货死在你们手里，这笔账我一起算。"),
	]
	if _here("vera"):
		lines.append(_l("薇拉", C_VERA, "渡鸦。灰袍众真正的头子。……当年买凶烧灰岩村的钱，就是从他手里出去的。"))
	lines.append_array([
		_l("艾德里克", C_EDRIC, "守住英灵廊的门！墓碑上刻着的，是我们来找的东西！"),
		_l("加雷斯", C_GARETH, "守城？这个我拿手。"),
	])
	return lines


func _owen_joins() -> Array:
	var lines: Array = [
		_l("", C_NARR, "英灵廊的门里，走出一个披着灰斗篷的人。手里的法杖，顶端嵌着一块旧铜。"),
		_l("欧文", C_OWEN, "守墓人，欧文。八英雄第八位「持杖者」的后裔。"),
		_l("欧文", C_OWEN, "你们是来烧墓的，还是来读墓的？"),
		_l("艾德里克", C_EDRIC, "来读的。……顺便帮你守门。"),
		_l("欧文", C_OWEN, "那就守好。八百年下来，还完整的墓碑只剩三块：巫女的、刻着八英雄誓言的、还有一块——被人刮过字的。"),
		_l("欧文", C_OWEN, "灰袍众要是站上墓碑，八百年的字就没了。……我会在里面守着。我要是倒了，这里就没有守墓人了。"),
	]
	if _here("silas"):
		lines.append(_l("塞拉斯", C_SILAS, "（八英雄的后裔……卷宗里说，持杖者的血脉早就断了。又是一句谎话。）"))
	return lines


func _wave2() -> Array:
	return [
		_l("渡鸦", C_BOSS, "西边的山路，也是我的人。……英灵廊没有后门，你们也没有。"),
	]


func _turn2_hint() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "金框是墓碑。别让敌人站上去——站上去的那块就会被烧掉。"),
		_l("艾德里克", C_EDRIC, "撑过第 8 回合，或者冲下山打倒渡鸦。欧文不能倒下！"),
	]


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	if foe_id == "vera":
		lines.append(_l("渡鸦", C_BOSS, "黑烬的团长。你拿过我的钱，现在又来砍我？"))
		lines.append(_l("薇拉", C_VERA, "钱我烧了。连同那个村子的账，今天还给你。"))
	elif foe_id == "tia":
		lines.append(_l("渡鸦", C_BOSS, "巫女。你的村子，是我付的钱。"))
		lines.append(_l("缇娅", C_TIA, "……我知道。所以，你最好别指望我手软。"))
	else:
		lines.append(_l("渡鸦", C_BOSS, "灰袍众的刀，从来只砍背后。……今天破例。"))
	return lines


func _boss_death() -> Array:
	return [
		_l("渡鸦", C_BOSS, "八百年……我们替大司祭……刮了八百年的字……"),
		_l("渡鸦", C_BOSS, "刮掉的……总会……长回来吗……"),
	]


func _post_battle() -> Array:
	var left := _tombs_left()
	var lines: Array = [
		_l("", C_NARR, "风雪停了。英灵廊里，欧文拂去墓碑上的雪。"),
	]
	if left == 0:
		lines.append_array([
			_l("欧文", C_OWEN, "……三块都烧了。可是没关系。这些字，我从小背到大。"),
		])
	elif left < 3:
		lines.append(_l("欧文", C_OWEN, "烧掉了一些。……剩下的我念给你们听，烧掉的那些，我背得出来。"))
	lines.append_array([
		_l("欧文", C_OWEN, "「巫女艾琳，以身为锁。八人以器为钥，同封炎龙于圣焰之下。」"),
		_l("欧文", C_OWEN, "「失控者，非巫女，乃大司祭——」……后面的名字，被人刮掉了。"),
		_l("缇娅", C_TIA, "艾琳……我的祖先，叫艾琳。"),
		_l("欧文", C_OWEN, "还有最后一句。八英雄的誓言：「火不可封，唯可守。愿后世守火之人，不必再以身为锁。」"),
		_l("缇娅", C_TIA, "火不可封，唯可守……"),
		_l("艾德里克", C_EDRIC, "被刮掉的名字……一定藏在什么地方。教会刮得掉石头，刮不掉所有的抄本。"),
	])
	if _here("silas"):
		lines.append(_l("塞拉斯", C_SILAS, "神殿的书库。八百年前的原本编年史，只可能在那里。"))
	lines.append_array([
		_l("欧文", C_OWEN, "我跟你们走。守墓人守的是字，不是石头。……字要是能让人知道，守墓人就能下山了。"),
	])
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "hero_hall", "from": "holy", "lines": [
		_moon(5),
		_l("", CB_NARR, "一行人连夜北上。雪山上的英灵廊，是八英雄的墓。"),
		_l("", CB_NARR, "八百年前的真相，刻在那里的墓碑上。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "黑石地牢 · 最底层", "mood": "dungeon", "lines": [
			_l("", CB_NARR, "黑石地牢的最底层，有一间比所有牢房都冷的屋子。"),
			_l("", CB_NARR, "一排排培养槽里，泡着半成形的灰色人影。"),
			_l("莉莉丝", C_LILITH, "……又有脚步声。是七号。"),
			_l("莉莉丝", C_LILITH, "她每次路过，都会在我的门口停一下。……今天，她停得比平时久。"),
			_l("七号", CB_SEVEN, "……十二号。你，会觉得冷吗？"),
			_l("莉莉丝", C_LILITH, "会啊。我的右半边还是人。……你呢？"),
			_l("七号", CB_SEVEN, "……不知道。"),
		]},
	]
