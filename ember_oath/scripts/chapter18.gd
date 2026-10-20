class_name Chapter18
extends ChapterBase
## 第十八章「灰岩的真相」：追着灰袍众南下，闯进林中的黑烬佣兵团营地。团长「灰狐」薇拉查明——
## 当年烧灰岩村的活，是教会通过灰袍众买的凶；被教会收买的叛徒和灰袍众正围在营地中心要她的命。
## 薇拉是敌方（站在营地中心不动），凯因或缇娅走过去【说得】她就倒戈，副团长格雷、军医塔莉亚随她入队。
## 胜利：击败灰袍众头目卡斯帕（第 8 章逃掉的那个，这次能击败）。败北：艾德里克、缇娅、加雷斯任一阵亡。

const CHAPTER_TITLE := "第十八章 · 灰岩的真相"
const VICTORY_TITLE := "第十八章 · 完"
const VICTORY_SUB := "灰袍众的账册上，盖满了圣都的火漆。"
const DEFEAT_SUB := "黑色的火焰旗下，再没有人站起来……"
const BG := ""

## 32×22。西南林道出发 → 营地南门（中心空地上薇拉被叛徒围着）→ 营地东门 → 东北灰袍众指挥所（卡斯帕守在堡垒上）。
## 西北小溪对岸有猎人小屋，东南有退伍老佣兵的木屋。
const MAP := [
	"F.F~.F...........F......PPPPPPP.",
	"...~..Fh.hFF.....FF...FFPA...AP.",
	".H.~FF.F.F........FFF...P..T..P.",
	"..F~.FFFF........FFFFFF.P.....P.",
	"...~FF..F...F..........FP.....P.",
	"F..BFFF.PPPPPPP..PPPPPPPP.....P.",
	"..F~.F..P.AA........AA.PPPP.PPP.",
	"FF.~F...P....A...W.....P...R.FF.",
	"~~~~....PA.................RFFFF",
	"....F.......T......T....RRRR.FFF",
	"...F..F................PF..FFFF.",
	"..F.FF..P.............AP..F.FF..",
	"...FFF..P.........A....PF..FF.F.",
	"..F..F..P.AA........AA.P...F.F..",
	"...FF...PPPPPPP..PPPPPPP...F....",
	"......T...F....RRF..............",
	".......FFFFFRRRRR........F.F....",
	".....F.....FR.....F.F.FF...T....",
	"........FFFFR...FFFFFFF.Fh.F....",
	"RRRRRRRRRRRRR.F...FFFF.F.h.h.H..",
	"..................F..F..Fh......",
	"........F.F.................FFFF",
]

const LEVELS := []                # 全图同一高度

const VERA_POS := Vector2i(15, 10)
const VISIT_HUNTER := Vector2i(1, 2)
const VISIT_VETERAN := Vector2i(29, 19)

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(1.0, 0.8, 0.5)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_VERA := Color(0.95, 0.6, 0.55)
const C_GRAY := Color(0.75, 0.7, 0.68)
const C_TALIA := Color(0.9, 0.85, 0.95)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

## 敌兵：Lv15–18，上级 2–4。黑烬叛徒（被教会收买的一派）+ 灰袍众
const _MERC := {"name": "黑烬叛徒", "class": "佣兵", "faction": "enemy", "level": 16,
	"hp": 35, "pwr": 12, "skl": 13, "spd": 12, "dfn": 9, "res": 4, "mov": 5,
	"weapons": ["steel_sword"], "color": Color(0.35, 0.32, 0.34),
	"hair": "short", "hair_color": Color(0.25, 0.22, 0.20), "armor": Color(0.30, 0.28, 0.30)}
const _FIGHTER := {"name": "黑烬叛徒", "class": "战士", "faction": "enemy", "level": 16,
	"hp": 40, "pwr": 14, "skl": 10, "spd": 9, "dfn": 8, "res": 3, "mov": 5,
	"weapons": ["steel_axe"], "color": Color(0.40, 0.33, 0.30),
	"hair": "spiky", "hair_color": Color(0.30, 0.20, 0.15), "armor": Color(0.36, 0.30, 0.28)}
const _ARCHER := {"name": "黑烬弓手", "class": "弓箭手", "faction": "enemy", "level": 15,
	"hp": 31, "pwr": 11, "skl": 12, "spd": 11, "dfn": 7, "res": 4, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.38, 0.35, 0.32),
	"hair": "hood", "armor": Color(0.32, 0.30, 0.28)}
const _GRAYCLOAK := {"name": "灰袍众", "class": "探子", "faction": "enemy", "level": 17,
	"hp": 32, "pwr": 12, "skl": 13, "spd": 14, "dfn": 7, "res": 6, "mov": 6,
	"weapons": ["steel_sword"], "color": Color(0.55, 0.55, 0.58),
	"hair": "hood", "armor": Color(0.50, 0.50, 0.54)}
const _DARKMAGE := {"name": "灰袍咒术师", "class": "暗法师", "faction": "enemy", "level": 16,
	"hp": 31, "pwr": 12, "skl": 10, "spd": 10, "dfn": 6, "res": 12, "mov": 5,
	"weapons": ["flux"], "color": Color(0.45, 0.42, 0.50),
	"hair": "hood", "armor": Color(0.40, 0.38, 0.46)}
const _SNIPER := {"name": "灰袍狙击手", "class": "狙击手", "faction": "enemy", "level": 3,
	"hp": 39, "pwr": 15, "skl": 17, "spd": 14, "dfn": 10, "res": 7, "mov": 6,
	"weapons": ["steel_bow"], "color": Color(0.55, 0.55, 0.58),
	"hair": "hood", "armor": Color(0.48, 0.48, 0.52)}
const _MYRM := {"name": "灰袍剑圣", "class": "剑圣", "faction": "enemy", "level": 3,
	"hp": 41, "pwr": 15, "skl": 19, "spd": 18, "dfn": 10, "res": 8, "mov": 6,
	"weapons": ["steel_sword"], "color": Color(0.55, 0.55, 0.58),
	"hair": "short", "hair_color": Color(0.20, 0.20, 0.22), "armor": Color(0.50, 0.50, 0.55)}

## 薇拉被说得后，副团长格雷、军医塔莉亚从帐篷后面冲出来，跟着她入队
const GRAY := {"id": "gray", "name": "格雷", "class": "佣兵", "level": 15,
	"hp": 36, "pwr": 14, "skl": 15, "spd": 13, "dfn": 9, "res": 4, "mov": 5,
	"weapons": ["steel_sword", "killing_edge"], "items": ["vulnerary"], "wexp": {"sword": 121},
	"growths": {"hp": 70, "pwr": 45, "skl": 45, "spd": 40, "dfn": 30, "res": 15},
	"color": Color(0.42, 0.38, 0.36), "hair": "short", "hair_color": Color(0.45, 0.42, 0.40), "armor": Color(0.36, 0.33, 0.32), "scar": true}
const TALIA := {"id": "talia", "name": "塔莉亚", "class": "修女", "level": 13,
	"hp": 24, "pwr": 10, "skl": 9, "spd": 11, "dfn": 4, "res": 13, "mov": 5,
	"weapons": ["mend_staff", "heal_staff"], "items": ["vulnerary"], "wexp": {"staff": 71},
	"growths": {"hp": 45, "pwr": 45, "skl": 40, "spd": 50, "dfn": 15, "res": 50},
	"color": Color(0.80, 0.75, 0.82), "hair": "ponytail", "hair_color": Color(0.35, 0.25, 0.20), "armor": Color(0.70, 0.66, 0.74)}

const UNITS := [
	# 我方（名单为空的单章测试用；正式战役里从名单取）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 15,
		"hp": 33, "pwr": 12, "skl": 14, "spd": 14, "dfn": 10, "res": 6, "mov": 5,
		"weapons": ["rapier", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(4, 19), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 3,
		"hp": 38, "pwr": 14, "skl": 16, "spd": 17, "dfn": 10, "res": 6, "mov": 6,
		"weapons": ["ember_blade", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(5, 19), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 14,
		"hp": 38, "pwr": 15, "skl": 10, "spd": 9, "dfn": 13, "res": 4, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(3, 19), "color": Color(0.70, 0.55, 0.35),
		"hair": "spiky", "hair_color": Color(0.85, 0.65, 0.30), "armor": Color(0.55, 0.45, 0.35)},
	{"id": "kain", "name": "凯因", "class": "佣兵", "faction": "player", "level": 16,
		"hp": 36, "pwr": 13, "skl": 16, "spd": 17, "dfn": 8, "res": 4, "mov": 5,
		"weapons": ["steel_sword", "killing_edge"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25},
		"pos": Vector2i(4, 18)},
	{"id": "noya", "name": "诺雅", "class": "修女", "faction": "player", "level": 14,
		"hp": 26, "pwr": 11, "skl": 9, "spd": 12, "dfn": 4, "res": 14, "mov": 5,
		"weapons": ["mend_staff", "heal_staff"], "wexp": {"staff": 71},
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 55},
		"pos": Vector2i(3, 20)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 15,
		"hp": 37, "pwr": 13, "skl": 11, "spd": 10, "dfn": 12, "res": 4, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(2, 19)},
	{"id": "nina", "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 15,
		"hp": 31, "pwr": 12, "skl": 15, "spd": 13, "dfn": 6, "res": 5, "mov": 5,
		"weapons": ["steel_bow", "iron_bow"], "wexp": {"bow": 121},
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15},
		"pos": Vector2i(4, 20)},
	{"id": "cyril", "name": "西里尔", "class": "魔道士", "faction": "player", "level": 15,
		"hp": 29, "pwr": 13, "skl": 11, "spd": 12, "dfn": 5, "res": 12, "mov": 5,
		"weapons": ["elfire", "thunder"], "wexp": {"anima": 121},
		"growths": {"hp": 50, "pwr": 55, "skl": 45, "spd": 50, "dfn": 15, "res": 45},
		"pos": Vector2i(2, 20)},
	# 薇拉：被叛徒围在营地中心，不动。凯因或缇娅【说得】
	{"id": "vera", "name": "薇拉", "class": "盗贼", "faction": "enemy", "level": 15, "stationary": true,
		"hp": 31, "pwr": 11, "skl": 15, "spd": 18, "dfn": 7, "res": 6, "mov": 6,
		"weapons": ["killing_edge", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 60, "dfn": 20, "res": 30},
		"pos": Vector2i(15, 10), "color": Color(0.45, 0.42, 0.45),
		"hair": "ponytail", "hair_color": Color(0.70, 0.70, 0.72), "armor": Color(0.32, 0.30, 0.32)},
	# 营地中心：围着薇拉的叛徒
	{"id": "merc1", "pos": Vector2i(14, 10), "hold": true},
	{"id": "merc2", "pos": Vector2i(16, 10), "hold": true},
	{"id": "fighter1", "pos": Vector2i(15, 8), "hold": true},
	{"id": "fighter2", "pos": Vector2i(15, 12), "hold": true, "weapons": ["steel_axe", "hand_axe"]},
	{"id": "merc3", "pos": Vector2i(11, 11), "hold": true},
	{"id": "merc6", "pos": Vector2i(20, 10)},
	{"id": "archer1", "pos": Vector2i(12, 9), "hold": true},
	{"id": "archer2", "pos": Vector2i(19, 9), "hold": true, "items": ["vulnerary"]},
	{"id": "graycloak1", "pos": Vector2i(16, 13), "items": ["door_key"]},
	# 营地外的林子
	{"id": "graycloak2", "pos": Vector2i(9, 17)},
	{"id": "fighter3", "pos": Vector2i(17, 17), "hold": true, "weapons": ["steel_axe", "hand_axe"]},
	{"id": "merc4", "pos": Vector2i(20, 15), "hold": true},
	{"id": "archer3", "pos": Vector2i(6, 12), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(6, 9), "hold": true, "items": ["vulnerary"]},
	{"id": "graycloak3", "pos": Vector2i(25, 11)},
	{"id": "merc5", "pos": Vector2i(26, 14), "hold": true},
	# 东北：灰袍众指挥所
	{"id": "graycloak4", "pos": Vector2i(26, 7), "items": ["elixir"]},
	{"id": "sniper1", "pos": Vector2i(25, 4), "hold": true},
	{"id": "myrm1", "pos": Vector2i(28, 5), "hold": true, "weapons": ["silver_sword"]},
	{"id": "darkmage2", "pos": Vector2i(29, 4), "hold": true, "weapons": ["nosferatu"]},
	# 卡斯帕：灰袍众头目。第 8 章逃掉了，这次守在指挥所的堡垒上
	{"id": "caspar", "name": "卡斯帕", "class": "刺客", "faction": "enemy", "level": 7,
		"hp": 48, "pwr": 17, "skl": 22, "spd": 23, "dfn": 11, "res": 9, "mov": 6,
		"weapons": ["silver_sword", "killing_edge"], "items": ["overlord_crest"], "boss": true, "hold": true,
		"sprite": "hawk", "pos": Vector2i(27, 2), "color": Color(0.55, 0.55, 0.60),
		"hair": "hood", "armor": Color(0.45, 0.45, 0.50)},
]

## 第 3 回合东边林子里灰袍众包抄；第 5 回合北边叛徒增援；第 7 回合西边再来灰袍众
const WAVES := {
	3: [{"id": "graycloak_r1", "pos": Vector2i(31, 12)}, {"id": "graycloak_r2", "pos": Vector2i(31, 13)},
		{"id": "fighter_r1", "pos": Vector2i(31, 14)}],
	5: [{"id": "merc_r1", "pos": Vector2i(14, 0)}, {"id": "merc_r2", "pos": Vector2i(16, 0)},
		{"id": "archer_r1", "pos": Vector2i(15, 1)}],
	7: [{"id": "graycloak_r3", "pos": Vector2i(0, 14)}, {"id": "darkmage_r1", "pos": Vector2i(0, 15)}],
}

const DEPLOY := [Vector2i(1, 18), Vector2i(2, 18), Vector2i(3, 18), Vector2i(5, 18), Vector2i(1, 20),
	Vector2i(5, 20), Vector2i(0, 19), Vector2i(0, 20)]


func chapter_id() -> String:
	return "ch18"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 9


func forced_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_deploy_slots() -> Array:
	return DEPLOY


func templates() -> Dictionary:
	return {"merc": _MERC, "fighter": _FIGHTER, "archer": _ARCHER, "graycloak": _GRAYCLOAK,
		"darkmage": _DARKMAGE, "sniper": _SNIPER, "myrm": _MYRM}


func lose_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_slots() -> Array:
	return DEPLOY


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "steel_lance", "steel_axe", "steel_bow", "elfire", "mend_staff"]


func is_won() -> bool:
	var c = battle.get_unit("caspar")
	return c == null or not c.is_alive()


func win_condition() -> String:
	return tr("击败灰袍众头目卡斯帕")


func lose_condition() -> String:
	return tr("艾德里克、缇娅或加雷斯阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		if t == 3:
			await battle.play_dialogue(_wave3())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t in [2, 4] and not flags.get("vera_fight_%d" % t, false):
		flags["vera_fight_%d" % t] = true
		await _vera_fights()


## 薇拉自己也在拼命：身边贴着叛徒时，砍倒一个，自己也挨一刀（不会被这样砍死）
func _vera_fights() -> void:
	var v = battle.get_unit("vera")
	if v == null or not v.is_alive() or v.is_player():
		return
	for d in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var e = battle.board.unit_at(v.grid_pos + d)
		if e == null or e.is_player() or e.is_npc() or e.is_boss:
			continue
		if not (e.unit_id.begins_with("merc") or e.unit_id.begins_with("fighter")):
			continue
		await battle.play_dialogue(_vera_cut())
		battle.units.erase(e)
		e.queue_free()
		v.take_damage(maxi(0, mini(6, v.hp - 10)))
		Audio.play_sfx("hit")
		battle.notify(tr("薇拉砍倒了一名叛徒，自己也挨了一刀"))
		return


func on_before_combat(att, def) -> void:
	if "caspar" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var foe = def if att.unit_id == "caspar" else att
		await battle.play_dialogue(_boss(foe.unit_id))


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var c = battle.get_unit("caspar")
	if c != null and not c.is_alive() and not flags.get("caspar_down", false):
		flags["caspar_down"] = true
		await battle.play_dialogue(_boss_death())
	var v = battle.get_unit("vera")
	if v != null and not v.is_alive() and not v.is_player() and not flags.get("vera_dead", false):
		flags["vera_dead"] = true
		await battle.play_dialogue(_vera_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_HUNTER:
		await battle.play_dialogue(_visit_hunter())
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))
	elif pos == VISIT_VETERAN:
		await battle.play_dialogue(_visit_veteran())
		u.receive("killer_lance")
		battle.notify(tr("获得 必杀枪"))


func recruits() -> Dictionary:
	return {"vera": ["kain", "tia"]}


func recruit_lines(_target_id: String, by_id: String) -> Array:
	if by_id == "kain":
		return _recruit_by_kain()
	return _recruit_by_tia()


func on_recruited(t, by) -> void:
	flags["vera_by"] = by.unit_id
	t.stationary = false
	t.hold = false
	await battle.play_dialogue(_vera_crew_arrives())
	battle.join_unit(GRAY, t.grid_pos)
	battle.join_unit(TALIA, t.grid_pos)
	await battle.play_dialogue(_vera_crew())
	battle.hint(tr("薇拉是盗贼：能开门、开宝箱，也能从敌人身上偷道具"))


func talks() -> Array:
	var out: Array = []
	if flags.get("vera_by", "") == "kain":
		out.append(["tia", "vera", "tia_vera"])
	out.append(["nina", "gray", "nina_gray"])
	return out


func talk_lines(key: String) -> Array:
	if key == "tia_vera":
		return [
			_l("薇拉", C_VERA, "……巫女。灰岩村的事，我欠你一句话。"),
			_l("缇娅", C_TIA, "你想说对不起？"),
			_l("薇拉", C_VERA, "不。对不起太便宜了。我想说的是：那天放火的人，我会一个一个找出来——连同付钱的那只手。"),
			_l("缇娅", C_TIA, "……我不原谅你。"),
			_l("缇娅", C_TIA, "但我需要你的剑。"),
			_l("薇拉", C_VERA, "够了。这句话，比原谅实在。"),
		]
	return [
		_l("妮娜", C_NINA, "你就是格雷。黑烬的副团长，山脚那单活的领头。"),
		_l("格雷", C_GRAY, "……猎户的女儿。凯因那小子跟我提过你。"),
		_l("妮娜", C_NINA, "我爹那天，只是下山去卖皮子。"),
		_l("格雷", C_GRAY, "我记得。他护着身后的屋子，不肯让开。……我砍倒他的时候，他手里还攥着弓。"),
		_l("妮娜", C_NINA, "（拉满了弓）……"),
		_l("格雷", C_GRAY, "射吧。我不躲。"),
		_l("妮娜", C_NINA, "……不。射一个站着等死的人，爹会骂我的。"),
		_l("妮娜", C_NINA, "等这场仗打完，你拿起剑、站直了，我们再算。"),
		_l("格雷", C_GRAY, "……好。我等着。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["vera_recruited"] = _vera_in()
	Campaign.flags["caspar_defeated"] = true


func on_defeat() -> void:
	await battle.play_dialogue(_defeat())


# ==================== 小工具 ====================

## 我方在场（活着、在我方）
func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


func _vera_in() -> bool:
	return _here("vera")


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "王都平原的战火还没有熄。一行人追着灰袍众的踪迹南下，走进了一片不见天日的密林。"),
		_l("", C_NARR, "林子深处，黑色的火焰旗在营帐之间翻动——黑烬佣兵团的营地。"),
	]
	if _here("kain"):
		lines.append(_l("凯因", C_KAIN, "……是团里的营地。不对劲，营门口连一个哨兵都没有。"))
	lines.append(_l("", C_NARR, "营地中央，传来兵刃相击的声音。"))
	lines.append_array([
		_l("卡斯帕", C_BOSS, "薇拉团长，你不该去翻那本账的。"),
		_l("薇拉", C_VERA, "灰岩村那一单。雇主栏上写着「某位虔诚的施主」，付的却是圣都铸的金币。"),
		_l("薇拉", C_VERA, "卡斯帕，你们灰袍众买凶，买到我头上来了。"),
		_l("卡斯帕", C_BOSS, "买凶？说得真难听。教会只是付钱，请佣兵做佣兵该做的事。"),
		_l("薇拉", C_VERA, "黑烬的规矩：只杀该杀之人。你们骗我烧了一整个村子的平民——还为了一个十七岁的丫头。"),
		_l("卡斯帕", C_BOSS, "规矩？你团里的人，可没有你这么讲规矩。……动手。团长的人头，教会另付一份。"),
		_l("黑烬佣兵", C_ENEMY, "对不住了，团长。教会给的，比你给的多。"),
		_l("艾德里克", C_EDRIC, "那个灰袍……是在菲恩城放火、要烧掉父亲书房的人！"),
		_l("加雷斯", C_GARETH, "被自己人围着砍的那个，就是黑烬的团长？……喂，艾德里克，这算哪一边的家务事？"),
		_l("缇娅", C_TIA, "黑烬佣兵团。……烧了灰岩村的人。"),
	])
	if _here("kain"):
		lines.append(_l("凯因", C_KAIN, "缇娅。团长不知道雇主是教会——至少，她现在知道了。"))
		lines.append(_l("凯因", C_KAIN, "让我去跟她说。……她把我从死人堆里捡回来过，我不能看着她死在叛徒手里。"))
		lines.append(_l("缇娅", C_TIA, "……我也想听她亲口说。我们一起过去。"))
	elif Campaign.alive_in_story("kain"):
		lines.append(_l("缇娅", C_TIA, "凯因还在后方养伤……要是他在这儿，一定第一个冲过去。"))
		lines.append(_l("缇娅", C_TIA, "那就我去。有些话，本来就该我来问。"))
	elif Campaign.has_member("kain"):
		lines.append(_l("缇娅", C_TIA, "凯因到最后，都想再见团长一面。……这句话，我替他带到。"))
	else:
		lines.append(_l("缇娅", C_TIA, "我去跟她说。有些话，本来就该我来问。"))
	lines.append_array([
		_l("艾德里克", C_EDRIC, "好。我们去打倒卡斯帕——灰袍众的脏活，都经他的手。"),
		_l("加雷斯", C_GARETH, "哈，简单！先救人，再揍那个灰袍。走！"),
	])
	return lines


func _turn2_hint() -> Array:
	var lines: Array = [_l("缇娅", C_TIA, "薇拉被围在营地正中间，撑不了太久。")]
	if _here("kain"):
		lines.append(_l("艾德里克", C_EDRIC, "凯因或缇娅走到她身边，选【说得】。……别让她死在叛徒手里。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "缇娅走到她身边，选【说得】。……别让她死在叛徒手里。"))
	return lines


func _wave3() -> Array:
	return [
		_l("卡斯帕", C_BOSS, "东边的人，包上去。连那几个多管闲事的一起埋在林子里。"),
	]


func _vera_cut() -> Array:
	return [
		_l("薇拉", C_VERA, "三年前你饿倒在路边，是谁给了你一碗饭？……拔剑之前，想清楚。"),
		_l("", C_NARR, "灰色的身影一闪，一名叛徒倒了下去。可薇拉的肩头，也多了一道血口。"),
	]


func _recruit_by_kain() -> Array:
	return [
		_l("凯因", C_KAIN, "团长。"),
		_l("薇拉", C_VERA, "……凯因？你这小子，跟着巫女跑了一年，还知道回来？"),
		_l("凯因", C_KAIN, "我不是回来的。……团长，这次的活，你也觉得不对吧。"),
		_l("薇拉", C_VERA, "灰岩村那天的火，烧得太干净了。干净得不像佣兵放的。"),
		_l("薇拉", C_VERA, "我查了一年。查到了灰袍众，查到了圣都的金币。"),
		_l("凯因", C_KAIN, "那就别再替他们干了。跟我们走——缇娅也在。"),
		_l("薇拉", C_VERA, "那个丫头……肯让我站在她身边？"),
		_l("凯因", C_KAIN, "她肯不肯，你自己去问。先活下来再说。"),
		_l("薇拉", C_VERA, "……哈。行。黑烬佣兵团从今天起，不接教会的单子。"),
	]


func _recruit_by_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "黑烬佣兵团的团长，「灰狐」薇拉。"),
		_l("薇拉", C_VERA, "红头发……灰岩村的丫头。来讨债的？现在倒是个好时候。"),
		_l("缇娅", C_TIA, "灰岩村烧起来那天晚上，我在火里找了一整夜。……我不会原谅你。"),
		_l("薇拉", C_VERA, "我也没打算求你原谅。"),
		_l("缇娅", C_TIA, "可是，烧了我家的，是付钱的那只手。我要找的，是那只手。"),
		_l("缇娅", C_TIA, "我不原谅你。但我需要你的剑。"),
		_l("薇拉", C_VERA, "……这一年，我一直在想，要是哪天你提着剑来找我，我该怎么办。"),
		_l("薇拉", C_VERA, "没想到，你是来雇我的。……好。这一单，我不收钱。"),
	]


func _vera_crew_arrives() -> Array:
	return [
		_l("薇拉", C_VERA, "格雷！塔莉亚！还肯跟我的人，都出来！"),
	]


func _vera_crew() -> Array:
	var lines: Array = [
		_l("格雷", C_GRAY, "团长！……啧，真要跟着这帮小鬼？"),
		_l("薇拉", C_VERA, "有意见？"),
		_l("格雷", C_GRAY, "没有。灰岩村那一单是我接的。这笔账……我也得自己去讨。"),
		_l("塔莉亚", C_TALIA, "伤员交给我。团长，你肩上的口子不浅，别逞强。"),
	]
	if _here("noya"):
		lines.append(_l("诺雅", C_NOYA, "那件修女服……您也是教会出身？"))
		lines.append(_l("塔莉亚", C_TALIA, "以前是。给异端包扎了一次伤口，就被赶出来了。……小修女，你呢？"))
		lines.append(_l("诺雅", C_NOYA, "……我也差不多。"))
	return lines


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	if foe_id == "edric":
		lines.append(_l("卡斯帕", C_BOSS, "菲恩家的小少爷，又见面了。你父亲的书房没烧干净，害我挨了大司祭好一顿骂。"))
		lines.append(_l("艾德里克", C_EDRIC, "卡斯帕。父亲的事，你知道多少？"))
		lines.append(_l("卡斯帕", C_BOSS, "知道得够多，所以才活得够久。"))
	elif foe_id == "vera":
		lines.append(_l("卡斯帕", C_BOSS, "团长亲自来了？可惜，你的人头已经有人付过钱了。"))
		lines.append(_l("薇拉", C_VERA, "那就让他们白付一次。"))
	else:
		lines.append(_l("卡斯帕", C_BOSS, "上次在菲恩城，我走得太急了。……这次，我们慢慢来。"))
	lines.append(_l("卡斯帕", C_BOSS, "灰袍只做一件事：让该消失的东西消失。今天，轮到你们了。"))
	return lines


func _boss_death() -> Array:
	return [
		_l("卡斯帕", C_BOSS, "灰袍……从来不缺人……我倒下了，还有下一个……"),
		_l("卡斯帕", C_BOSS, "大司祭要的东西……你们……挡不住……"),
	]


func _vera_death() -> Array:
	return [
		_l("薇拉", C_VERA, "只杀……该杀之人……这一次……是我自己……"),
		_l("", C_NARR, "营地深处，传来格雷的怒吼。黑烬佣兵团的残部趁乱散进密林，再也没有出现。"),
	]


func _visit_hunter() -> Array:
	return [
		_l("猎人", C_NPC, "佣兵们在林子里打了三天了，夜里全是喊杀声。"),
		_l("猎人", C_NPC, "你们要往营地去？……这瓶药拿着。别死在林子里，林子会记仇的。"),
	]


func _visit_veteran() -> Array:
	return [
		_l("老人", C_NPC, "我在黑烬干了二十年，膝盖坏了才退下来。……团里出了叛徒？"),
		_l("老人", C_NPC, "薇拉那丫头是我看着长大的。这杆枪是我的老伙计，替我捅那帮叛徒几下。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "卡斯帕倒下了。灰袍众的指挥所里，翻出了一箱又一箱盖着圣都火漆的信。"),
	]
	if _vera_in():
		lines.append_array([
			_l("薇拉", C_VERA, "这些，是灰袍众这三年接的单子。烧村子、绑人、往圣都送……雇主一栏，全是同一个印。"),
			_l("艾德里克", C_EDRIC, "圣焰教会的印。……父亲查到的，就是这些。"),
			_l("薇拉", C_VERA, "还有这一封。下一单：「南方海岸，废修道院，取铁之盾。阻者格杀。」"),
			_l("加雷斯", C_GARETH, "铁之盾！埃德蒙大人笔记上写着的那一件！"),
			_l("艾德里克", C_EDRIC, "他们也在抢圣器。……我们得赶在前面。"),
			_l("薇拉", C_VERA, "带路的活，交给我。那座修道院，我年轻时去讨过一碗热汤。"),
			_l("缇娅", C_TIA, "……薇拉。等这一切结束，灰岩村的账，我们还没算完。"),
			_l("薇拉", C_VERA, "我知道。到那时，你想怎么算都行。"),
		])
		if _here("kain"):
			lines.append(_l("凯因", C_KAIN, "（……团长，欢迎回来。）"))
	else:
		lines.append_array([
			_l("艾德里克", C_EDRIC, "灰袍众这三年接的单子……烧村子、绑人、往圣都送。雇主一栏，全是教会的印。"),
			_l("艾德里克", C_EDRIC, "还有这一封。下一单：「南方海岸，废修道院，取铁之盾。阻者格杀。」"),
			_l("加雷斯", C_GARETH, "铁之盾！埃德蒙大人笔记上写着的那一件！"),
			_l("缇娅", C_TIA, "……薇拉团长，到最后什么也没来得及说。"),
			_l("艾德里克", C_EDRIC, "那就由我们替她说完。……去修道院，赶在灰袍众前面。"),
		])
		if _here("kain"):
			lines.append(_l("凯因", C_KAIN, "……团长。"))
	return lines


func _defeat() -> Array:
	for id in ["edric", "tia", "gareth"]:
		var u = battle.get_unit(id)
		if u != null and not u.is_alive():
			if id == "edric":
				return [_l("艾德里克", C_EDRIC, "父亲……真相……就在眼前了……"),
					_l("", C_NARR, "艾德里克倒下了。灰袍众把账册连同营地，一起烧成了灰。")]
			if id == "tia":
				return [_l("缇娅", C_TIA, "灰岩村的火……我还没……找到……"),
					_l("", C_NARR, "缇娅倒下了。黑色的火焰旗下，灰袍众带走了红发的少女。")]
			return [_l("加雷斯", C_GARETH, "哈……这下……真丢脸了……"),
				_l("", C_NARR, "加雷斯倒下了。布罗登的王子，再也没能回到故乡。")]
	return []


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "camp", "from": "plains", "lines": [
		_l("", CB_NARR, "王都平原一战之后，莫尔甘的檄文传遍各国：布罗登王子勾结异端，盗走圣器。"),
		_l("", CB_NARR, "艾德里克一行没有辩解。他们追着灰袍众的踪迹，一路向南。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "圣都 · 大圣堂", "mood": "church", "lines": [
			_l("塞拉斯", CB_SILAS, "大司祭大人。卡斯帕失手了，灰袍众的账册落到了菲恩家的小子手里。"),
			_l("莫尔甘", CB_MORGAN, "账册？无所谓。灰袍本来就是用完要扔掉的东西。"),
			_l("莫尔甘", CB_MORGAN, "他们在抢圣器——铁之盾、风之弓、地之斧。埃德蒙那本笔记，倒是替他们把路画好了。"),
			_l("塞拉斯", CB_SILAS, "要拦吗？"),
			_l("莫尔甘", CB_MORGAN, "让他们去拿。拿到了，最后都要送到神殿来。……塞拉斯，你去神殿布防。"),
			_l("塞拉斯", CB_SILAS, "……是。"),
			_l("塞拉斯", CB_SILAS, "大司祭大人，八百年前的记录……我在审判所的旧档里，读到过一页被撕掉的——"),
			_l("莫尔甘", CB_MORGAN, "塞拉斯。"),
			_l("塞拉斯", CB_SILAS, "……属下多嘴了。"),
			_l("", CB_NARR, "退出大圣堂时，塞拉斯第一次没有回头行礼。"),
		]},
		{"title": "南方海岸 · 废修道院", "mood": "night", "lines": [
			_l("", CB_NARR, "海风吹过坍塌的钟楼。礼拜堂里，一个老修士在一面古旧的铁盾前点亮了蜡烛。"),
			_l("老修士", CB_NARR, "八百年了……又有人，要来敲这扇门了吗。"),
		]},
	]
