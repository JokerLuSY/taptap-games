class_name Chapter14
extends ChapterBase
## 第十四章「布罗登的援军」：逃出圣都后，圣焰骑士团一路追到布罗登边境关口。防守章：撑过 10 回合（或击败副团长瓦伦）。
## 我方守在关口前山丘上的木栅营地（堡垒 T）；敌人从西边大路、北边山道、南边溪流分批压上来。
## 第 2 回合：布罗登王子加雷斯带着哈根、莉丝从东边关门赶来（绿色援军），第 3 回合开始转为我方——三人组集结。
## 第 6 回合：副团长瓦伦随大部队出现。

const CHAPTER_TITLE := "第十四章 · 布罗登的援军"
const VICTORY_TITLE := "第十四章 · 完"
const VICTORY_SUB := "关口的狼旗，第一次为菲恩家的人升了起来。"
const DEFEAT_SUB := "边境的关门前，只剩下一地折断的长枪……"
const BG := ""
const DEFEND_TURNS := 10

## 30×22。东边是布罗登的边境城墙与关门（加雷斯从这里来）；关门前的山丘（高度 2）上围着一圈木栅，里面四座堡垒是我方据点。
## 西边一条大路直通营地西门（敌人主攻方向）；西北有山道绕到营地北面，南边隔着一条小溪（桥 + 浅滩）。
## 北边山脚、西南溪边各有一户人家可访问。
const MAP := [
	"MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM",
	"M...MM..M.M.MM.MM..M..M.MMMMMM",
	".........RFFF.FF.FF.FFHF.MMMMM",
	"RRRRRRRRRR.F.FFF.FFF.FF..MMMMM",
	".FFFFFF..R.F.FF.FFF....F.MMMMM",
	"..FF.FF..R.F..F.F........M#MMM",
	"..FFF.FF.RFFFF.FPPPP.PPPPM#MMM",
	".F.FFFFF.R.............D..#.MM",
	"..FF.FFF.R....h.P.T...T...#...",
	".........R......P.........#...",
	"RRRRRRRRRRRRRRRRRRRRRRRRRRGRRR",
	"RRRRRR.R...F..F.R.........GRRR",
	"..h....R..FFFF.hP.A.....T.#...",
	".FFF.F.R...F..F.P.A.T.....#...",
	".FFFFF.R..F.F...P.........#.MM",
	"..F.F..R....F.F.PPPPP.PPPM#MMM",
	"~~~~~~~B~~~~ww~~.........M#MMM",
	".......RFFFFF.F.FF.FF.h..MMMMM",
	"...H...RFF.F..F...F.F.F..MMMMM",
	".......R.F....F.FF.F..F..MMMMM",
	".M...M..MM..M.M..M.MMM.M.MMMMM",
	"MMMMMMMMMMMMMMMMMMMMMMMMMMMMMM",
]

const LEVELS := [
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111122222222221111",
	"111111111111111122222222221222",
	"111111111111111122222222221222",
	"111111111111111122222222221222",
	"111111111111111122222222221222",
	"111111111111111122222222221222",
	"111111111111111122222222221222",
	"111111111111111122222222221222",
	"111111111111111122222222221222",
	"111111111111111122222222221111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
]

const VISIT_SHEPHERD := Vector2i(22, 2)
const VISIT_MILLER := Vector2i(3, 18)
const BRODDEN := ["gareth", "hagen", "liss"]

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(0.95, 0.8, 0.45)
const C_HAGEN := Color(0.8, 0.7, 0.6)
const C_LISS := Color(0.75, 0.95, 0.8)
const C_LANCE := Color(0.8, 0.9, 0.75)
const C_GWEN := Color(1.0, 0.75, 0.6)
const C_OSCAR := Color(0.8, 0.82, 0.9)
const C_VICTOR := Color(0.75, 0.65, 0.95)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _KNIGHT := {"name": "圣焰骑士", "class": "骑士", "faction": "enemy", "level": 13,
	"hp": 33, "pwr": 12, "skl": 10, "spd": 9, "dfn": 11, "res": 4, "mov": 7,
	"weapons": ["steel_lance"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _SOLDIER := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 12,
	"hp": 31, "pwr": 11, "skl": 9, "spd": 10, "dfn": 9, "res": 3, "mov": 5,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 12,
	"hp": 28, "pwr": 11, "skl": 12, "spd": 11, "dfn": 6, "res": 4, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 12,
	"hp": 25, "pwr": 12, "skl": 10, "spd": 10, "dfn": 4, "res": 10, "mov": 5,
	"weapons": ["thunder"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _CLERIC := {"name": "随军修女", "class": "修女", "faction": "enemy", "level": 12,
	"hp": 24, "pwr": 11, "skl": 9, "spd": 11, "dfn": 3, "res": 12, "mov": 5,
	"weapons": ["heal_staff"], "items": ["vulnerary"], "color": Color(0.94, 0.92, 0.86),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.84)}
const _MYRM := {"name": "教会剑士", "class": "剑士", "faction": "enemy", "level": 13,
	"hp": 30, "pwr": 11, "skl": 15, "spd": 16, "dfn": 6, "res": 5, "mov": 5,
	"weapons": ["steel_sword"], "color": Color(0.78, 0.76, 0.80),
	"hair": "short", "hair_color": Color(0.25, 0.22, 0.20), "armor": Color(0.74, 0.72, 0.78)}
const _PEGASUS := {"name": "天马骑士", "class": "天马骑士", "faction": "enemy", "level": 13,
	"hp": 28, "pwr": 11, "skl": 12, "spd": 16, "dfn": 7, "res": 11, "mov": 7,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.90, 0.92, 0.98),
	"hair": "short", "hair_color": Color(0.70, 0.60, 0.40), "armor": Color(0.88, 0.90, 0.96)}
const _PALADIN := {"name": "圣焰骑士长", "class": "圣骑士", "faction": "enemy", "level": 1,
	"hp": 38, "pwr": 14, "skl": 12, "spd": 12, "dfn": 12, "res": 7, "mov": 8,
	"weapons": ["steel_lance", "steel_sword"], "color": Color(0.88, 0.86, 0.92),
	"hair": "short", "hair_color": Color(0.62, 0.52, 0.36), "armor": Color(0.92, 0.90, 0.96)}
const _ARMOR := {"name": "圣焰重甲兵", "class": "重甲兵", "faction": "enemy", "level": 13,
	"hp": 36, "pwr": 13, "skl": 8, "spd": 5, "dfn": 15, "res": 4, "mov": 4,
	"weapons": ["steel_lance"], "color": Color(0.70, 0.68, 0.66),
	"hair": "short", "hair_color": Color(0.30, 0.26, 0.22), "armor": Color(0.74, 0.72, 0.70)}

const UNITS := [
	# 我方：山丘营地里（名单为空直接开打时用这些数值）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 14,
		"hp": 32, "pwr": 12, "skl": 15, "spd": 15, "dfn": 10, "res": 6, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(21, 10), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 8,
		"hp": 36, "pwr": 15, "skl": 16, "spd": 18, "dfn": 10, "res": 5, "mov": 5,
		"weapons": ["ember_blade", "iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(20, 9), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "lance", "pos": Vector2i(19, 9), "name": "兰斯", "class": "骑士", "faction": "player", "level": 13,
		"hp": 33, "pwr": 12, "skl": 10, "spd": 10, "dfn": 11, "res": 3, "mov": 7, "weapons": ["steel_lance", "javelin"],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20}},
	{"id": "oscar", "pos": Vector2i(18, 10), "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 13,
		"hp": 34, "pwr": 12, "skl": 8, "spd": 4, "dfn": 15, "res": 3, "mov": 4, "weapons": ["iron_lance", "javelin"],
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15}},
	{"id": "noya", "pos": Vector2i(22, 10), "name": "诺雅", "class": "修女", "faction": "player", "level": 12,
		"hp": 25, "pwr": 11, "skl": 9, "spd": 13, "dfn": 4, "res": 12, "mov": 5, "weapons": ["heal_staff", "mend_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 45}},
	{"id": "victor", "pos": Vector2i(21, 12), "name": "维克多", "class": "暗法师", "faction": "player", "level": 13,
		"hp": 28, "pwr": 12, "skl": 10, "spd": 9, "dfn": 6, "res": 12, "mov": 5, "weapons": ["flux"],
		"growths": {"hp": 55, "pwr": 50, "skl": 40, "spd": 35, "dfn": 25, "res": 45}},
	{"id": "kain", "pos": Vector2i(20, 11), "name": "凯因", "class": "佣兵", "faction": "player", "level": 14,
		"hp": 34, "pwr": 13, "skl": 16, "spd": 18, "dfn": 8, "res": 4, "mov": 5, "weapons": ["steel_sword", "iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25, "res": 20}},
	{"id": "nina", "pos": Vector2i(22, 12), "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 13,
		"hp": 29, "pwr": 11, "skl": 14, "spd": 13, "dfn": 5, "res": 5, "mov": 5, "weapons": ["steel_bow", "iron_bow"],
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15, "res": 25}},
	{"id": "gwen", "pos": Vector2i(19, 11), "name": "葛温", "class": "骑士", "faction": "player", "level": 12,
		"hp": 31, "pwr": 12, "skl": 9, "spd": 12, "dfn": 9, "res": 3, "mov": 7, "weapons": ["iron_lance", "steel_lance"],
		"growths": {"hp": 75, "pwr": 50, "skl": 35, "spd": 50, "dfn": 25, "res": 15}},
	{"id": "mira", "pos": Vector2i(23, 9), "name": "米拉", "class": "枪兵", "faction": "player", "level": 12,
		"hp": 30, "pwr": 11, "skl": 11, "spd": 12, "dfn": 7, "res": 4, "mov": 5, "weapons": ["iron_lance", "javelin"],
		"growths": {"hp": 70, "pwr": 40, "skl": 50, "spd": 55, "dfn": 25, "res": 25}},
	# 敌方：圣焰骑士团的先锋
	{"id": "knight1", "pos": Vector2i(3, 10)},
	{"id": "knight2", "pos": Vector2i(2, 11), "items": ["vulnerary"]},
	{"id": "knight3", "pos": Vector2i(1, 3)},
	{"id": "soldier1", "pos": Vector2i(9, 8)},
	{"id": "soldier2", "pos": Vector2i(10, 12)},
	{"id": "mage1", "pos": Vector2i(6, 9)},
	{"id": "archer1", "pos": Vector2i(8, 11)},
	{"id": "myrm1", "pos": Vector2i(12, 5)},
	{"id": "soldier3", "pos": Vector2i(4, 18)},
	{"id": "archer2", "pos": Vector2i(11, 19)},
	{"id": "cleric1", "pos": Vector2i(2, 9)},
]

## 副团长瓦伦：第 6 回合随大部队从西边大路压上来
const VAREN := {"id": "varen", "name": "瓦伦", "class": "圣骑士", "faction": "enemy", "level": 3,
	"hp": 42, "pwr": 16, "skl": 14, "spd": 13, "dfn": 14, "res": 8, "mov": 8,
	"weapons": ["silver_lance", "steel_sword"], "items": ["elixir"], "boss": true, "sprite": "knight",
	"pos": Vector2i(0, 10), "color": Color(0.90, 0.88, 0.96),
	"hair": "short", "hair_color": Color(0.82, 0.78, 0.70), "armor": Color(0.95, 0.93, 0.98)}

## 布罗登的援军：第 2 回合从东边关门出现（绿色），第 3 回合开始转为我方
const GARETH_TEAM := [
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "npc", "fights": true, "level": 10,
		"hp": 32, "pwr": 12, "skl": 9, "spd": 9, "dfn": 11, "res": 5, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 55, "skl": 45, "spd": 45, "dfn": 40, "res": 35},
		"pos": Vector2i(27, 10), "color": Color(0.75, 0.55, 0.30),
		"hair": "spiky", "hair_color": Color(0.62, 0.38, 0.18), "armor": Color(0.55, 0.42, 0.30)},
	{"id": "hagen", "name": "哈根", "class": "战士", "faction": "npc", "fights": true, "level": 11,
		"hp": 38, "pwr": 13, "skl": 9, "spd": 9, "dfn": 8, "res": 2, "mov": 5,
		"weapons": ["steel_axe", "hand_axe"],
		"growths": {"hp": 80, "pwr": 50, "skl": 35, "spd": 30, "dfn": 30, "res": 10},
		"pos": Vector2i(27, 11), "color": Color(0.55, 0.48, 0.40),
		"hair": "short", "hair_color": Color(0.20, 0.18, 0.16), "armor": Color(0.50, 0.44, 0.36)},
	{"id": "liss", "name": "莉丝", "class": "弓箭手", "faction": "npc", "fights": true, "level": 11,
		"hp": 27, "pwr": 10, "skl": 13, "spd": 12, "dfn": 6, "res": 4, "mov": 5,
		"weapons": ["steel_bow", "iron_bow"], "items": ["vulnerary"],
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30},
		"pos": Vector2i(28, 10), "color": Color(0.45, 0.62, 0.40),
		"hair": "ponytail", "hair_color": Color(0.30, 0.22, 0.16), "armor": Color(0.40, 0.55, 0.36)},
]

## 增援：2 西路骑兵；4 北面天马 + 南面溪边；6 瓦伦与大部队；8 最后一波
const WAVES := {
	2: [{"id": "knight_r1", "pos": Vector2i(0, 10)}, {"id": "knight_r2", "pos": Vector2i(0, 11)}, {"id": "soldier_r1", "pos": Vector2i(0, 3)}],
	4: [{"id": "pegasus_r1", "pos": Vector2i(11, 1)}, {"id": "pegasus_r2", "pos": Vector2i(18, 1)},
		{"id": "knight_r3", "pos": Vector2i(0, 17)}, {"id": "archer_r1", "pos": Vector2i(1, 19)}],
	6: [VAREN, {"id": "paladin_r1", "pos": Vector2i(0, 11)}, {"id": "knight_r4", "pos": Vector2i(1, 10)},
		{"id": "mage_r1", "pos": Vector2i(0, 9)}, {"id": "cleric_r1", "pos": Vector2i(1, 11)}],
	8: [{"id": "knight_r5", "pos": Vector2i(0, 10)}, {"id": "myrm_r1", "pos": Vector2i(0, 11)}, {"id": "armor_r1", "pos": Vector2i(0, 3)},
		{"id": "archer_r2", "pos": Vector2i(1, 3)}],
}


func chapter_id() -> String:
	return "ch14"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 8


func extra_deploy_slots() -> Array:
	return [Vector2i(23, 11), Vector2i(23, 12), Vector2i(24, 9), Vector2i(24, 11), Vector2i(21, 8), Vector2i(20, 8)]


func templates() -> Dictionary:
	return {"knight": _KNIGHT, "soldier": _SOLDIER, "archer": _ARCHER, "mage": _MAGE, "cleric": _CLERIC,
		"myrm": _MYRM, "pegasus": _PEGASUS, "paladin": _PALADIN, "armor": _ARMOR}


## 三主角：加雷斯转为我方之后也算
## 加雷斯一出场（绿色时也算）就是败北条件；倒下后 get_unit 仍在，所以照样判败北
func lose_ids() -> Array:
	var out := ["edric", "tia"]
	if battle != null and battle.get_unit("gareth") != null:
		out.append("gareth")
	return out


func must_join_on_victory() -> Array:
	return ["gareth", "hagen", "liss"]


func forced_ids() -> Array:
	return ["edric", "tia"]


func extra_slots() -> Array:
	return [Vector2i(23, 11), Vector2i(23, 12), Vector2i(24, 9), Vector2i(24, 11), Vector2i(21, 8), Vector2i(20, 8),
		Vector2i(19, 7), Vector2i(20, 7), Vector2i(21, 7), Vector2i(22, 13), Vector2i(23, 13), Vector2i(21, 14),
		Vector2i(22, 14), Vector2i(24, 8), Vector2i(24, 13), Vector2i(17, 8), Vector2i(17, 12)]


func shop_items() -> Array:
	return ["vulnerary", "elixir", "steel_sword", "steel_lance", "steel_axe", "steel_bow", "javelin", "hand_axe", "thunder", "flux", "mend_staff"]


func is_won() -> bool:
	if battle.turn > DEFEND_TURNS:
		return true
	var v = battle.get_unit("varen")
	return v != null and not v.is_alive()


func win_condition() -> String:
	return tr("守住营地 10 回合，或击败瓦伦")


func lose_condition() -> String:
	if battle != null and battle.get_unit("gareth") != null:  # 和 lose_ids 同一判定
		return tr("艾德里克、缇娅或加雷斯阵亡")
	return tr("艾德里克或缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if t == 2 and not flags.get("brodden_arrive", false):
		flags["brodden_arrive"] = true
		battle.spawn_units(GARETH_TEAM.filter(func(d) -> bool: return battle.get_unit(d["id"]) == null))
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("布罗登的援军！"), Color(0.95, 0.8, 0.4))
		await battle.play_dialogue(_brodden_arrive())
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		if t == 4:
			await battle.play_dialogue(_wave4())
		elif t == 6:
			await battle.play_dialogue(_varen_arrives())
		elif t == 8:
			await battle.play_dialogue(_wave8())
	if t == DEFEND_TURNS:
		battle.show_banner(tr("最后一回合！"), Color(1.0, 0.85, 0.35))
	elif t > 1 and t < DEFEND_TURNS:
		battle.notify(tr("距离天黑还有 %d 回合") % (DEFEND_TURNS - t + 1))


## 对话入队：艾德里克（或缇娅）走到加雷斯身边【对话】，哈根、莉丝跟着王子一起归我方指挥。
## 加雷斯在场就算败北条件（绿色时倒下也一样）
func recruits() -> Dictionary:
	if battle != null and battle.state == battle.S.PREP:
		return {}
	return {"gareth": ["edric", "tia"]}


func recruit_lines(_target_id: String, by_id: String) -> Array:
	var lines: Array = _brodden_join()
	if by_id == "tia":
		lines.push_front(_l("缇娅", C_TIA, "你就是艾德里克说的那个朋友？他在山丘上，叫你们过去会合。"))
	return lines


func on_recruited(_t, _by) -> void:
	flags["brodden_join"] = true
	_brodden_to_player()


## 加雷斯、哈根、莉丝：中立 → 我方（Campaign 名单在胜利时由 store_party 写入）
func _brodden_to_player() -> void:
	for id in BRODDEN:
		var u = battle.get_unit(id)
		if u == null or not u.is_alive() or u.is_player():
			continue
		u.faction = "player"
		u.has_acted = false
		u.stationary = false
		u.hold = false
		u.queue_redraw()
		battle.notify(tr("%s 成为同伴了！") % tr(u.display_name))
	battle._refresh_objectives()
	battle._update_hover_info()


func on_resume() -> void:
	if flags.get("brodden_join", false):
		battle._refresh_objectives()


func on_before_combat(att, def) -> void:
	if "varen" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "varen" else att
		if other.unit_id == "edric":
			await battle.play_dialogue(_boss_edric())
		elif other.unit_id == "gareth":
			await battle.play_dialogue(_boss_gareth())
		else:
			await battle.play_dialogue(_boss())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "varen" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_SHEPHERD:
		await battle.play_dialogue(_visit_shepherd())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))
	elif pos == VISIT_MILLER:
		await battle.play_dialogue(_visit_miller())
		battle.add_gold(2000)
		battle.notify(tr("获得 2000G"))


func talks() -> Array:
	return [["tia", "gareth", "tia_gareth"], ["liss", "nina", "liss_nina"]]


func talk_lines(key: String) -> Array:
	if key == "tia_gareth":
		return [
			_l("加雷斯", C_GARETH, "红头发，剑上带火……你就是缇娅？艾德里克在信里提过你。"),
			_l("缇娅", C_TIA, "信里？他写了什么？"),
			_l("加雷斯", C_GARETH, "写了整整三页。前两页是「她很危险」，最后一页是「但我想帮她」。"),
			_l("缇娅", C_TIA, "……那个笨蛋。"),
			_l("加雷斯", C_GARETH, "哈哈！我认识他十年，头一回见他写信写到第三页。——以后多关照了，火之巫女。"),
			_l("缇娅", C_TIA, "别那么叫我。叫缇娅就好。……也请多关照，王子殿下。"),
			_l("加雷斯", C_GARETH, "那也别叫我殿下！在这儿，我就是个拿斧头的。"),
		]
	return [
		_l("莉丝", C_LISS, "你拉弓的时候，左肩会往上耸。射偏了别怪风。"),
		_l("妮娜", C_NINA, "……我爹也这么说过。可我一直改不过来。"),
		_l("莉丝", C_LISS, "那就别改，把箭往左边多压一指。猎人的毛病，猎人自己会找补。"),
		_l("妮娜", C_NINA, "你说话真不客气。"),
		_l("莉丝", C_LISS, "客气能让箭飞得更准吗？……不过你那一箭，射得不坏。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["edmund_at_blackstone"] = true


func on_defeat() -> void:
	var g = battle.get_unit("gareth")
	if g != null and g.is_player() and not g.is_alive():
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
		_l("", C_NARR, "逃出圣都的第三天。一行人沿着东去的大路，奔到了布罗登王国的边境。"),
		_l("", C_NARR, "身后，白色的旗帜一面接一面地出现在地平线上。"),
	]
	if _here("lance"):
		lines.append(_l("兰斯", C_LANCE, "少主，是圣焰骑士团。旗子有三十面以上……骑兵居多，我们跑不过他们。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "圣焰骑士团……旗子有三十面以上。骑兵居多，我们跑不过他们。"))
	lines.append(_l("缇娅", C_TIA, "前面就是布罗登的关门了。……可关门是关着的。"))
	lines.append(_l("艾德里克", C_EDRIC, "布罗登不会为了几个被教会通缉的人开门。……这里有一座旧营地，木栅还在，地势也高。"))
	lines.append(_l("艾德里克", C_EDRIC, "我们在这里守住。只要撑到骑士团天黑收兵，就还有路可走。"))
	if _here("oscar"):
		lines.append(_l("奥斯卡", C_OSCAR, "守城是老头子的本行。少主，前头交给我这身铁皮。"))
	if _here("victor"):
		lines.append(_l("维克多", C_VICTOR, "站在高处打低处，命中和伤害都占便宜。弓手站上山丘，还能多射一格。"))
	lines.append(_l("缇娅", C_TIA, "守住营地。……谁也别倒下。"))
	return lines


func _brodden_arrive() -> Array:
	return [
		_l("", C_NARR, "东边的关门，轰隆一声打开了。三个人影从门洞里冲了出来。"),
		_l("加雷斯", C_GARETH, "喂——！那边山丘上的！拿细剑的那个，是不是艾德里克·菲恩！"),
		_l("艾德里克", C_EDRIC, "……这个嗓门。加雷斯？！"),
		_l("加雷斯", C_GARETH, "哈！果然是你！边境的哨兵说，圣焰骑士团在追一个「金头发的菲恩家少爷」，我一猜就是你！"),
		_l("哈根", C_HAGEN, "……王子。陛下没有准许出兵。"),
		_l("加雷斯", C_GARETH, "所以我只带了你们两个啊！三个人不叫出兵，叫出门散步！"),
		_l("莉丝", C_LISS, "散步散到教会骑士团的枪尖上。殿下，您的散步路线真有品位。"),
		_l("加雷斯", C_GARETH, "艾德里克！再撑一会儿，我们这就上来！"),
		_l("缇娅", C_TIA, "绿色的……是友军？艾德里克，过去跟他【对话】，让他们听你调度吧。"),
	]


func _brodden_join() -> Array:
	var lines: Array = [
		_l("加雷斯", C_GARETH, "布罗登的苍狼，加雷斯！从现在起，这座营地也归我守了！"),
		_l("艾德里克", C_EDRIC, "加雷斯……你不该来的。教会会拿这件事为难布罗登。"),
		_l("加雷斯", C_GARETH, "骑士学校的时候，你替我挨过院长三十下戒尺。我说过要还的。"),
		_l("艾德里克", C_EDRIC, "……那是你把院长的马涂成了花斑。"),
		_l("加雷斯", C_GARETH, "细节就别计较了！——哈根、莉丝，跟上！"),
	]
	if _here("noya"):
		lines.append(_l("诺雅", C_NOYA, "布罗登的王子……真的会为了朋友，跟教会作对吗？"))
	lines.append(_l("缇娅", C_TIA, "（艾德里克的朋友……和他一点也不像。可是，笑起来很让人安心。）"))
	return lines


func _wave4() -> Array:
	return [
		_l("莉丝", C_LISS, "北边的天上有白翅膀，南边的溪边也有人摸过来了。……教会的人还真舍得下本钱。"),
		_l("加雷斯", C_GARETH, "天马交给莉丝！弓对天上的东西最管用！"),
	]


func _varen_arrives() -> Array:
	return [
		_l("", C_NARR, "西边的大路上，一面绣着金色火焰的大旗缓缓升起。白甲的骑士团主力到了。"),
		_l("瓦伦", C_BOSS, "圣焰骑士团副团长瓦伦。……布罗登的王子也在？很好，省得我再去王城敲门。"),
		_l("瓦伦", C_BOSS, "全军压上。异端、协助异端者——一并净化。"),
		_l("加雷斯", C_GARETH, "副团长亲自来了。……艾德里克，打倒他，这仗就结束了。打不倒，就再撑几个回合！"),
	]


func _wave8() -> Array:
	return [
		_l("圣焰骑士", C_ENEMY, "副团长有令！天黑前拿下营地，一个不留！"),
		_l("艾德里克", C_EDRIC, "最后一波了。……撑住！"),
	]


func _boss() -> Array:
	return [
		_l("瓦伦", C_BOSS, "螳臂当车。圣焰骑士团的枪，八百年来没有折过。"),
	]


func _boss_edric() -> Array:
	return [
		_l("瓦伦", C_BOSS, "艾德里克·菲恩。你的父亲是个好骑士——可惜，他站错了地方。"),
		_l("艾德里克", C_EDRIC, "站错的是你们。在地牢里把人烧成灰的，也配叫骑士吗？"),
		_l("瓦伦", C_BOSS, "……地牢里的事，不是骑士该问的。我只管执行。"),
		_l("艾德里克", C_EDRIC, "那我就替你问。——拔枪吧，副团长！"),
	]


func _boss_gareth() -> Array:
	return [
		_l("瓦伦", C_BOSS, "布罗登的王子，亲手对圣焰骑士团举斧。你可知道，这会给你的国家带来什么？"),
		_l("加雷斯", C_GARETH, "知道啊。会带来一个不用看教会脸色的布罗登！"),
	]


func _boss_death() -> Array:
	return [
		_l("瓦伦", C_BOSS, "撤……撤退……这面旗……不能……倒在这里……"),
		_l("", C_NARR, "副团长倒下，白色的骑士团像退潮一样往西撤去。"),
	]


func _visit_shepherd() -> Array:
	return [
		_l("牧羊人", C_NPC, "你们在帮王子殿下打教会的人？……殿下小时候常来我这儿偷羊奶喝。"),
		_l("牧羊人", C_NPC, "这个你们拿去。是给殿下备着的，他要是摔着了，就给他喝。"),
	]


func _visit_miller() -> Array:
	return [
		_l("磨坊主", C_NPC, "骑士团的人路过，把我们的麦子全征走了，说是「供奉圣焰」。"),
		_l("磨坊主", C_NPC, "这些钱是我藏在磨盘底下的。给你们……总比被他们拿走强。"),
	]


func _post_battle() -> Array:
	var lines: Array = []
	if battle.turn > DEFEND_TURNS:
		lines.append(_l("", C_NARR, "太阳落到了西边的山后。骑士团的号角响了三声，白色的旗帜一面面地往回收。"))
	else:
		lines.append(_l("", C_NARR, "副团长倒下以后，骑士团的阵线乱了。白色的旗帜一面面地往西退去。"))
	lines.append(_l("加雷斯", C_GARETH, "哈……哈……守住了！艾德里克，你还活着吧？"))
	lines.append(_l("艾德里克", C_EDRIC, "托你的福。……加雷斯，谢谢你。"))
	lines.append(_l("加雷斯", C_GARETH, "谢早了。我有坏消息要带给你。……关于埃德蒙大人。"))
	lines.append(_l("艾德里克", C_EDRIC, "……！"))
	lines.append(_l("加雷斯", C_GARETH, "布罗登的密探在教会里有眼线。前些日子，教会从圣都押走了一个「贵客」——送去了黑石地牢。"))
	lines.append(_l("加雷斯", C_GARETH, "押送的人里，有一个戴面具的、不说话的家伙。……眼线说，那个人身上，有灰的味道。"))
	lines.append(_l("缇娅", C_TIA, "黑石地牢……典狱长说的「更深的地方」，就是那里？"))
	lines.append(_l("艾德里克", C_EDRIC, "去黑石地牢。……最近的路，是穿过风鸣峡谷。"))
	lines.append(_l("加雷斯", C_GARETH, "我跟你去。父王那边……我会想办法。教会的手已经伸进布罗登的宫廷了，我留在王城也只是被人盯着。"))
	# 哈根、莉丝在这一章是会参战的第三方，可能已经倒下
	var hg = battle.get_unit("hagen")
	if hg != null and hg.is_alive():
		lines.append(_l("哈根", C_HAGEN, "……王子去哪，我去哪。"))
	var ls = battle.get_unit("liss")
	if ls != null and ls.is_alive():
		lines.append(_l("莉丝", C_LISS, "我要是不跟着，谁替殿下数他捅了几个马蜂窝？"))
	lines.append(_l("", C_NARR, "那一夜，营地里点起了三堆篝火。火之巫女、菲恩的继承人、布罗登的王子——三个人，第一次围坐在同一团火边。"))
	return lines


func _defeat_edric() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "加雷斯……抱歉……让你……白跑一趟……"),
		_l("", C_NARR, "营地的木栅被白色的潮水淹没了。"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "火……要灭了……"),
		_l("", C_NARR, "营地的木栅被白色的潮水淹没了。"),
	]


func _defeat_gareth() -> Array:
	return [
		_l("加雷斯", C_GARETH, "哈……还是……没能还上……那三十下戒尺啊……"),
		_l("", C_NARR, "布罗登的苍狼倒在了边境的山丘上。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "brodden_pass", "from": "holy", "lines": [
		_l("", CB_NARR, "逃出圣都的一行人，一路向东。追兵的马蹄声，一天比一天近。"),
		_l("", CB_NARR, "大路的尽头，是北方的山国——布罗登的边境关口。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "布罗登王城", "mood": "castle", "lines": [
			_l("布罗登国王", CB_NARR, "……加雷斯带着哈根和莉丝出了关？去帮一个被教会通缉的人？"),
			_l("宰相", CB_ENEMY, "是的，陛下。圣焰骑士团的副团长也在那一战里受了伤。教会那边，恐怕不会善罢甘休。"),
			_l("布罗登国王", CB_NARR, "那孩子……总是这样。"),
			_l("宰相", CB_ENEMY, "陛下宽心。圣都那边的事，臣会替陛下周旋的。"),
		]},
		{"title": "圣都 · 大圣堂", "mood": "church", "lines": [
			_l("塞拉斯", CB_SILAS, "骑士团在布罗登关前受挫。布罗登的王子，站到了他们那边。"),
			_l("莫尔甘", CB_MORGAN, "火之巫女，菲恩家的剑，布罗登的斧……"),
			_l("莫尔甘", CB_MORGAN, "八百年前，也是这样三个人，走到了封印的跟前。……历史，总是喜欢重复自己。"),
			_l("塞拉斯", CB_SILAS, "大司祭大人？"),
			_l("莫尔甘", CB_MORGAN, "没什么。让他们去黑石地牢吧。七号已经在那里等着了。"),
		]},
	]
