class_name Chapter8
extends ChapterBase
## 第八章「离城」：第二篇「寻父之旅」开篇。父亲埃德蒙失踪的消息传来的当夜，菲恩城城下町起火——
## 教会的暗部「灰袍众」要烧掉埃德蒙的书斋。艾德里克带着兰斯、葛温、奥斯卡从城门杀出：
## 先赶去东边的领主书斋（艾德里克【访问】拿到父亲的笔记，第 4 回合结束前不去就被烧掉），再从南门出城。
## 胜利：把灰袍众头目卡斯帕打到撤退（HP 降到一半以下），或艾德里克到达南门。卡斯帕不会真正死去（第 18 章再登场）。

const CHAPTER_TITLE := "第八章 · 离城"
const VICTORY_TITLE := "第八章 · 完"
const VICTORY_SUB := "菲恩城的火光留在了身后。前面，是父亲走过的路。"
const DEFEAT_SUB := "菲恩城的火，一直烧到了天明……"
const BG := ""

## 30×22。北边是菲恩城（我方从城门内的前院出发，城门 = 出发点）；中间是城下町：两条东西大街（第 4、14 行），
## 一条运河横穿（三座桥）；东边大街旁是「领主书斋」（门口 H），西边有铁匠铺、南城有一户老人家可访问。
## 南城墙正中是南门（撤离点），门外大道旁的堡垒上站着灰袍众头目卡斯帕。
const MAP := [
	".F.DD..F.############.F.DD..F.",
	"D..D...D.#ISSSSSSSSI#..D...D.D",
	"..F..D...#SSSSSSSSSS#.D...F...",
	".D...D...#####GG#####...D..D..",
	"SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
	".D.DD.S.D..D..SS.D..D...DHD...",
	"...H..S.....F.SS......F.DDD...",
	".DD...S..D....SS..D.....S..D..",
	"..D.F.S.D..D..SS.D..D...S..D..",
	"......S.......SS.......FS.....",
	"~~~~~~B~~~~~~~BB~~~~~~~~B~~~~~",
	"..F...S.......SS........S..F..",
	".D.D..S.D.D...SS...D.D..S.D.D.",
	"......S..H....SS.......FS.....",
	"SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS",
	".D..D...D.F...SS..D...D..F.D..",
	"..D...D.....D.SS....D....D..D.",
	"##############GG##############",
	".F..F......F..RR....F....F..F.",
	"..FF....h.....RRRRRRT....FF...",
	".F....F...h...R..h.....F...F..",
	"..F.F.....F...R.F......F..F...",
]

const LEVELS := []                # 全图同一高度

const GOAL := [Vector2i(14, 17), Vector2i(15, 17)]
const STUDY := Vector2i(25, 5)    # 领主书斋（只有艾德里克访问才拿得到笔记）
const VISIT_SMITH := Vector2i(3, 6)
const VISIT_ELDER := Vector2i(9, 13)
const STUDY_BURNS := 5            # 第 5 回合开始时还没访问，书斋被点着
const CASPAR_LEAVES := 8          # 第 8 回合开始时卡斯帕自己撤走

const C_EDRIC := Color(0.55, 0.85, 1.0)
const C_LANCE := Color(0.8, 0.9, 0.75)
const C_GWEN := Color(1.0, 0.78, 0.6)
const C_OSCAR := Color(0.78, 0.82, 0.9)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _GRAY := {"name": "灰袍众", "class": "探子", "faction": "enemy", "level": 7,
	"hp": 24, "pwr": 8, "skl": 9, "spd": 10, "dfn": 4, "res": 2, "mov": 6,
	"weapons": ["iron_sword"], "color": Color(0.55, 0.55, 0.58),
	"hair": "hood", "armor": Color(0.50, 0.50, 0.54)}
const _GRAY_M := {"name": "灰袍剑士", "class": "佣兵", "faction": "enemy", "level": 8,
	"hp": 28, "pwr": 9, "skl": 10, "spd": 9, "dfn": 6, "res": 2, "mov": 5,
	"weapons": ["steel_sword"], "color": Color(0.48, 0.48, 0.52),
	"hair": "hood", "armor": Color(0.42, 0.42, 0.46)}
const _BANDIT := {"name": "流氓", "class": "山贼", "faction": "enemy", "level": 6,
	"hp": 25, "pwr": 7, "skl": 3, "spd": 4, "dfn": 3, "res": 0, "mov": 5,
	"weapons": ["iron_axe"], "color": Color(0.62, 0.42, 0.30),
	"hair": "spiky", "hair_color": Color(0.25, 0.18, 0.12), "armor": Color(0.50, 0.36, 0.26)}
const _ARCHER := {"name": "灰袍弓手", "class": "弓箭手", "faction": "enemy", "level": 6,
	"hp": 22, "pwr": 7, "skl": 8, "spd": 6, "dfn": 3, "res": 2, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.52, 0.52, 0.55),
	"hair": "hood", "armor": Color(0.46, 0.46, 0.50)}

const UNITS := [
	# 我方：艾德里克从名单取（before_spawn_status 设回在队、补到 Lv7）；家臣三人本章入队
	{"id": "edric", "name": "艾德里克", "class": "领主骑士", "faction": "player", "level": 7,
		"hp": 27, "pwr": 8, "skl": 10, "spd": 10, "dfn": 7, "res": 3, "mov": 5,
		"weapons": ["rapier"], "items": ["vulnerary"],
		"growths": {"hp": 70, "pwr": 45, "skl": 55, "spd": 55, "dfn": 35, "res": 30},
		"pos": Vector2i(14, 3), "color": Color(0.35, 0.50, 0.85),
		"hair": "short", "hair_color": Color(0.30, 0.42, 0.75), "armor": Color(0.40, 0.48, 0.70)},
	{"id": "lance", "name": "兰斯", "class": "骑士", "faction": "player", "level": 7, "join": true,
		"hp": 28, "pwr": 9, "skl": 8, "spd": 7, "dfn": 8, "res": 2, "mov": 7,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 80, "pwr": 45, "skl": 40, "spd": 40, "dfn": 30, "res": 20},
		"pos": Vector2i(15, 3), "color": Color(0.35, 0.55, 0.40),
		"hair": "short", "hair_color": Color(0.35, 0.28, 0.20), "armor": Color(0.45, 0.60, 0.48)},
	{"id": "gwen", "name": "葛温", "class": "骑士", "faction": "player", "level": 6, "join": true,
		"hp": 26, "pwr": 8, "skl": 7, "spd": 9, "dfn": 7, "res": 1, "mov": 7,
		"weapons": ["iron_lance", "steel_lance"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 50, "skl": 35, "spd": 50, "dfn": 25, "res": 15},
		"pos": Vector2i(14, 2), "color": Color(0.70, 0.35, 0.30),
		"hair": "ponytail", "hair_color": Color(0.85, 0.50, 0.20), "armor": Color(0.68, 0.38, 0.32)},
	{"id": "oscar", "name": "奥斯卡", "class": "重甲兵", "faction": "player", "level": 9, "join": true,
		"hp": 30, "pwr": 10, "skl": 7, "spd": 3, "dfn": 13, "res": 1, "mov": 4,
		"weapons": ["iron_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 85, "pwr": 45, "skl": 35, "spd": 25, "dfn": 45, "res": 15},
		"pos": Vector2i(15, 2), "color": Color(0.50, 0.52, 0.60),
		"hair": "short", "hair_color": Color(0.45, 0.42, 0.40), "armor": Color(0.60, 0.62, 0.70)},
	# 敌方：城门大街
	{"id": "graycloak1", "pos": Vector2i(9, 4), "hold": true},
	{"id": "graycloak2", "pos": Vector2i(20, 4), "hold": true},
	{"id": "bandit1", "pos": Vector2i(17, 7), "hold": true},
	# 书斋一带：纵火的灰袍众和放风的弓手
	{"id": "graycloak3", "pos": Vector2i(27, 5), "hold": true, "items": ["vulnerary"]},
	{"id": "archer1", "pos": Vector2i(22, 6), "hold": true},
	# 运河两岸
	{"id": "bandit2", "pos": Vector2i(5, 8)},
	{"id": "bandit3", "pos": Vector2i(15, 9), "hold": true},
	{"id": "archer2", "pos": Vector2i(11, 11)},
	{"id": "graycloak4", "pos": Vector2i(24, 11)},
	# 南城
	{"id": "bandit4", "pos": Vector2i(8, 13)},
	{"id": "graycloak5", "pos": Vector2i(23, 13)},
	{"id": "archer3", "pos": Vector2i(19, 14)},
	{"id": "graycloak_m1", "pos": Vector2i(15, 15), "items": ["vulnerary"]},
	# 南门与门外
	{"id": "graycloak_m2", "pos": Vector2i(14, 16), "hold": true},
	{"id": "graycloak_m3", "pos": Vector2i(17, 19), "hold": true},
	{"id": "archer4", "pos": Vector2i(13, 19), "hold": true},
	{"id": "bandit6", "pos": Vector2i(23, 20)},
	# 灰袍众头目卡斯帕：南门外的堡垒上不动。HP 降到一半以下就撤退（不会真正死去）
	{"id": "caspar", "name": "卡斯帕", "class": "佣兵队长", "faction": "enemy", "level": 10,
		"hp": 36, "pwr": 11, "skl": 13, "spd": 12, "dfn": 6, "res": 3, "mov": 5,
		"weapons": ["steel_sword"], "boss": true, "stationary": true, "sprite": "hawk",
		"pos": Vector2i(20, 19), "color": Color(0.40, 0.40, 0.45),
		"hair": "hood", "hair_color": Color(0.20, 0.20, 0.22), "armor": Color(0.36, 0.36, 0.40), "scar": true},
]

## 第 3 回合东边大街来灰袍众；第 5 回合西边、门外来流氓；第 7 回合再来一批
const WAVES := {
	3: [{"id": "graycloak_r1", "pos": Vector2i(29, 4)}, {"id": "graycloak_r2", "pos": Vector2i(29, 14)}],
	5: [{"id": "bandit_r1", "pos": Vector2i(0, 14)}, {"id": "bandit_r2", "pos": Vector2i(0, 4)},
		{"id": "graycloak_m_r1", "pos": Vector2i(14, 21)}],
	7: [{"id": "archer_r1", "pos": Vector2i(29, 14)}],
}


func chapter_id() -> String:
	return "ch8"


func prep_mode() -> String:
	return "full"


func deploy_limit() -> int:
	return 5


func forced_ids() -> Array:
	return ["edric"]


func extra_deploy_slots() -> Array:
	return [Vector2i(13, 2), Vector2i(16, 2), Vector2i(12, 2)]


func templates() -> Dictionary:
	return {"graycloak": _GRAY, "graycloak_m": _GRAY_M, "bandit": _BANDIT, "archer": _ARCHER}


func lose_ids() -> Array:
	return ["edric"]


func extra_slots() -> Array:
	return [Vector2i(13, 2), Vector2i(16, 2), Vector2i(12, 2), Vector2i(17, 2)]


## 第二篇开场：艾德里克回队，并补到 Lv7（离开第 3 章后他自己也在练剑）
func before_spawn_status() -> Dictionary:
	Campaign.raise_to("edric", 7)
	return {"edric": "active"}


func goal_tiles() -> Array:
	return GOAL


func is_won() -> bool:
	if flags.get("caspar_beaten", false):
		return true
	var e = battle.get_unit("edric")
	if e != null and e.is_alive() and e.grid_pos in GOAL:
		return true
	return super.is_won()


func win_condition() -> String:
	return tr("击退卡斯帕，或艾德里克到达南门")


func lose_condition() -> String:
	return tr("艾德里克阵亡")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_resume() -> void:
	if flags.get("study_burned", false):
		_burn_study()


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
	if t == STUDY_BURNS and not visited.has(STUDY) and not flags.get("study_burned", false):
		flags["study_burned"] = true
		_burn_study()
		Audio.play_sfx("fire")
		battle.show_banner(tr("书斋起火！"), Color(1.0, 0.45, 0.2))
		await battle.play_dialogue(_study_burned())
	if t == CASPAR_LEAVES and not flags.get("caspar_beaten", false) and not flags.get("caspar_left", false):
		var c = battle.get_unit("caspar")
		if c != null and c.is_alive():
			flags["caspar_left"] = true
			await battle.play_dialogue(_caspar_leaves())
			_remove(c)
			battle.notify(tr("卡斯帕撤走了"))
			battle.hint(tr("卡斯帕走了——让艾德里克冲到南门！"))


## 书斋烧起来：门口那一格变成火焰（门口站着人就只烧成焦土）
func _burn_study() -> void:
	visited[STUDY] = true
	battle.board.set_tile(STUDY, "E" if battle.board.unit_at(STUDY) == null else "C")


func _remove(u) -> void:
	battle.units.erase(u)
	u.queue_free()
	battle.update_topbar()


func on_before_combat(att, def) -> void:
	if "caspar" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "caspar" else att
		await battle.play_dialogue(_boss(other.unit_id))


## 卡斯帕 HP 降到一半以下就撤退；万一一击打穿了，也只是被打退（烟雾弹脱身）
func on_after_combat(att, def, _def_died: bool) -> void:
	for u in [att, def]:
		if u.unit_id != "caspar" or flags.get("caspar_beaten", false):
			continue
		if not u.is_alive() or u.hp * 2 <= u.max_hp:
			flags["caspar_beaten"] = true
			await battle.play_dialogue(_caspar_retreat(not u.is_alive()))
			_remove(u)


func on_visit(u, pos: Vector2i) -> void:
	if pos == STUDY:
		if u.unit_id != "edric":
			await battle.play_dialogue(_study_not_edric(u.unit_id))
			return
		visited[pos] = true
		Campaign.flags["edmund_notes"] = true
		await battle.play_dialogue(_study_notes())
		battle.notify(tr("获得 埃德蒙的笔记"))
		return
	visited[pos] = true
	if pos == VISIT_SMITH:
		await battle.play_dialogue(_visit_smith())
		u.receive("steel_lance")
		battle.notify(tr("获得 钢枪"))
	elif pos == VISIT_ELDER:
		await battle.play_dialogue(_visit_elder())
		battle.add_gold(1000)
		battle.notify(tr("获得 1000G"))


func talks() -> Array:
	return [["lance", "gwen", "lance_gwen_ch8"], ["edric", "oscar", "edric_oscar_ch8"]]


func talk_lines(key: String) -> Array:
	if key == "lance_gwen_ch8":
		return [
			_l("葛温", C_GWEN, "兰斯！你左边那个，我替你收拾了。这是今晚第三个，你欠我一顿酒。"),
			_l("兰斯", C_LANCE, "……他本来就要倒了。你冲得太快，少主身边空了一大截。"),
			_l("葛温", C_GWEN, "少主身边有奥斯卡那堵墙！我不冲，谁去把路打开？"),
			_l("兰斯", C_LANCE, "路要开，退路也要留。……领主大人走的时候，就是没给自己留退路。"),
			_l("葛温", C_GWEN, "……知道了。这次我听你的，跟紧少主。酒还是你请。"),
		]
	return [
		_l("奥斯卡", C_OSCAR, "少主，您握剑的手在发抖。"),
		_l("艾德里克", C_EDRIC, "……是吗。我以为我藏得很好。"),
		_l("奥斯卡", C_OSCAR, "您五岁第一次骑马摔下来，也是这样。手抖，嘴上却说不疼。"),
		_l("奥斯卡", C_OSCAR, "领主大人把城门交给我守了二十年。今晚起，我守的是您。……您只管往前走。"),
		_l("艾德里克", C_EDRIC, "……谢谢你，奥斯卡。等找到父亲，我们一起回来守这道门。"),
	]


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	Campaign.flags["caspar_fled"] = true
	if not Campaign.flags.has("edmund_notes"):
		Campaign.flags["edmund_notes"] = false


func on_defeat() -> void:
	await battle.play_dialogue([
		_l("艾德里克", C_EDRIC, "父亲……对不起……我连菲恩城的门……都没走出去……"),
		_l("", C_NARR, "菲恩城的火，一直烧到了天明。"),
	])


# ==================== 台词 ====================

func _pre_battle() -> Array:
	return [
		_l("", C_NARR, "当夜。菲恩城。"),
		_l("", C_NARR, "艾德里克刚备好马，城下町的方向就亮起了火光。"),
		_l("兰斯", C_LANCE, "少主！城下町起火了——是一群穿灰袍的人，见人就砍，往东边去了！"),
		_l("艾德里克", C_EDRIC, "东边……是父亲的书斋！他调查圣器的笔记都在那里！"),
		_l("奥斯卡", C_OSCAR, "灰袍子……挑领主不在的这一夜来。他们知道领主大人回不来了。"),
		_l("葛温", C_GWEN, "那还等什么？少主，下令吧！"),
		_l("艾德里克", C_EDRIC, "……兰斯、葛温、奥斯卡。我们先去书斋，把父亲的笔记拿回来。然后从南门出城。"),
		_l("艾德里克", C_EDRIC, "今晚之后，我们就去找父亲。"),
	]


func _turn2_hint() -> Array:
	return [
		_l("兰斯", C_LANCE, "书斋门口的那个灰袍子手里提着油罐。……拖得越久，越危险。"),
		_l("艾德里克", C_EDRIC, "父亲的书斋，得我亲手打开。……我去东边大街，站到书斋门口【访问】。"),
		_l("奥斯卡", C_OSCAR, "南门外的堡垒上还站着一个人，一动不动。那是领头的。……少主，别一个人冲过去。"),
	]


func _wave3() -> Array:
	return [
		_l("灰袍众", C_ENEMY, "东边来人了！把领主家的小子堵在城里，一个都别放出去！"),
		_l("葛温", C_GWEN, "还有援兵？这些家伙到底来了多少人！"),
	]


func _study_burned() -> Array:
	return [
		_l("", C_NARR, "领主书斋的窗子里窜出了火舌。一屋子的书和信，转眼就烧成了灰。"),
		_l("艾德里克", C_EDRIC, "……父亲的笔记！"),
		_l("兰斯", C_LANCE, "来不及了，少主！……领主大人出发前说过，他要先去雾沼那一带见一个人。我们还有线索。"),
		_l("艾德里克", C_EDRIC, "……走。从南门出去。"),
	]


func _study_not_edric(by: String) -> Array:
	var name := "兰斯"
	var c := C_LANCE
	if by == "gwen":
		name = "葛温"
		c = C_GWEN
	elif by == "oscar":
		name = "奥斯卡"
		c = C_OSCAR
	return [
		_l(name, c, "书斋的门上了领主大人的锁……钥匙只有少主有。得让少主亲自来。"),
	]


func _study_notes() -> Array:
	return [
		_l("", C_NARR, "书斋里一片狼藉。抽屉被翻过，可是书桌暗格里的那本皮面笔记，还在。"),
		_l("艾德里克", C_EDRIC, "父亲的字……「八圣器失窃案」。"),
		_l("艾德里克", C_EDRIC, "「大圣堂里失窃的，是炎之冠、天之枪、月之镜三件。看守的人说是盗贼。可大圣堂的门锁完好如初。」"),
		_l("艾德里克", C_EDRIC, "「偷走圣器的，是教会自己。」"),
		_l("艾德里克", C_EDRIC, "「剩下的五件，我已查到下落：铁之盾在海边的废修道院，风之弓在天马峰，地之斧在布罗登王城的宝库，星之杖与日之剑，在圣焰神殿。」"),
		_l("艾德里克", C_EDRIC, "「他们要集齐八件。为什么？……下一步，去雾沼村，见那个从研究所逃出来的人。」"),
		_l("艾德里克", C_EDRIC, "……教会在偷自己的圣器。父亲是查到了这个，才回不来的。"),
	]


func _visit_smith() -> Array:
	return [
		_l("铁匠", C_NPC, "少主！外面那帮灰袍子把我的炉子都踢翻了……"),
		_l("铁匠", C_NPC, "这杆钢枪是给城里卫队打的，还没来得及送。您拿着，替领主大人出这口气！"),
	]


func _visit_elder() -> Array:
	return [
		_l("老奶奶", C_NPC, "是领主家的少爷啊……领主大人的事，城里都传开了。"),
		_l("老奶奶", C_NPC, "这是街坊们凑的一点盘缠。出了城，路上处处都要花钱。……一定要把领主大人带回来。"),
	]


func _boss(other_id: String) -> Array:
	var lines: Array = [
		_l("卡斯帕", C_BOSS, "领主家的小少爷，亲自来送行？"),
	]
	if other_id == "edric":
		lines.append(_l("艾德里克", C_EDRIC, "你们是什么人？为什么要烧我父亲的书斋！"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "（远处）你们是什么人？为什么要烧我父亲的书斋！"))
	lines.append(_l("卡斯帕", C_BOSS, "灰袍众，卡斯帕。……不该看的东西，看了就得烧掉。书是这样，人也是这样。"))
	lines.append(_l("艾德里克", C_EDRIC, "人……？你知道我父亲在哪里！"))
	lines.append(_l("卡斯帕", C_BOSS, "知道又怎样？想问，先从我的剑底下活下来。"))
	return lines


func _caspar_retreat(knocked_down: bool) -> Array:
	var lines: Array = []
	if knocked_down:
		lines.append(_l("卡斯帕", C_BOSS, "咳……！好剑……可惜，还要不了我的命。"))
	else:
		lines.append(_l("卡斯帕", C_BOSS, "啧……小少爷的剑，比传闻里利索。"))
	lines.append(_l("卡斯帕", C_BOSS, "今晚的活到此为止。撤！"))
	lines.append(_l("", C_NARR, "一团灰烟炸开。烟散的时候，堡垒上已经没有人了。"))
	lines.append(_l("艾德里克", C_EDRIC, "站住！……父亲在哪里！"))
	return lines


func _caspar_leaves() -> Array:
	return [
		_l("卡斯帕", C_BOSS, "天快亮了。书斋烧没烧干净，回去都能交差。……撤。"),
		_l("", C_NARR, "堡垒上的人影一晃，消失在了南边的林子里。"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "南门外。回头望去，城下町的火已经被扑灭了大半。"),
	]
	if flags.get("caspar_beaten", false):
		lines.append(_l("葛温", C_GWEN, "那个领头的跑得真快！下次见面，我一定一枪捅穿他。"))
	else:
		lines.append(_l("兰斯", C_LANCE, "南门打开了。……那个领头的没追来，是不屑，还是另有安排？"))
	lines.append(_l("奥斯卡", C_OSCAR, "城里我已托付给副队长。卫队会守住菲恩城，等您和领主大人回来。"))
	if visited.has(STUDY) and not flags.get("study_burned", false):
		lines.append(_l("艾德里克", C_EDRIC, "父亲的笔记最后一页写着：去雾沼村，见那个「从研究所逃出来的人」。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "笔记没能保住……可兰斯说得对，父亲出发前提过雾沼。"))
	lines.append(_l("兰斯", C_LANCE, "雾沼村在东边的沼泽里，两天的路程。"))
	lines.append(_l("艾德里克", C_EDRIC, "那就去雾沼。……父亲，等着我。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "fenn", "from": "fenn", "lines": [
		_l("", CB_NARR, "菲恩领。王国西境，一座守了三百年的城。"),
		_l("", CB_NARR, "领主埃德蒙前往圣都调查圣器失窃案，至今未归。"),
		_l("", CB_NARR, "失踪的消息传回来的那一夜，城下町起了火。"),
	]}


func epilogue() -> Array:
	return [{"title": "圣都 · 大圣堂", "mood": "church", "lines": [
		_l("塞拉斯", CB_SILAS, "大司祭大人。巫女已入笼。白垣镇的铁笼车，三日后进圣都。"),
		_l("莫尔甘", CB_MORGAN, "辛苦了，塞拉斯。……菲恩那边呢？"),
		_l("塞拉斯", CB_SILAS, "灰袍众回报：书斋烧了一半，领主之子带着三个家臣出了城。"),
		_l("莫尔甘", CB_MORGAN, "父亲在找圣器，儿子在找父亲。……都往同一个地方走，倒省了我们的事。"),
		_l("莫尔甘", CB_MORGAN, "七号。那位领主大人，最近还安分吗？"),
		_l("七号", CB_SEVEN, "……他不说话了。"),
	]}]
