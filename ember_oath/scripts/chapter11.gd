class_name Chapter11
extends ChapterBase
## 第十一章「渡口重逢」：两篇合流。艾德里克一行在白鹭渡伏击押送缇娅（与诺雅）去圣都的教会队伍。
## 囚车是中立单位（不会被攻击），停在北岸大路的十字路口，被押送兵围着；我方任何人走到囚车旁【对话】，
## 囚车就打开，缇娅、诺雅回队（诺雅第 7 章没被擒、阵亡或转幕后则只有缇娅）。
## 第 6 回合开始时囚车还没打开，教会的渡船把它运走 → 败北。胜利：救出缇娅后击败押送队长贝尔纳。

const CHAPTER_TITLE := "第十一章 · 渡口重逢"
const VICTORY_TITLE := "第十一章 · 完"
const VICTORY_SUB := "约好的地方是王都。可重逢的地方，是渡口。"
const DEFEAT_SUB := "白鹭渡的水，把一切都带走了……"
const BG := ""

## 32×22。大河（~）横贯中间：西桥、东桥两座木桥，正中一片浅滩（w）可以涉水；
## 北岸一条东西大路，囚车停在大路与北上道路的十字路口，押送队长贝尔纳在北边路口的堡垒上；
## 大路两侧是教会的营帐（A、栅栏 P），东边河岸有渡船码头。我方从南岸出发，南岸有两户人家。
const MAP := [
	"................R...............",
	".FF...F...PPPPP.R..PPPPP....h.F.",
	".F.....h...A.A..R...A.A...FF.h..",
	"....FF..........T...............",
	"h.H.....F..A....R............FF.",
	"...F............R........F......",
	"................R...............",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	"...h...R................R..RR...",
	"~~~....R...........h....R.h.B...",
	"~~~~~~~B~~~~~~~ww~~~~~~~B~~~BB~~",
	"~~~~~~~B~~~~~~wwww~~~~~~B~~~~~~~",
	"~~~~~~~B~~~~~~~ww~~~~~~~B~~~~~~~",
	".......R....~~.RRR......R....~~~",
	".FF.h..R..FF....R...F...R.......",
	"..F....R.....h..R..h....R..FF...",
	".......RRRRRRRRRRRRRRRRRR...F...",
	".h.H.F..........R............D..",
	"..D.D......F....R....F....hDH.F.",
	"...FF.......F...R.....F......F..",
	"......h..F......R........F......",
	"................R...............",
]

const LEVELS := []

const CAGE_TOWED := 6             # 第 6 回合开始时囚车还没打开 → 被渡船运走（败北）
const VISIT_FERRYMAN := Vector2i(3, 17)
const VISIT_WIDOW := Vector2i(28, 18)
const VISIT_NORTH := Vector2i(2, 4)

## 缇娅、诺雅：名单为空（直接从本章开打的测试）时用的默认数值
const TIA_FALLBACK := {"name": "缇娅", "class": "炎刃使", "level": 5,
	"hp": 36, "pwr": 13, "skl": 15, "spd": 16, "dfn": 9, "res": 5, "mov": 6,
	"weapons": ["ember_blade"], "items": ["vulnerary"], "wexp": {"sword": 71},
	"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
	"color": Color(0.95, 0.40, 0.22), "hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12),
	"armor": Color(0.72, 0.28, 0.16)}
const NOYA_FALLBACK := {"name": "诺雅", "class": "修女", "level": 9,
	"hp": 21, "pwr": 7, "skl": 8, "spd": 10, "dfn": 3, "res": 9, "mov": 5,
	"weapons": ["heal_staff"], "items": ["vulnerary"],
	"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 50},
	"color": Color(0.95, 0.92, 0.85), "hair": "ponytail", "hair_color": Color(0.85, 0.75, 0.50),
	"armor": Color(0.92, 0.90, 0.84)}

const C_TIA := Color(1.0, 0.62, 0.45)
const C_NOYA := Color(1.0, 0.95, 0.8)
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

const _SOLDIER := {"name": "押送兵", "class": "枪兵", "faction": "enemy", "level": 10,
	"hp": 29, "pwr": 10, "skl": 9, "spd": 8, "dfn": 8, "res": 2, "mov": 5,
	"weapons": ["iron_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _KNIGHT := {"name": "押送骑士", "class": "骑士", "faction": "enemy", "level": 10,
	"hp": 31, "pwr": 11, "skl": 8, "spd": 8, "dfn": 9, "res": 2, "mov": 7,
	"weapons": ["iron_lance", "javelin"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _ARMOR := {"name": "押送重甲", "class": "重甲兵", "faction": "enemy", "level": 10,
	"hp": 32, "pwr": 11, "skl": 7, "spd": 3, "dfn": 14, "res": 1, "mov": 4,
	"weapons": ["iron_lance"], "color": Color(0.70, 0.70, 0.74),
	"hair": "short", "armor": Color(0.74, 0.74, 0.80)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 9,
	"hp": 26, "pwr": 9, "skl": 10, "spd": 8, "dfn": 4, "res": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 10,
	"hp": 25, "pwr": 11, "skl": 8, "spd": 8, "dfn": 3, "res": 9, "mov": 5,
	"weapons": ["fire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _CLERIC := {"name": "随军修女", "class": "修女", "faction": "enemy", "level": 9,
	"hp": 22, "pwr": 7, "skl": 7, "spd": 8, "dfn": 3, "res": 8, "mov": 5,
	"weapons": ["heal_staff"], "items": ["vulnerary"], "color": Color(0.95, 0.92, 0.86),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.84)}

const UNITS := [
	# 我方：名单里有存档时用存档；这里只给位置和直接进本章时的默认数值
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 10,
		"hp": 30, "pwr": 9, "skl": 12, "spd": 12, "dfn": 8, "res": 4, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(16, 20), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 10,
		"hp": 31, "pwr": 10, "skl": 9, "spd": 8, "dfn": 9, "res": 2, "mov": 7,
		"weapons": ["iron_lance", "javelin"], "items": [],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(15, 20), "color": Color(0.35, 0.55, 0.40),
		"hair": "short", "hair_color": Color(0.35, 0.28, 0.20), "armor": Color(0.45, 0.60, 0.48)},
	{"id": "gwen", "name": "葛温", "class": "骑士", "faction": "player", "level": 9,
		"hp": 29, "pwr": 10, "skl": 8, "spd": 11, "dfn": 8, "res": 1, "mov": 7,
		"weapons": ["iron_lance", "steel_lance"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 50, "skl": 35, "spd": 50, "dfn": 25, "res": 15},
		"pos": Vector2i(17, 20), "color": Color(0.70, 0.35, 0.30),
		"hair": "ponytail", "hair_color": Color(0.85, 0.50, 0.20), "armor": Color(0.68, 0.38, 0.32)},
	{"id": "oscar", "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 11,
		"hp": 33, "pwr": 11, "skl": 8, "spd": 3, "dfn": 15, "res": 1, "mov": 4,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(16, 21), "color": Color(0.50, 0.52, 0.60),
		"hair": "short", "hair_color": Color(0.45, 0.42, 0.40), "armor": Color(0.60, 0.62, 0.70)},
	{"id": "mira", "name": "米拉", "class": "枪兵", "faction": "player", "level": 10,
		"hp": 28, "pwr": 9, "skl": 10, "spd": 12, "dfn": 7, "res": 3, "mov": 5,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 40, "skl": 50, "spd": 55, "dfn": 25, "res": 25},
		"pos": Vector2i(15, 21), "color": Color(0.40, 0.62, 0.55),
		"hair": "ponytail", "hair_color": Color(0.30, 0.22, 0.16), "armor": Color(0.42, 0.58, 0.50)},
	{"id": "victor", "name": "维克多", "class": "暗法师", "faction": "player", "level": 10,
		"hp": 25, "pwr": 10, "skl": 7, "spd": 7, "dfn": 5, "res": 10, "mov": 5,
		"weapons": ["flux"], "items": ["vulnerary"],
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45},
		"pos": Vector2i(17, 21), "color": Color(0.34, 0.30, 0.44),
		"hair": "short", "hair_color": Color(0.22, 0.20, 0.26), "armor": Color(0.30, 0.28, 0.38)},
	# 囚车：中立，不动，谁也打不了。我方任何人走到旁边【对话】就能打开
	{"id": "cage", "name": "囚车", "class": "重甲兵", "faction": "npc", "level": 1,
		"hp": 40, "pwr": 0, "skl": 0, "spd": 0, "dfn": 15, "res": 15, "mov": 0,
		"weapons": [], "stationary": true, "sprite": "cage",
		"pos": Vector2i(16, 7), "color": Color(0.42, 0.40, 0.38),
		"hair": "hood", "hair_color": Color(0.30, 0.30, 0.32), "armor": Color(0.36, 0.34, 0.32)},
	# 敌方：南岸埋伏
	{"id": "soldier1", "pos": Vector2i(10, 15)},
	{"id": "archer1", "pos": Vector2i(20, 15), "hold": true},
	{"id": "knight1", "pos": Vector2i(4, 15)},
	{"id": "soldier2", "pos": Vector2i(26, 16), "hold": true},
	# 桥头与浅滩
	{"id": "armor1", "pos": Vector2i(7, 9), "hold": true},
	{"id": "armor2", "pos": Vector2i(24, 9), "hold": true},
	{"id": "soldier3", "pos": Vector2i(15, 9)},
	{"id": "archer2", "pos": Vector2i(17, 9), "hold": true},
	# 囚车四周的押送兵
	{"id": "soldier4", "pos": Vector2i(15, 7), "hold": true, "items": ["vulnerary"]},
	{"id": "armor3", "pos": Vector2i(17, 7), "hold": true},
	{"id": "cleric1", "pos": Vector2i(16, 6), "hold": true},
	{"id": "mage1", "pos": Vector2i(14, 5), "hold": true},
	{"id": "archer3", "pos": Vector2i(18, 5), "hold": true},
	# 营帐一带
	{"id": "knight3", "pos": Vector2i(12, 4)},
	{"id": "soldier6", "pos": Vector2i(12, 3), "hold": true},
	{"id": "mage2", "pos": Vector2i(21, 3), "hold": true},
	{"id": "archer4", "pos": Vector2i(4, 6)},
	{"id": "mage3", "pos": Vector2i(25, 4)},
	# 渡船码头
	{"id": "knight4", "pos": Vector2i(28, 7), "hold": true},
	{"id": "soldier7", "pos": Vector2i(27, 8), "hold": true},
	# 押送队长贝尔纳：北边路口的堡垒上
	{"id": "bernard", "name": "贝尔纳", "class": "骑士", "faction": "enemy", "level": 13,
		"hp": 38, "pwr": 14, "skl": 11, "spd": 10, "dfn": 12, "res": 4, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "boss": true, "stationary": true, "sprite": "knight",
		"items": ["elixir"],
		"pos": Vector2i(16, 3), "color": Color(0.84, 0.82, 0.88),
		"hair": "short", "hair_color": Color(0.60, 0.52, 0.36), "armor": Color(0.92, 0.90, 0.96)},
]

## 第 4 回合大路两头来骑士；第 6 回合渡船靠岸，又下来一批
const WAVES := {
	4: [{"id": "knight_r1", "pos": Vector2i(0, 7)}, {"id": "knight_r2", "pos": Vector2i(31, 7)}],
	6: [{"id": "soldier_r1", "pos": Vector2i(28, 8)}, {"id": "soldier_r2", "pos": Vector2i(16, 0)},
		{"id": "archer_r1", "pos": Vector2i(31, 4)}],
}


func chapter_id() -> String:
	return "ch11"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 6


func forced_ids() -> Array:
	return ["edric"]


func extra_deploy_slots() -> Array:
	return [Vector2i(14, 21), Vector2i(18, 21), Vector2i(14, 20), Vector2i(18, 20)]


func templates() -> Dictionary:
	return {"soldier": _SOLDIER, "knight": _KNIGHT, "armor": _ARMOR, "archer": _ARCHER,
		"mage": _MAGE, "cleric": _CLERIC}


## 救出前：艾德里克阵亡或囚车被运走（囚车从地图上消失）就败北；救出后：艾德里克或缇娅阵亡
func lose_ids() -> Array:
	if flags.get("tia_freed", false):
		return ["edric", "tia"]
	if flags.get("cage_opened", false):
		return ["edric"]
	return ["edric", "cage"]


func extra_slots() -> Array:
	return [Vector2i(14, 21), Vector2i(18, 21), Vector2i(14, 20), Vector2i(18, 20), Vector2i(13, 21), Vector2i(19, 21)]


func shop_items() -> Array:
	return ["vulnerary", "elixir", "iron_lance", "steel_lance", "javelin", "iron_sword", "steel_sword", "flux", "heal_staff"]


func is_won() -> bool:
	if not flags.get("cage_opened", false):
		return false
	var b = battle.get_unit("bernard")
	if b != null and not b.is_alive():
		return true
	return super.is_won()


func win_condition() -> String:
	if flags.get("cage_opened", false):
		return tr("击败押送队长贝尔纳")
	return tr("打开囚车，救出缇娅后击败贝尔纳")


func lose_condition() -> String:
	if flags.get("tia_freed", false):
		return tr("艾德里克或缇娅阵亡")
	return tr("艾德里克阵亡，或第 6 回合囚车被运走")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if t == CAGE_TOWED and not flags.get("cage_opened", false):
		var c = battle.get_unit("cage")
		if c != null:
			flags["cage_lost"] = true
			Audio.play_sfx("reinforce")
			battle.show_banner(tr("囚车被运走了！"), Color(1.0, 0.4, 0.3))
			await battle.play_dialogue(_cage_towed())
			battle.units.erase(c)
			c.queue_free()
			await battle.check_end_conditions()
			return
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t == CAGE_TOWED - 1 and not flags.get("cage_opened", false) and not flags.get("warn", false):
		flags["warn"] = true
		battle.show_banner(tr("渡船靠岸了！"), Color(1.0, 0.6, 0.3))
		await battle.play_dialogue(_ferry_warning())


func on_before_combat(att, def) -> void:
	if "bernard" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "bernard" else att
		await battle.play_dialogue(_boss(other.unit_id))


func on_after_combat(att, def, def_died: bool) -> void:
	if def.unit_id == "bernard" and def_died:
		await battle.play_dialogue(_boss_death())
	# 囚车是中立单位，正常打不到；万一被打了（例如自动测试）也不会坏
	for u in [att, def]:
		if u.unit_id == "cage":
			u.hp = u.max_hp
			u.visible = true
			u.modulate.a = 1.0
			u.scale = Vector2.ONE


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_FERRYMAN:
		await battle.play_dialogue(_visit_ferryman())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))
	elif pos == VISIT_WIDOW:
		await battle.play_dialogue(_visit_widow())
		battle.add_gold(1500)
		battle.notify(tr("获得 1500G"))
	elif pos == VISIT_NORTH:
		await battle.play_dialogue(_visit_north())
		u.receive("steel_sword")
		battle.notify(tr("获得 钢剑"))


## 囚车：我方任何人都能【对话】（整备时不列进「需要谁出击」的提示）
func recruits() -> Dictionary:
	if battle == null or battle.prep != null or flags.get("cage_opened", false):
		return {}
	var ids: Array = []
	for u in battle.units:
		if u.is_player():
			ids.append(u.unit_id)
	return {"cage": ids}


## 打开囚车：囚车不入队，从地图上拿掉，缇娅（和诺雅）从名单回队，站到囚车的位置附近
func on_recruit(u) -> void:
	var t = get_recruit_target(u)
	if t == null:
		return
	if t.unit_id != "cage":
		await super.on_recruit(u)
		return
	var pos: Vector2i = t.grid_pos
	var noya_in := _noya_captured()
	await battle.play_dialogue(_cage_open(u.unit_id, noya_in))
	flags["cage_opened"] = true
	battle.units.erase(t)
	t.queue_free()
	Audio.play_sfx("coin")
	var fresh := Campaign.roster.is_empty()
	var tia = battle.rejoin_unit("tia", pos, "player", TIA_FALLBACK if fresh else {})
	if tia != null:
		flags["tia_freed"] = true
		if fresh:
			battle.notify(tr("%s 回到了队伍！") % tr("缇娅"))
	var noya = null
	if noya_in:
		noya = battle.rejoin_unit("noya", pos, "player", NOYA_FALLBACK if fresh else {})
		if noya != null and fresh:
			battle.notify(tr("%s 回到了队伍！") % tr("诺雅"))
	await battle.play_dialogue(_reunion(noya != null))
	battle._refresh_objectives()
	battle.hint(tr("救出了缇娅！击败北边堡垒上的押送队长贝尔纳"))


## 第 7 章篇末诺雅也被擒了、而且还能回队（没阵亡、没转幕后）
func _noya_captured() -> bool:
	var cap: Array = Campaign.flags.get("arc1_captured", ["tia", "noya"])
	if not "noya" in cap:
		return false
	if Campaign.roster.is_empty():
		return true
	return Campaign.can_rejoin("noya") or Campaign.status_of("noya") == "active"


func talks() -> Array:
	return [["tia", "edric", "tia_edric_ch11"], ["noya", "victor", "noya_victor"]]


func talk_lines(key: String) -> Array:
	if key == "tia_edric_ch11":
		return [
			_l("缇娅", C_TIA, "……喂。你怎么知道我在那辆车上？"),
			_l("艾德里克", C_EDRIC, "北山的研究所里有押送令。上面写着「火之巫女」。……我只认识一个会用火的红头发。"),
			_l("缇娅", C_TIA, "研究所？你不是在菲恩城当少主吗，跑那种地方去干什么。"),
			_l("艾德里克", C_EDRIC, "父亲失踪了。他在查教会偷圣器的事，查着查着，就没有回来。"),
			_l("缇娅", C_TIA, "……对不起。我不知道。"),
			_l("艾德里克", C_EDRIC, "父亲临走前说，若你再遇险，要我替他还你人情。……所以这不算我救你。是父亲救你。"),
			_l("缇娅", C_TIA, "那等找到他，我当面谢他。……在那之前，我的剑借你用。"),
		]
	return [
		_l("诺雅", C_NOYA, "你身上的魔力……是暗魔法。你以前是教会的人吧？"),
		_l("维克多", C_VICTOR, "研究员。你呢，见习修女小姐？这身修女服，是教会的式样。"),
		_l("诺雅", C_NOYA, "……以前是。审判官大人要烧村子的那天，我就不是了。"),
		_l("维克多", C_VICTOR, "那我们都是逃兵。……我逃了十年，现在才敢回头看。"),
		_l("诺雅", C_NOYA, "回头看到了什么？"),
		_l("维克多", C_VICTOR, "看到了自己做过的事。……修女小姐，你还祈祷吗？替我也祈祷一次吧。"),
		_l("诺雅", C_NOYA, "……好。不过要你自己也一起。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	if flags.get("cage_lost", false):
		await battle.play_dialogue([
			_l("艾德里克", C_EDRIC, "囚车……被运走了……"),
			_l("", C_NARR, "渡船顺流而下，消失在了河雾里。"),
		])
		return
	var tia = battle.get_unit("tia")
	if tia != null and not tia.is_alive():
		await battle.play_dialogue([
			_l("缇娅", C_TIA, "好不容易……才出了笼子……"),
			_l("", C_NARR, "白鹭渡的水，把一切都带走了。"),
		])
		return
	await battle.play_dialogue([
		_l("艾德里克", C_EDRIC, "缇娅……父亲……对不起……"),
		_l("", C_NARR, "白鹭渡的水，把一切都带走了。"),
	])


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "白鹭渡。大河在这里放宽了身子，水浅的地方，能看见河底的白石。"),
		_l("", C_NARR, "北岸的大路上，一辆铁笼车停在十字路口，四周都是白袍的押送兵。"),
		_l("贝尔纳", C_BOSS, "渡船还没到？……再催！大司祭大人要的人，耽搁一刻都是罪过。"),
	]
	var w := _first_here(["lance", "oscar", "gwen"])
	if w != "":
		lines.append(_ret(w, "囚车停在北岸大路的正中间。押送兵围了两圈，桥头也有人守。"))
	else:
		lines.append(_l("", C_NARR, "囚车停在北岸大路的正中间。押送兵围了两圈，桥头也有人守。"))
	if battle.get_unit("victor") != null:
		lines.append(_l("维克多", C_VICTOR, "东边的码头上已经在收缆绳了。渡船一靠岸，囚车就会被推上去。"))
	if battle.get_unit("mira") != null:
		lines.append(_l("米拉", C_MIRA, "河中间那片浅滩能涉水过去，就是走得慢。桥远，但路好走。"))
	w = _first_here(["oscar", "lance", "gwen"])
	if w != "":
		lines.append(_ret(w, "少主，我们兵力不多。要救人，就得快。"))
	lines.append(_l("艾德里克", C_EDRIC, "……谁先到囚车旁边，谁就把笼门打开。北岸见！"))
	return lines


func _turn2_hint() -> Array:
	var lines: Array = []
	var w := _first_here(["gwen", "lance", "oscar"])
	if w != "":
		lines.append(_ret(w, "囚车是锁着的，不用打，走到旁边【对话】就能撬开！谁都行！"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "囚车是锁着的，不用打，走到旁边【对话】就能撬开！谁都行！"))
	w = _first_here(["lance", "oscar", "gwen"])
	if w != "":
		lines.append(_ret(w, "渡船大概第 6 回合靠岸。在那之前，必须打开囚车。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "渡船大概第 6 回合靠岸。在那之前，必须打开囚车。"))
	return lines


func _ferry_warning() -> Array:
	return [
		_l("", C_NARR, "下游传来了号角声。一条渡船正在往码头靠。"),
		_l("押送兵", C_ENEMY, "渡船来了！准备把囚车推上船！"),
		_l("艾德里克", C_EDRIC, "来不及了……！这个回合，一定要打开囚车！"),
	]


func _cage_towed() -> Array:
	return [
		_l("押送兵", C_ENEMY, "推！上船！快！"),
		_l("", C_NARR, "铁笼车被推上了渡船。缆绳一松，船顺着水流驶远了。"),
	]


func _cage_open(by: String, noya_in: bool) -> Array:
	var lines: Array = []
	match by:
		"edric":
			lines.append(_l("艾德里克", C_EDRIC, "退后！我把锁砍开！"))
		"lance":
			lines.append(_l("兰斯", C_LANCE, "笼门的锁是教会的样式……一枪就够了。"))
		"gwen":
			lines.append(_l("葛温", C_GWEN, "看我的！……嘿！开了！"))
		"oscar":
			lines.append(_l("奥斯卡", C_OSCAR, "这种锁，我在城门上换过一百把。……开了。"))
		"mira":
			lines.append(_l("米拉", C_MIRA, "别动，我把锁撬开。……好了！"))
		"victor":
			lines.append(_l("维克多", C_VICTOR, "锁上刻着封火的咒文……解开它，比解开研究所的门简单多了。"))
		_:
			lines.append(_l("", C_NARR, "沉重的铁锁被砸开了。"))
	lines.append(_l("", C_NARR, "笼门吱呀一声打开了。"))
	if noya_in:
		lines.append(_l("诺雅", C_NOYA, "缇娅，门开了……！是来救我们的人！"))
	return lines


func _reunion(noya_in: bool) -> Array:
	var lines: Array = [
		_l("缇娅", C_TIA, "……你？"),
		_l("艾德里克", C_EDRIC, "缇娅。……我们约的是王都。这里不是王都啊。"),
		_l("缇娅", C_TIA, "……你也不是来逛街的吧。"),
		_l("艾德里克", C_EDRIC, "嗯。来接一个说好要再见的人。……能走吗？"),
		_l("缇娅", C_TIA, "能走，能打。……把他们的剑还我一把就行。不，不用了——我手里有火。"),
	]
	if noya_in:
		lines.append(_l("诺雅", C_NOYA, "我、我会治伤！请让我也一起！"))
	lines.append(_l("艾德里克", C_EDRIC, "押送队长在北边的堡垒上。打倒他，我们一起离开这里。"))
	return lines


func _visit_ferryman() -> Array:
	return [
		_l("摆渡人", C_NPC, "这几天河上不太平。教会的人征了我的船，说是要运「要紧的货」。"),
		_l("摆渡人", C_NPC, "要紧的货？我看见了，是笼子里的两个姑娘。……这瓶药给你们，替我把她们放出来。"),
	]


func _visit_widow() -> Array:
	return [
		_l("寡妇", C_NPC, "我丈夫以前是教会的船工。去年他看见了不该看的东西，就再也没回家。"),
		_l("寡妇", C_NPC, "这是他留下的钱。……用在跟教会作对的人身上，他会高兴的。"),
	]


func _visit_north() -> Array:
	return [
		_l("村民", C_NPC, "你们是来劫囚车的？……小声点，我什么都没看见。"),
		_l("村民", C_NPC, "这把剑是押送兵落在我家的。拿去用吧，算我没看见你们。"),
	]


func _boss(other_id: String) -> Array:
	var lines: Array = [
		_l("贝尔纳", C_BOSS, "押送队长贝尔纳。……劫教会的囚车，是要上火刑架的重罪。"),
	]
	if other_id == "tia":
		lines.append(_l("缇娅", C_TIA, "火刑架？那正好。我手里的火，就是从那上面捡回来的。"))
	elif other_id == "edric":
		lines.append(_l("艾德里克", C_EDRIC, "菲恩领主之子艾德里克。我父亲失踪，和你们教会脱不了干系。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "（远处）罪？把不该抓的人关进笼子，才是罪！"))
	lines.append(_l("贝尔纳", C_BOSS, "嘴硬。……那就看看，是你们的骨头硬，还是我的枪硬！"))
	return lines


func _boss_death() -> Array:
	return [
		_l("贝尔纳", C_BOSS, "火种……出笼了……审判官大人……恕罪……"),
	]


func _post_battle() -> Array:
	var noya = battle.get_unit("noya")
	var noya_in: bool = noya != null and noya.is_alive() and noya.is_player()
	var lines: Array = [
		_l("", C_NARR, "押送队溃散了。空空的铁笼车翻倒在路边，被河风吹得吱呀作响。"),
		_l("缇娅", C_TIA, "……谢谢。真的。"),
		_l("艾德里克", C_EDRIC, "你和你的同伴……其他人呢？"),
	]
	var names := _scattered_names()
	if names.is_empty():
		lines.append(_l("缇娅", C_TIA, "白垣镇那一夜，大家分头逃了。……我不知道还有谁活着。"))
	else:
		lines.append(_l("缇娅", C_TIA, tr("白垣镇那一夜，大家分头逃了。%s……我不知道他们在哪。") % tr("、").join(PackedStringArray(names))))
	if noya_in:
		lines.append(_l("诺雅", C_NOYA, "押送兵说过，有人往东边的港口去了。……银湾港。"))
	else:
		var w := _first_here(["lance", "oscar", "gwen"])
		if w != "":
			lines.append(_ret(w, "押送兵的文书里提到，东边的银湾港在搜捕「巫女的同党」。"))
		else:
			lines.append(_l("艾德里克", C_EDRIC, "押送兵的文书里提到，东边的银湾港在搜捕「巫女的同党」。"))
	lines.append(_l("艾德里克", C_EDRIC, "银湾港……从那里坐船，也能去圣都。父亲的下落，八成也在圣都。"))
	lines.append(_l("缇娅", C_TIA, "那就一起走。你找你的父亲，我找我的同伴。"))
	lines.append(_l("艾德里克", C_EDRIC, "……嗯。一起走。"))
	return lines


## 白垣镇那一夜四散的同伴：入过队、剧情里还活着的才提（名字已经过 tr）
func _scattered_names() -> Array:
	var out: Array = []
	for pair in [["kain", "凯因"], ["nina", "妮娜"], ["cyril", "西里尔"], ["sparrow", "小雀"]]:
		if Campaign.has_member(pair[0]) and Campaign.alive_in_story(pair[0]):
			out.append(tr(pair[1]))
	return out


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "riverford", "from": "lab", "lines": [
		_l("", CB_NARR, "从北山下来，一路往东南，赶了两天两夜。"),
		_l("", CB_NARR, "白鹭渡。押送令上写着，囚车将从这里过河。"),
	]}


func epilogue() -> Array:
	return [{"title": "圣都 · 大圣堂", "mood": "church", "lines": [
		_l("塞拉斯", CB_SILAS, "……白鹭渡的押送队，全灭。囚车被劫了。"),
		_l("塞拉斯", CB_SILAS, "劫车的是菲恩领主之子。属下……这就带兵去追。"),
		_l("", CB_NARR, "莫尔甘没有回答。他看着窗外，看了很久。"),
		_l("塞拉斯", CB_SILAS, "……"),
		_l("莫尔甘", CB_MORGAN, "不急。火种自己会走到神殿来。"),
		_l("莫尔甘", CB_MORGAN, "领主的儿子在找父亲，巫女在找同伴。……人总会走向自己想见的人。我们只要在那里等着。"),
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
