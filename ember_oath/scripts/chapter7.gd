class_name Chapter7
extends ChapterBase
## 第七章「笼中之鸟」：去王都路上的边境城镇白垣镇。偷了教会押运车的孤儿盗贼小雀（中立）被教会兵满城追捕，
## 缇娅和她对话就能收留她入队；她会开教会仓库里的宝箱。第 3 回合北门落闸，东门来骑士。
## 胜利：缇娅冲到南门（撤离点）。可南门外是审判官塞拉斯的圈套——篇末缇娅与诺雅被擒，其余同伴四散。

const CHAPTER_TITLE := "第七章 · 笼中之鸟"
const VICTORY_TITLE := "第一篇「灰烬之芽」 · 完"
const VICTORY_SUB := "铁笼车往圣都去了。其余的人，消失在夜色里。"
const DEFEAT_SUB := "白垣镇的城门，再也没有打开……"
const BG := ""

## 34×24。城墙围起来的白垣镇：北门（我方进城处，第 3 回合落闸）、南门（撤离点，守门骑士队长在门洞里）、东门（增援）。
## 一条运河把城分成北城、南城（三座桥）：北城有广场、西北钟楼院子（小雀躲在这儿）、东北教会仓库（押运车、两只宝箱）；
## 南城集市里有武器店、道具店；两户人家可访问。
const MAP := [
	"################GG################",
	"#########.......SS..F...########F#",
	"#.ISSSSI..DD..FFSS..DD..#QSAASQ#.#",
	"#fSSSSSS..D..DD.SS..D.F.#SSSSSS#.#",
	"#fSSSSSS........SS....D.#ISSSSI#.#",
	"#...F...........SS...FF.###G####.#",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"#...............SS.F..........SSS#",
	"#.DD....D...ISSSSSSSSI..DDF...SSS#",
	"#....DD..D..SWSSSSSSSSFF...D..SSS#",
	"#.D........FSSSSSSSSSSD...D...SSS#",
	"#...FFS.........SS.........S..SSSG",
	"#~~~~~B~~~~~~~~~BB~~~~~~~~~B~~SSS#",
	"#.....S..F.F....SS.........S..SSS#",
	"#.DD....D.F.SSSSSSSSSS..D..D..SSS#",
	"#....D...D.YSSSSSSSSSSV..D..D.SSS#",
	"#...........ISSSSSSSSI.D.F....SSS#",
	"#...............SSF....F......SSS#",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"#..F........FF..SS.......FF......#",
	"#.DFH....D...D..SS..D...D....HD..#",
	"#F...DD...D.....SS...D...D..D....#",
	"#....F..........SSF............FF#",
	"################GG################",
]

const LEVELS := []                # 全图同一高度

const GOAL := [Vector2i(16, 23), Vector2i(17, 23)]
const NORTH_GATE := [Vector2i(16, 0), Vector2i(17, 0)]
const CHESTS := {Vector2i(25, 2): "hero_crest", Vector2i(30, 2): "elixir"}
const VISIT_OLD := Vector2i(4, 20)
const VISIT_WIDOW := Vector2i(29, 20)
const SHOP_ARMORY := Vector2i(11, 15)
const SHOP_VENDOR := Vector2i(22, 15)
const SPARROW_LEAVES := 6         # 第 6 回合开始时还没收留，小雀就自己翻墙跑了

const C_TIA := Color(1.0, 0.62, 0.45)
const C_NINA := Color(0.7, 0.95, 0.7)
const C_KAIN := Color(0.85, 0.8, 1.0)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_CYRIL := Color(1.0, 0.72, 0.42)
const C_SPARROW := Color(0.95, 0.85, 0.45)
const C_SILAS := Color(0.95, 0.92, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _CHURCH := {"name": "圣焰教会兵", "class": "枪兵", "faction": "enemy", "level": 7,
	"hp": 26, "pwr": 8, "skl": 6, "spd": 6, "dfn": 6, "mov": 5,
	"weapons": ["iron_lance"], "color": Color(0.85, 0.82, 0.75),
	"hair": "short", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.82, 0.78, 0.70)}
const _KNIGHT := {"name": "圣焰骑士", "class": "骑士", "faction": "enemy", "level": 8,
	"hp": 29, "pwr": 9, "skl": 7, "spd": 6, "dfn": 8, "mov": 7,
	"weapons": ["iron_lance"], "color": Color(0.80, 0.78, 0.82),
	"hair": "short", "hair_color": Color(0.55, 0.45, 0.30), "armor": Color(0.86, 0.84, 0.88)}
const _ARCHER := {"name": "教会弓兵", "class": "弓箭手", "faction": "enemy", "level": 7,
	"hp": 23, "pwr": 7, "skl": 8, "spd": 7, "dfn": 3, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.80, 0.78, 0.70),
	"hair": "hood", "armor": Color(0.78, 0.74, 0.64)}
const _MAGE := {"name": "教会魔道士", "class": "魔道士", "faction": "enemy", "level": 7,
	"hp": 21, "pwr": 8, "skl": 6, "spd": 6, "dfn": 2, "res": 7, "mov": 5,
	"weapons": ["fire"], "color": Color(0.92, 0.88, 0.78),
	"hair": "hood", "armor": Color(0.90, 0.86, 0.74)}

const UNITS := [
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 10,
		"hp": 30, "pwr": 10, "skl": 12, "spd": 13, "dfn": 7, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(16, 1), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "nina", "pos": Vector2i(17, 1), "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 6,
		"hp": 22, "pwr": 7, "skl": 11, "spd": 9, "dfn": 4, "mov": 5, "weapons": ["iron_bow"],
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15}},
	{"id": "kain", "pos": Vector2i(16, 2), "name": "凯因", "class": "佣兵", "faction": "player", "level": 7,
		"hp": 27, "pwr": 9, "skl": 12, "spd": 13, "dfn": 5, "mov": 5, "weapons": ["iron_sword"],
		"growths": {"hp": 70, "pwr": 40, "skl": 60, "spd": 65, "dfn": 25}},
	{"id": "noya", "pos": Vector2i(17, 2), "name": "诺雅", "class": "修女", "faction": "player", "level": 5,
		"hp": 19, "pwr": 5, "skl": 6, "spd": 8, "dfn": 2, "mov": 5, "weapons": ["heal_staff"],
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15}},
	{"id": "cyril", "pos": Vector2i(15, 1), "name": "西里尔", "class": "魔道士", "faction": "player", "level": 7,
		"hp": 24, "pwr": 8, "skl": 7, "spd": 8, "dfn": 3, "res": 8, "mov": 5, "weapons": ["fire"],
		"growths": {"hp": 50, "pwr": 55, "skl": 45, "spd": 50, "dfn": 15, "res": 45}},
	# 小雀：中立（绿色），躲在钟楼院子里。缇娅和她对话就入队
	{"id": "sparrow", "name": "小雀", "class": "盗贼", "faction": "npc", "level": 3, "stationary": true,
		"hp": 17, "pwr": 4, "skl": 7, "spd": 10, "dfn": 2, "res": 2, "mov": 6,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 50, "pwr": 30, "skl": 50, "spd": 65, "dfn": 15, "res": 25},
		"pos": Vector2i(4, 3), "color": Color(0.55, 0.70, 0.45),
		"hair": "short", "hair_color": Color(0.62, 0.38, 0.22), "armor": Color(0.40, 0.58, 0.44)},
	# 敌方：满城搜捕的教会兵
	{"id": "church1", "pos": Vector2i(6, 5)},
	{"id": "church2", "pos": Vector2i(10, 6)},
	{"id": "church3", "pos": Vector2i(19, 9)},
	{"id": "church4", "pos": Vector2i(27, 6), "hold": true},
	{"id": "church5", "pos": Vector2i(16, 11)},
	{"id": "church6", "pos": Vector2i(6, 13)},
	{"id": "church7", "pos": Vector2i(27, 13)},
	{"id": "church8", "pos": Vector2i(14, 18)},
	{"id": "knight1", "pos": Vector2i(22, 9)},
	{"id": "knight2", "pos": Vector2i(19, 19)},
	{"id": "knight3", "pos": Vector2i(31, 15)},
	{"id": "archer1", "pos": Vector2i(26, 3), "hold": true},
	{"id": "archer2", "pos": Vector2i(9, 10)},
	{"id": "archer3", "pos": Vector2i(15, 20)},
	{"id": "archer4", "pos": Vector2i(20, 16)},
	{"id": "mage1", "pos": Vector2i(14, 14)},
	{"id": "mage2", "pos": Vector2i(29, 3), "hold": true},
	{"id": "mage3", "pos": Vector2i(18, 21)},
	# 南门守将罗伦兹：站在门洞里不动（门洞守备高，回合开始回血）
	{"id": "lorenz", "name": "罗伦兹", "class": "骑士", "faction": "enemy", "level": 10,
		"hp": 34, "pwr": 11, "skl": 9, "spd": 8, "dfn": 10, "res": 4, "mov": 7,
		"weapons": ["silver_lance"], "boss": true, "stationary": true,
		"pos": Vector2i(17, 23), "color": Color(0.84, 0.82, 0.88),
		"hair": "short", "hair_color": Color(0.70, 0.62, 0.40), "armor": Color(0.90, 0.88, 0.94)},
]

## 第 3 回合北门落闸、东门冲进骑士；第 5 回合东门再来教会兵
const WAVES := {
	3: [{"id": "knight_r1", "pos": Vector2i(32, 11)}, {"id": "knight_r2", "pos": Vector2i(32, 10)}],
	5: [{"id": "church_r1", "pos": Vector2i(32, 12)}, {"id": "church_r2", "pos": Vector2i(31, 11)}],
	7: [{"id": "knight_r3", "pos": Vector2i(32, 11)}, {"id": "archer_r1", "pos": Vector2i(32, 12)}],
}


func chapter_id() -> String:
	return "ch7"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 5


func extra_deploy_slots() -> Array:
	return [Vector2i(18, 1), Vector2i(15, 2), Vector2i(18, 2)]


func templates() -> Dictionary:
	return {"church": _CHURCH, "knight": _KNIGHT, "archer": _ARCHER, "mage": _MAGE}


func lose_ids() -> Array:
	return ["tia"]


func extra_slots() -> Array:
	return [Vector2i(18, 1), Vector2i(15, 2), Vector2i(18, 2), Vector2i(14, 1)]


## 南城集市的武器店、道具店
func shops() -> Dictionary:
	return {SHOP_ARMORY: ["iron_sword", "steel_sword", "iron_lance", "steel_lance", "iron_axe", "steel_bow", "fire", "thunder"],
		SHOP_VENDOR: ["vulnerary", "elixir", "heal_staff", "mend_staff"]}


func goal_tiles() -> Array:
	return GOAL


func chests() -> Dictionary:
	return CHESTS


## 篇末：缇娅与诺雅被擒，其余同伴四散（都标成离队，第二篇再一个个找回来）
func after_victory_status() -> Dictionary:
	var out := {}
	for id in Campaign.active_ids():
		out[id] = "away"
	return out


func is_won() -> bool:
	var tia = battle.get_unit("tia")
	if tia != null and tia.is_alive() and tia.grid_pos in GOAL:
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("缇娅冲出南城门")


func lose_condition() -> String:
	return tr("缇娅阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_resume() -> void:
	if flags.get("gate_closed", false):
		_close_north_gate()


func on_turn_start(t: int) -> void:
	if t == 3 and not flags.get("gate_closed", false):
		flags["gate_closed"] = true
		_close_north_gate()
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("北门落闸！"), Color(1.0, 0.5, 0.3))
		await battle.play_dialogue(_gate_closed())
	if WAVES.has(t) and not flags.get("wave_%d" % t, false):
		flags["wave_%d" % t] = true
		battle.spawn_units(WAVES[t])
		if t != 3:
			Audio.play_sfx("reinforce")
			battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t == SPARROW_LEAVES:
		var s = battle.get_unit("sparrow")
		if s != null and s.is_npc():
			await battle.play_dialogue(_sparrow_leaves())
			battle.units.erase(s)
			s.queue_free()
			battle.notify(tr("小雀翻过城墙跑掉了"))


## 北门落闸：门洞换成城墙（门洞里有人就先不关，下回合再关）
func _close_north_gate() -> void:
	for p in NORTH_GATE:
		if battle.board.unit_at(p) == null:
			battle.board.set_tile(p, "#")


func on_before_combat(att, def) -> void:
	if "lorenz" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())


func on_after_combat(_att, def, def_died: bool) -> void:
	if def.unit_id == "lorenz" and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_OLD:
		await battle.play_dialogue(_visit_old())
		u.receive("vulnerary")
		battle.notify(tr("获得 伤药"))
	elif pos == VISIT_WIDOW:
		await battle.play_dialogue(_visit_widow())
		battle.add_gold(1000)
		battle.notify(tr("获得 1000G"))


func recruits() -> Dictionary:
	return {"sparrow": ["tia"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return [
		_l("小雀", C_SPARROW, "别过来！……你们也是来抓我的？"),
		_l("缇娅", C_TIA, "不是。我们也被教会追着，一路追到这儿。"),
		_l("小雀", C_SPARROW, "……骗人。教会追的都是坏人。"),
		_l("缇娅", C_TIA, "那你呢？你偷了什么，让他们满城找你？"),
		_l("小雀", C_SPARROW, "我以为押运车里装的是粮……掀开篷布一看，全是铁笼子。笼子上都刻着火的纹章。"),
		_l("小雀", C_SPARROW, "我就拿了一把钥匙。……他们要抓的，是会用火的人，对不对？"),
		_l("缇娅", C_TIA, "……对。所以我们得一起跑出去。"),
		_l("小雀", C_SPARROW, "我叫小雀。没爹没娘，会开锁，什么锁都行。……带上我，仓库里的箱子我闭着眼都能打开。"),
	]


func on_recruited(t, _by) -> void:
	t.stationary = false
	t.hold = false
	battle.hint(tr("小雀是盗贼：站到宝箱上可以【开宝箱】"))


func talks() -> Array:
	return [["tia", "noya", "tia_noya_ch7"], ["nina", "sparrow", "nina_sparrow"]]


func talk_lines(key: String) -> Array:
	if key == "tia_noya_ch7":
		return [
			_l("诺雅", C_NOYA, "缇娅，这座镇子……太安静了。教会兵到处都是，可没有一个人在找路上的我们。"),
			_l("缇娅", C_TIA, "你也觉得像个陷阱？"),
			_l("诺雅", C_NOYA, "……审判官大人布局的时候，就是这样。先让猎物以为自己逃掉了。"),
			_l("诺雅", C_NOYA, "缇娅，如果真的出了什么事——我会站在你这边。哪怕对面是审判官大人。"),
			_l("缇娅", C_TIA, "……傻瓜。我们都会出去的。"),
		]
	return [
		_l("妮娜", C_NINA, "你多大了？爬墙比林子里的松鼠还快。"),
		_l("小雀", C_SPARROW, "十四。……大概吧，没人记得我生日。"),
		_l("妮娜", C_NINA, "……我爹以前说，十四岁就能自己进山了。出了城，我教你下套子抓兔子。"),
		_l("小雀", C_SPARROW, "真的？那你可别反悔！"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["arc1_captured"] = _captured_ids()


func on_defeat() -> void:
	await battle.play_dialogue(_defeat_tia())


func _captured_ids() -> Array:
	var out := ["tia"]
	var n = battle.get_unit("noya")
	if n != null and n.is_alive() and n.is_player():
		out.append("noya")
	return out


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "离王都还有三天路程。边境的白垣镇，城墙刷得雪白。"),
		_l("", C_NARR, "一行人刚进北门，街上就乱了起来。"),
		_l("圣焰教会兵", C_ENEMY, "站住！小贼！教会的押运车你也敢碰？！"),
		_l("", C_NARR, "一个瘦小的身影从人群里钻过去，翻上了西北钟楼的院墙。"),
		_l("妮娜", C_NINA, "那孩子……被一整队教会兵追着。"),
	]
	if battle.get_unit("cyril") != null:
		lines.append(_l("西里尔", C_CYRIL, "城里的教会兵太多了，多得不像是在抓一个小偷。……像是在等什么人。"))
	if battle.get_unit("kain") != null:
		lines.append(_l("凯因", C_KAIN, "城门有兵守着，进来容易，出去难。要走就趁现在，往南门冲。"))
	lines.append(_l("缇娅", C_TIA, "先把那孩子带上，再从南门出城。……我不想丢下被教会追着的人。"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("妮娜", C_NINA, "钟楼院子里那个孩子没动，教会兵也不碰她……像是在拿她当饵。"),
		_l("缇娅", C_TIA, "那我去跟她说。……走到她身边，选【对话】。"),
	]


func _gate_closed() -> Array:
	return [
		_l("", C_NARR, "轰的一声，北门的铁闸落了下来。东门那边，马蹄声越来越近。"),
		_l("圣焰骑士", C_ENEMY, "东门的骑士已经进城！所有出口封锁，只留南门——审判官大人有令，一个不许放过！"),
		_l("西里尔", C_CYRIL, "只留南门……这话说得也太大声了。"),
		_l("缇娅", C_TIA, "管不了那么多了。往南冲！"),
	]


func _sparrow_leaves() -> Array:
	return [
		_l("小雀", C_SPARROW, "……谁都靠不住。我自己走！"),
		_l("", C_NARR, "那个瘦小的身影翻过城墙，消失了。"),
	]


func _boss() -> Array:
	return [
		_l("罗伦兹", C_BOSS, "南门守将罗伦兹。……审判官大人说得没错，你们果然往这边来了。"),
		_l("缇娅", C_TIA, "让开！"),
		_l("罗伦兹", C_BOSS, "让？我的任务，是让你们「好不容易」才走出这道门。"),
	]


func _boss_death() -> Array:
	return [
		_l("罗伦兹", C_BOSS, "去吧……笼门……已经开了……"),
	]


func _visit_old() -> Array:
	return [
		_l("老人", C_NPC, "外乡人，听我一句：今天的白垣镇，进来的人比出去的多。"),
		_l("老人", C_NPC, "教会的人前天就封了半座城，说是在等「一只鸟」。这瓶药你们带着。"),
	]


func _visit_widow() -> Array:
	return [
		_l("寡妇", C_NPC, "那孩子……小雀，常给我家小儿子偷面包吃。她不是坏孩子。"),
		_l("寡妇", C_NPC, "这些钱你们拿着，替我带她出城。别让她被关进笼子里。"),
	]


func _post_battle() -> Array:
	var noya_in := _captured_ids().has("noya")
	var lines: Array = [
		_l("", C_NARR, "南门洞开。门外的大道上，一个人也没有。"),
		_l("缇娅", C_TIA, "出来了……！大家快——"),
		_l("", C_NARR, "道路两侧的树林里，一排排白色的火把同时亮了起来。"),
		_l("塞拉斯", C_SILAS, "好久不见，炎之巫女。"),
		_l("缇娅", C_TIA, "……审判官塞拉斯！"),
		_l("塞拉斯", C_SILAS, "笼子从你们走进北门那一刻就关上了。我只留了一道门——让你们以为，自己还能飞出去。"),
		_l("塞拉斯", C_SILAS, "放下剑。你一个人跟我回圣都，其余的人，我今晚不追。"),
	]
	if battle.get_unit("kain") != null:
		lines.append(_l("凯因", C_KAIN, "别听他的，缇娅！我们杀出去——"))
	lines.append(_l("缇娅", C_TIA, "……你看看四周，凯因。我们杀不出去的。"))
	lines.append(_l("缇娅", C_TIA, "大家分头走！活下去——活着，才能再见！"))
	if battle.get_unit("sparrow") != null and battle.get_unit("sparrow").is_player():
		lines.append(_l("小雀", C_SPARROW, "下水道！跟我来，城墙底下有条老水道！"))
	if battle.get_unit("cyril") != null:
		lines.append(_l("西里尔", C_CYRIL, "……缇娅。王都大书库，我会先去。等你。"))
	if noya_in:
		lines.append(_l("诺雅", C_NOYA, "我不走。"))
		lines.append(_l("缇娅", C_TIA, "诺雅！"))
		lines.append(_l("诺雅", C_NOYA, "我说过的，我会站在你这边。……哪怕对面是审判官大人。"))
		lines.append(_l("塞拉斯", C_SILAS, "……诺雅。连你也选了她吗。"))
	lines.append(_l("", C_NARR, "那一夜，白垣镇的南门外，一辆铁笼车缓缓驶向圣都。"))
	if noya_in:
		lines.append(_l("", C_NARR, "笼子里坐着两个人。一个红发的少女，一个穿白衣的见习修女。"))
	else:
		lines.append(_l("", C_NARR, "笼子里坐着一个红发的少女。她一直望着北方。"))
	lines.append(_l("", C_NARR, "其余的人，都消失在了夜色里。"))
	return lines


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "笼子……原来，一直都是笼子……"),
		_l("", C_NARR, "缇娅倒下了。白垣镇的城门，一扇接一扇地关上。"),
	]


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "whitewall", "from": "inn", "lines": [
		_l("", CB_NARR, "翻过雪岭，离王都只剩三天的路程。"),
		_l("", CB_NARR, "边境的白垣镇，城墙刷得雪白。南来北往的商队，都在这里歇一晚。"),
	]}


func epilogue() -> Array:
	var scenes: Array = []
	var noya_in := _captured_ids().has("noya")
	var cage: Array = [
		_l("", CB_NARR, "铁笼车在夜路上颠簸。车外的白色火把，一路延伸到看不见的地方。"),
	]
	if noya_in:
		cage.append(_l("诺雅", C_NOYA, "缇娅……你冷吗？"))
		cage.append(_l("缇娅", C_TIA, "不冷。手心里，还剩一点点火。"))
		cage.append(_l("诺雅", C_NOYA, "那就留着它。……等到能用的那一天。"))
		cage.append(_l("缇娅", C_TIA, "嗯。大家……一定都逃出去了吧。"))
	else:
		cage.append(_l("缇娅", C_TIA, "（手心里，还剩一点点火。……大家，一定都逃出去了吧。）"))
	scenes.append({"title": "通往圣都的夜路", "mood": "night", "lines": cage})
	scenes.append({"title": "菲恩城", "mood": "castle", "lines": [
		_l("兰斯", CB_LANCE, "少主！圣都来的信——领主大人他……在调查圣器失窃案的途中，失踪了。"),
		_l("艾德里克", CB_EDRIC, "……父亲？"),
		_l("兰斯", CB_LANCE, "最后一次有人见到他，是在去圣都的路上。"),
		_l("艾德里克", CB_EDRIC, "备马。叫上葛温和奥斯卡。……我去把他找回来。"),
		_l("", CB_NARR, "——第一篇「灰烬之芽」 完。"),
		_l("", CB_NARR, "第二篇「寻父之旅」，制作中。"),
	]})
	return scenes
