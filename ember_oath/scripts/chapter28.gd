class_name Chapter28
extends Part3Chapter
## 第二十八章「被刮去的名字」：圣焰神殿外环的书库。埃德蒙的侍从罗兰扮成神殿杂役藏在书架间（绿色中立），
## 艾德里克【对话】→ 罗兰入队，并把父亲的佩剑「菲恩之剑」交给艾德里克。
## 禁书库最里面的读经台（王座 K，金框）：我方行动结束时站在上面 → 读到原本的编年史，初代大司祭的名字是「莫尔甘」。
## 缇娅 × 七号「名字」对话（七号在队时，真结局条件）。
## 胜利：击败枢机卿阿尔班。败北：三主角阵亡。

const CHAPTER_TITLE := "第二十八章 · 被刮去的名字"
const VICTORY_TITLE := "第二十八章 · 完"
const VICTORY_SUB := "刮得掉石头上的字，刮不掉所有人的记性。"
const DEFEAT_SUB := "书库的灯熄了。那个名字，又一次被埋进了灰里……"
const BG := ""

## 34×24。圣焰神殿外环的书库。南边回廊进来 → 书架迷宫（书架 = 墙，隔出几条通道）→ 北边禁书库：
## 中间两扇牢门是近路（盗贼 / 钥匙），两侧窄道绕过去是远路。读经台（王座 K，金框）在禁书库最里面，枢机卿阿尔班守在台前。
const MAP := [
	"##################################",
	"###########SSSSSSSSSSSS###########",
	"###SSSSSSSSSSISSKSSSISSSSSSSSSS###",
	"###SS######SSSSSSSSSSSS######SS###",
	"###SS######SSSSSSSSSSSS######SS###",
	"###SS######SSISSSSSSISS######SS###",
	"###SS######SSSSSSSSSSSS######SS###",
	"###SS#########O####O#########SS###",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##QSSSSSSSSSSSSSIISSSSSSSSSSSSSQ##",
	"##SS##########SSSSSS##########SS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##########SS##########SS##########",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##SSSSSSSSSSSSSSIISSSSSSSSSSSSSS##",
	"##SS##########SSSSSS##########SS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"############S###SS###S############",
	"#########SSSSSSSSSSSSSSSS#########",
	"#########SISSSSSSSSSSSSIS#########",
	"#########SSSSSSSSSSSSSSSS#########",
	"#########SSSSSSSSSSSSSSSS#########",
	"################GG################",
]

const LEVELS := []                # 全图同一高度

const LECTERN := Vector2i(16, 2)
const CHESTS := {Vector2i(2, 9): "silver_bow", Vector2i(31, 9): "elixir"}

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "faction": "player", "pos": Vector2i(16, 21)},
	{"id": "tia", "faction": "player", "pos": Vector2i(17, 21)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(15, 21)},
	{"id": "seven", "faction": "player", "pos": Vector2i(18, 21)},
	{"id": "silas", "faction": "player", "pos": Vector2i(16, 22)},
	{"id": "owen", "faction": "player", "pos": Vector2i(17, 22)},
	{"id": "vera", "faction": "player", "pos": Vector2i(15, 22)},
	{"id": "balto", "faction": "player", "pos": Vector2i(18, 22)},
	{"id": "orion", "faction": "player", "pos": Vector2i(14, 21)},
	{"id": "lilith", "faction": "player", "pos": Vector2i(19, 21)},
	{"id": "noya", "faction": "player", "pos": Vector2i(14, 22)},
	# 罗兰：扮成神殿杂役，藏在西边的书架间（中立）
	{"id": "roland", "faction": "npc", "stationary": true, "pos": Vector2i(6, 15)},
	# 回廊
	{"id": "puppet1", "pos": Vector2i(13, 17), "hold": true},
	{"id": "puppet2", "pos": Vector2i(20, 17), "hold": true},
	{"id": "fighter1", "pos": Vector2i(16, 17), "hold": true},
	# 书架迷宫
	{"id": "sniper1", "pos": Vector2i(8, 9), "hold": true},
	{"id": "sniper2", "pos": Vector2i(25, 9), "hold": true},
	{"id": "sage1", "pos": Vector2i(3, 11), "hold": true},
	{"id": "sage2", "pos": Vector2i(30, 11), "hold": true},
	{"id": "myrm1", "pos": Vector2i(14, 12), "hold": true},
	{"id": "myrm2", "pos": Vector2i(19, 12), "hold": true},
	{"id": "paladin1", "pos": Vector2i(6, 14), "hold": true},
	{"id": "paladin2", "pos": Vector2i(27, 14), "hold": true},
	{"id": "graycloak1", "pos": Vector2i(11, 17), "hold": true},
	{"id": "graycloak2", "pos": Vector2i(22, 17), "hold": true, "items": ["door_key"]},
	{"id": "general1", "pos": Vector2i(16, 11), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(17, 14), "hold": true},
	# 两侧窄道
	{"id": "myrm3", "pos": Vector2i(4, 4), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(29, 4), "hold": true},
	# 禁书库
	{"id": "general2", "pos": Vector2i(12, 3), "hold": true},
	{"id": "general3", "pos": Vector2i(21, 3), "hold": true},
	{"id": "cleric1", "pos": Vector2i(15, 6)},
	{"id": "sage3", "pos": Vector2i(18, 6), "hold": true},
	# 枢机卿阿尔班：守在读经台前
	{"id": "alban", "name": "阿尔班", "class": "贤者", "faction": "enemy", "level": 15,
		"hp": 52, "pwr": 23, "skl": 19, "spd": 17, "dfn": 13, "res": 24, "mov": 6,
		"weapons": ["bolganone", "divine", "mend_staff"], "items": ["elixir"], "boss": true, "stationary": true,
		"pos": Vector2i(16, 5), "color": Color(0.90, 0.30, 0.30),
		"hair": "hood", "hair_color": Color(0.85, 0.85, 0.85), "armor": Color(0.85, 0.20, 0.22)},
]

## 第 3 回合两侧窄道下来；第 5 回合回廊后面堵过来；第 7 回合禁书库里又出来一批
const WAVES := {
	3: [{"id": "graycloak_r1", "pos": Vector2i(3, 2)}, {"id": "graycloak_r2", "pos": Vector2i(30, 2)}],
	5: [{"id": "paladin_r1", "pos": Vector2i(9, 22)}, {"id": "paladin_r2", "pos": Vector2i(24, 22)}],
	7: [{"id": "sage_r1", "pos": Vector2i(13, 4)}, {"id": "sniper_r1", "pos": Vector2i(20, 4)},
		{"id": "myrm_r1", "pos": Vector2i(14, 1)}, {"id": "myrm_r2", "pos": Vector2i(19, 1)}],
}

const DEPLOY := [Vector2i(13, 21), Vector2i(20, 21), Vector2i(13, 22), Vector2i(20, 22), Vector2i(12, 21), Vector2i(21, 21),
	Vector2i(12, 22), Vector2i(21, 22), Vector2i(11, 21), Vector2i(22, 21), Vector2i(11, 22), Vector2i(22, 22)]


func chapter_id() -> String:
	return "ch28"


func stage() -> int:
	return 5


func deploy_limit() -> int:
	return 12


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func chests() -> Dictionary:
	return CHESTS


func foes() -> Dictionary:
	return {
		"puppet": foe("puppet", 20, {"hp": 48}), "fighter": foe("fighter", 10),
		"sniper": foe("sniper", 10), "sage": foe("sage", 10),
		"myrm": foe("myrm", 10), "paladin": foe("paladin", 10, {"weapons": ["silver_lance", "steel_sword"]}),
		"graycloak": foe("graycloak", 9, {"weapons": ["steel_sword"]}), "general": foe("general", 10),
		"darkmage": foe("darkmage", 20, {"weapons": ["nosferatu"]}), "cleric": foe("cleric", 10),
	}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "door_key", "silver_sword", "killing_edge", "silver_lance", "killer_lance", "silver_axe",
		"silver_bow", "bolganone", "divine", "fenrir", "mend_staff"]


func goal_label() -> String:
	return "读经台"


func goal_tiles() -> Array:
	return [] if flags.get("chronicle", false) else [LECTERN]


func is_won() -> bool:
	var b = battle.get_unit("alban")
	return b != null and not b.is_alive()


func win_condition() -> String:
	return tr("击败枢机卿阿尔班")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	if _wave(t, WAVES):
		if t == 5:
			await battle.play_dialogue(_wave5())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())


## 站上读经台：读到原本的编年史
func on_action_end(u) -> void:
	if not u.is_alive() or not u.is_player() or u.grid_pos != LECTERN or flags.get("chronicle", false):
		return
	flags["chronicle"] = true
	battle.board.goal_tiles = goal_tiles()
	Audio.play_sfx("coin")
	await battle.play_dialogue(_chronicle(u.unit_id))
	battle.notify(tr("读到了原本的编年史"))


## 罗兰：只有艾德里克能【对话】
func recruits() -> Dictionary:
	return {"roland": ["edric"]}


func recruit_lines(_target_id: String, _by_id: String) -> Array:
	return _roland_lines()


func on_recruited(t, _by) -> void:
	if t.unit_id != "roland":
		return
	t.stationary = false
	t.hold = false
	flags["roland"] = true
	var e = battle.get_unit("edric")
	if e != null:
		e.receive("fenn_sword")
		battle.notify(tr("艾德里克 得到了 菲恩之剑"))
		await _edric_oath(e)


## 接过父亲的剑：领主骑士满 Lv10 剧情转职为「誓约领主」（不满就只拿剑，转职门槛照旧）
func _edric_oath(e) -> void:
	if e.class_label != "领主骑士" or e.level < 10:
		return
	await battle.play_dialogue([
		_l("艾德里克", C_EDRIC, "……父亲。您的剑，我接下了。"),
		_l("艾德里克", C_EDRIC, "菲恩家的骑士，以这把剑起誓：守护所有该守护的人。"),
		_l("", C_NARR, "剑柄上的旧纹章，在艾德里克手里亮了一下。"),
	])
	e.promote("誓约领主", {"hp": 5, "pwr": 3, "skl": 2, "spd": 2, "dfn": 3, "res": 3, "mov": 1})
	Audio.play_sfx("promote")
	battle.show_banner(tr("转职 · 誓约领主"), Color(0.55, 0.85, 1.0))
	battle.notify(tr("艾德里克转职为誓约领主！"))


func on_before_combat(att, def) -> void:
	if "alban" in [att.unit_id, def.unit_id] and not flags.get("boss", false):
		flags["boss"] = true
		var other = def if att.unit_id == "alban" else att
		await battle.play_dialogue(_boss(other.unit_id))


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var b = battle.get_unit("alban")
	if b != null and not b.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())
		if not flags.get("chronicle", false):
			battle.hint(tr("读经台上的编年史还没读——要读的话，趁现在"))


func talks() -> Array:
	var out: Array = [["edric", "roland", "edric_roland_28"], ["silas", "owen", "silas_owen_28"]]
	if _name_talk_ok():
		out.append_array(_name_talk())
	return out


func talk_lines(key: String) -> Array:
	match key:
		"seven_name":
			return _name_lines()
		"edric_roland_28":
			return [
				_l("罗兰", C_ROLAND, "少主。……您出剑的时候，右肩会先动一下。和领主大人一模一样。"),
				_l("艾德里克", C_EDRIC, "父亲也这样？"),
				_l("罗兰", C_ROLAND, "他自己不知道。我给他提过三次，他改了三次，又犯了三次。"),
				_l("艾德里克", C_EDRIC, "（笑）……那我就不改了。"),
			]
	return [
		_l("塞拉斯", C_SILAS, "欧文。英灵廊的墓碑上，被刮掉的那一行……你小时候，看见过原来的字吗？"),
		_l("欧文", C_OWEN, "没有。刮的时候我还没出生。可我父亲说，刮字的那个审判官，一边刮一边在哭。"),
		_l("塞拉斯", C_SILAS, "……三十年前。那是我的老师。"),
		_l("欧文", C_OWEN, "那今天，就由学生来把它念出来。"),
	]


func on_talked(key: String, _u, _partner) -> void:
	if key == "seven_name":
		_on_name_talked()


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())
	# 没拿到父亲的剑（罗兰没说动或倒下）：艾德里克照样在这一章立誓转职，否则第三篇后半他永远卡在 Lv20 的领主骑士
	if not flags.get("roland", false):
		var e = battle.get_unit("edric")
		if e != null and e.is_alive() and e.class_label == "领主骑士" and e.level >= 10:
			await battle.play_dialogue([
				_l("艾德里克", C_EDRIC, "……父亲的剑没能拿回来。可我要守的东西，不会因此变少。"),
				_l("艾德里克", C_EDRIC, "菲恩家的骑士，以这双手起誓：守护所有该守护的人。"),
			])
			e.promote("誓约领主", {"hp": 5, "pwr": 3, "skl": 2, "spd": 2, "dfn": 3, "res": 3, "mov": 1})
			Audio.play_sfx("promote")
			battle.notify(tr("艾德里克转职为誓约领主！"))
	Campaign.flags["roland_joined"] = _here("roland")
	Campaign.flags["fenn_sword"] = flags.get("roland", false)
	Campaign.flags["chronicle_read"] = flags.get("chronicle", false)


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "灰烬回廊的尽头，是圣焰神殿的外环——书库。"),
		_l("", C_NARR, "书架一直顶到天花板。教会八百年来的经典、卷宗、审判记录，全在这里。"),
		_l("阿尔班", C_BOSS, "枢机卿阿尔班。……这里是神殿的记忆。不许弄脏。"),
		_l("阿尔班", C_BOSS, "禁书库里的东西，八百年来只有大司祭大人读过。你们没有资格。"),
		_l("艾德里克", C_EDRIC, "禁书库……原本的编年史，一定就在那里。"),
	]
	if _here("silas"):
		lines.append(_l("塞拉斯", C_SILAS, "最里面的读经台。审判官只有在受封那天，才被允许远远地看一眼。"))
	lines.append(_l("", C_NARR, "书架的阴影里，一个穿着杂役衣服的男人，正一动不动地盯着艾德里克。"))
	return lines


func _turn2_hint() -> Array:
	var lines: Array = [
		_l("艾德里克", C_EDRIC, "禁书库的牢门能抄近路；没有会开锁的人，就从两边的窄道绕过去。"),
		_l("艾德里克", C_EDRIC, "金框的读经台上，就是原本的编年史。站上去读一读。"),
	]
	if _npc("roland"):
		lines.append(_l("加雷斯", C_GARETH, "艾德里克，西边书架那个杂役……一直在看你。"))
	return lines


func _wave5() -> Array:
	return [
		_l("阿尔班", C_BOSS, "回廊的门，封上。……一个也别放出去。"),
	]


func _roland_lines() -> Array:
	return [
		_l("罗兰", C_ROLAND, "……少主。艾德里克少主。"),
		_l("艾德里克", C_EDRIC, "你是……罗兰？父亲的侍从！你不是和父亲一起——"),
		_l("罗兰", C_ROLAND, "圣都郊外被伏击的那天，领主大人让我带着他的剑先走。他说：「要是我回不去，把它交给艾德里克。」"),
		_l("罗兰", C_ROLAND, "我没能回菲恩城。灰袍众一直在追。……我只好扮成杂役，躲进了神殿。最危险的地方，最没人找。"),
		_l("罗兰", C_ROLAND, "我在这里扫了几个月的地。每天都在想，领主大人什么时候来取他的剑。"),
		_l("艾德里克", C_EDRIC, "……父亲不会来了。他在黑石地牢……"),
		_l("罗兰", C_ROLAND, "我知道。灰袍众说话的时候，从来不避着扫地的人。"),
		_l("罗兰", C_ROLAND, "那么——这把剑，交给您。菲恩之剑。领主大人说过，它是用来守护的。"),
		_l("艾德里克", C_EDRIC, "……我收下了。罗兰，你也一起来吧。"),
		_l("罗兰", C_ROLAND, "这正是我一直在等的话。"),
	]


func _chronicle(by_id: String) -> Array:
	var lines: Array = [
		_l("", C_NARR, "读经台上，摊着一本被铁链锁住的旧书。纸页黄得发脆，墨却一点没褪。"),
		_l("", C_NARR, "「圣焰历元年。大司祭莫尔甘，于神殿之下，欲取炎龙之力，以求不灭之身。」"),
		_l("", C_NARR, "「炎龙怒，焚世之灾起。巫女艾琳以身为锁，与八人同封炎龙。」"),
		_l("", C_NARR, "「大司祭为龙火所焚，不知所终。」"),
		_l("", C_NARR, "书页的空白处，有人用另一种笔迹，一遍又一遍地写着同一句话——"),
		_l("", C_NARR, "「我还活着。我还活着。我还活着。」"),
	]
	if by_id == "tia":
		lines.append(_l("缇娅", C_TIA, "……莫尔甘。八百年前的大司祭，也叫莫尔甘。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "……莫尔甘。八百年前的大司祭，也叫莫尔甘。"))
	lines.append(_l("", C_NARR, "书的最后一页，夹着一张小小的画像。画上的人，和今天的大司祭长得一模一样。"))
	return lines


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	if foe_id == "silas":
		lines.append(_l("阿尔班", C_BOSS, "塞拉斯。你受封那天，我亲手给你戴的徽章。"))
		lines.append(_l("塞拉斯", C_SILAS, "那天您说：「审判官的眼睛，要看清真相。」……我看清了。"))
	else:
		lines.append(_l("阿尔班", C_BOSS, "知道得太多的人，都会被书压死。"))
	return lines


func _boss_death() -> Array:
	return [
		_l("阿尔班", C_BOSS, "大司祭大人……您说过……读过那本书的人……都要……"),
	]


func _post_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "书库里只剩下翻书的声音。"),
	]
	if flags.get("chronicle", false):
		lines.append_array([
			_l("艾德里克", C_EDRIC, "八百年前的大司祭，叫莫尔甘。今天的大司祭，也叫莫尔甘。……画像上是同一张脸。"),
		])
	else:
		lines.append_array([
			_l("艾德里克", C_EDRIC, "读经台上的书……被阿尔班临死前撕掉了一半。剩下的半页上，写着一个名字：莫尔甘。"),
		])
	if _here("lilith"):
		lines.append(_l("莉莉丝", C_LILITH, "灰烬的身体，一具接一具地换。……八百年，原来是这么活下来的。"))
	elif _here("owen"):
		lines.append(_l("欧文", C_OWEN, "被龙火烧成灰，却没死……于是学会了用灰给自己造身体。"))
	lines.append_array([
		_l("加雷斯", C_GARETH, "活了八百年的老怪物。……难怪他什么都不急。"),
		_l("缇娅", C_TIA, "他急的。……「我还活着」写了一整页。那不是不急的人写的字。"),
	])
	if _here("roland"):
		lines.append(_l("罗兰", C_ROLAND, "封印回廊就在书库的北边。……满月只剩两天了，少主。"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "封印回廊就在书库的北边。……满月，只剩两天了。"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "temple", "from": "temple", "lines": [
		_moon(2),
		_l("", CB_NARR, "穿过灰烬回廊，一行人从地底走进了圣焰神殿的外环。"),
		_l("", CB_NARR, "那里有一座书库。八百年来，教会把所有的历史都锁在了里面。"),
	]}


func epilogue() -> Array:
	return [
		{"title": "圣焰神殿 · 封印台", "mood": "dungeon", "lines": [
			_l("", CB_NARR, "封印台下，那颗巨大的心脏跳得越来越响。"),
			_l("莫尔甘", CB_MORGAN, "艾琳。你的血，又回到这里来了。"),
			_l("莫尔甘", CB_MORGAN, "八百年前你用自己锁住了它，也锁住了我。……我在灰里醒来，又在灰里活了八百年。"),
			_l("莫尔甘", CB_MORGAN, "再过两个晚上，这一切就结束了。"),
		]},
	]
