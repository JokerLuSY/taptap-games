class_name Chapter9
extends ChapterBase
## 第九章「雾沼的村落」：埃德蒙最后一次被人看见，是在雾沼村。赶到时，村子正被「沼泽强盗」围着打——
## 强盗背后是教会的钱。村子当中有 5 户民居：艾德里克【访问】村长屋，村长的女儿、自卫队队长米拉入队，
## 她见过埃德蒙最后一面。其余民居会被强盗放火烧掉（守着民居的强盗活到期限还在旁边，或者有强盗站上去）。
## 胜利：击败守在北边堡垒里的强盗头目斯卡尔。

const CHAPTER_TITLE := "第九章 · 雾沼的村落"
const VICTORY_TITLE := "第九章 · 完"
const VICTORY_SUB := "雾散了。北边的山里，有一座没有名字的研究所。"
const DEFEAT_SUB := "雾沼的雾，吞没了最后的火光……"
const BG := ""

## 32×22。南边是我方进村的大路；两侧是沼泽（浅滩 w、深水 ~）和树林；
## 村子在中间（5 户民居 H、一口井、几块菜地），村长屋在村子南口；北边是强盗占的木寨（城墙 #、城门 G），
## 斯卡尔坐在寨子里的堡垒 T 上。
const MAP := [
	"FF~~ww.FF..##########..FFww~~FFF",
	"F~~~ww..F..#SSSSSSSS#...Fww~~~FF",
	".~~www..h..#SSSTSSSS#..h..ww~~F.",
	"..www.....F#SSSSSSSS#F....www...",
	"F.ww..F....####GG####...F...ww.F",
	"FF....FF.......RR.......FF....FF",
	"F..ww...F......RR......F..www..F",
	".www......D.H..RR..D......wwww..",
	"ww~ww...ffff...RR....H.f...ww~ww",
	"w~~~w..Fffff.RRRRRRRR..ffF..w~~w",
	"ww~ww....D.H.R..W...R.D...ww~~ww",
	".www.....F...R......R..H...www..",
	"..w..ff......RRRRHRRR...ff...w..",
	"F.ww..ff...F...RR.D...ff...ww.FF",
	"FFwww.......F..RR....F.....www.F",
	"Fw~~ww..F......RR.......F..ww~~F",
	"w~~~~w...h..F..RR..F..h....w~~~w",
	"ww~~ww..F......RR.......F..ww~ww",
	"FwwwF..FF..F...RR...F..FF...wwwF",
	"FF.....F.......RR......F.....FFF",
	"F..F.........R.RR.R.........F..F",
	"FF...F......RRRRRRRR......F...FF",
]

const LEVELS := []

const MIRA_HOUSE := Vector2i(17, 12)   # 村长屋（米拉家）：艾德里克访问 → 米拉入队
const H_NORTH := Vector2i(12, 7)
const H_EAST := Vector2i(21, 8)
const H_WEST := Vector2i(11, 10)
const H_SOUTHEAST := Vector2i(23, 11)
## 放火的强盗：{单位 id: [民居, 第几回合开始时动手]}。到点时这个强盗还活着、还在民居 3 格内，民居就被烧掉
const RAIDERS := {
	"bandit_raid1": [H_NORTH, 5],
	"bandit_raid2": [H_EAST, 5],
	"bandit_raid3": [H_WEST, 4],
	"bandit_raid4": [H_SOUTHEAST, 4],
}

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_LANCE := Color(0.8, 0.9, 0.75)
const C_GWEN := Color(1.0, 0.78, 0.6)
const C_OSCAR := Color(0.78, 0.82, 0.9)
const C_MIRA := Color(0.75, 0.95, 0.85)
const C_VICTOR := Color(0.78, 0.7, 0.95)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _BANDIT := {"name": "沼泽强盗", "class": "山贼", "faction": "enemy", "level": 8,
	"hp": 30, "pwr": 10, "skl": 5, "spd": 6, "dfn": 4, "res": 0, "mov": 5,
	"weapons": ["iron_axe"], "color": Color(0.45, 0.50, 0.35),
	"hair": "spiky", "hair_color": Color(0.22, 0.20, 0.12), "armor": Color(0.40, 0.44, 0.30)}
const _FIGHTER := {"name": "强盗战士", "class": "战士", "faction": "enemy", "level": 8,
	"hp": 32, "pwr": 11, "skl": 6, "spd": 6, "dfn": 5, "res": 1, "mov": 5,
	"weapons": ["iron_axe", "hand_axe"], "color": Color(0.50, 0.46, 0.32),
	"hair": "short", "hair_color": Color(0.30, 0.22, 0.14), "armor": Color(0.46, 0.42, 0.30)}
const _ARCHER := {"name": "强盗弓手", "class": "弓箭手", "faction": "enemy", "level": 7,
	"hp": 24, "pwr": 8, "skl": 9, "spd": 7, "dfn": 3, "res": 2, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.45, 0.50, 0.36),
	"hair": "hood", "armor": Color(0.40, 0.46, 0.32)}
const _MERC := {"name": "雇佣剑客", "class": "佣兵", "faction": "enemy", "level": 8,
	"hp": 28, "pwr": 9, "skl": 10, "spd": 10, "dfn": 5, "res": 2, "mov": 5,
	"weapons": ["iron_sword"], "color": Color(0.42, 0.40, 0.48),
	"hair": "short", "hair_color": Color(0.20, 0.18, 0.22), "armor": Color(0.38, 0.36, 0.44)}
const _MAGE := {"name": "黑衣术士", "class": "魔道士", "faction": "enemy", "level": 8,
	"hp": 23, "pwr": 9, "skl": 7, "spd": 7, "dfn": 2, "res": 8, "mov": 5,
	"weapons": ["fire"], "color": Color(0.22, 0.22, 0.26),
	"hair": "hood", "armor": Color(0.20, 0.20, 0.24)}

const UNITS := [
	# 我方：名单里有存档时用存档；这里只给位置和直接进本章时的默认数值
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 8,
		"hp": 28, "pwr": 8, "skl": 11, "spd": 11, "dfn": 7, "res": 3, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(15, 20), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 8,
		"hp": 29, "pwr": 9, "skl": 9, "spd": 7, "dfn": 8, "res": 2, "mov": 7,
		"weapons": ["iron_lance", "javelin"], "items": [],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(16, 20), "color": Color(0.35, 0.55, 0.40),
		"hair": "short", "hair_color": Color(0.35, 0.28, 0.20), "armor": Color(0.45, 0.60, 0.48)},
	{"id": "gwen", "name": "葛温", "class": "骑士", "faction": "player", "level": 7,
		"hp": 27, "pwr": 9, "skl": 7, "spd": 10, "dfn": 7, "res": 1, "mov": 7,
		"weapons": ["iron_lance", "steel_lance"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 50, "skl": 35, "spd": 50, "dfn": 25, "res": 15},
		"pos": Vector2i(15, 21), "color": Color(0.70, 0.35, 0.30),
		"hair": "ponytail", "hair_color": Color(0.85, 0.50, 0.20), "armor": Color(0.68, 0.38, 0.32)},
	{"id": "oscar", "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 10,
		"hp": 31, "pwr": 10, "skl": 7, "spd": 3, "dfn": 14, "res": 1, "mov": 4,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(16, 21), "color": Color(0.50, 0.52, 0.60),
		"hair": "short", "hair_color": Color(0.45, 0.42, 0.40), "armor": Color(0.60, 0.62, 0.70)},
	# 敌方：村南沼泽
	{"id": "bandit1", "pos": Vector2i(8, 16)},
	{"id": "bandit2", "pos": Vector2i(24, 17), "hold": true},
	{"id": "archer1", "pos": Vector2i(20, 15)},
	{"id": "merc1", "pos": Vector2i(11, 14), "hold": true},
	# 村子里：守着民居、准备放火的强盗
	{"id": "bandit_raid1", "pos": Vector2i(10, 6), "hold": true, "items": ["vulnerary"]},
	{"id": "bandit_raid2", "pos": Vector2i(23, 7), "hold": true},
	{"id": "bandit_raid3", "pos": Vector2i(9, 11), "hold": true},
	{"id": "bandit_raid4", "pos": Vector2i(25, 12), "hold": true},
	{"id": "fighter1", "pos": Vector2i(16, 9)},
	{"id": "archer2", "pos": Vector2i(19, 10)},
	{"id": "mage1", "pos": Vector2i(14, 11)},
	{"id": "merc2", "pos": Vector2i(20, 13)},
	# 村北
	{"id": "bandit3", "pos": Vector2i(6, 5)},
	{"id": "fighter2", "pos": Vector2i(22, 3), "hold": true},
	{"id": "mage2", "pos": Vector2i(20, 6), "items": ["vulnerary"]},
	# 木寨
	{"id": "bandit5", "pos": Vector2i(15, 5), "hold": true},
	{"id": "bandit6", "pos": Vector2i(16, 5), "hold": true},
	{"id": "fighter3", "pos": Vector2i(13, 2), "hold": true},
	{"id": "archer4", "pos": Vector2i(18, 1), "hold": true},
	{"id": "merc3", "pos": Vector2i(17, 3), "hold": true},
	# 沼泽强盗头目斯卡尔：寨子里的堡垒上
	{"id": "skarl", "name": "斯卡尔", "class": "山贼头目", "faction": "enemy", "level": 11,
		"hp": 40, "pwr": 13, "skl": 8, "spd": 8, "dfn": 7, "res": 2, "mov": 5,
		"weapons": ["steel_axe", "hand_axe"], "boss": true, "stationary": true, "sprite": "boss",
		"items": ["elixir"],
		"pos": Vector2i(15, 2), "color": Color(0.40, 0.45, 0.30),
		"hair": "spiky", "hair_color": Color(0.15, 0.14, 0.10), "armor": Color(0.36, 0.40, 0.26), "scar": true},
]

## 第 3 回合沼泽两侧来强盗；第 5 回合两侧再来；第 7 回合南边林子里来弓手和剑客
const WAVES := {
	3: [{"id": "bandit_r1", "pos": Vector2i(0, 9)}, {"id": "bandit_r2", "pos": Vector2i(31, 9)}],
	5: [{"id": "fighter_r1", "pos": Vector2i(0, 12)}, {"id": "bandit_r3", "pos": Vector2i(31, 12)}],
	7: [{"id": "archer_r1", "pos": Vector2i(0, 19)}, {"id": "merc_r1", "pos": Vector2i(31, 19)}],
}

## 米拉：访问村长屋后入队
const MIRA := {"id": "mira", "name": "米拉", "class": "枪兵", "level": 8,
	"hp": 26, "pwr": 8, "skl": 9, "spd": 10, "dfn": 6, "res": 3, "mov": 5,
	"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
	"growths": {"hp": 70, "pwr": 40, "skl": 50, "spd": 55, "dfn": 25, "res": 25},
	"color": Color(0.40, 0.62, 0.55), "hair": "ponytail", "hair_color": Color(0.30, 0.22, 0.16),
	"armor": Color(0.42, 0.58, 0.50)}


func chapter_id() -> String:
	return "ch9"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 6


func forced_ids() -> Array:
	return ["edric"]


func extra_deploy_slots() -> Array:
	return [Vector2i(14, 21), Vector2i(17, 21), Vector2i(13, 21), Vector2i(18, 21)]


func templates() -> Dictionary:
	return {"bandit": _BANDIT, "fighter": _FIGHTER, "archer": _ARCHER, "merc": _MERC, "mage": _MAGE}


func lose_ids() -> Array:
	return ["edric"]


func extra_slots() -> Array:
	return [Vector2i(14, 21), Vector2i(17, 21), Vector2i(13, 21), Vector2i(18, 21), Vector2i(12, 21), Vector2i(19, 21)]


func is_won() -> bool:
	var s = battle.get_unit("skarl")
	if s != null and not s.is_alive():
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("击败强盗头目斯卡尔")


func lose_condition() -> String:
	return tr("艾德里克阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_resume() -> void:
	for p in flags.get("burned", []):
		battle.board.set_tile(Vector2i(int(p[0]), int(p[1])), "Z")


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	await _raiders_burn(t)


## 放火：到点时守着民居的强盗还活着、还在附近，或者有强盗站在没访问过的民居上，民居就烧掉
func _raiders_burn(t: int) -> void:
	var targets: Array = []
	for rid in RAIDERS:
		var house: Vector2i = RAIDERS[rid][0]
		if t < int(RAIDERS[rid][1]) or visited.has(house):
			continue
		var r = battle.get_unit(rid)
		if r != null and r.is_alive() and GameData.dist(r.grid_pos, house) <= 3:
			targets.append(house)
	for e in battle.units:
		if e.is_alive() and not e.is_player() and not e.is_npc():
			var p: Vector2i = e.grid_pos
			if p != MIRA_HOUSE and p in [H_NORTH, H_EAST, H_WEST, H_SOUTHEAST] and not visited.has(p) and not p in targets:
				targets.append(p)
	if targets.is_empty():
		return
	for p in targets:
		visited[p] = true
		battle.board.set_tile(p, "Z")
		var burned: Array = flags.get("burned", [])
		burned.append([p.x, p.y])
		flags["burned"] = burned
	Audio.play_sfx("fire")
	battle.show_banner(tr("民居被烧毁了……"), Color(1.0, 0.45, 0.2))
	if not flags.get("burn_talk", false):
		flags["burn_talk"] = true
		await battle.play_dialogue(_house_burned())


func on_before_combat(att, def) -> void:
	if "skarl" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "skarl" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	if pos == MIRA_HOUSE:
		if u.unit_id != "edric":
			await battle.play_dialogue(_mira_door())
			return
		visited[pos] = true
		await battle.play_dialogue(_visit_mira())
		if battle.get_unit("mira") == null:
			battle.join_unit(MIRA, pos)
		return
	visited[pos] = true
	if pos == H_NORTH:
		await battle.play_dialogue(_visit_north())
		u.receive("steel_lance")
		battle.notify(tr("获得 钢枪"))
	elif pos == H_EAST:
		await battle.play_dialogue(_visit_east())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))
	elif pos == H_WEST:
		await battle.play_dialogue(_visit_west())
		battle.add_gold(1000)
		battle.notify(tr("获得 1000G"))
	elif pos == H_SOUTHEAST:
		await battle.play_dialogue(_visit_southeast())
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))


func talks() -> Array:
	return [["gwen", "mira", "gwen_mira"], ["lance", "oscar", "lance_oscar"]]


func talk_lines(key: String) -> Array:
	if key == "gwen_mira":
		return [
			_l("葛温", C_GWEN, "喂，自卫队长！你那一枪是跟谁学的？刚才那个强盗，连斧头都没举起来就倒了。"),
			_l("米拉", C_MIRA, "跟沼泽学的。陷在泥里的时候，只来得及刺一枪——刺不中就没命了。"),
			_l("葛温", C_GWEN, "……哈！我喜欢这个答案。骑士学校的老头子要是这么教，我早就出师了。"),
			_l("米拉", C_MIRA, "你骑在马上，在泥地里可要小心。沼泽不认识骑士。"),
			_l("葛温", C_GWEN, "知道啦。……那你也小心点，枪兵队长。别让我替你收尸。"),
		]
	return [
		_l("兰斯", C_LANCE, "奥斯卡大人。少主今天……一句话都没提领主大人。"),
		_l("奥斯卡", C_OSCAR, "他是怕一开口，就停不下来。……这孩子从小就这样。"),
		_l("兰斯", C_LANCE, "您呢？您跟随领主大人最久。"),
		_l("奥斯卡", C_OSCAR, "我？我是城门。城门不问城里的人回不回来，只管开着。"),
		_l("兰斯", C_LANCE, "……我明白了。那我就做少主的枪。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	await battle.play_dialogue([
		_l("艾德里克", C_EDRIC, "父亲走过的路……我竟然……连一半都没走到……"),
		_l("", C_NARR, "雾沼的雾，吞没了最后的火光。"),
	])


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "雾沼村。终年起雾的沼泽中间，一座只有几十户人家的小村子。"),
		_l("", C_NARR, "一行人赶到的时候，村子里已经响起了喊杀声。"),
		_l("沼泽强盗", C_ENEMY, "老大说了！先把粮抢光，再把房子一间间点了！一个活口都别留！"),
	]
	if _here("gwen"):
		lines.append(_l("葛温", C_GWEN, "强盗？这种穷村子，有什么好抢的！"))
	if _here("lance"):
		lines.append(_l("兰斯", C_LANCE, "……他们的斧子是新的，弓也是教会军械库的样式。这不是普通的强盗。"))
	if _here("oscar"):
		lines.append(_l("奥斯卡", C_OSCAR, "有人出钱，让他们来烧村子。……灰袍众烧书斋，这些人烧村子。"))
	lines.append(_l("艾德里克", C_EDRIC, "父亲最后一次被人看见，就是在这里。……不能让他们把村子烧了！"))
	lines.append(_l("艾德里克", C_EDRIC, "去村长家问父亲的下落。其他人，把放火的强盗赶走！"))
	return lines


func _turn2_hint() -> Array:
	var lines: Array = []
	var w := _first_here(["lance", "oscar", "gwen"])
	if w != "":
		lines.append(_ret(w, "少主，村子南口那间大屋子是村长家。门口有自卫队的标记。"))
	else:
		lines.append(_l("", C_NARR, "村子南口那间大屋子是村长家。门口有自卫队的标记。"))
	lines.append(_l("艾德里克", C_EDRIC, "我亲自去。……站到门口【访问】。"))
	w = _first_here(["gwen", "lance", "oscar"])
	if w != "":
		lines.append(_ret(w, "看那几个守在民居旁边的强盗，手里都拿着火把！拖久了，房子就保不住了。"))
	else:
		lines.append(_l("", C_NARR, "守在民居旁边的强盗，手里都拿着火把。拖久了，房子就保不住了。"))
	w = _first_here(["oscar", "lance", "gwen"])
	if w != "":
		lines.append(_ret(w, "要么先去访问，要么把放火的家伙解决掉，或者把他们引开。"))
	return lines


func _house_burned() -> Array:
	var lines: Array = [
		_l("", C_NARR, "火把扔上了茅草屋顶。一户民居在浓烟里塌了下去。"),
		_l("艾德里克", C_EDRIC, "……可恶！"),
	]
	var w := _first_here(["lance", "oscar", "gwen"])
	if w != "":
		lines.append(_ret(w, "还有其他人家。少主，别停下！"))
	return lines


func _mira_door() -> Array:
	return [
		_l("米拉", C_MIRA, "（门里）站住！你们是什么人？……要说话，让你们领头的来。"),
	]


func _visit_mira() -> Array:
	var lines: Array = [
		_l("米拉", C_MIRA, "别动！……再往前一步，我就——"),
		_l("艾德里克", C_EDRIC, "我不是强盗。我是艾德里克，菲恩领主埃德蒙之子。我在找我的父亲。"),
		_l("米拉", C_MIRA, "……埃德蒙大人的儿子？"),
		_l("米拉", C_MIRA, "我是村长的女儿，米拉，村里自卫队的队长。……你父亲来过这里。半个月前。"),
		_l("米拉", C_MIRA, "他在我家住了一晚，问的全是北边山里那座废弃研究所的事。教会十年前封了那里，说是闹瘟疫。"),
		_l("米拉", C_MIRA, "第二天一早，他带着几个骑士往北边的山里去了。说是要见一个「从研究所逃出来的人」。……之后，再也没回来。"),
		_l("艾德里克", C_EDRIC, "废弃的研究所……"),
		_l("米拉", C_MIRA, "他走后没几天，这些强盗就来了。他们一直在问：「那个领主跟谁说过话」。"),
		_l("米拉", C_MIRA, "……带上我。我认得去研究所的路。我也想知道，这个村子到底是被谁盯上的。"),
	]
	if Campaign.flags.get("edmund_notes", false):
		lines.insert(7, _l("艾德里克", C_EDRIC, "父亲的笔记里也写着：去雾沼村，见那个从研究所逃出来的人。……原来是这样。"))
	return lines


func _visit_north() -> Array:
	return [
		_l("猎户", C_NPC, "你们是来帮忙的？……那就拿着这杆枪吧，是我家老头子年轻时用的。"),
		_l("猎户", C_NPC, "沼泽里的路软，骑马的人别往浅滩里冲。"),
	]


func _visit_east() -> Array:
	return [
		_l("农妇", C_NPC, "谢天谢地……强盗刚才就在窗外，拿着火把转来转去。"),
		_l("农妇", C_NPC, "这是家里最后一瓶伤药。你们比我更需要它。"),
	]


func _visit_west() -> Array:
	return [
		_l("老人", C_NPC, "半个月前，有个穿蓝披风的大人路过，给过我一袋钱，说是买我一句实话。"),
		_l("老人", C_NPC, "他问我研究所里的灯，晚上还亮不亮。……我说亮。那位大人的脸色，一下子就变了。"),
		_l("老人", C_NPC, "钱我一个子儿没花。你们拿去吧，就当还给他。"),
	]


func _visit_southeast() -> Array:
	return [
		_l("村民", C_NPC, "这是村里祖传的万灵药，本来是留着救命的。"),
		_l("村民", C_NPC, "……可要是村子没了，留着也没用。拿去吧，把强盗赶出去！"),
	]


func _boss() -> Array:
	return [
		_l("斯卡尔", C_BOSS, "哪来的毛头小子？穿得倒挺体面，是哪家的少爷？"),
		_l("艾德里克", C_EDRIC, "你们拿着教会的弓，烧的是王国的村子。是谁雇了你们？"),
		_l("斯卡尔", C_BOSS, "嘿，眼睛挺尖。……雇主说了，问东问西的人，一律送进沼泽里喂泥鳅！"),
	]


func _boss_death() -> Array:
	return [
		_l("斯卡尔", C_BOSS, "穿……灰袍的……说好的……没人会来……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "强盗退了。村民们从烧剩的屋子里走出来，默默地扑灭余火。"),
	]
	var burned: int = flags.get("burned", []).size()
	if burned == 0:
		var w := _first_here(["lance", "oscar", "gwen"])
		if w != "":
			lines.append(_ret(w, "一户都没烧掉。……少主，我们守住了。"))
		else:
			lines.append(_l("艾德里克", C_EDRIC, "一户都没烧掉。……我们守住了。"))
	else:
		var w := _first_here(["oscar", "lance", "gwen"])
		if w != "":
			lines.append(_ret(w, "烧掉了几户人家。……人都还在，房子还能再盖。"))
		else:
			lines.append(_l("艾德里克", C_EDRIC, "烧掉了几户人家。……人都还在，房子还能再盖。"))
	if _here("mira"):
		lines.append(_l("米拉", C_MIRA, "斯卡尔说「穿灰袍的」……雇他们的人，和烧你家书斋的，是同一伙。"))
		lines.append(_l("米拉", C_MIRA, "研究所在北边的山里，一天的路。我带路。"))
	else:
		var w := _first_here(["lance", "oscar", "gwen"])
		if w != "":
			lines.append(_ret(w, "村长说，领主大人往北边的山里去了。那里有一座教会封掉的研究所。"))
		else:
			lines.append(_l("艾德里克", C_EDRIC, "村长说，父亲往北边的山里去了。那里有一座教会封掉的研究所。"))
	lines.append(_l("艾德里克", C_EDRIC, "教会说那里闹过瘟疫……可半个月前，那里的灯还亮着。"))
	lines.append(_l("艾德里克", C_EDRIC, "去研究所。父亲要见的那个人，也许还在那里。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "marsh", "from": "fenn", "lines": [
		_l("", CB_NARR, "离开菲恩城的第三天。一行人一路往东，走进了雾沼。"),
		_l("", CB_NARR, "领主埃德蒙最后一次被人看见，就是在这片沼泽里的村子。"),
	]}


func epilogue() -> Array:
	return [{"title": "北山 · 废弃研究所", "mood": "dungeon", "lines": [
		_l("", CB_NARR, "北边山里，教会封了十年的研究所。最深处的一间屋子里，一支蜡烛还亮着。"),
		_l("维克多", C_VICTOR, "「第七批实验体，灰化率百分之六十。意识残留……无。」"),
		_l("维克多", C_VICTOR, "……埃德蒙大人，您留下的笔记，我读完了。您说得对。他们用的不是罪人，是普通人。"),
		_l("", CB_NARR, "走廊尽头，传来了整齐的脚步声。铁靴踩在石板上，一下，又一下。"),
		_l("维克多", C_VICTOR, "……来得真快。教会的「清理部队」。"),
		_l("维克多", C_VICTOR, "也好。这一次，我不逃了。"),
	]}]

# ==================== 工具 ====================

const _RET := {"lance": ["兰斯", C_LANCE], "gwen": ["葛温", C_GWEN], "oscar": ["奥斯卡", C_OSCAR]}


## 我方、活着、在地图上
func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


## 剧情里还活着：本章倒下的人名单状态要到尾声后才写回，先看地图上的结果
func _alive(id: String) -> bool:
	var u = battle.get_unit(id)
	if u != null and u.is_player():
		return u.is_alive() or bool(u.get_meta("retreated", false))
	return Campaign.alive_in_story(id)


## 依次找第一个此刻在地图上的人；都不在返回 ""
func _first_here(ids: Array) -> String:
	for id in ids:
		if _here(id):
			return id
	return ""


## 依次找第一个剧情里还活着的人；都不在返回 ""
func _first_alive(ids: Array) -> String:
	for id in ids:
		if _alive(id):
			return id
	return ""


## 菲恩家臣（兰斯 / 葛温 / 奥斯卡）说话
func _ret(id: String, text: String) -> Dictionary:
	return _l(_RET[id][0], _RET[id][1], text)
