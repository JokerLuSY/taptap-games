class_name Chapter15
extends ChapterBase
## 第十五章「风鸣峡谷」：得知埃德蒙被关在黑石地牢，一行人抄近路穿过风鸣峡谷。
## 峡谷底一条长路由西向东；两侧崖壁（X）上是高地（北侧西段高度 2、东段 3，南侧 2），只有几处缓坡（丘陵）能爬上去，高处有弓手、狙击手。
## 东方剑客朔（中立）在峡谷中段独自跟教会兵交手：缇娅走过去【对话】入队。第 3 回合敌方天马骑士从两侧飞来。
## 胜利：击败北侧高台堡垒上的教会狙击手西蒙。

const CHAPTER_TITLE := "第十五章 · 风鸣峡谷"
const VICTORY_TITLE := "第十五章 · 完"
const VICTORY_SUB := "风停了。峡谷的尽头，黑石地牢的塔影浮在雾里。"
const DEFEAT_SUB := "峡谷里的风，一直吹着。吹散了脚印，也吹散了名字……"
const BG := ""

## 34×20。上下两排山（M）；第 7、13 行是崖壁，缓坡在 (9,7)、(23,7)、(14,13)、(28,13)。
## 北侧高地的东段（高度 3）由 (21,4) 的台阶和 (23,7) 的缓坡上去，西蒙守在 (30,3) 的堡垒上；
## 西北高地有一户猎人小屋，南侧高地有一户牧人家。
const MAP := [
	"MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM",
	"MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM",
	".....M.M...M......MM.X.M....M.....",
	"h...F.......h......T.X......D.T.h.",
	"...hH...F............h.....F.....h",
	".........h........hF.X.........DF.",
	"...F.hh.......Fh...hFX............",
	"XXXXXXXXXhXXXXXXXXXXXXXhXXXXXXXXXX",
	"......F.Z.....Z......Z.h......h..h",
	"...RRRRRR...............RRRRRR....",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR",
	".......F....RRRRRRRR...Z........hh",
	"......h.......F.....F..........h..",
	"XXXXXXXXXXXXXXhXXXXXXXXXXXXXhXXXXX",
	"...h.......F..F...........F.F.....",
	"..h...H..F....h....FT.......h..F..",
	"..........FF............F.........",
	"MMM..MMM.M..M.....M...MM..M.MMMM.M",
	"MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM",
	"MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM",
]

const LEVELS := [
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"2222222222222222222222333333333333",
	"2222222222222222222222333333333333",
	"2222222222222222222223333333333333",
	"2222222222222222222222333333333333",
	"2222222222222222222222333333333333",
	"1111111112111111111111121111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
	"2222222222222222222222222222222222",
	"2222222222222222222222222222222222",
	"2222222222222222222222222222222222",
	"2222222222222222222222222222222222",
	"2222222222222222222222222222222222",
	"1111111111111111111111111111111111",
	"1111111111111111111111111111111111",
]

const VISIT_HUNTER := Vector2i(4, 4)
const VISIT_HERDER := Vector2i(6, 15)
const SHUO_FIGHT_TURNS := [2, 3, 4]   # 这几回合开始时，还没入队的朔会和身边的教会兵交手

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(0.95, 0.8, 0.45)
const C_HAGEN := Color(0.8, 0.7, 0.6)
const C_LISS := Color(0.75, 0.95, 0.8)
const C_SHUO := Color(0.9, 0.9, 0.95)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_VICTOR := Color(0.75, 0.65, 0.95)
const C_SELENE := Color(0.8, 0.9, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _SOLDIER := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 13,
	"hp": 32, "pwr": 12, "skl": 10, "spd": 10, "dfn": 10, "res": 4, "mov": 5,
	"weapons": ["steel_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _MYRM := {"name": "教会剑士", "class": "剑士", "faction": "enemy", "level": 13,
	"hp": 30, "pwr": 11, "skl": 15, "spd": 16, "dfn": 7, "res": 5, "mov": 5,
	"weapons": ["steel_sword"], "color": Color(0.78, 0.76, 0.80),
	"hair": "short", "hair_color": Color(0.25, 0.22, 0.20), "armor": Color(0.74, 0.72, 0.78)}
const _FIGHTER := {"name": "教会斧兵", "class": "战士", "faction": "enemy", "level": 14,
	"hp": 38, "pwr": 14, "skl": 9, "spd": 10, "dfn": 7, "res": 2, "mov": 5,
	"weapons": ["steel_axe"], "color": Color(0.70, 0.64, 0.56),
	"hair": "short", "hair_color": Color(0.32, 0.24, 0.18), "armor": Color(0.66, 0.60, 0.52)}
const _KNIGHT := {"name": "圣焰骑士", "class": "骑士", "faction": "enemy", "level": 14,
	"hp": 34, "pwr": 13, "skl": 11, "spd": 10, "dfn": 12, "res": 4, "mov": 7,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _ARMOR := {"name": "圣焰重甲兵", "class": "重甲兵", "faction": "enemy", "level": 14,
	"hp": 37, "pwr": 14, "skl": 8, "spd": 5, "dfn": 16, "res": 4, "mov": 4,
	"weapons": ["steel_lance"], "color": Color(0.70, 0.68, 0.66),
	"hair": "short", "hair_color": Color(0.30, 0.26, 0.22), "armor": Color(0.74, 0.72, 0.70)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 13,
	"hp": 29, "pwr": 12, "skl": 13, "spd": 12, "dfn": 6, "res": 5, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _SNIPER := {"name": "教会狙击手", "class": "狙击手", "faction": "enemy", "level": 2,
	"hp": 34, "pwr": 13, "skl": 15, "spd": 13, "dfn": 9, "res": 6, "mov": 5,
	"weapons": ["longbow"], "color": Color(0.74, 0.72, 0.64),
	"hair": "hood", "armor": Color(0.70, 0.68, 0.58)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 13,
	"hp": 26, "pwr": 13, "skl": 11, "spd": 11, "dfn": 5, "res": 11, "mov": 5,
	"weapons": ["thunder"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _CLERIC := {"name": "随军修女", "class": "修女", "faction": "enemy", "level": 13,
	"hp": 25, "pwr": 12, "skl": 9, "spd": 12, "dfn": 4, "res": 13, "mov": 5,
	"weapons": ["heal_staff"], "items": ["vulnerary"], "color": Color(0.94, 0.92, 0.86),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.84)}
const _PEGASUS := {"name": "天马骑士", "class": "天马骑士", "faction": "enemy", "level": 14,
	"hp": 28, "pwr": 11, "skl": 12, "spd": 16, "dfn": 7, "res": 12, "mov": 7,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.90, 0.92, 0.98),
	"hair": "short", "hair_color": Color(0.70, 0.60, 0.40), "armor": Color(0.88, 0.90, 0.96)}
const _GRAY := {"name": "灰袍众", "class": "探子", "faction": "enemy", "level": 14,
	"hp": 30, "pwr": 11, "skl": 15, "spd": 16, "dfn": 7, "res": 6, "mov": 6,
	"weapons": ["steel_sword"], "color": Color(0.52, 0.52, 0.56),
	"hair": "hood", "armor": Color(0.46, 0.46, 0.50)}

const UNITS := [
	# 我方：峡谷西口（名单为空直接开打时用这些数值）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 15,
		"hp": 33, "pwr": 13, "skl": 16, "spd": 16, "dfn": 10, "res": 7, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(3, 10), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 9,
		"hp": 37, "pwr": 15, "skl": 17, "spd": 19, "dfn": 11, "res": 6, "mov": 5,
		"weapons": ["ember_blade", "iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(3, 9), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 11,
		"hp": 34, "pwr": 13, "skl": 9, "spd": 8, "dfn": 12, "res": 3, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(2, 10), "color": Color(0.75, 0.55, 0.30),
		"hair": "spiky", "hair_color": Color(0.62, 0.38, 0.18), "armor": Color(0.55, 0.42, 0.30)},
	{"id": "liss", "pos": Vector2i(2, 9), "name": "莉丝", "class": "弓箭手", "faction": "player", "level": 12,
		"hp": 28, "pwr": 11, "skl": 14, "spd": 13, "dfn": 6, "res": 5, "mov": 5, "weapons": ["steel_bow", "iron_bow"],
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30}},
	{"id": "hagen", "pos": Vector2i(2, 11), "name": "哈根", "class": "战士", "faction": "player", "level": 12,
		"hp": 39, "pwr": 14, "skl": 9, "spd": 9, "dfn": 8, "res": 2, "mov": 5, "weapons": ["steel_axe", "hand_axe"],
		"growths": {"hp": 80, "pwr": 50, "skl": 35, "spd": 30, "dfn": 30, "res": 10}},
	{"id": "noya", "pos": Vector2i(1, 10), "name": "诺雅", "class": "修女", "faction": "player", "level": 13,
		"hp": 26, "pwr": 12, "skl": 10, "spd": 13, "dfn": 4, "res": 13, "mov": 5, "weapons": ["heal_staff", "mend_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 45}},
	{"id": "kain", "pos": Vector2i(3, 11), "name": "凯因", "class": "佣兵", "faction": "player", "level": 15,
		"hp": 35, "pwr": 13, "skl": 17, "spd": 18, "dfn": 9, "res": 4, "mov": 5, "weapons": ["steel_sword", "iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25, "res": 20}},
	{"id": "victor", "pos": Vector2i(1, 9), "name": "维克多", "class": "暗法师", "faction": "player", "level": 14,
		"hp": 29, "pwr": 13, "skl": 10, "spd": 9, "dfn": 6, "res": 13, "mov": 5, "weapons": ["flux"],
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45}},
	{"id": "lance", "pos": Vector2i(1, 11), "name": "兰斯", "class": "骑士", "faction": "player", "level": 14,
		"hp": 34, "pwr": 12, "skl": 11, "spd": 10, "dfn": 11, "res": 4, "mov": 7, "weapons": ["steel_lance", "javelin"],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20}},
	{"id": "nina", "pos": Vector2i(2, 12), "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 14,
		"hp": 30, "pwr": 12, "skl": 15, "spd": 14, "dfn": 5, "res": 5, "mov": 5, "weapons": ["steel_bow", "iron_bow"],
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15, "res": 25}},
	# 朔：东方剑客，绿色第三方，在峡谷中段自己和教会兵打（友军阶段行动）。缇娅【对话】入队
	{"id": "shuo", "name": "朔", "class": "剑士", "faction": "npc", "fights": true, "level": 12,
		"hp": 29, "pwr": 10, "skl": 16, "spd": 17, "dfn": 6, "res": 4, "mov": 5,
		"weapons": ["killing_edge", "iron_sword"], "wexp": {"sword": 71},
		"growths": {"hp": 65, "pwr": 40, "skl": 60, "spd": 60, "dfn": 20, "res": 25},
		"pos": Vector2i(16, 10), "color": Color(0.30, 0.32, 0.40),
		"hair": "ponytail", "hair_color": Color(0.10, 0.10, 0.12), "armor": Color(0.28, 0.30, 0.38)},
	# 敌方：峡谷底
	{"id": "soldier1", "pos": Vector2i(8, 9)},
	{"id": "myrm1", "pos": Vector2i(10, 11)},
	{"id": "fighter1", "pos": Vector2i(12, 10), "items": ["vulnerary"]},
	{"id": "soldier2", "pos": Vector2i(15, 10), "hold": true},
	{"id": "soldier3", "pos": Vector2i(17, 10), "hold": true},
	{"id": "myrm2", "pos": Vector2i(16, 9), "hold": true},
	{"id": "knight1", "pos": Vector2i(21, 10), "hold": true},
	{"id": "armor1", "pos": Vector2i(25, 10), "hold": true},
	{"id": "fighter2", "pos": Vector2i(28, 11), "hold": true},
	# 北侧高地
	{"id": "archer1", "pos": Vector2i(7, 4), "hold": true},
	{"id": "sniper1", "pos": Vector2i(19, 3), "hold": true},
	{"id": "mage1", "pos": Vector2i(24, 5)},
	{"id": "archer3", "pos": Vector2i(29, 5), "hold": true},
	# 南侧高地
	{"id": "sniper2", "pos": Vector2i(20, 15), "hold": true, "items": ["elixir"]},
	{"id": "mage2", "pos": Vector2i(26, 14), "hold": true},
	{"id": "cleric1", "pos": Vector2i(23, 15)},
	# 教会狙击手西蒙：北侧东段高台的堡垒上
	{"id": "simon", "name": "西蒙", "class": "狙击手", "faction": "enemy", "level": 4,
		"hp": 38, "pwr": 15, "skl": 17, "spd": 14, "dfn": 10, "res": 7, "mov": 5,
		"weapons": ["silver_bow", "longbow"], "items": ["vulnerary"], "boss": true, "stationary": true, "sprite": "archer",
		"pos": Vector2i(30, 3), "color": Color(0.70, 0.66, 0.56),
		"hair": "hood", "hair_color": Color(0.40, 0.32, 0.24), "armor": Color(0.66, 0.62, 0.52)},
]

## 增援：3 天马骑士从两侧高地飞来；5 东口骑兵；7 灰袍众从西口追来
const WAVES := {
	3: [{"id": "pegasus_r1", "pos": Vector2i(14, 3)}, {"id": "pegasus_r2", "pos": Vector2i(17, 16)}],
	5: [{"id": "knight_r1", "pos": Vector2i(33, 10)}, {"id": "knight_r2", "pos": Vector2i(32, 9)}, {"id": "myrm_r1", "pos": Vector2i(33, 11)}],
	7: [{"id": "graycloak_r1", "pos": Vector2i(0, 9)}, {"id": "graycloak_r2", "pos": Vector2i(0, 11)}],
}


func chapter_id() -> String:
	return "ch15"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 8


func extra_deploy_slots() -> Array:
	return [Vector2i(1, 8), Vector2i(1, 12), Vector2i(3, 12), Vector2i(4, 11), Vector2i(3, 8), Vector2i(4, 12)]


func templates() -> Dictionary:
	return {"soldier": _SOLDIER, "myrm": _MYRM, "fighter": _FIGHTER, "knight": _KNIGHT, "armor": _ARMOR, "archer": _ARCHER,
		"sniper": _SNIPER, "mage": _MAGE, "cleric": _CLERIC, "pegasus": _PEGASUS, "graycloak": _GRAY}


## 三主角（名单里没有加雷斯时不算）
func lose_ids() -> Array:
	var out := ["edric", "tia"]
	if battle != null and battle.get_unit("gareth") != null:
		out.append("gareth")
	return out


func extra_slots() -> Array:
	return [Vector2i(1, 8), Vector2i(1, 12), Vector2i(3, 12), Vector2i(4, 11), Vector2i(3, 8), Vector2i(4, 12),
		Vector2i(2, 8), Vector2i(4, 8), Vector2i(0, 10), Vector2i(0, 8), Vector2i(0, 12), Vector2i(5, 11),
		Vector2i(5, 12), Vector2i(4, 9), Vector2i(5, 8), Vector2i(0, 9), Vector2i(0, 11)]


func shop_items() -> Array:
	return ["vulnerary", "elixir", "steel_sword", "armorslayer", "steel_lance", "horseslayer", "steel_axe", "steel_bow", "longbow", "thunder", "flux", "mend_staff"]


func is_won() -> bool:
	var s = battle.get_unit("simon")
	return s != null and not s.is_alive()


func win_condition() -> String:
	return tr("击败教会狙击手西蒙")


func lose_condition() -> String:
	if battle != null and battle.get_unit("gareth") != null:
		return tr("艾德里克、缇娅或加雷斯阵亡")
	return tr("艾德里克或缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		if t == 3:
			battle.show_banner(tr("天马骑士来袭！"), Color(0.75, 0.85, 1.0))
			await battle.play_dialogue(_pegasus())
		else:
			battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
			if t == 7:
				await battle.play_dialogue(_graycloaks())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


## （旧的演出式交手，朔现在在友军阶段真打了，不再调用）
func _shuo_duel() -> void:
	var s = battle.get_unit("shuo")
	if s == null or not s.is_alive() or not s.is_npc():
		return
	for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var e = battle.board.unit_at(s.grid_pos + d)
		if e != null and e.is_alive() and not e.is_player() and not e.is_npc():
			e.hp = maxi(1, e.hp - 8)
			s.hp = maxi(12, s.hp - 4)
			e.queue_redraw()
			s.queue_redraw()
			battle.notify(tr("朔 与 %s 交手了") % tr(e.display_name))
			return


func on_before_combat(att, def) -> void:
	if "simon" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "simon" else att
		await battle.play_dialogue(_boss_liss() if other.unit_id == "liss" else _boss())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "simon" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_HUNTER:
		await battle.play_dialogue(_visit_hunter())
		u.receive("killer_bow")
		battle.notify(tr("获得 锐锋弓"))
	elif pos == VISIT_HERDER:
		await battle.play_dialogue(_visit_herder())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))


func recruits() -> Dictionary:
	return {"shuo": ["tia"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return [
		_l("朔", C_SHUO, "……别过来。这些人是冲我来的，与你无关。"),
		_l("缇娅", C_TIA, "冲你来的？教会的人，为什么要追一个外乡的剑客？"),
		_l("朔", C_SHUO, "我在边境的村子里，砍了一个要烧掉孩子的审判官。……就这么回事。"),
		_l("朔", C_SHUO, "……等等。你的剑。"),
		_l("缇娅", C_TIA, "我的剑怎么了？"),
		_l("朔", C_SHUO, "你的剑，是火的剑。我走了三千里路，第一次见到会烧起来的剑意。"),
		_l("朔", C_SHUO, "我叫朔。从东边来，找能让我拔出全力的对手。……你，就是。"),
		_l("缇娅", C_TIA, "我可没空跟你比剑。我们要去黑石地牢救人。"),
		_l("朔", C_SHUO, "那我跟着。等你救完了人，再跟我比。在那之前——你的敌人，就是我的敌人。"),
	]


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false
	battle.hint(tr("朔是剑士：速度很快，暗刃容易打出必杀"))


func talks() -> Array:
	return [["edric", "gareth", "edric_gareth15"], ["shuo", "kain", "shuo_kain"]]


func talk_lines(key: String) -> Array:
	if key == "edric_gareth15":
		return [
			_l("加雷斯", C_GARETH, "艾德里克。从刚才起，你一句话都没说。"),
			_l("艾德里克", C_EDRIC, "……我在想，到了黑石地牢，我会看见什么。"),
			_l("艾德里克", C_EDRIC, "圣都地底的那些傀儡……如果父亲他……"),
			_l("加雷斯", C_GARETH, "那就到了再说。我们是骑士学校里最会闯祸的两个人，什么场面没见过？"),
			_l("加雷斯", C_GARETH, "不管门后面是什么——你推门的时候，我会站在你旁边。"),
			_l("艾德里克", C_EDRIC, "……嗯。谢谢你，加雷斯。"),
		]
	return [
		_l("凯因", C_KAIN, "你的剑握得很怪。刀刃朝外，手腕压得那么低。"),
		_l("朔", C_SHUO, "东边的剑法。不求格挡，只求比对手先一步。……你的剑，是佣兵的剑。"),
		_l("凯因", C_KAIN, "佣兵的剑，只求活下去。"),
		_l("朔", C_SHUO, "活下去，也是一种剑道。……等这场仗完了，你也跟我比一场。"),
		_l("凯因", C_KAIN, "……排在缇娅后面吧。我不急。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	var g = battle.get_unit("gareth")
	if g != null and not g.is_alive():
		await battle.play_dialogue(_defeat_gareth())
		return
	var e = battle.get_unit("edric")
	if e != null and not e.is_alive():
		await battle.play_dialogue(_defeat_edric())
	else:
		await battle.play_dialogue(_defeat_tia())


func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "风鸣峡谷。两侧的崖壁像被巨斧劈开，风从缝里穿过，发出哭一样的声音。"),
		_l("加雷斯", C_GARETH, "穿过这条峡谷，黑石地牢就只剩一天的路。……可教会的人，也知道这条近路。"),
	]
	if _here("liss"):
		lines.append(_l("莉丝", C_LISS, "崖上有弓手，高处还有拿长弓的。站在高处的弓，能多射一格——别傻站在谷底当靶子。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "崖上有弓手。站在高处的弓，能多射一格——别在谷底站着当靶子。"))
	lines.append(_l("", C_NARR, "峡谷中段，刀剑相击的声音被风送了过来。"))
	lines.append(_l("缇娅", C_TIA, "前面有人在打。……一个人，被教会兵围着。"))
	lines.append(_l("朔", C_SHUO, "……一起上吧。一个一个来，太慢了。"))
	lines.append(_l("缇娅", C_TIA, "那个人的剑……好快。我去跟他说话。"))
	lines.append(_l("艾德里克", C_EDRIC, "首领应该在东边的高台上。爬上缓坡，拿下他，峡谷就是我们的。"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("缇娅", C_TIA, "崖壁爬不上去，只有那几处缓坡能走。往上爬很费脚力，但站在上面打下面，占便宜。"),
		_l("缇娅", C_TIA, "那个剑客……我走到他身边，跟他【对话】。"),
	]


func _pegasus() -> Array:
	var lines: Array = [
		_l("", C_NARR, "风里夹进了翅膀的声音。白色的天马越过崖顶，从两侧扑了下来。"),
	]
	if _here("liss"):
		lines.append(_l("莉丝", C_LISS, "天马！弓箭对飞在天上的东西有三倍的威力——这就是我们弓手出风头的时候。"))
	elif _here("nina"):
		lines.append(_l("妮娜", C_NINA, "天马！弓箭对飞在天上的东西有三倍的威力——交给我！"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "天马骑士！它们不管崖壁，也不吃地形。……弓箭对它们有三倍的威力！"))
	if _here("selene"):
		lines.append(_l("赛莲", C_SELENE, "……骑士团的后辈们。对不起，今天，我站在这一边。"))
	return lines


func _graycloaks() -> Array:
	return [
		_l("灰袍众", C_ENEMY, "目标在峡谷里。……大司祭大人有令：别让菲恩家的人活着走到地牢。"),
		_l("加雷斯", C_GARETH, "后面也来了！别回头，往东压！"),
	]


func _boss() -> Array:
	return [
		_l("西蒙", C_BOSS, "风鸣峡谷的风，从不说谎。它告诉我，你们的脚步声，到这里就该停了。"),
		_l("西蒙", C_BOSS, "教会狙击手西蒙。我的箭，会搭着风，送到你们的心口上。"),
	]


func _boss_liss() -> Array:
	return [
		_l("西蒙", C_BOSS, "布罗登的猎卫？拿着猎兔子的弓，也敢上来？"),
		_l("莉丝", C_LISS, "猎兔子的弓，射穿过的熊比你见过的都多。……你也就比熊吵一点。"),
	]


func _boss_death() -> Array:
	return [
		_l("西蒙", C_BOSS, "风……停了……怎么……听不见了……"),
	]


func _visit_hunter() -> Array:
	return [
		_l("猎人", C_NPC, "外乡人？这峡谷的风会偏箭，教会那些弓手在这儿可吃不开。"),
		_l("猎人", C_NPC, "这把弓我用了二十年，射得准，也射得狠。我老了，拉不开了——给会用的人吧。"),
	]


func _visit_herder() -> Array:
	return [
		_l("牧人", C_NPC, "教会的人把我的羊都赶走了，说是「征用」。……你们在跟他们打？"),
		_l("牧人", C_NPC, "这瓶药是我留着救命的。……也算救命，拿去吧。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "狙击手倒下，峡谷里的风像是松了一口气，渐渐地停了。"),
		_l("", C_NARR, "峡谷的东口外，荒原的尽头，一座黑色的石塔立在雾里。"),
		_l("加雷斯", C_GARETH, "那就是黑石地牢。……教会关「不能见光的人」的地方。"),
	]
	if _here("shuo"):
		lines.append(_l("朔", C_SHUO, "黑石地牢？……我在东边的时候就听过。进去的人，出来的时候都不认得自己了。"))
	else:
		lines.append(_l("", C_NARR, "那个东方剑客的身影，已经消失在峡谷的风里了。"))
	lines.append(_l("艾德里克", C_EDRIC, "父亲就在那里。"))
	lines.append(_l("缇娅", C_TIA, "艾德里克。不管里面是什么，我们一起进去。"))
	lines.append(_l("艾德里克", C_EDRIC, "……嗯。一起。"))
	return lines


func _defeat_edric() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "就差……一天的路了……父亲……"),
		_l("", C_NARR, "峡谷里的风，把最后一句话也吹散了。"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "风……好冷……火……"),
		_l("", C_NARR, "峡谷里的风，把那一点火光吹灭了。"),
	]


func _defeat_gareth() -> Array:
	return [
		_l("加雷斯", C_GARETH, "抱歉……艾德里克……推门的时候……我站不到你旁边了……"),
		_l("", C_NARR, "布罗登的苍狼倒在了峡谷的风里。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "valley", "from": "brodden_pass", "lines": [
		_l("", CB_NARR, "黑石地牢——教会关押「不能见光之人」的地方。埃德蒙，就被送去了那里。"),
		_l("", CB_NARR, "从布罗登关往西南去，最近的路，是一条终年刮着风的峡谷。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "黑石地牢 · 最深处", "mood": "dungeon", "lines": [
			_l("", CB_NARR, "地底最深的那间石室里，铁链从四面的墙上垂下来，锁着一个人影。"),
			_l("七号", CB_SEVEN, "……他们来了。"),
			_l("", CB_NARR, "锁链动了一下。灰色的余烬，从那人的指缝里一点点地渗出来。"),
			_l("埃德蒙", CB_EDMUND, "……艾德……里克……"),
			_l("七号", CB_SEVEN, "……"),
			_l("埃德蒙", CB_EDMUND, "……入侵者……确认。……排除。"),
			_l("", CB_NARR, "那是埃德蒙的声音。可那双睁开的眼睛里，什么也没有。"),
		]},
	]
