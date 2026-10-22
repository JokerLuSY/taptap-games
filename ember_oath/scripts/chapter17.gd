class_name Chapter17
extends ChapterBase
## 第十七章「战火」：莫尔甘以「布罗登王子勾结异端、偷走圣器」为名，煽动王国军进攻布罗登。
## 王都平原上，西边是王国军的营地，东边是被教会挑唆的布罗登叛兵，一条大河横在北面；教会的将军巴洛在河北岸的高地上坐镇挑拨。
## 两边的兵都把我方当成「异端」来打。布罗登士兵伊万（敌方）由加雷斯【说得】入队；村子里的民居可以访问，两边营地旁的民居会被抢掠烧掉。
## 胜利：击败教会将军巴洛。

const CHAPTER_TITLE := "第十七章 · 战火"
const VICTORY_TITLE := "第十七章 · 完"
const VICTORY_SUB := "平原上的两面旗帜，各自往回收。可战火，已经点起来了。"
const DEFEAT_SUB := "王都平原燃起了大火。没有人记得，这场仗是为什么打的……"
const BG := ""

## 36×24。第 8–9 行是一条横贯东西的大河：西桥 (6)、中央大桥 (17–18)、东桥 (29)，两处浅滩 (12)、(24)。
## 河南岸：西边是王国军营地（营帐 A、堡垒 T），东边是布罗登叛兵营地，两座营地南面各有一道木栅，中间一条大路从南边的农田（我方出发点）笔直向北。
## 河北岸：教会的指挥营，巴洛站在中央的高地（丘陵 h）上；两侧小村各有一户人家。
## 民居：西营 (4,16)、东营 (31,16)（第 4 回合起，旁边 2 格内还有敌人就会被烧掉）、南边农田两户、北岸两户。
const MAP := [
	".......hF........R.F...........F....",
	"...F.F........AA...DAA.........h....",
	"...F....DHD.......h...F..FDHD.......",
	"...h..R....F.F.T....T.....FF.R......",
	"......R......F...R...........R......",
	"......RRRRRRRRRRRRRRRRRRRRRRRRF.....",
	"....F.R...F..F...R....F......R...F..",
	"..F...R.....h....R...........R......",
	"~~~~~~B~~~~~w~~~~BB~~~~~w~~~~B~~~~~~",
	"~~~~~~B~~~~~w~~~~BB~~~~~w~~~~B~~~~~~",
	"......R..........RRFh......F.R......",
	"...h..R.........FRR....F.F...R......",
	"..RRRRRRRRRRRRRRRRRRRRRRRRRRRRRRRR..",
	"...........h.....RR.............F...",
	"FhAA.F...AA.....FRR......AA...h.AA..",
	"...F.hT.....F.h..RR..F...hF..T...FFF",
	"....H...F.......FRR.F......F..FH....",
	"..AA.h....A...F..RR.....hAFF....FA..",
	"F..............hFRRh...FF...........",
	".PPPPP..PPPP...FhRR.....PPPP..PPPPP.",
	".f..f.ffff..ff...RR..f.......ff....f",
	".f......f....H...RR...H.....f.f..f.f",
	"f......f....D.D..RR..DfD.f.....f....",
	"....f...f.f......RR..f..............",
]

const LEVELS := []                # 全图同一高度

const VISIT_WEST := Vector2i(4, 16)
const VISIT_EAST := Vector2i(31, 16)
const VISIT_CHILD := Vector2i(13, 21)
const VISIT_VETERAN := Vector2i(22, 21)
const VISIT_NW := Vector2i(9, 2)
const VISIT_NE := Vector2i(27, 2)
const RAID_HOUSES := [Vector2i(4, 16), Vector2i(31, 16)]
const RAID_FROM := 4              # 第 4 回合起，营地旁的民居会被烧

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(0.95, 0.8, 0.45)
const C_HAGEN := Color(0.8, 0.7, 0.6)
const C_LISS := Color(0.75, 0.95, 0.8)
const C_IVAN := Color(0.85, 0.85, 0.7)
const C_GERARD := Color(0.75, 0.8, 0.95)
const C_IVY := Color(1.0, 0.8, 0.6)
const C_VICTOR := Color(0.75, 0.65, 0.95)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_REBEL := Color(0.95, 0.7, 0.45)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

## 王国军（西）
const _SOLDIER := {"name": "王国军枪兵", "class": "枪兵", "faction": "enemy", "level": 15,
	"hp": 35, "pwr": 13, "skl": 12, "spd": 12, "dfn": 11, "res": 4, "mov": 5,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.45, 0.52, 0.72),
	"hair": "short", "hair_color": Color(0.36, 0.28, 0.20), "armor": Color(0.42, 0.50, 0.70)}
const _KNIGHT := {"name": "王国骑士", "class": "骑士", "faction": "enemy", "level": 16,
	"hp": 37, "pwr": 14, "skl": 12, "spd": 11, "dfn": 13, "res": 5, "mov": 7,
	"weapons": ["steel_lance"], "color": Color(0.46, 0.52, 0.74),
	"hair": "short", "hair_color": Color(0.50, 0.40, 0.26), "armor": Color(0.44, 0.50, 0.74)}
const _ARCHER := {"name": "王国弓兵", "class": "弓箭手", "faction": "enemy", "level": 15,
	"hp": 31, "pwr": 13, "skl": 15, "spd": 13, "dfn": 7, "res": 5, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.48, 0.54, 0.70),
	"hair": "hood", "armor": Color(0.46, 0.52, 0.68)}
const _MAGE := {"name": "王国魔道士", "class": "魔道士", "faction": "enemy", "level": 15,
	"hp": 28, "pwr": 14, "skl": 12, "spd": 12, "dfn": 5, "res": 12, "mov": 5,
	"weapons": ["elfire"], "color": Color(0.52, 0.56, 0.76),
	"hair": "hood", "armor": Color(0.50, 0.54, 0.74)}
const _PALADIN := {"name": "王国骑士长", "class": "圣骑士", "faction": "enemy", "level": 2,
	"hp": 42, "pwr": 16, "skl": 14, "spd": 14, "dfn": 14, "res": 8, "mov": 8,
	"weapons": ["steel_lance", "steel_sword"], "color": Color(0.50, 0.56, 0.80),
	"hair": "short", "hair_color": Color(0.70, 0.62, 0.42), "armor": Color(0.52, 0.58, 0.82)}
## 布罗登叛兵（东）：被教会挑唆、来打「勾结异端的王子」的布罗登兵
const _BRODDEN := {"name": "布罗登叛兵", "class": "战士", "faction": "enemy", "level": 16,
	"hp": 42, "pwr": 16, "skl": 11, "spd": 11, "dfn": 8, "res": 2, "mov": 5,
	"weapons": ["steel_axe", "hand_axe"], "color": Color(0.62, 0.50, 0.36),
	"hair": "spiky", "hair_color": Color(0.40, 0.26, 0.16), "armor": Color(0.58, 0.46, 0.32)}
## 教会（北岸）
const _GRAY := {"name": "灰袍众", "class": "探子", "faction": "enemy", "level": 16,
	"hp": 33, "pwr": 13, "skl": 17, "spd": 18, "dfn": 8, "res": 7, "mov": 6,
	"weapons": ["steel_sword"], "color": Color(0.52, 0.52, 0.56),
	"hair": "hood", "armor": Color(0.46, 0.46, 0.50)}
const _DARK := {"name": "教会咒术师", "class": "暗法师", "faction": "enemy", "level": 16,
	"hp": 32, "pwr": 15, "skl": 11, "spd": 11, "dfn": 7, "res": 13, "mov": 5,
	"weapons": ["flux"], "color": Color(0.40, 0.34, 0.48),
	"hair": "hood", "armor": Color(0.36, 0.30, 0.44)}
const _CLERIC := {"name": "随军修女", "class": "修女", "faction": "enemy", "level": 15,
	"hp": 27, "pwr": 13, "skl": 11, "spd": 13, "dfn": 5, "res": 14, "mov": 5,
	"weapons": ["mend_staff"], "items": ["vulnerary"], "color": Color(0.94, 0.92, 0.86),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.84)}
const _SNIPER := {"name": "教会狙击手", "class": "狙击手", "faction": "enemy", "level": 1,
	"hp": 35, "pwr": 15, "skl": 17, "spd": 14, "dfn": 10, "res": 7, "mov": 5,
	"weapons": ["longbow"], "color": Color(0.74, 0.72, 0.64),
	"hair": "hood", "armor": Color(0.70, 0.68, 0.58)}
const _ARMOR := {"name": "圣焰重甲兵", "class": "重甲兵", "faction": "enemy", "level": 16,
	"hp": 39, "pwr": 15, "skl": 9, "spd": 6, "dfn": 17, "res": 5, "mov": 4,
	"weapons": ["steel_lance"], "color": Color(0.70, 0.68, 0.66),
	"hair": "short", "hair_color": Color(0.30, 0.26, 0.22), "armor": Color(0.74, 0.72, 0.70)}

const UNITS := [
	# 我方：南边的农田（名单为空直接开打时用这些数值）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 17,
		"hp": 35, "pwr": 15, "skl": 18, "spd": 18, "dfn": 12, "res": 8, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(17, 21), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 11,
		"hp": 40, "pwr": 17, "skl": 19, "spd": 21, "dfn": 12, "res": 7, "mov": 5,
		"weapons": ["ember_blade", "iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(18, 21), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 13,
		"hp": 38, "pwr": 15, "skl": 11, "spd": 9, "dfn": 14, "res": 4, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(18, 20), "color": Color(0.75, 0.55, 0.30),
		"hair": "spiky", "hair_color": Color(0.62, 0.38, 0.18), "armor": Color(0.55, 0.42, 0.30)},
	{"id": "hagen", "pos": Vector2i(17, 20), "name": "哈根", "class": "战士", "faction": "player", "level": 14,
		"hp": 41, "pwr": 16, "skl": 11, "spd": 11, "dfn": 10, "res": 3, "mov": 5, "weapons": ["steel_axe", "hand_axe"],
		"growths": {"hp": 80, "pwr": 50, "skl": 35, "spd": 30, "dfn": 30, "res": 10}},
	{"id": "liss", "pos": Vector2i(16, 21), "name": "莉丝", "class": "弓箭手", "faction": "player", "level": 14,
		"hp": 30, "pwr": 13, "skl": 16, "spd": 15, "dfn": 7, "res": 6, "mov": 5, "weapons": ["steel_bow", "iron_bow"],
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30}},
	{"id": "gerard", "pos": Vector2i(19, 21), "name": "杰拉德", "class": "骑士", "faction": "player", "level": 15,
		"hp": 37, "pwr": 14, "skl": 12, "spd": 11, "dfn": 13, "res": 5, "mov": 7, "weapons": ["steel_lance", "javelin"],
		"growths": {"hp": 60, "pwr": 35, "skl": 35, "spd": 30, "dfn": 30, "res": 15}},
	{"id": "ivy", "pos": Vector2i(17, 22), "name": "艾薇", "class": "魔道士", "faction": "player", "level": 15,
		"hp": 28, "pwr": 14, "skl": 13, "spd": 12, "dfn": 6, "res": 13, "mov": 5, "weapons": ["elfire", "thunder"],
		"growths": {"hp": 45, "pwr": 50, "skl": 45, "spd": 45, "dfn": 15, "res": 50}},
	{"id": "noya", "pos": Vector2i(18, 22), "name": "诺雅", "class": "修女", "faction": "player", "level": 15,
		"hp": 28, "pwr": 14, "skl": 11, "spd": 15, "dfn": 5, "res": 15, "mov": 5, "weapons": ["heal_staff", "mend_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 45}},
	{"id": "victor", "pos": Vector2i(16, 22), "name": "维克多", "class": "暗法师", "faction": "player", "level": 16,
		"hp": 31, "pwr": 15, "skl": 11, "spd": 10, "dfn": 7, "res": 14, "mov": 5, "weapons": ["flux"],
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45}},
	{"id": "kain", "pos": Vector2i(19, 22), "name": "凯因", "class": "佣兵", "faction": "player", "level": 17,
		"hp": 37, "pwr": 15, "skl": 18, "spd": 20, "dfn": 10, "res": 5, "mov": 5, "weapons": ["steel_sword", "iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25, "res": 20}},
	{"id": "shuo", "pos": Vector2i(16, 20), "name": "朔", "class": "剑士", "faction": "player", "level": 13,
		"hp": 30, "pwr": 11, "skl": 17, "spd": 18, "dfn": 6, "res": 4, "mov": 5, "weapons": ["killing_edge", "iron_sword"],
		"wexp": {"sword": 71}, "growths": {"hp": 65, "pwr": 40, "skl": 60, "spd": 60, "dfn": 20, "res": 25}},
	# 王国军（西营）
	{"id": "soldier1", "pos": Vector2i(5, 12)},
	{"id": "soldier2", "pos": Vector2i(8, 13), "hold": true},
	{"id": "soldier4", "pos": Vector2i(5, 16), "hold": true},
	{"id": "knight1", "pos": Vector2i(10, 11)},
	{"id": "knight2", "pos": Vector2i(12, 13)},
	{"id": "archer1", "pos": Vector2i(6, 15), "hold": true},
	{"id": "archer2", "pos": Vector2i(9, 16), "hold": true},
	{"id": "mage1", "pos": Vector2i(7, 17), "hold": true},
	{"id": "paladin1", "pos": Vector2i(4, 13), "hold": true, "items": ["elixir"]},
	# 布罗登叛兵（东营）
	{"id": "brodden1", "pos": Vector2i(27, 12)},
	{"id": "brodden2", "pos": Vector2i(30, 13), "hold": true},
	{"id": "brodden3", "pos": Vector2i(33, 11), "hold": true},
	{"id": "brodden4", "pos": Vector2i(32, 16), "hold": true},
	{"id": "brodden5", "pos": Vector2i(24, 16), "hold": true},
	{"id": "archer3", "pos": Vector2i(29, 15), "hold": true, "name": "布罗登猎手", "color": Color(0.58, 0.50, 0.38), "armor": Color(0.54, 0.46, 0.34)},
	{"id": "archer4", "pos": Vector2i(34, 13), "hold": true, "name": "布罗登猎手", "color": Color(0.58, 0.50, 0.38), "armor": Color(0.54, 0.46, 0.34)},
	# 伊万：被派来打自己人的布罗登士兵。加雷斯【说得】
	{"id": "ivan", "name": "伊万", "class": "枪兵", "faction": "enemy", "level": 13,
		"hp": 32, "pwr": 12, "skl": 11, "spd": 12, "dfn": 9, "res": 3, "mov": 5,
		"weapons": ["steel_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 45, "spd": 45, "dfn": 30, "res": 15},
		"pos": Vector2i(26, 11), "color": Color(0.62, 0.52, 0.38),
		"hair": "short", "hair_color": Color(0.55, 0.40, 0.22), "armor": Color(0.58, 0.48, 0.34)},
	# 教会（北岸）
	{"id": "graycloak1", "pos": Vector2i(17, 6)},
	{"id": "armor1", "pos": Vector2i(18, 7), "hold": true},
	{"id": "sniper1", "pos": Vector2i(15, 3), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(20, 3), "hold": true},
	{"id": "cleric1", "pos": Vector2i(16, 2)},
	{"id": "graycloak2", "pos": Vector2i(24, 4), "items": ["door_key"]},
	# 教会将军巴洛：河北岸中央的高地上
	{"id": "barlow", "name": "巴洛", "class": "将军", "faction": "enemy", "level": 6,
		"hp": 48, "pwr": 18, "skl": 13, "spd": 8, "dfn": 18, "res": 9, "mov": 5,
		"weapons": ["silver_lance", "javelin"], "items": ["elixir"], "boss": true, "stationary": true, "sprite": "barrett",
		"pos": Vector2i(18, 2), "color": Color(0.82, 0.80, 0.76),
		"hair": "short", "hair_color": Color(0.60, 0.58, 0.55), "armor": Color(0.88, 0.86, 0.82)},
]

## 增援：4 王国骑兵从西边；6 布罗登叛兵从东边；8 灰袍众从北边
const WAVES := {
	4: [{"id": "knight_r1", "pos": Vector2i(0, 12)}, {"id": "knight_r2", "pos": Vector2i(0, 13)}],
	6: [{"id": "brodden_r1", "pos": Vector2i(35, 12)}, {"id": "brodden_r2", "pos": Vector2i(35, 11)}],
	8: [{"id": "graycloak_r1", "pos": Vector2i(17, 0)}, {"id": "graycloak_r2", "pos": Vector2i(18, 0)}],
}


func chapter_id() -> String:
	return "ch17"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 9


func extra_deploy_slots() -> Array:
	return [Vector2i(15, 21), Vector2i(20, 21), Vector2i(15, 22), Vector2i(20, 22), Vector2i(16, 23), Vector2i(19, 23)]


func templates() -> Dictionary:
	return {"soldier": _SOLDIER, "knight": _KNIGHT, "archer": _ARCHER, "mage": _MAGE, "paladin": _PALADIN,
		"brodden": _BRODDEN, "graycloak": _GRAY, "darkmage": _DARK, "cleric": _CLERIC, "sniper": _SNIPER, "armor": _ARMOR}


## 三主角（名单里没有加雷斯时不算）
func lose_ids() -> Array:
	var out := ["edric", "tia"]
	if battle != null and battle.get_unit("gareth") != null:
		out.append("gareth")
	return out


func extra_slots() -> Array:
	return [Vector2i(15, 21), Vector2i(20, 21), Vector2i(15, 22), Vector2i(20, 22), Vector2i(16, 23), Vector2i(19, 23),
		Vector2i(15, 20), Vector2i(20, 20), Vector2i(15, 23), Vector2i(20, 23), Vector2i(17, 23), Vector2i(18, 23),
		Vector2i(14, 21), Vector2i(21, 21), Vector2i(14, 20), Vector2i(21, 20), Vector2i(14, 23), Vector2i(21, 23),
		Vector2i(13, 20), Vector2i(22, 20)]


func shop_items() -> Array:
	return ["vulnerary", "elixir", "steel_sword", "armorslayer", "killing_edge", "steel_lance", "horseslayer", "killer_lance",
		"steel_axe", "killer_axe", "steel_bow", "killer_bow", "elfire", "flux", "mend_staff"]


func is_won() -> bool:
	var b = battle.get_unit("barlow")
	return b != null and not b.is_alive()


func win_condition() -> String:
	return tr("击败教会将军巴洛")


func lose_condition() -> String:
	if battle != null and battle.get_unit("gareth") != null:
		return tr("艾德里克、缇娅或加雷斯阵亡")
	return tr("艾德里克或缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_resume() -> void:
	for pair in flags.get("razed", []):
		if typeof(pair) == TYPE_ARRAY and pair.size() >= 2:
			battle.board.set_tile(Vector2i(int(pair[0]), int(pair[1])), "Z")


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		if t == 4:
			await battle.play_dialogue(_wave_royal())
		elif t == 6:
			await battle.play_dialogue(_wave_rebel())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t >= RAID_FROM:
		await _raid_houses()


## 营地旁的民居：还没访问、旁边 2 格内还有敌兵 → 被烧成废墟
func _raid_houses() -> void:
	for p in RAID_HOUSES:
		if visited.has(p) or battle.board.tile_at(p) != "H":
			continue
		var near := false
		for u in battle.units:
			if u.is_alive() and not u.is_player() and not u.is_npc() and GameData.dist(u.grid_pos, p) <= 2:
				near = true
				break
		if not near or battle.board.unit_at(p) != null:
			continue
		visited[p] = true
		battle.board.set_tile(p, "Z")
		var razed: Array = flags.get("razed", [])
		razed.append([p.x, p.y])
		flags["razed"] = razed
		Audio.play_sfx("fire")
		battle.notify(tr("民居被烧毁了……"))
		await battle.play_dialogue(_raided(p))


func on_before_combat(att, def) -> void:
	var ids := [att.unit_id, def.unit_id]
	if "barlow" in ids and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "barlow" else att
		await battle.play_dialogue(_boss_gareth() if other.unit_id == "gareth" else _boss())
	if "ivan" in ids and not flags.get("ivan_fight", false):
		var iv = battle.get_unit("ivan")
		if iv != null and not iv.is_player():
			flags["ivan_fight"] = true
			await battle.play_dialogue(_ivan_fight())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "barlow" and def_died:
		await battle.play_dialogue(_boss_death())
	elif def.unit_id == "ivan" and def_died:
		await battle.play_dialogue(_ivan_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_WEST:
		await battle.play_dialogue(_visit_west())
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))
	elif pos == VISIT_EAST:
		await battle.play_dialogue(_visit_east())
		u.receive("hero_crest")
		battle.notify(tr("获得 勇者之证"))
	elif pos == VISIT_CHILD:
		await battle.play_dialogue(_visit_child())
		battle.add_gold(1500)
		battle.notify(tr("获得 1500G"))
	elif pos == VISIT_VETERAN:
		await battle.play_dialogue(_visit_veteran())
		u.receive("armorslayer")
		battle.notify(tr("获得 破甲剑"))
	elif pos == VISIT_NW:
		await battle.play_dialogue(_visit_nw())
		u.receive("killer_axe")
		battle.notify(tr("获得 锐锋斧"))
	elif pos == VISIT_NE:
		await battle.play_dialogue(_visit_ne())
		u.receive("sage_crest")
		battle.notify(tr("获得 贤者之证"))


func recruits() -> Dictionary:
	return {"ivan": ["gareth"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return [
		_l("加雷斯", C_GARETH, "住手！你是第三连队的伊万吧？去年冬天，在北境哨所跟我掰过手腕的那个！"),
		_l("伊万", C_IVAN, "……殿下？！您、您真的是加雷斯殿下？"),
		_l("伊万", C_IVAN, "可是……队长说，殿下勾结了异端，偷走了教会的圣器，要把布罗登卖给火之巫女……"),
		_l("加雷斯", C_GARETH, "你看看我。我像是会卖掉布罗登的人吗？"),
		_l("伊万", C_IVAN, "……不像。您连输了掰手腕都不肯认账。"),
		_l("加雷斯", C_GARETH, "哈！那就对了。告诉你们队长那些话的，是谁？"),
		_l("伊万", C_IVAN, "是……教会派来的将军。他说只要我们在平原上拦住王国军，教会就会替布罗登说话……"),
		_l("加雷斯", C_GARETH, "教会一边让王国军来打我们，一边让我们去打王国军。……伊万，你被人当成柴火了。"),
		_l("伊万", C_IVAN, "……我明白了。殿下，伊万这杆枪，从现在起跟着您！"),
	]


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false


func talks() -> Array:
	return [["tia", "edric", "tia_edric17"], ["hagen", "ivan", "hagen_ivan"]]


func talk_lines(key: String) -> Array:
	if key == "tia_edric17":
		return [
			_l("缇娅", C_TIA, "艾德里克。……你睡着了吗？这几天晚上。"),
			_l("艾德里克", C_EDRIC, "……睡不太着。一闭上眼，就是父亲挡在我前面的样子。"),
			_l("缇娅", C_TIA, "我养父受伤那天，我也睡不着。后来我想通了一件事。"),
			_l("缇娅", C_TIA, "他们拼命护着我们，不是要我们一直难过。是要我们接着往前走。"),
			_l("艾德里克", C_EDRIC, "……你说得对。可我还想再难过一会儿。"),
			_l("缇娅", C_TIA, "那就难过一会儿吧。我陪你。……打完这一仗再说。"),
		]
	return [
		_l("伊万", C_IVAN, "哈根大哥！您也跟着殿下？"),
		_l("哈根", C_HAGEN, "……嗯。"),
		_l("伊万", C_IVAN, "队里的人都说您是布罗登最能打的。殿下跑出去那天，您一个人追出关的！"),
		_l("哈根", C_HAGEN, "……王子去哪，我去哪。"),
		_l("伊万", C_IVAN, "那、那我也是！王子去哪，我去哪！"),
		_l("哈根", C_HAGEN, "……先学会把枪握稳。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["plains_war"] = true


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
		_l("", C_NARR, "王都平原。西边飘着王国的蓝旗，东边飘着布罗登的狼旗。两支军队隔着一片麦田，扎下了营。"),
		_l("", C_NARR, "大河北岸的高地上，一面金色火焰的旗帜，静静地看着两边。"),
		_l("加雷斯", C_GARETH, "……真的打起来了。教会说我「勾结异端、偷走圣器」，王国军就真的开过来了。"),
		_l("加雷斯", C_GARETH, "东边那些，是布罗登的兵。他们以为自己在为布罗登打仗……其实是在为教会。"),
		_l("艾德里克", C_EDRIC, "河北岸那面金色的旗——那是教会的人。两边的仗，都是他点起来的。"),
		_l("缇娅", C_TIA, "那就去把点火的人打倒。……可两边的兵，都会把我们当敌人吧。"),
	]
	if _here("gerard"):
		lines.append(_l("杰拉德", C_GERARD, "王国军的阵线我看得懂。西边营地是老派的打法，骑兵多，正面硬。"))
	if _here("ivy"):
		lines.append(_l("艾薇", C_IVY, "北岸那个将军穿着全身重甲。剑和枪砍上去只会卷刃——用魔法，或者破甲剑。"))
	lines.append(_l("加雷斯", C_GARETH, "东营里有我认识的人。……让我去跟他们说。"))
	lines.append(_l("艾德里克", C_EDRIC, "渡河，打倒北岸的将军。……尽量别让这片平原烧起来。"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("加雷斯", C_GARETH, "东营那个拿枪的年轻人……是伊万！我得走到他身边【说得】他。"),
		_l("缇娅", C_TIA, "营地旁边的村子……要是敌人一直在旁边转悠，会被烧掉的。要先去【访问】，就得快。"),
	]


func _wave_royal() -> Array:
	var lines: Array = [_l("王国骑士", C_ENEMY, "王国军第二骑兵队到！布罗登的叛贼和异端，一并拿下！")]
	# 杰拉德第 16 章是可选救援，可能没救出来或已经倒下
	var g = battle.get_unit("gerard")
	if g != null and g.is_alive() and g.is_player():
		lines.append(_l("杰拉德", C_GERARD, "……那面旗，我年轻的时候也扛过。如今却对着我们。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "……王国的旗。如今却对着我们。"))
	return lines


func _wave_rebel() -> Array:
	return [
		_l("布罗登叛兵", C_REBEL, "为了布罗登！把勾结异端的王子抓回去！"),
		_l("加雷斯", C_GARETH, "……为了布罗登？你们手里的斧头，正砍在布罗登的骨头上啊！"),
	]


func _raided(p: Vector2i) -> Array:
	if p == VISIT_WEST:
		return [_l("", C_NARR, "西营旁的民居冒起了黑烟。王国军的士兵抱着抢来的麦袋，从门里走了出来。")]
	return [_l("", C_NARR, "东营旁的民居冒起了黑烟。叛兵把粮仓的门劈开，火把扔了进去。")]


func _ivan_fight() -> Array:
	return [
		_l("伊万", C_IVAN, "勾结异端的家伙……为了布罗登，我不会手下留情！"),
	]


func _ivan_death() -> Array:
	return [
		_l("伊万", C_IVAN, "我……是为了……布罗登……"),
	]


func _boss() -> Array:
	return [
		_l("巴洛", C_BOSS, "教会将军巴洛。你们以为打到这里，这场仗就会停？"),
		_l("巴洛", C_BOSS, "战火一旦点起来，就会自己烧下去。……大司祭大人要的，就是这片平原上的火。"),
	]


func _boss_gareth() -> Array:
	return [
		_l("巴洛", C_BOSS, "布罗登的王子亲自来了？正好。你的人头，能让这场仗打得更旺。"),
		_l("加雷斯", C_GARETH, "你骗了王国，也骗了布罗登。……我今天就让两边的人都看清楚，点火的是谁！"),
	]


func _boss_death() -> Array:
	return [
		_l("巴洛", C_BOSS, "呵……打倒我……也没用……火已经……点着了……"),
	]


func _visit_west() -> Array:
	return [
		_l("村妇", C_NPC, "王国军说要「征粮」，把我们的麦子全搬走了……连种子都没剩下。"),
		_l("村妇", C_NPC, "这个你们拿着。是我男人当兵时留下的。……求你们，别让这里变成战场。"),
	]


func _visit_east() -> Array:
	return [
		_l("老兵", C_NPC, "我年轻的时候，在布罗登的军队里待过。……现在那些叛兵，喊的口号跟我们当年一样。"),
		_l("老兵", C_NPC, "可当年我们是守着家，现在他们是在烧别人的家。……这块勋章，给比我更配得上它的人吧。"),
	]


func _visit_child() -> Array:
	return [
		_l("小孩", C_NPC, "大哥哥大姐姐，你们是来打仗的吗？……爹说打完仗就回家，可他已经走了好久了。"),
		_l("小孩", C_NPC, "这是我攒的钱。你们要是看见我爹，叫他快点回来。"),
	]


func _visit_veteran() -> Array:
	return [
		_l("退役骑士", C_NPC, "你们要去打北岸那个穿重甲的将军？光靠铁剑可砍不动他。"),
		_l("退役骑士", C_NPC, "拿着这把破甲剑。对付重甲，它比银剑还好使。"),
	]


func _visit_nw() -> Array:
	return [
		_l("樵夫", C_NPC, "教会的人在河北岸扎营以后，我们连山都不敢上了。"),
		_l("樵夫", C_NPC, "这把斧子是在林子里捡的，看上去是好东西。你们比我用得上。"),
	]


func _visit_ne() -> Array:
	return [
		_l("老人", C_NPC, "我在教会当了三十年的书记官。……退下来以后才知道，自己抄的那些「教典」，一半是假的。"),
		_l("老人", C_NPC, "这个，是我从书记院带出来的。拿着它的魔道士，能走得更远。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "金色火焰的旗帜倒下了。平原上的两支军队，同时安静了下来。"),
		_l("加雷斯", C_GARETH, "布罗登的士兵们！听着！我是加雷斯！"),
		_l("加雷斯", C_GARETH, "我没有勾结异端，也没有偷什么圣器。骗你们来这儿流血的，是教会！"),
		_l("", C_NARR, "东营里一阵骚动。一面狼旗，慢慢地降了下来。"),
	]
	if _here("ivan"):
		lines.append(_l("伊万", C_IVAN, "殿下说的是真的！教会的将军亲口说的——他要的就是这场仗！"))
	if _here("gerard"):
		lines.append(_l("杰拉德", C_GERARD, "西边的王国军也在后撤。……可他们的指挥官没有被说服，只是被将军的死吓住了。"))
	lines.append(_l("艾德里克", C_EDRIC, "这一仗停了。可教会只要再写一封信，下一仗就会在别的地方打起来。"))
	lines.append(_l("缇娅", C_TIA, "那就在他们写下一封信之前，把剩下的圣器找到。"))
	lines.append(_l("艾德里克", C_EDRIC, "父亲查到的圣器下落里，最近的一件——铁之盾，在海边的废修道院。……我们去那里。"))
	return lines


func _defeat_edric() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "父亲……您没走完的路……我也……"),
		_l("", C_NARR, "王都平原上的火，烧了整整一个月。"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "这片火……不是我的火……"),
		_l("", C_NARR, "王都平原上的火，烧了整整一个月。"),
	]


func _defeat_gareth() -> Array:
	return [
		_l("加雷斯", C_GARETH, "布罗登的……子民们……别再……打了……"),
		_l("", C_NARR, "布罗登的苍狼倒在了王都平原上。两边的军队，再也没有人能拦住。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "plains", "from": "prison", "lines": [
		_l("", CB_NARR, "埃德蒙下葬后的第七天，王都传来了消息：大司祭莫尔甘宣布布罗登王子「勾结异端、盗取圣器」。"),
		_l("", CB_NARR, "王国军开向东方的边境。布罗登的狼旗，也在平原的另一头升了起来。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "王都 · 王宫", "mood": "castle", "lines": [
			_l("国王", CB_NARR, "……巴洛将军战死，平原上的军队退了回来？"),
			_l("教会使者", CB_ENEMY, "是的，陛下。布罗登的王子与异端联手，杀害了教会的将军。大司祭大人深感痛心。"),
			_l("国王", CB_NARR, "那……依大司祭之见，朕该如何？"),
			_l("教会使者", CB_ENEMY, "大司祭大人说：陛下只需相信圣焰。其余的事，教会自会处置。"),
			_l("国王", CB_NARR, "……好。一切，就照大司祭的意思办吧。"),
		]},
		{"title": "布罗登王城 · 宰相府", "mood": "castle", "lines": [
			_l("", CB_NARR, "深夜。宰相奥斯瓦尔德在烛光下拆开了一封盖着金色火焰火漆的信。"),
			_l("奥斯瓦尔德", CB_ENEMY, "「地之斧，务必在王子回国之前，送到神殿来。」……"),
			_l("奥斯瓦尔德", CB_ENEMY, "大司祭大人还是这么心急。……也罢。陛下那边，我自有办法让他听话。"),
			_l("", CB_NARR, "信纸被投进了烛火。火漆上的金色火焰，在灰里慢慢地熔化了。"),
		]},
	]
