class_name Chapter10
extends ChapterBase
## 第十章「废弃研究所」：北山里教会封了十年的研究所，被教会的「清理部队」包围。
## 埃德蒙的线人、前教会研究员维克多困在里面，杀红了眼，敌我不分地放暗魔法（敌方单位、不动），
## 艾德里克走到他身边【说得】，他就入队，并说出灰烬傀儡的存在与「教会在偷自己的圣器」。
## 第 8 章没拿到笔记的话，维克多也会补上 5 件圣器的下落。胜利：击败研究所深处的监察官赫尔曼。

const CHAPTER_TITLE := "第十章 · 废弃研究所"
const VICTORY_TITLE := "第十章 · 完"
const VICTORY_SUB := "研究所的灯熄了。笼子里的人，还在等。"
const DEFEAT_SUB := "研究所的门又一次封上了。这一次，里面多了几个人……"
const BG := ""

## 30×20。西半边是山路（我方从西南的山道上来），东半边是研究所（城墙 #、石地 S）：
## 西墙城门 → 前厅（北、南各一间实验室，满地碎掉的培养槽 Z）→ 中廊（维克多困在正中）→
## 最里面的监察室，赫尔曼坐在王座 K 上。山路北边有一间猎户小屋可以访问。
const MAP := [
	"MMMMXMMMMMM###################",
	"MMMM...MMMM#ISSSSI#SSSSS#ISSI#",
	".FF.hF.MMMM#SSZSSS#SZSZS#SSSS#",
	"X....hh..h.#SSSSZSSSSSSS#SSSS#",
	"XF......F.X#SSSSSS#SSSSS#SISS#",
	"X..H..F...X###S####SSSSSSSSSS#",
	"..F......FX#SSSSSS#SZSZS#SSSS#",
	"F..........#SISSIS#ISSSI#SISS#",
	"..hh.F.....#SSSSSS#SSSSS#SSSS#",
	"...........GSSSSSSSSSSSS#SSKS#",
	"RRRRRRRRRRRGSSSSSSSSSSSS#SSSS#",
	"........RR.#SSSSSS#SSSSS#SISS#",
	".hh.F..RR..#SISSIS#ISSSI#SSSS#",
	"F.....RR..X#SSSSSS#SZSZS#SSSS#",
	".F...RR...X####S###SSSSSSSSSS#",
	"....RR..F.h#SSSSSS#SSSSS#SISS#",
	"...RR..hh..#SZSSSSSSSSSS#SSSS#",
	"RRRR..F..F.#SSSSZS#SZSZS#SSSS#",
	"....hh....F#ISSSSI#SSSSS#ISSI#",
	"XMMF..XXXX.###################",
]

const LEVELS := []

const VISIT_HUNTER := Vector2i(3, 5)

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_LANCE := Color(0.8, 0.9, 0.75)
const C_GWEN := Color(1.0, 0.78, 0.6)
const C_OSCAR := Color(0.78, 0.82, 0.9)
const C_MIRA := Color(0.75, 0.95, 0.85)
const C_VICTOR := Color(0.78, 0.7, 0.95)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _SOLDIER := {"name": "清理部队枪兵", "class": "枪兵", "faction": "enemy", "level": 9,
	"hp": 28, "pwr": 10, "skl": 8, "spd": 8, "dfn": 7, "res": 2, "mov": 5,
	"weapons": ["iron_lance"], "color": Color(0.78, 0.76, 0.72),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.70, 0.68, 0.64)}
const _KNIGHT := {"name": "清理部队骑士", "class": "骑士", "faction": "enemy", "level": 9,
	"hp": 30, "pwr": 10, "skl": 8, "spd": 7, "dfn": 9, "res": 2, "mov": 7,
	"weapons": ["iron_lance", "javelin"], "color": Color(0.74, 0.72, 0.76),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.78, 0.76, 0.80)}
const _ARMOR := {"name": "清理部队重甲", "class": "重甲兵", "faction": "enemy", "level": 9,
	"hp": 31, "pwr": 10, "skl": 6, "spd": 3, "dfn": 13, "res": 1, "mov": 4,
	"weapons": ["iron_lance"], "color": Color(0.62, 0.62, 0.66),
	"hair": "short", "armor": Color(0.66, 0.66, 0.72)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 8,
	"hp": 25, "pwr": 9, "skl": 9, "spd": 8, "dfn": 4, "res": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 9,
	"hp": 24, "pwr": 10, "skl": 8, "spd": 8, "dfn": 3, "res": 9, "mov": 5,
	"weapons": ["fire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _DARKMAGE := {"name": "清理部队暗法师", "class": "暗法师", "faction": "enemy", "level": 9,
	"hp": 25, "pwr": 10, "skl": 7, "spd": 6, "dfn": 4, "res": 9, "mov": 5,
	"weapons": ["flux"], "color": Color(0.30, 0.26, 0.36),
	"hair": "hood", "armor": Color(0.32, 0.28, 0.40)}
const _CLERIC := {"name": "随军修女", "class": "修女", "faction": "enemy", "level": 8,
	"hp": 21, "pwr": 7, "skl": 7, "spd": 8, "dfn": 3, "res": 8, "mov": 5,
	"weapons": ["heal_staff"], "items": ["vulnerary"], "color": Color(0.95, 0.92, 0.86),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.84)}

const UNITS := [
	# 我方：名单里有存档时用存档；这里只给位置和直接进本章时的默认数值
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 9,
		"hp": 29, "pwr": 9, "skl": 11, "spd": 12, "dfn": 8, "res": 3, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(1, 17), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 9,
		"hp": 30, "pwr": 10, "skl": 9, "spd": 8, "dfn": 9, "res": 2, "mov": 7,
		"weapons": ["iron_lance", "javelin"], "items": [],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(2, 17), "color": Color(0.35, 0.55, 0.40),
		"hair": "short", "hair_color": Color(0.35, 0.28, 0.20), "armor": Color(0.45, 0.60, 0.48)},
	{"id": "gwen", "name": "葛温", "class": "骑士", "faction": "player", "level": 8,
		"hp": 28, "pwr": 9, "skl": 8, "spd": 10, "dfn": 8, "res": 1, "mov": 7,
		"weapons": ["iron_lance", "steel_lance"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 50, "skl": 35, "spd": 50, "dfn": 25, "res": 15},
		"pos": Vector2i(0, 17), "color": Color(0.70, 0.35, 0.30),
		"hair": "ponytail", "hair_color": Color(0.85, 0.50, 0.20), "armor": Color(0.68, 0.38, 0.32)},
	{"id": "oscar", "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 10,
		"hp": 32, "pwr": 11, "skl": 7, "spd": 3, "dfn": 14, "res": 1, "mov": 4,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(1, 18), "color": Color(0.50, 0.52, 0.60),
		"hair": "short", "hair_color": Color(0.45, 0.42, 0.40), "armor": Color(0.60, 0.62, 0.70)},
	{"id": "mira", "name": "米拉", "class": "枪兵", "faction": "player", "level": 9,
		"hp": 27, "pwr": 9, "skl": 10, "spd": 11, "dfn": 6, "res": 3, "mov": 5,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 40, "skl": 50, "spd": 55, "dfn": 25, "res": 25},
		"pos": Vector2i(2, 18), "color": Color(0.40, 0.62, 0.55),
		"hair": "ponytail", "hair_color": Color(0.30, 0.22, 0.16), "armor": Color(0.42, 0.58, 0.50)},
	# 敌方：山路上围着研究所的清理部队
	{"id": "soldier1", "pos": Vector2i(5, 12)},
	{"id": "knight1", "pos": Vector2i(7, 8), "hold": true},
	{"id": "archer1", "pos": Vector2i(6, 4), "hold": true},
	{"id": "soldier2", "pos": Vector2i(9, 9), "hold": true},
	{"id": "knight2", "pos": Vector2i(4, 7), "hold": true},
	{"id": "cleric1", "pos": Vector2i(8, 6)},
	# 前厅与两间实验室
	{"id": "armor1", "pos": Vector2i(12, 9), "hold": true},
	{"id": "soldier3", "pos": Vector2i(15, 8)},
	{"id": "darkmage1", "pos": Vector2i(14, 11)},
	{"id": "archer2", "pos": Vector2i(16, 13), "hold": true},
	{"id": "mage1", "pos": Vector2i(15, 3), "hold": true, "items": ["vulnerary"]},
	{"id": "soldier4", "pos": Vector2i(14, 16), "hold": true},
	# 中廊
	{"id": "armor2", "pos": Vector2i(19, 4), "hold": true},
	{"id": "armor3", "pos": Vector2i(19, 15), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(23, 9), "hold": true},
	{"id": "archer3", "pos": Vector2i(21, 3), "hold": true},
	{"id": "mage2", "pos": Vector2i(21, 16), "hold": true},
	# 监察室
	{"id": "darkmage3", "pos": Vector2i(26, 5), "hold": true},
	{"id": "armor4", "pos": Vector2i(26, 13), "hold": true},
	{"id": "cleric2", "pos": Vector2i(28, 9), "hold": true},
	# 维克多：困在中廊，敌我不分地放暗魔法（敌方、不动）。艾德里克【说得】入队
	{"id": "victor", "name": "维克多", "class": "暗法师", "faction": "enemy", "level": 9,
		"hp": 24, "pwr": 9, "skl": 7, "spd": 6, "dfn": 5, "res": 9, "mov": 5,
		"weapons": ["flux"], "items": ["vulnerary"], "stationary": true,
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45},
		"pos": Vector2i(21, 9), "color": Color(0.34, 0.30, 0.44),
		"hair": "short", "hair_color": Color(0.22, 0.20, 0.26), "armor": Color(0.30, 0.28, 0.38)},
	# 研究所监察官赫尔曼：最里面的王座上不动
	{"id": "hermann", "name": "赫尔曼", "class": "暗法师", "faction": "enemy", "level": 12,
		"hp": 38, "pwr": 13, "skl": 10, "spd": 8, "dfn": 6, "res": 12, "mov": 5,
		"weapons": ["flux", "nosferatu"], "boss": true, "stationary": true, "sprite": "mage",
		"items": ["elixir"],
		"pos": Vector2i(27, 9), "color": Color(0.26, 0.22, 0.30),
		"hair": "hood", "armor": Color(0.36, 0.20, 0.30)},
]

## 第 3 回合西边山路追来骑士；第 5 回合再来枪兵和弓兵；第 7 回合暗法师
const WAVES := {
	3: [{"id": "knight_r1", "pos": Vector2i(0, 10)}, {"id": "knight_r2", "pos": Vector2i(0, 2)}],
	5: [{"id": "soldier_r1", "pos": Vector2i(0, 10)}, {"id": "archer_r1", "pos": Vector2i(0, 2)}],
	7: [{"id": "darkmage_r1", "pos": Vector2i(0, 10)}, {"id": "soldier_r2", "pos": Vector2i(0, 16)}],
}


func chapter_id() -> String:
	return "ch10"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 6


func forced_ids() -> Array:
	return ["edric"]


func extra_deploy_slots() -> Array:
	return [Vector2i(0, 18), Vector2i(3, 18), Vector2i(0, 16), Vector2i(1, 16)]


func templates() -> Dictionary:
	return {"soldier": _SOLDIER, "knight": _KNIGHT, "armor": _ARMOR, "archer": _ARCHER,
		"mage": _MAGE, "darkmage": _DARKMAGE, "cleric": _CLERIC}


func lose_ids() -> Array:
	return ["edric"]


func extra_slots() -> Array:
	return [Vector2i(0, 18), Vector2i(3, 18), Vector2i(0, 16), Vector2i(1, 16), Vector2i(2, 16), Vector2i(3, 16)]


func shop_items() -> Array:
	return ["vulnerary", "iron_lance", "steel_lance", "javelin", "iron_sword", "steel_sword", "flux", "heal_staff"]


func is_won() -> bool:
	var h = battle.get_unit("hermann")
	if h != null and not h.is_alive():
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("击败监察官赫尔曼")


func lose_condition() -> String:
	return tr("艾德里克阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


func on_before_combat(att, def) -> void:
	if "hermann" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())
	elif "victor" in [att.unit_id, def.unit_id] and not flags.get("victor_fight", false):
		var v = att if att.unit_id == "victor" else def
		if not v.is_player():
			flags["victor_fight"] = true
			await battle.play_dialogue(_victor_fight())


func on_after_combat(att, def, def_died: bool) -> void:
	if def.unit_id == "hermann" and def_died:
		await battle.play_dialogue(_boss_death())
	# 维克多还没入队就倒下了：临死前把知道的说出来，剧情照样往下走
	for u in [att, def]:
		if u.unit_id == "victor" and not u.is_player() and not u.is_alive() and not flags.get("victor_dead", false):
			flags["victor_dead"] = true
			await battle.play_dialogue(_victor_death())
			Campaign.flags["edmund_notes"] = true


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_HUNTER:
		await battle.play_dialogue(_visit_hunter())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))


func recruits() -> Dictionary:
	return {"victor": ["edric"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	var lines: Array = [
		_l("维克多", C_VICTOR, "别过来！……教会的狗，还是来抢笔记的强盗？靠近一步，我就把你也变成灰！"),
		_l("艾德里克", C_EDRIC, "我是艾德里克。埃德蒙之子。……你就是父亲要见的那个人吧？"),
		_l("维克多", C_VICTOR, "埃德蒙大人的……儿子？那双眼睛……是真的。"),
		_l("维克多", C_VICTOR, "我叫维克多。十年前，我是这座研究所的研究员。我在这里，帮教会做过一件事——"),
		_l("维克多", C_VICTOR, "用灰烬魔法，把活人改造成没有意志的兵器。教会管它们叫「灰烬傀儡」。"),
		_l("艾德里克", C_EDRIC, "活人……做成兵器？"),
		_l("维克多", C_VICTOR, "我逃出去了，可我忘不掉那些人的脸。……半个月前，埃德蒙大人找到我。他在查圣器失窃案。"),
		_l("维克多", C_VICTOR, "失窃？不。是教会自己偷的。它要集齐八件圣器，打开神殿的封印——傀儡只是那件事的一小部分。"),
		_l("维克多", C_VICTOR, "埃德蒙大人说要去圣都找证据。……然后，他就再也没有消息了。我回到这里，想把剩下的记录带走，结果被堵在了里面。"),
	]
	if not Campaign.flags.get("edmund_notes", false):
		lines.append(_l("维克多", C_VICTOR, "大人走前，把笔记念给我听过一遍。我记性好。……冠、枪、镜，已经在教会手里。"))
		lines.append(_l("维克多", C_VICTOR, "剩下的：铁之盾在海边的废修道院，风之弓在天马峰，地之斧在布罗登王城的宝库，星之杖与日之剑，在圣焰神殿。"))
		lines.append(_l("艾德里克", C_EDRIC, "……书斋烧掉的东西，原来都在你脑子里。"))
	lines.append(_l("维克多", C_VICTOR, "带上我吧。这副身体打不了几场仗，可我知道教会怕什么。"))
	lines.append(_l("艾德里克", C_EDRIC, "……好。我们一起把父亲找回来，把真相带出去。"))
	return lines


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false
	Campaign.flags["edmund_notes"] = true
	battle.hint(tr("维克多是暗法师：暗魔法打魔防，克制理魔法"))


func talks() -> Array:
	return [["mira", "victor", "mira_victor"], ["edric", "lance", "edric_lance_ch10"]]


func talk_lines(key: String) -> Array:
	if key == "mira_victor":
		return [
			_l("米拉", C_MIRA, "……我见过你。十年前，雾沼的小孩们在沼泽边捡到过一个浑身是血的人。是你吧？"),
			_l("维克多", C_VICTOR, "是我。一个小姑娘给了我半块饼，还骂我把她的鞋弄脏了。"),
			_l("米拉", C_MIRA, "……那是我。"),
			_l("维克多", C_VICTOR, "那我欠你半块饼。……还有一句谢谢，迟了十年。"),
			_l("米拉", C_MIRA, "饼就算了。把研究所里那些人的仇报了，就当还清。"),
		]
	return [
		_l("兰斯", C_LANCE, "少主。这里的墙上……刻满了名字。"),
		_l("艾德里克", C_EDRIC, "实验体的名字。……每一个，都曾经是某个村子里的人。"),
		_l("兰斯", C_LANCE, "领主大人看到这些，一定也是这样的表情。"),
		_l("艾德里克", C_EDRIC, "……兰斯，把这些名字记下来。总有一天，要让所有人都知道。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["edmund_notes"] = true


func on_defeat() -> void:
	await battle.play_dialogue([
		_l("艾德里克", C_EDRIC, "原来……父亲看到的……就是这个……"),
		_l("", C_NARR, "研究所的门，又一次封上了。"),
	])


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "北山深处。藤蔓爬满了研究所的外墙，门口却插着崭新的白色火把。"),
		_l("清理部队枪兵", C_ENEMY, "里面那个疯子还在放暗魔法！已经倒了三个人了！"),
		_l("赫尔曼", C_BOSS, "不必急。他逃不出去。……把门守住，外面来的，一并清理。"),
	]
	if battle.get_unit("mira") != null:
		lines.append(_l("米拉", C_MIRA, "就是这里。……十年来，晚上总有灯。原来一直有人在。"))
	lines.append(_l("兰斯", C_LANCE, "教会的部队把研究所围住了。里面困着什么人。"))
	lines.append(_l("维克多", C_VICTOR, "（远处）滚开！谁都别过来！教会的、强盗的——谁靠近，谁就是灰！"))
	lines.append(_l("艾德里克", C_EDRIC, "那个声音……会不会就是父亲要见的人？"))
	lines.append(_l("奥斯卡", C_OSCAR, "他现在敌我不分。少主，要跟他说话，得您亲自走到他跟前。"))
	lines.append(_l("艾德里克", C_EDRIC, "我去。……先打进研究所！"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("葛温", C_GWEN, "那个法师就在中廊正中间，一步也不挪。可他连教会的人也打，咱们靠近了也得挨。"),
		_l("艾德里克", C_EDRIC, "我走到他身边【说得】。在那之前，别对他动手。"),
	]


func _victor_fight() -> Array:
	return [
		_l("维克多", C_VICTOR, "又一个……！都一样，都是来抢笔记的！"),
	]


func _victor_death() -> Array:
	return [
		_l("维克多", C_VICTOR, "等……等等……你们……不是教会的人……？"),
		_l("维克多", C_VICTOR, "埃德蒙大人的……笔记……八圣器……盾在废修道院……弓在天马峰……斧在布罗登……杖与剑……在神殿……"),
		_l("维克多", C_VICTOR, "教会……在偷……自己的……圣器……灰烬……傀儡……"),
		_l("艾德里克", C_EDRIC, "……！"),
	]


func _visit_hunter() -> Array:
	return [
		_l("猎户", C_NPC, "那座研究所？十年前封的时候，抬出来好多盖着白布的担架。没有一具棺材。"),
		_l("猎户", C_NPC, "我在山里打了一辈子猎，从没见过那样的「瘟疫」。……伤药拿着，小心点。"),
	]


func _boss() -> Array:
	return [
		_l("赫尔曼", C_BOSS, "研究所监察官，赫尔曼。……菲恩家的人，父子俩都喜欢往不该去的地方钻。"),
		_l("艾德里克", C_EDRIC, "你认识我父亲？他在哪里！"),
		_l("赫尔曼", C_BOSS, "在他该在的地方。很快，你也会去的——作为材料。"),
	]


func _boss_death() -> Array:
	return [
		_l("赫尔曼", C_BOSS, "大司祭大人……您的「作品」……一定会……完成……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "监察室里堆满了记录。最上面的一份，是新的押送令。"),
	]
	var v = battle.get_unit("victor")
	if v != null and v.is_alive() and v.is_player():
		lines.append(_l("维克多", C_VICTOR, "「火之巫女一名、叛教修女一名，押送圣都。因河道封锁，改由白鹭渡过河。」"))
		lines.append(_l("维克多", C_VICTOR, "……火之巫女。教会找了八百年的那个血脉。他们抓到了。"))
	else:
		lines.append(_l("兰斯", C_LANCE, "「火之巫女一名、叛教修女一名，押送圣都。因河道封锁，改由白鹭渡过河。」"))
	lines.append(_l("艾德里克", C_EDRIC, "火之巫女……红头发的……缇娅？"))
	lines.append(_l("奥斯卡", C_OSCAR, "少主认识？"))
	lines.append(_l("艾德里克", C_EDRIC, "北山道上，我们一起打过仗。后来在大河渡口约好了：王都再见。……父亲也说过，若她再遇险，要我替他还她这份人情。"))
	lines.append(_l("艾德里克", C_EDRIC, "白鹭渡，在去圣都的路上。……我们去截下那辆囚车。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "lab", "from": "marsh", "lines": [
		_l("", CB_NARR, "从雾沼往北，山路越走越窄。"),
		_l("", CB_NARR, "林子尽头，是教会十年前以「瘟疫」为名封掉的研究所。"),
	]}


func epilogue() -> Array:
	var captured: Array = Campaign.flags.get("arc1_captured", ["tia", "noya"])
	var lines: Array = [
		_l("", CB_NARR, "大河边的夜路上，铁笼车掉转了方向，往白鹭渡驶去。"),
	]
	if "noya" in captured:
		lines.append(_l("", CB_NARR, "笼子里，诺雅轻轻哼着一首歌。是修道院里教的、给睡不着的孩子唱的歌。"))
		lines.append(_l("缇娅", C_TIA, "……诺雅。你唱歌，真好听。"))
		lines.append(_l("诺雅", C_NOYA, "修道院的嬷嬷说，唱歌的时候，神会听见。……我不知道神还听不听我的。"))
		lines.append(_l("缇娅", C_TIA, "那我听着。……车子转弯了。不是往圣都的大路。"))
		lines.append(_l("诺雅", C_NOYA, "白鹭渡。……缇娅，你说，会有人来吗？"))
		lines.append(_l("缇娅", C_TIA, "会的。我们约好了的。……虽然，约的地方是王都。"))
	else:
		lines.append(_l("缇娅", C_TIA, "（车子转弯了。不是往圣都的大路。……手心里的火，还在。）"))
		lines.append(_l("缇娅", C_TIA, "（大家都还活着吗。……那个约好在王都见的人，还记得吗。）"))
	return [{"title": "押送圣都的夜路", "mood": "night", "lines": lines}]
