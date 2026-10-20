class_name Chapter19
extends ChapterBase
## 第十九章「废修道院」：南方海岸的废修道院里，老修士本笃守着八圣器之一「铁之盾」，教会贤者欧蕾莉亚带兵来抢。
## 任意我方【访问】礼拜堂西墙外的修士房（H），本笃入队。
## 第 3 回合灰袍盗贼从海上登岸，第 4 回合起每回合开始时直扑礼拜堂祭台（K）：敌人站上祭台，铁之盾就被抢走（不败北，剧情改一句）。
## 胜利：击败欧蕾莉亚。败北：艾德里克、缇娅、加雷斯任一阵亡。

const CHAPTER_TITLE := "第十九章 · 废修道院"
const VICTORY_TITLE := "第十九章 · 完"
const VICTORY_SUB := "海风吹过礼拜堂。祭台上的烛火，还亮着。"
const DEFEAT_SUB := "坍塌的钟楼下，海浪吞没了最后的足迹……"
const BG := ""

## 32×22。西边来路 → 西门进修道院 → 回廊中庭 → 东北礼拜堂（祭台 K 上是铁之盾，西墙外是本笃的修士房 H）。
## 北坡是教会阵地（欧蕾莉亚守在堡垒上），东边是沙滩和海，海门通沙滩——第 3 回合灰袍盗贼从这里登岸。
const MAP := [
	"....F..h.A.......A.......ss~~~~~",
	"......hhh....T....hh...h.ss~~~~~",
	"...F.Z.h.................sss~~~~",
	"..F..F..#####G###########sss~~~~",
	".F.FF...#SSZSSSSS#SSSSSS#sss~~~~",
	"..FFF...#SISSSISS#ISKSSI#sss~~~~",
	".F..F...ZSSSSSSSS#SSSSSS#sss~~~~",
	"..FF....#SSSSS####SSSSSS#sss~~~~",
	"........#ZSSSSSSH#ISSSSI#sss~~~~",
	".......F#S.....SS#SSSSSS#sss~~~~",
	"........#S.....SS###SS###sss~~~~",
	"RRRRRRRRGS..W..SSSSSSSS##sss~~~~",
	"........#S.....SS##SSSZS#sss~~~~",
	"........#S.....SS#SSSSSS#sss~~~~",
	"..TF....#SSSSSSSSSSSSZSSGsss~~~~",
	".FFFF...#SISSZISSSZSSSSS#sss~~~~",
	"F..FFFF.#SSSSSSSS#SDDSSS#sss~~~~",
	"FF....FF########Z########sss~~~~",
	"....F...........F.....H..sss~~~~",
	"..FFF.Z...Z..FFF...sssssssss~~~~",
	"..........FZF..F....ss~~~sss~~~~",
	"...F.FF......F........~~~sss~~~~",
]

const LEVELS := []                # 全图同一高度

const ALTAR := Vector2i(20, 5)         # 礼拜堂祭台：铁之盾
const VISIT_CELL := Vector2i(16, 8)    # 本笃的修士房
const VISIT_FISHER := Vector2i(22, 18) # 渔夫的小屋
const RAID_FROM := 4                   # 第 4 回合起，盗贼每回合开始时直扑祭台

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(1.0, 0.8, 0.5)
const C_VERA := Color(0.95, 0.6, 0.55)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_SELENE := Color(0.75, 0.9, 1.0)
const C_CYRIL := Color(1.0, 0.72, 0.42)
const C_BENEDICT := Color(0.85, 0.82, 0.7)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

## 敌兵：Lv16–18，上级 3–5
const _SOLDIER := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 17,
	"hp": 36, "pwr": 13, "skl": 11, "spd": 11, "dfn": 11, "res": 5, "mov": 5,
	"weapons": ["steel_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _KNIGHT := {"name": "圣焰骑士", "class": "骑士", "faction": "enemy", "level": 17,
	"hp": 38, "pwr": 14, "skl": 11, "spd": 10, "dfn": 13, "res": 4, "mov": 7,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _ARMOR := {"name": "圣焰重甲兵", "class": "重甲兵", "faction": "enemy", "level": 17,
	"hp": 40, "pwr": 15, "skl": 9, "spd": 5, "dfn": 18, "res": 3, "mov": 4,
	"weapons": ["steel_lance"], "color": Color(0.78, 0.76, 0.80),
	"hair": "short", "armor": Color(0.84, 0.82, 0.88)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 16,
	"hp": 33, "pwr": 12, "skl": 13, "spd": 11, "dfn": 8, "res": 4, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 16,
	"hp": 30, "pwr": 13, "skl": 11, "spd": 11, "dfn": 5, "res": 12, "mov": 5,
	"weapons": ["elfire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}
const _CLERIC := {"name": "教会修女", "class": "修女", "faction": "enemy", "level": 16,
	"hp": 28, "pwr": 11, "skl": 9, "spd": 11, "dfn": 4, "res": 14, "mov": 5,
	"weapons": ["mend_staff"], "color": Color(0.95, 0.93, 0.88),
	"hair": "hood", "armor": Color(0.92, 0.90, 0.86)}
const _PALADIN := {"name": "圣焰圣骑士", "class": "圣骑士", "faction": "enemy", "level": 4,
	"hp": 46, "pwr": 17, "skl": 14, "spd": 13, "dfn": 15, "res": 8, "mov": 8,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.84, 0.82, 0.88),
	"hair": "short", "hair_color": Color(0.70, 0.62, 0.40), "armor": Color(0.90, 0.88, 0.94)}
const _SAGE := {"name": "教会贤者", "class": "贤者", "faction": "enemy", "level": 4,
	"hp": 38, "pwr": 16, "skl": 14, "spd": 13, "dfn": 7, "res": 15, "mov": 6,
	"weapons": ["elfire"], "color": Color(0.94, 0.90, 0.80),
	"hair": "hood", "armor": Color(0.92, 0.88, 0.78)}
## 第 3 回合从海上登岸、直扑祭台的灰袍盗贼
const _THIEF := {"name": "灰袍盗贼", "class": "盗贼", "faction": "enemy", "level": 17,
	"hp": 31, "pwr": 11, "skl": 15, "spd": 17, "dfn": 6, "res": 5, "mov": 7,
	"weapons": ["steel_sword"], "color": Color(0.55, 0.55, 0.58),
	"hair": "hood", "armor": Color(0.50, 0.50, 0.54)}

## 本笃：访问修士房后入队
const BENEDICT := {"id": "benedict", "name": "本笃", "class": "修士", "level": 14,
	"hp": 28, "pwr": 11, "skl": 9, "spd": 8, "dfn": 6, "res": 15, "mov": 5,
	"weapons": ["mend_staff", "heal_staff"], "items": ["elixir"], "wexp": {"staff": 71},
	"growths": {"hp": 50, "pwr": 45, "skl": 40, "spd": 30, "dfn": 20, "res": 55},
	"color": Color(0.55, 0.48, 0.40), "hair": "short", "hair_color": Color(0.85, 0.85, 0.85), "armor": Color(0.48, 0.42, 0.36)}

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 16,
		"hp": 34, "pwr": 13, "skl": 15, "spd": 15, "dfn": 10, "res": 6, "mov": 5,
		"weapons": ["rapier", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(5, 11), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 4,
		"hp": 39, "pwr": 15, "skl": 17, "spd": 18, "dfn": 10, "res": 6, "mov": 6,
		"weapons": ["ember_blade", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(5, 10), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 15,
		"hp": 39, "pwr": 16, "skl": 10, "spd": 9, "dfn": 14, "res": 4, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(5, 12), "color": Color(0.70, 0.55, 0.35),
		"hair": "spiky", "hair_color": Color(0.85, 0.65, 0.30), "armor": Color(0.55, 0.45, 0.35)},
	{"id": "vera", "name": "薇拉", "class": "盗贼", "faction": "player", "level": 16,
		"hp": 32, "pwr": 11, "skl": 16, "spd": 19, "dfn": 7, "res": 6, "mov": 6,
		"weapons": ["killing_edge", "steel_sword"], "wexp": {"sword": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 60, "dfn": 20, "res": 30},
		"pos": Vector2i(4, 10)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 16,
		"hp": 38, "pwr": 13, "skl": 11, "spd": 10, "dfn": 13, "res": 4, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(4, 11)},
	{"id": "noya", "name": "诺雅", "class": "修女", "faction": "player", "level": 15,
		"hp": 27, "pwr": 11, "skl": 9, "spd": 12, "dfn": 4, "res": 15, "mov": 5,
		"weapons": ["mend_staff", "heal_staff"], "wexp": {"staff": 71},
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 55},
		"pos": Vector2i(3, 11)},
	{"id": "selene", "name": "赛莲", "class": "天马骑士", "faction": "player", "level": 15,
		"hp": 30, "pwr": 11, "skl": 13, "spd": 17, "dfn": 7, "res": 12, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 55, "pwr": 35, "skl": 50, "spd": 65, "dfn": 15, "res": 45},
		"pos": Vector2i(4, 12)},
	{"id": "cyril", "name": "西里尔", "class": "魔道士", "faction": "player", "level": 16,
		"hp": 30, "pwr": 14, "skl": 11, "spd": 12, "dfn": 5, "res": 13, "mov": 5,
		"weapons": ["elfire", "thunder"], "wexp": {"anima": 121},
		"growths": {"hp": 50, "pwr": 55, "skl": 45, "spd": 50, "dfn": 15, "res": 45},
		"pos": Vector2i(3, 10)},
	{"id": "oscar", "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 16,
		"hp": 40, "pwr": 14, "skl": 10, "spd": 6, "dfn": 18, "res": 4, "mov": 4,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(3, 12)},
	# 修道院里：已经破门而入、到处搜刮的教会兵
	{"id": "soldier1", "pos": Vector2i(11, 6)},
	{"id": "soldier2", "pos": Vector2i(14, 13)},
	{"id": "armor1", "pos": Vector2i(20, 11), "hold": true},
	{"id": "mage1", "pos": Vector2i(10, 14), "items": ["vulnerary"]},
	{"id": "archer1", "pos": Vector2i(15, 15), "hold": true},
	{"id": "soldier3", "pos": Vector2i(19, 14), "hold": true},
	{"id": "cleric1", "pos": Vector2i(21, 15)},
	# 西边来路
	{"id": "soldier4", "pos": Vector2i(6, 7)},
	{"id": "armor2", "pos": Vector2i(5, 15), "hold": true},
	{"id": "archer3", "pos": Vector2i(3, 6), "hold": true},
	# 北坡：教会阵地
	{"id": "knight1", "pos": Vector2i(10, 1), "hold": true},
	{"id": "knight2", "pos": Vector2i(17, 1), "hold": true},
	{"id": "archer2", "pos": Vector2i(11, 0), "hold": true},
	{"id": "paladin1", "pos": Vector2i(15, 2), "hold": true, "items": ["elixir"]},
	{"id": "sage1", "pos": Vector2i(12, 1), "hold": true},
	# 欧蕾莉亚：教会贤者，守在北坡的堡垒上
	{"id": "aurelia", "name": "欧蕾莉亚", "class": "贤者", "faction": "enemy", "level": 8,
		"hp": 44, "pwr": 18, "skl": 15, "spd": 13, "dfn": 9, "res": 17, "mov": 6,
		"weapons": ["bolganone", "heal_staff"], "items": ["sage_crest"], "boss": true, "hold": true,
		"pos": Vector2i(13, 1), "color": Color(0.95, 0.92, 0.85),
		"hair": "hood", "armor": Color(0.96, 0.90, 0.72)},
]

## 第 3 回合灰袍盗贼从海上登岸；第 5 回合北坡增援骑兵；第 7 回合北坡再来步兵
const WAVES := {
	3: [{"id": "thief1", "pos": Vector2i(26, 12)}, {"id": "thief2", "pos": Vector2i(26, 14)},
		{"id": "thief3", "pos": Vector2i(25, 16)}],
	5: [{"id": "knight_r1", "pos": Vector2i(18, 0)}, {"id": "knight_r2", "pos": Vector2i(19, 0)},
		{"id": "paladin_r1", "pos": Vector2i(20, 0)}],
	7: [{"id": "soldier_r1", "pos": Vector2i(8, 0)}, {"id": "mage_r1", "pos": Vector2i(9, 1)}],
}

const DEPLOY := [Vector2i(2, 10), Vector2i(2, 11), Vector2i(2, 12), Vector2i(1, 10), Vector2i(1, 11),
	Vector2i(1, 12), Vector2i(6, 10), Vector2i(6, 12)]


func chapter_id() -> String:
	return "ch19"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 10


func forced_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_deploy_slots() -> Array:
	return DEPLOY


func templates() -> Dictionary:
	return {"soldier": _SOLDIER, "knight": _KNIGHT, "armor": _ARMOR, "archer": _ARCHER, "mage": _MAGE,
		"cleric": _CLERIC, "paladin": _PALADIN, "sage": _SAGE, "thief": _THIEF}


func lose_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_slots() -> Array:
	return DEPLOY


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "steel_sword", "steel_lance", "steel_axe", "steel_bow", "elfire", "mend_staff"]


func goal_label() -> String:
	return "祭坛"


func goal_tiles() -> Array:
	return [] if flags.get("shield_lost", false) else [ALTAR]


func is_won() -> bool:
	var b = battle.get_unit("aurelia")
	return b == null or not b.is_alive()


func win_condition() -> String:
	return tr("击败教会贤者欧蕾莉亚（别让敌人踏上祭台）")


func lose_condition() -> String:
	return tr("艾德里克、缇娅或加雷斯阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		var made: Array = battle.spawn_units(WAVES[t])
		Audio.play_sfx("reinforce")
		if t == 3:
			for m in made:
				m.stationary = true       # 盗贼只听「直扑祭台」的命令，敌方回合原地出手
			battle.show_banner(tr("灰袍盗贼从海上登岸！"), Color(1.0, 0.5, 0.3))
			await battle.play_dialogue(_raiders_land())
		else:
			battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
	await _check_altar()
	if t >= RAID_FROM and not flags.get("shield_lost", false):
		await _raiders_dash()
		await _check_altar()
	if t == 2 and not flags.get("hint", false) and not visited.has(VISIT_CELL):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


## 盗贼直扑祭台：沿着离祭台最近的路走满移动力；祭台上站着我方的人，就只能贴到旁边
func _raiders_dash() -> void:
	var raiders: Array = battle.units.filter(func(u) -> bool:
		return u.unit_id.begins_with("thief") and u.is_alive() and not u.is_player() and not u.is_npc())
	if raiders.is_empty():
		return
	if not flags.get("dash_told", false):
		flags["dash_told"] = true
		battle.show_banner(tr("盗贼冲向礼拜堂！"), Color(1.0, 0.5, 0.3))
	var field := _dist_field(ALTAR)
	for r in raiders:
		if flags.get("shield_lost", false):
			return
		r.stationary = false
		var mr: Dictionary = battle.board.move_range(r)
		r.stationary = true
		var best: Vector2i = r.grid_pos
		var best_d: int = int(field.get(r.grid_pos, 999))
		for tile in mr.keys():
			var d: int = int(field.get(tile, 999))
			if d < best_d:
				best_d = d
				best = tile
		if best == r.grid_pos:
			continue
		r.stationary = false
		var path: Array = battle.board.find_path(r, best, mr)
		r.stationary = true
		battle.cursor.set_grid(r.grid_pos)
		battle.board.ensure_visible(best, 1)
		if not path.is_empty():
			await battle._animate_move(r, path)
		r.grid_pos = best
		r.position = r.tile_center()
		if best == ALTAR:
			return


## 到祭台的步数场（只看地形，不看单位）：盗贼按它找路
func _dist_field(goal: Vector2i) -> Dictionary:
	var out := {goal: 0}
	var frontier: Array = [goal]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var np: Vector2i = cur + d
			if not battle.board.in_bounds(np) or not battle.board.terrain(np)["pass"]:
				continue
			var nd: int = int(out[cur]) + int(battle.board.terrain(np)["cost"])
			if out.has(np) and int(out[np]) <= nd:
				continue
			out[np] = nd
			frontier.append(np)
	return out


## 敌人站在祭台上：铁之盾被抢走，那人带着盾跑掉
func _check_altar() -> void:
	if flags.get("shield_lost", false):
		return
	var u = battle.board.unit_at(ALTAR)
	if u == null or u.is_player() or u.is_npc():
		return
	flags["shield_lost"] = true
	battle.board.goal_tiles = []
	await battle.play_dialogue(_shield_stolen(u))
	if not u.is_boss:
		battle.units.erase(u)
		u.queue_free()
	battle.notify(tr("铁之盾被抢走了……"))


func on_before_combat(att, def) -> void:
	if "aurelia" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var foe = def if att.unit_id == "aurelia" else att
		await battle.play_dialogue(_boss(foe.unit_id))


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("aurelia")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_CELL:
		await battle.play_dialogue(_visit_benedict(u.unit_id))
		battle.join_unit(BENEDICT, pos)
		battle.hint(tr("本笃是修士：用杖治疗同伴。站上祭台，也能护住铁之盾"))
	elif pos == VISIT_FISHER:
		await battle.play_dialogue(_visit_fisher())
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))


func talks() -> Array:
	return [["tia", "benedict", "tia_benedict"], ["noya", "benedict", "noya_benedict"]]


func talk_lines(key: String) -> Array:
	if key == "tia_benedict":
		return [
			_l("本笃", C_BENEDICT, "红头发的孩子，过来。……让老头子看看你的手。"),
			_l("缇娅", C_TIA, "我的手？"),
			_l("本笃", C_BENEDICT, "握剑的地方有一层薄茧，掌心却是烫的。……巫女的血，竟然还没断。"),
			_l("缇娅", C_TIA, "你知道巫女的事？教典上说，是她放火烧了半个大陆。"),
			_l("本笃", C_BENEDICT, "修道院的旧书上写的，是另一个故事：火失控的时候，巫女是最后一个走进火里的人。"),
			_l("本笃", C_BENEDICT, "八件圣器是锁。可锁这东西，总得有一把钥匙。……那一页，被人撕掉了。"),
			_l("缇娅", C_TIA, "钥匙……？"),
			_l("本笃", C_BENEDICT, "老头子也不知道。只知道撕书的人，一定很怕有人读到它。"),
		]
	return [
		_l("诺雅", C_NOYA, "本笃修士……您守着这座修道院，是奉了教会的命令吗？"),
		_l("本笃", C_BENEDICT, "四十年前是。后来教会把这里废了，命令也就没了。"),
		_l("诺雅", C_NOYA, "那您为什么还留下来？"),
		_l("本笃", C_BENEDICT, "因为盾还在这里。……孩子，命令会变，可该守的东西，不会因为没人下令就不该守了。"),
		_l("诺雅", C_NOYA, "……我以前以为，信仰就是听从。"),
		_l("本笃", C_BENEDICT, "听从是最省力的信仰。你选了费力的那一种——神会多看你一眼的。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	var lost: bool = flags.get("shield_lost", false)
	Campaign.flags["shield_lost"] = lost
	if not lost:
		var r: Array = Campaign.flags.get("relics", [])
		if not "iron_shield" in r:
			r.append("iron_shield")
		Campaign.flags["relics"] = r


func on_defeat() -> void:
	await battle.play_dialogue(_defeat())


# ==================== 小工具 ====================

func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "南方海岸。坍塌的钟楼立在悬崖上，修道院的围墙被海风啃得只剩一半。"),
		_l("", C_NARR, "一行人赶到时，教会的白旗已经插在了修道院北边的山坡上。"),
		_l("欧蕾莉亚", C_BOSS, "铁之盾就在礼拜堂里。那个老东西不肯交，就连礼拜堂一起拆了。"),
		_l("圣焰教会兵", C_ENEMY, "欧蕾莉亚大人，修道院里只有一个老修士……"),
		_l("欧蕾莉亚", C_BOSS, "一个老修士，守着一面盾守了四十年。……教会的耐心，就到今天为止。"),
		_l("艾德里克", C_EDRIC, "教会的部队已经到了……！"),
	]
	if _here("vera"):
		lines.append(_l("薇拉", C_VERA, "比账册上写的还早。卡斯帕一死，他们干脆自己动手抢了。"))
	lines.append_array([
		_l("加雷斯", C_GARETH, "礼拜堂在修道院东北角。冲进去，抢在他们前面！"),
		_l("缇娅", C_TIA, "那个老修士呢？"),
		_l("艾德里克", C_EDRIC, "礼拜堂西墙外的小屋……他应该在那里。谁先到，就去【访问】，让他知道我们不是来抢东西的。"),
		_l("艾德里克", C_EDRIC, "还有——盾供在礼拜堂的祭台上。无论如何，别让敌人踏上那座祭台。"),
	])
	return lines


func _turn2_hint() -> Array:
	return [
		_l("缇娅", C_TIA, "礼拜堂西墙外那间小屋，门还关着。……老修士还在里面吧？"),
		_l("艾德里克", C_EDRIC, "站到小屋门口【访问】。祭台那边，也得有人守着。"),
	]


func _raiders_land() -> Array:
	var lines: Array = [
		_l("灰袍盗贼", C_ENEMY, "船靠岸了！趁乱摸进礼拜堂，盾一到手就走！"),
		_l("艾德里克", C_EDRIC, "从海上……！他们要直取礼拜堂。"),
		_l("艾德里克", C_EDRIC, "下个回合起，他们就会冲向祭台。挡住他们——站上祭台，或者先把他们打倒！"),
	]
	if _here("vera"):
		lines.append(_l("薇拉", C_VERA, "灰袍养的耗子。跑得快，骨头脆。先下手的人赢。"))
	return lines


func _shield_stolen(u) -> Array:
	var lines: Array = [
		_l(u.display_name, C_ENEMY, "到手了！铁之盾——撤！"),
		_l("", C_NARR, "祭台上的铁盾被一把扯下。抢盾的人钻进坍塌的墙缝，消失在海风里。"),
		_l("艾德里克", C_EDRIC, "……被抢走了。"),
	]
	if _here("benedict"):
		lines.append(_l("本笃", C_BENEDICT, "别追了。它最后，总会回到它该去的地方。"))
	return lines


func _visit_benedict(by_id: String) -> Array:
	var lines: Array = [
		_l("本笃", C_BENEDICT, "……又是来抢盾的？老头子没力气打架了。可这把老骨头，还挡得住一扇门。"),
	]
	if by_id == "edric":
		lines.append_array([
			_l("艾德里克", C_EDRIC, "我是菲恩领的艾德里克。埃德蒙·菲恩的儿子。"),
			_l("本笃", C_BENEDICT, "埃德蒙……那个年轻人。十年前，他就坐在这间屋里，听我讲了一整夜八英雄的故事。"),
			_l("本笃", C_BENEDICT, "他说，有一天会有人来问铁之盾的事。让我看清楚，来的是什么人。"),
			_l("艾德里克", C_EDRIC, "……父亲他，已经不在了。"),
			_l("本笃", C_BENEDICT, "是吗。……那你就是他让我等的人。"),
		])
	elif by_id == "tia":
		lines.append_array([
			_l("缇娅", C_TIA, "我们不是教会的人。我们来，是不想让盾落到教会手里。"),
			_l("本笃", C_BENEDICT, "红头发……掌心是烫的。……孩子，你身上有火的味道。"),
			_l("本笃", C_BENEDICT, "教会追了八百年的东西，自己走进了老头子的门。看来，是神派你们来的。"),
		])
	else:
		lines.append_array([
			_l("本笃", C_BENEDICT, "……不对。你们的眼神，跟外面那帮人不一样。"),
			_l("本笃", C_BENEDICT, "外面的人想要盾。你们，是想让盾别落到他们手里。"),
		])
	lines.append(_l("本笃", C_BENEDICT, "盾，老头子守了四十年。今天也不会交给教会。……我跟你们一起守。"))
	return lines


func _visit_fisher() -> Array:
	return [
		_l("村民", C_NPC, "修道院的老修士，每年冬天都分鱼汤给我们这些打渔的。"),
		_l("村民", C_NPC, "你们是去帮他的？……这瓶药是老修士给的，一直没舍得用。还给他吧。"),
	]


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	if foe_id == "edric":
		lines.append(_l("欧蕾莉亚", C_BOSS, "菲恩家的孩子。你父亲当年也是这样——闯进不该去的地方，问不该问的问题。"))
		lines.append(_l("艾德里克", C_EDRIC, "所以你们就把他变成了傀儡？"))
		lines.append(_l("欧蕾莉亚", C_BOSS, "他把自己变成了异端。教会只是物尽其用。"))
	elif foe_id == "tia":
		lines.append(_l("欧蕾莉亚", C_BOSS, "炎之巫女。大司祭大人吩咐过，要你活着。……可没说要你完整。"))
	else:
		lines.append(_l("欧蕾莉亚", C_BOSS, "为了一面破盾拼命？你们根本不知道它是用来锁什么的。"))
	lines.append(_l("欧蕾莉亚", C_BOSS, "圣焰之下，异端皆为灰烬。"))
	return lines


func _boss_death() -> Array:
	return [
		_l("欧蕾莉亚", C_BOSS, "大司祭大人……圣器……终究会……回到神殿……"),
	]


func _post_battle() -> Array:
	var lost: bool = flags.get("shield_lost", false)
	var lines: Array = [
		_l("", C_NARR, "教会的部队退下了北坡。修道院里，只剩海浪拍打悬崖的声音。"),
	]
	if not lost:
		if _here("benedict"):
			lines.append_array([
				_l("本笃", C_BENEDICT, "拿去吧。八英雄之一、铁壁骑士的盾。……它挡下过不灭之火。"),
				_l("艾德里克", C_EDRIC, "……好重。"),
				_l("本笃", C_BENEDICT, "守护的东西，本来就重。"),
			])
		else:
			lines.append_array([
				_l("", C_NARR, "礼拜堂的门开了。一个老修士捧着铁盾走了出来。"),
				_l("老修士", C_BENEDICT, "你们守住了它。……拿去吧，它在这里，已经守不住了。"),
				_l("老修士", C_BENEDICT, "老头子就不跟你们走了。这座修道院，总得有人点蜡烛。"),
			])
		lines.append(_l("", C_NARR, "得到了圣器「铁之盾」。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "铁之盾……还是被抢走了。"))
		if _here("benedict"):
			lines.append(_l("本笃", C_BENEDICT, "别低头。教会抢圣器，最后都要送进神殿。它会在那里等你们。"))
		lines.append(_l("加雷斯", C_GARETH, "那就去神殿，连本带利抢回来！"))
	lines.append_array([
		_l("艾德里克", C_EDRIC, "父亲的笔记上，下一件是「风之弓」——北方的天马峰。"),
	])
	if _here("selene"):
		lines.append(_l("赛莲", C_SELENE, "天马骑士团的驻地……我的老家。"))
		lines.append(_l("赛莲", C_SELENE, "团长阿德琳要是还在……不，她一定还在。她不会让任何人碰那把弓的。"))
	else:
		lines.append(_l("缇娅", C_TIA, "天马骑士团世代守着那把弓……希望他们还没被教会收买。"))
	return lines


func _defeat() -> Array:
	for id in ["edric", "tia", "gareth"]:
		var u = battle.get_unit(id)
		if u != null and not u.is_alive():
			if id == "edric":
				return [_l("艾德里克", C_EDRIC, "父亲……对不起……盾……"),
					_l("", C_NARR, "艾德里克倒下了。铁之盾被装上了教会的马车。")]
			if id == "tia":
				return [_l("缇娅", C_TIA, "火……熄了……"),
					_l("", C_NARR, "缇娅倒下了。海风吹灭了礼拜堂里最后一根蜡烛。")]
			return [_l("加雷斯", C_GARETH, "父王……对不住……"),
				_l("", C_NARR, "加雷斯倒下了。布罗登的王子，再也没能回到故乡。")]
	return []


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "monastery", "from": "camp", "lines": [
		_l("", CB_NARR, "灰袍众的账册上，写着下一单的地点：南方海岸，废修道院。"),
		_l("", CB_NARR, "那里供着八圣器之一——「铁之盾」。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "天马峰 · 骑士团驻地", "mood": "castle", "lines": [
			_l("阿德琳", CB_ENEMY, "教会的命令：风之弓，交给大司祭。"),
			_l("琪拉", CB_NARR, "团长！风之弓是骑士团世代守护的东西——"),
			_l("阿德琳", CB_ENEMY, "世代守护，守到骑士团只剩二十匹天马、连草料都买不起。"),
			_l("阿德琳", CB_ENEMY, "琪拉，饿着肚子的人，守不住任何东西。"),
			_l("琪拉", CB_NARR, "……赛莲前辈要是在，一定不会答应的。"),
			_l("阿德琳", CB_ENEMY, "赛莲早就离开了。……别再提她。"),
		]},
	]
