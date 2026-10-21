class_name Chapter20
extends ChapterBase
## 第二十章「天马峰」：北方群峰上的天马骑士团驻地，「风之弓」由骑士团世代守护——可团长阿德琳已经投靠了教会。
## 四层台地之间是崖壁，步兵只能沿之字形的窄路往上爬；敌人大多是天马骑士，从崖壁上空直接飞过来（弓对飞行三倍威力）。
## 琪拉（赛莲的后辈，敌方天马骑士）：赛莲【说得】入队；赛莲不在时她只是普通敌人，可以击败。
## 胜利：击败团长阿德琳，得到风之弓。败北：艾德里克、缇娅、加雷斯任一阵亡。

const CHAPTER_TITLE := "第二十章 · 天马峰"
const VICTORY_TITLE := "第二十章 · 完"
const VICTORY_SUB := "峰顶的风停了。风之弓，第一次离开了天马峰。"
const DEFEAT_SUB := "云海之上，只剩天马的嘶鸣……"
const BG := ""
const THEME := "snow"

## 30×24。四层台地：山脚 1 → 半山 2 → 山肩 3 → 峰顶 4，层与层之间是崖壁 X，各只有一条坡道（东 → 西 → 东，之字形往上爬）。
## 步兵只能走窄路；天马骑士从崖壁、山岩上空直接飞过来。峰顶是天马骑士团驻地，团长阿德琳守在堡垒上。
const MAP := [
	"MMMMMMMMM....h........MMMMMMMM",
	"MMMMMMMM.DD....T....DD.MMMMMMM",
	"MMMMMMMM....XX.........MMMMMMM",
	"MMMMMMMM....XX....XX...MMMMMMM",
	"MMMMMMMMMhhA......XX...MMMMMMM",
	"XXXXXXXXXXXXXXXXXXXXRRXXXXXXXX",
	"MMMM.RRRRRRRRRR.....FR.....MMM",
	"MMM..R...XX..TRRRRRRRR..F..MMM",
	"MMM.FR...XX....XXX....F....MMM",
	"MMM..R...XX....XXX.........MMM",
	"MMM..R...F..F..XXX....F.F.MMMM",
	"XXXXRRXXXXXXXXXXXXXXXXXXXXXXXX",
	"MM..hRRRRRRRRRRh..XX.......MMM",
	"MM.......hXXXhR...XX....h..MMM",
	"MM........XXX.R...XX........MM",
	"MM........XXX.RRRRRRRRRR.H..MM",
	"MMM.................h..R...hMM",
	"XXXXXXXXXXXXXXXXXXXXXXXRRXXXXX",
	"MMM........FF..XX.F....R..F.MM",
	"MMM....F....RRRXXRRRRRRR....MM",
	"MMF.....XX..R..XX...........MM",
	"MMF..RRRXXRRR........T....FFMM",
	"MM..H...XX.............F...MMM",
	"MM.....F...........F......MMMM",
]

const LEVELS := [
	"444444444444444444444444444444",
	"444444444444444444444444444444",
	"444444444444444444444444444444",
	"444444444444444444444444444444",
	"444444444444444444444444444444",
	"333333333333333333334433333333",
	"333333333333333333333333333333",
	"333333333333333333333333333333",
	"333333333333333333333333333333",
	"333333333333333333333333333333",
	"333333333333333333333333333333",
	"222233222222222222222222222222",
	"222222222222222222222222222222",
	"222222222222222222222222222222",
	"222222222222222222222222222222",
	"222222222222222222222222222222",
	"222222222222222222222222222222",
	"111111111111111111111112211111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
	"111111111111111111111111111111",
]

const VISIT_SHEPHERD := Vector2i(4, 22)
const VISIT_STABLE := Vector2i(25, 15)

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_TIA := Color(1.0, 0.62, 0.45)
const C_GARETH := Color(1.0, 0.8, 0.5)
const C_SELENE := Color(0.75, 0.9, 1.0)
const C_NOYA := Color(1.0, 0.95, 0.8)
const C_KIRA := Color(0.8, 0.95, 0.85)
const C_LISS := Color(0.85, 0.95, 0.7)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

## 敌兵：天马为主 Lv16–19，上级 4–6
const _PEGASUS := {"name": "天马骑士", "class": "天马骑士", "faction": "enemy", "level": 17,
	"hp": 30, "pwr": 10, "skl": 12, "spd": 14, "dfn": 8, "res": 12, "mov": 7,
	"weapons": ["steel_lance"], "color": Color(0.85, 0.88, 0.95),
	"hair": "ponytail", "hair_color": Color(0.55, 0.45, 0.35), "armor": Color(0.88, 0.90, 0.96)}
const _FALCON := {"name": "隼骑士", "class": "隼骑士", "faction": "enemy", "level": 5,
	"hp": 38, "pwr": 14, "skl": 15, "spd": 17, "dfn": 11, "res": 15, "mov": 8,
	"weapons": ["steel_lance", "javelin"], "color": Color(0.82, 0.86, 0.96),
	"hair": "ponytail", "hair_color": Color(0.40, 0.32, 0.25), "armor": Color(0.86, 0.88, 0.98)}
const _SOLDIER := {"name": "骑士团卫兵", "class": "枪兵", "faction": "enemy", "level": 17,
	"hp": 36, "pwr": 13, "skl": 11, "spd": 11, "dfn": 11, "res": 5, "mov": 5,
	"weapons": ["steel_lance"], "color": Color(0.80, 0.84, 0.92),
	"hair": "short", "armor": Color(0.78, 0.82, 0.90)}
const _ARCHER := {"name": "骑士团弓手", "class": "弓箭手", "faction": "enemy", "level": 17,
	"hp": 33, "pwr": 12, "skl": 13, "spd": 12, "dfn": 8, "res": 5, "mov": 5,
	"weapons": ["steel_bow"], "color": Color(0.80, 0.84, 0.92),
	"hair": "hood", "armor": Color(0.76, 0.80, 0.88)}
const _CLERIC := {"name": "骑士团修女", "class": "修女", "faction": "enemy", "level": 16,
	"hp": 28, "pwr": 11, "skl": 9, "spd": 11, "dfn": 4, "res": 14, "mov": 5,
	"weapons": ["mend_staff"], "color": Color(0.95, 0.95, 0.98),
	"hair": "hood", "armor": Color(0.92, 0.92, 0.98)}

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 17,
		"hp": 35, "pwr": 13, "skl": 15, "spd": 15, "dfn": 11, "res": 7, "mov": 5,
		"weapons": ["rapier", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(5, 21), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "tia", "name": "缇娅", "class": "炎刃使", "faction": "player", "level": 5,
		"hp": 40, "pwr": 15, "skl": 17, "spd": 18, "dfn": 11, "res": 7, "mov": 6,
		"weapons": ["ember_blade", "steel_sword"], "items": ["vulnerary"], "wexp": {"sword": 121},
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35, "res": 30},
		"pos": Vector2i(6, 21), "color": Color(0.95, 0.40, 0.22),
		"hair": "ponytail", "hair_color": Color(1.0, 0.42, 0.12), "armor": Color(0.72, 0.28, 0.16)},
	{"id": "gareth", "name": "加雷斯", "class": "王子", "faction": "player", "level": 16,
		"hp": 40, "pwr": 16, "skl": 11, "spd": 9, "dfn": 14, "res": 5, "mov": 5,
		"weapons": ["wolf_axe", "hand_axe"], "items": ["vulnerary"],
		"growths": {"hp": 90, "pwr": 60, "skl": 40, "spd": 30, "dfn": 45, "res": 20},
		"pos": Vector2i(4, 21), "color": Color(0.70, 0.55, 0.35),
		"hair": "spiky", "hair_color": Color(0.85, 0.65, 0.30), "armor": Color(0.55, 0.45, 0.35)},
	{"id": "selene", "name": "赛莲", "class": "天马骑士", "faction": "player", "level": 16,
		"hp": 31, "pwr": 11, "skl": 13, "spd": 18, "dfn": 7, "res": 13, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 55, "pwr": 35, "skl": 50, "spd": 65, "dfn": 15, "res": 45},
		"pos": Vector2i(5, 20)},
	{"id": "liss", "name": "莉丝", "class": "弓箭手", "faction": "player", "level": 16,
		"hp": 32, "pwr": 13, "skl": 16, "spd": 15, "dfn": 7, "res": 6, "mov": 5,
		"weapons": ["steel_bow", "iron_bow"], "wexp": {"bow": 121},
		"growths": {"hp": 60, "pwr": 40, "skl": 55, "spd": 50, "dfn": 20, "res": 30},
		"pos": Vector2i(4, 20)},
	{"id": "nina", "name": "妮娜", "class": "弓箭手", "faction": "player", "level": 16,
		"hp": 32, "pwr": 12, "skl": 16, "spd": 14, "dfn": 6, "res": 5, "mov": 5,
		"weapons": ["steel_bow", "iron_bow"], "wexp": {"bow": 121},
		"growths": {"hp": 55, "pwr": 45, "skl": 55, "spd": 50, "dfn": 15},
		"pos": Vector2i(6, 20)},
	{"id": "noya", "name": "诺雅", "class": "修女", "faction": "player", "level": 16,
		"hp": 28, "pwr": 12, "skl": 10, "spd": 13, "dfn": 4, "res": 15, "mov": 5,
		"weapons": ["mend_staff", "heal_staff"], "wexp": {"staff": 71},
		"growths": {"hp": 45, "pwr": 40, "skl": 40, "spd": 50, "dfn": 15, "res": 55},
		"pos": Vector2i(3, 21)},
	{"id": "ivy", "name": "艾薇", "class": "魔道士", "faction": "player", "level": 16,
		"hp": 29, "pwr": 14, "skl": 13, "spd": 12, "dfn": 5, "res": 13, "mov": 5,
		"weapons": ["elfire", "thunder"], "wexp": {"anima": 121},
		"growths": {"hp": 45, "pwr": 50, "skl": 45, "spd": 45, "dfn": 15, "res": 50},
		"pos": Vector2i(5, 22)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 17,
		"hp": 39, "pwr": 14, "skl": 12, "spd": 11, "dfn": 13, "res": 4, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "wexp": {"lance": 121},
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(3, 20)},
	# 琪拉：赛莲的后辈。守在半山腰，赛莲【说得】入队
	{"id": "kira", "name": "琪拉", "class": "天马骑士", "faction": "enemy", "level": 13, "hold": true,
		"hp": 26, "pwr": 10, "skl": 12, "spd": 16, "dfn": 7, "res": 11, "mov": 7,
		"weapons": ["steel_lance", "javelin"], "items": ["vulnerary"], "wexp": {"lance": 71},
		"growths": {"hp": 55, "pwr": 35, "skl": 45, "spd": 60, "dfn": 15, "res": 40},
		"pos": Vector2i(13, 16), "color": Color(0.80, 0.90, 0.85),
		"hair": "ponytail", "hair_color": Color(0.85, 0.70, 0.40), "armor": Color(0.82, 0.92, 0.88)},
	# 山脚：坡道前的卫兵、巡逻的天马
	{"id": "pegasus1", "pos": Vector2i(13, 19)},
	{"id": "pegasus2", "pos": Vector2i(20, 20), "hold": true},
	{"id": "soldier1", "pos": Vector2i(23, 18), "hold": true},
	{"id": "archer1", "pos": Vector2i(25, 18), "hold": true, "items": ["vulnerary"]},
	# 半山
	{"id": "pegasus3", "pos": Vector2i(22, 14), "hold": true},
	{"id": "pegasus4", "pos": Vector2i(16, 13), "hold": true},
	{"id": "pegasus5", "pos": Vector2i(8, 12), "hold": true},
	{"id": "falcon1", "pos": Vector2i(7, 16), "hold": true, "items": ["elixir"]},
	{"id": "soldier2", "pos": Vector2i(4, 12), "hold": true},
	{"id": "cleric1", "pos": Vector2i(4, 14)},
	# 山肩
	{"id": "pegasus6", "pos": Vector2i(12, 8), "hold": true},
	{"id": "pegasus7", "pos": Vector2i(19, 6), "hold": true},
	{"id": "pegasus8", "pos": Vector2i(23, 8), "hold": true},
	{"id": "pegasus9", "pos": Vector2i(21, 10), "hold": true},
	{"id": "falcon2", "pos": Vector2i(6, 7), "hold": true},
	{"id": "archer2", "pos": Vector2i(13, 7), "hold": true},
	# 峰顶：骑士团驻地
	{"id": "falcon3", "pos": Vector2i(14, 2), "hold": true, "weapons": ["silver_lance", "javelin"]},
	{"id": "pegasus10", "pos": Vector2i(17, 2), "hold": true},
	{"id": "pegasus11", "pos": Vector2i(11, 2), "hold": true},
	{"id": "archer3", "pos": Vector2i(16, 4), "hold": true},
	# 阿德琳：天马骑士团长，守在峰顶的堡垒上
	{"id": "adeline", "name": "阿德琳", "class": "隼骑士", "faction": "enemy", "level": 9,
		"hp": 46, "pwr": 18, "skl": 18, "spd": 20, "dfn": 13, "res": 17, "mov": 8,
		"weapons": ["silver_lance", "javelin"], "items": ["overlord_crest"], "boss": true, "hold": true,
		"sprite": "pegasus", "pos": Vector2i(15, 1), "color": Color(0.90, 0.88, 0.96),
		"hair": "ponytail", "hair_color": Color(0.30, 0.25, 0.22), "armor": Color(0.95, 0.92, 1.0)},
]

## 第 3 回合东边山岩上空飞来天马；第 5 回合东边山脚；第 7 回合峰顶后方飞来隼骑士
const WAVES := {
	3: [{"id": "pegasus_r1", "pos": Vector2i(28, 13)}, {"id": "pegasus_r2", "pos": Vector2i(28, 14)},
		{"id": "pegasus_r3", "pos": Vector2i(28, 15)}],
	5: [{"id": "pegasus_r4", "pos": Vector2i(28, 19)}, {"id": "pegasus_r5", "pos": Vector2i(28, 20)}],
	7: [{"id": "falcon_r1", "pos": Vector2i(23, 1)}, {"id": "pegasus_r6", "pos": Vector2i(24, 1)},
		{"id": "pegasus_r7", "pos": Vector2i(7, 1)}],
}

const DEPLOY := [Vector2i(3, 22), Vector2i(6, 22), Vector2i(7, 22), Vector2i(3, 23), Vector2i(5, 23),
	Vector2i(7, 20), Vector2i(7, 21), Vector2i(2, 22)]


func chapter_id() -> String:
	return "ch20"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 10


func forced_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_deploy_slots() -> Array:
	return DEPLOY


func templates() -> Dictionary:
	return {"pegasus": _PEGASUS, "falcon": _FALCON, "soldier": _SOLDIER, "archer": _ARCHER, "cleric": _CLERIC}


func lose_ids() -> Array:
	return ["edric", "tia", "gareth"]


func extra_slots() -> Array:
	return DEPLOY


func shop_items() -> Array:
	return ["vulnerary", "elixir", "steel_bow", "silver_bow", "longbow", "steel_lance", "steel_sword", "steel_axe", "thunder", "mend_staff"]


func is_won() -> bool:
	var b = battle.get_unit("adeline")
	return b == null or not b.is_alive()


func win_condition() -> String:
	return tr("击败天马骑士团长阿德琳")


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
		battle.show_banner(tr("天马骑士从云中飞来！"), Color(1.0, 0.5, 0.3))
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


func on_before_combat(att, def) -> void:
	if "adeline" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		await battle.play_dialogue(_boss())


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("adeline")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())
	var k = battle.get_unit("kira")
	if k != null and not k.is_alive() and not k.is_player() and not flags.get("kira_down", false):
		flags["kira_down"] = true
		await battle.play_dialogue(_kira_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == VISIT_SHEPHERD:
		await battle.play_dialogue(_visit_shepherd())
		u.receive("elixir")
		battle.notify(tr("获得 万灵药"))
	elif pos == VISIT_STABLE:
		await battle.play_dialogue(_visit_stable())
		u.receive("overlord_crest")
		battle.notify(tr("获得 霸王之证"))


func recruits() -> Dictionary:
	return {"kira": ["selene"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return [
		_l("琪拉", C_KIRA, "赛莲前辈……？您、您回来了？"),
		_l("赛莲", C_SELENE, "琪拉。你的枪在发抖。"),
		_l("琪拉", C_KIRA, "团长说……这是命令。教会给了骑士团粮草和金币，没有那些，天马会饿死的……"),
		_l("赛莲", C_SELENE, "所以就把风之弓卖给他们？骑士团守了它四百年。守的不是一把弓，是「绝不让它被用来伤人」的誓言。"),
		_l("琪拉", C_KIRA, "……我知道。我每天晚上，都在想这件事。"),
		_l("赛莲", C_SELENE, "那就跟我来。团长那边，我去说。"),
		_l("琪拉", C_KIRA, "……是！前辈！"),
	]


func on_recruited(t, _by) -> void:
	t.hold = false


func talks() -> Array:
	return [["selene", "noya", "selene_noya"], ["edric", "gareth", "edric_gareth_20"]]


func talk_lines(key: String) -> Array:
	if key == "selene_noya":
		return [
			_l("诺雅", C_NOYA, "姐姐，这里就是你长大的地方？"),
			_l("赛莲", C_SELENE, "嗯。十二岁那年，我被送上山。你那时还在修道院里学写字。"),
			_l("诺雅", C_NOYA, "我一直以为……姐姐是讨厌我，才走的。"),
			_l("赛莲", C_SELENE, "傻瓜。我是想有一天骑着天马，飞去圣都把你接走。……结果你自己先跑出来了。"),
			_l("诺雅", C_NOYA, "……嗯。是缇娅带我跑出来的。"),
			_l("赛莲", C_SELENE, "那我得好好谢谢她。"),
		]
	return [
		_l("加雷斯", C_GARETH, "艾德里克，骑士学校那会儿，你还记得我们偷溜上钟楼看天马飞过吗？"),
		_l("艾德里克", C_EDRIC, "记得。你说长大了要骑天马，被教官罚跑了二十圈。"),
		_l("加雷斯", C_GARETH, "哈哈！……后来父王说，布罗登的王子该骑的是战马，不是会飞的东西。"),
		_l("加雷斯", C_GARETH, "这一仗打完，就该回布罗登了。我有种不好的预感——宰相的信，越来越少了。"),
		_l("艾德里克", C_EDRIC, "到时候，我陪你回去。"),
		_l("加雷斯", C_GARETH, "……够意思。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	var r: Array = Campaign.flags.get("relics", [])
	if not "wind_bow" in r:
		r.append("wind_bow")
	Campaign.flags["relics"] = r
	Campaign.flags["kira_recruited"] = _here("kira")


func on_defeat() -> void:
	await battle.play_dialogue(_defeat())


# ==================== 小工具 ====================

func _here(id: String) -> bool:
	var u = battle.get_unit(id)
	return u != null and u.is_alive() and u.is_player()


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "天马峰。云在脚下流动，只有一条之字形的山路通向峰顶。"),
		_l("阿德琳", C_BOSS, "来者止步。天马骑士团驻地，不接待外人。"),
		_l("艾德里克", C_EDRIC, "我们是来请骑士团守住风之弓的。教会正在搜集八圣器——"),
		_l("阿德琳", C_BOSS, "教会？风之弓明天就会送往圣都。……骑士团已经接了大司祭的命令。"),
	]
	if _here("selene"):
		lines.append_array([
			_l("赛莲", C_SELENE, "团长！您怎么能——风之弓是骑士团世代的誓言！"),
			_l("阿德琳", C_BOSS, "赛莲。离开骑士团的人，没资格谈誓言。"),
			_l("赛莲", C_SELENE, "……琪拉呢？琪拉也同意了吗？"),
			_l("阿德琳", C_BOSS, "琪拉是骑士。骑士服从命令。……全员上马！把他们从山上赶下去！"),
		])
	else:
		lines.append(_l("阿德琳", C_BOSS, "全员上马！把他们从山上赶下去！"))
	lines.append_array([
		_l("加雷斯", C_GARETH, "全是会飞的！山路这么窄，我们只能一层一层往上爬。"),
		_l("艾德里克", C_EDRIC, "弓对天马有奇效。弓手跟紧队伍，别让天马把他们单独围住。"),
	])
	if _here("selene"):
		lines.append(_l("赛莲", C_SELENE, "半山腰那个年轻的……是琪拉。让我去跟她说。"))
	else:
		lines.append(_l("缇娅", C_TIA, "半山腰那个年轻的天马骑士……枪一直在晃。她在犹豫。"))
	return lines


func _turn2_hint() -> Array:
	if _here("selene"):
		return [
			_l("赛莲", C_SELENE, "琪拉还守在半山腰。……让我飞过去，走到她身边【说得】。"),
		]
	return [
		_l("艾德里克", C_EDRIC, "天马会从崖壁上空直接扑过来。站位别太散，弓手和法师躲在后面。"),
	]


func _boss() -> Array:
	if _here("selene"):
		return [
			_l("阿德琳", C_BOSS, "赛莲，你还是回来了。可惜，是站在对面。"),
			_l("赛莲", C_SELENE, "团长，我回来，是为了把骑士团带回来。"),
			_l("阿德琳", C_BOSS, "带回哪里？带回饿着肚子守一把弓的日子？……拔枪吧。"),
		]
	return [
		_l("阿德琳", C_BOSS, "风之弓不是你们这些外人能碰的东西。"),
		_l("阿德琳", C_BOSS, "……也不是骑士团还守得住的东西了。所以，交给出得起价的人。"),
	]


func _boss_death() -> Array:
	return [
		_l("阿德琳", C_BOSS, "骑士团……只剩二十匹天马……我只是……想让它们活下去……"),
	]


func _kira_death() -> Array:
	return [
		_l("琪拉", C_KIRA, "团长……这样……真的对吗……"),
	]


func _visit_shepherd() -> Array:
	return [
		_l("村民", C_NPC, "骑士团的天马，最近瘦得肋骨都看得见了。教会的粮车一来，团长就变了。"),
		_l("村民", C_NPC, "你们要上山？这瓶药拿着。山上的风，会把伤口吹裂的。"),
	]


func _visit_stable() -> Array:
	return [
		_l("老人", C_NPC, "我给骑士团喂了五十年天马。……团长要把风之弓交出去，老马夫拦不住。"),
		_l("老人", C_NPC, "这块证是骑士团代代传下来的，给最好的骑士用。交给你们——交给真正的骑士。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "阿德琳的天马落在峰顶的积雪上。剩下的骑士们放下了枪。"),
	]
	if _here("selene"):
		lines.append(_l("赛莲", C_SELENE, "骑士团剩下的人，我来说服。……风之弓，交给你们。"))
		if _here("kira"):
			lines.append(_l("琪拉", C_KIRA, "前辈，我去把弓取来！团长的房间，我闭着眼都认得路！"))
	else:
		lines.append(_l("", C_NARR, "团长的房间里，一把通体银白的长弓静静挂在墙上。"))
	lines.append_array([
		_l("", C_NARR, "得到了圣器「风之弓」。"),
	])
	if Campaign.flags.get("shield_lost", false):
		lines.append(_l("艾德里克", C_EDRIC, "这一件，总算没让教会抢走。……下一件是「地之斧」，在布罗登王城的宝库里。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "第二件。……下一件是「地之斧」，在布罗登王城的宝库里。"))
	lines.append_array([
		_l("加雷斯", C_GARETH, "……我家。"),
		_l("加雷斯", C_GARETH, "教会的手，伸得比我想的还长。宰相奥斯瓦尔德最近的信，字里行间全是圣焰的味道。"),
		_l("缇娅", C_TIA, "那就趁他们还没动手，先回去。"),
		_l("加雷斯", C_GARETH, "哈，说得对。……走吧，带你们看看布罗登的城墙。"),
	])
	return lines


func _defeat() -> Array:
	for id in ["edric", "tia", "gareth"]:
		var u = battle.get_unit(id)
		if u != null and not u.is_alive():
			if id == "edric":
				return [_l("艾德里克", C_EDRIC, "父亲……我……爬不上去了……"),
					_l("", C_NARR, "艾德里克倒下了。风之弓被送往了圣都。")]
			if id == "tia":
				return [_l("缇娅", C_TIA, "风……好冷……"),
					_l("", C_NARR, "缇娅倒下了。天马骑士带走了红发的少女，飞向圣都。")]
			return [_l("加雷斯", C_GARETH, "布罗登……我还没……回去……"),
				_l("", C_NARR, "加雷斯倒下了。布罗登的王子，再也没能回到故乡。")]
	return []


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "peak", "from": "monastery", "lines": [
		_l("", CB_NARR, "北方群峰终年积雪。最高的那座，是天马骑士团世代的驻地。"),
		_l("", CB_NARR, "骑士团守着八圣器之一——「风之弓」。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "布罗登王城 · 王座间", "mood": "castle", "lines": [
			_l("奥斯瓦尔德", CB_ENEMY, "陛下，请在这里签字。地之斧，交由圣焰教会保管。"),
			_l("布罗登国王", CB_NARR, "……加雷斯在哪里？"),
			_l("奥斯瓦尔德", CB_ENEMY, "王子勾结异端、盗走圣器，大陆皆知。陛下还指望他吗？"),
			_l("布罗登国王", CB_NARR, "我指望他的，从来不是听话。"),
			_l("奥斯瓦尔德", CB_ENEMY, "……送陛下回寝宫休息。没有我的命令，谁也不许进出。"),
		]},
	]
