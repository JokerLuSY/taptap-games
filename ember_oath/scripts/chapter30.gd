class_name Chapter30
extends Part3Chapter
## 终章「不灭之火」：满月之夜，圣焰神殿最深处。莫尔甘用净火塔里取的缇娅之血打开封印，与炎龙之力融合（职业「炎龙」）。
## 四座封印柱（王座 K，金框）：我方行动结束时站上去点亮，莫尔甘守备、魔防各 -4；
## 莫尔甘每个我方回合开始按「没点亮的柱子数 × 5」回血。
## 守护之火：第 3 回合开始（或缇娅第一次与莫尔甘交战前）缇娅觉醒，得到专属武器「守护之火」（对炎龙特效）；
## 是炎刃使且满 Lv10 的话，再剧情转职为「不灭巫女」。
## 胜利：击败莫尔甘。败北：三主角阵亡。七号在队时强制出击，倒下不算败北。
## 双结局：七号在队、活到最后、并且和缇娅聊过「名字」→ 真结局「黎明之火」；否则普通结局「余烬」。

const CHAPTER_TITLE := "终章 · 不灭之火"
const DEFEAT_SUB := "满月下，不灭之火吞没了神殿。八百年的灰，终于等到了火……"
const BG := ""
## 胜利标题随结局改写（battle 读的是实例上的 VICTORY_TITLE / VICTORY_SUB）
var VICTORY_TITLE := "终章「不灭之火」 · 完"
var VICTORY_SUB := "火焰无善恶，在于为何而燃。"

## 36×26。圣焰神殿最深处的圆形封印大厅。我方从南边入口进来；北边是封印台（火焰环，南面开口），
## 与炎龙融合的莫尔甘站在台上。四角四座封印柱（王座 K，金框）：点亮一座，莫尔甘守备、魔防各 -4。
const MAP := [
	"####################################",
	"########SSSSSSSSSSSSSSSSSSSS########",
	"######SSSSSSSSSSSSSSSSSSSSSSSS######",
	"#####SSSSSSSSEEEEEEEEEESSSSSSSS#####",
	"####SSSSSSSSSEISSSSSSIESSSSSSSSS####",
	"####SSSSSSSSSESSSSSSSSESSSSSSSSS####",
	"###SSSSSSSSSSESSSSSSSSESSSSSSSSSS###",
	"##SSSSKSSSSSSESSSSSSSSESSSSSSKSSSS##",
	"##SSSSSSSSSSSSEESSSSEESSSSSSSSSSSS##",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"#SSSSSSSSISSSSSSSSSSSSSSSSISSSSSSSS#",
	"#SSSSSSSSSSSSSSSSEESSSSSSSSSSSSSSSS#",
	"#SSSESSSSSSSSSSSSSSSSSSSSSSSSSSESSS#",
	"#SSSESSSZSSSISSSSSSSSSSISSSZSSSESSS#",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"#SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS#",
	"#SSSSSSSSISSSSSSSSSSSSSSSSISSSSSSSS#",
	"##SSSSSSSSSSSSSSSSSSSSSSSSSSSSSSSS##",
	"##SSSSSSSSSSSSZSSSSSSZSSSSSSSSSSSS##",
	"##SSSSKSSSSSSSSSSSSSSSSSSSSSSKSSSS##",
	"###SSSSSSSSESSSSSSSSSSSSESSSSSSSS###",
	"####SSSSSSSSSSSSSSSSSSSSSSSSSSSS####",
	"####SSSSSSSSSSSSSSSSSSSSSSSSSSSS####",
	"#####SSSSSSSSSSSSSSSSSSSSSSSSSS#####",
	"######SSSSSSSSSSSSSSSSSSSSSSSS######",
	"#################GG#################",
]

const LEVELS := []                # 全图同一高度

const PILLARS := [Vector2i(6, 7), Vector2i(29, 7), Vector2i(6, 19), Vector2i(29, 19)]
const PILLAR_CUT := 4
const REGEN_PER := 5
const AWAKEN_TURN := 3

const UNITS := [
	# 我方（名单为空的单章测试用）
	{"id": "edric", "faction": "player", "pos": Vector2i(17, 22)},
	{"id": "tia", "faction": "player", "pos": Vector2i(18, 22)},
	{"id": "gareth", "faction": "player", "pos": Vector2i(16, 22)},
	{"id": "seven", "faction": "player", "pos": Vector2i(19, 22)},
	{"id": "silas", "faction": "player", "pos": Vector2i(16, 23)},
	{"id": "owen", "faction": "player", "pos": Vector2i(17, 23)},
	{"id": "roland", "faction": "player", "pos": Vector2i(18, 23)},
	{"id": "balto", "faction": "player", "pos": Vector2i(19, 23)},
	{"id": "orion", "faction": "player", "pos": Vector2i(15, 22)},
	{"id": "lilith", "faction": "player", "pos": Vector2i(20, 22)},
	{"id": "noya", "faction": "player", "pos": Vector2i(15, 21)},
	{"id": "vera", "faction": "player", "pos": Vector2i(20, 21)},
	# 莫尔甘·炎龙：站在封印台上不动
	{"id": "morgan", "name": "莫尔甘", "class": "炎龙", "faction": "enemy", "level": 20,
		"hp": 120, "pwr": 21, "skl": 20, "spd": 13, "dfn": 26, "res": 22, "mov": 5,
		"weapons": ["dragon_flame"], "boss": true, "stationary": true,
		"pos": Vector2i(17, 6), "color": Color(1.0, 0.45, 0.20),
		"hair": "hood", "hair_color": Color(1.0, 0.85, 0.40), "armor": Color(0.95, 0.35, 0.15)},
	# 封印台前的亲卫
	{"id": "general1", "pos": Vector2i(15, 6), "hold": true},
	{"id": "general2", "pos": Vector2i(20, 6), "hold": true},
	{"id": "sage1", "pos": Vector2i(16, 9), "hold": true},
	{"id": "sage2", "pos": Vector2i(19, 9), "hold": true},
	{"id": "sniper1", "pos": Vector2i(11, 8), "hold": true},
	{"id": "sniper2", "pos": Vector2i(24, 8), "hold": true},
	# 封印柱旁
	{"id": "paladin1", "pos": Vector2i(6, 8), "hold": true},
	{"id": "paladin2", "pos": Vector2i(29, 8), "hold": true},
	{"id": "puppet1", "pos": Vector2i(6, 18), "hold": true},
	{"id": "puppet2", "pos": Vector2i(29, 18), "hold": true},
	# 大厅中段
	{"id": "puppet3", "pos": Vector2i(10, 14), "hold": true},
	{"id": "puppet4", "pos": Vector2i(25, 14), "hold": true},
	{"id": "myrm1", "pos": Vector2i(14, 15), "hold": true},
	{"id": "myrm2", "pos": Vector2i(21, 15), "hold": true},
	{"id": "darkmage1", "pos": Vector2i(17, 14), "hold": true},
	{"id": "darkmage2", "pos": Vector2i(18, 14), "hold": true},
	{"id": "graycloak1", "pos": Vector2i(8, 11)},
	{"id": "graycloak2", "pos": Vector2i(27, 11)},
	{"id": "puppet5", "pos": Vector2i(11, 18), "hold": true},
	{"id": "puppet6", "pos": Vector2i(24, 18), "hold": true},
	{"id": "cleric1", "pos": Vector2i(17, 17)},
]

## 第 2、4、6、8 回合：四个方向的灰里不停地爬出傀儡和亲卫
const WAVES := {
	2: [{"id": "puppet_r1", "pos": Vector2i(3, 13)}, {"id": "puppet_r2", "pos": Vector2i(32, 13)}],
	4: [{"id": "paladin_r1", "pos": Vector2i(8, 4)}, {"id": "paladin_r2", "pos": Vector2i(27, 4)},
		{"id": "puppet_r3", "pos": Vector2i(3, 14)}, {"id": "puppet_r4", "pos": Vector2i(32, 14)}],
	6: [{"id": "puppet_r5", "pos": Vector2i(5, 21)}, {"id": "puppet_r6", "pos": Vector2i(30, 21)},
		{"id": "sage_r1", "pos": Vector2i(9, 4)}, {"id": "sage_r2", "pos": Vector2i(26, 4)}],
	8: [{"id": "general_r1", "pos": Vector2i(8, 4)}, {"id": "general_r2", "pos": Vector2i(27, 4)},
		{"id": "puppet_r7", "pos": Vector2i(3, 13)}, {"id": "puppet_r8", "pos": Vector2i(32, 13)}],
}

const DEPLOY := [Vector2i(14, 22), Vector2i(21, 22), Vector2i(14, 21), Vector2i(21, 21), Vector2i(16, 21), Vector2i(19, 21),
	Vector2i(17, 21), Vector2i(18, 21), Vector2i(13, 22), Vector2i(22, 22), Vector2i(16, 24), Vector2i(19, 24)]


func chapter_id() -> String:
	return "ch30"


func stage() -> int:
	return 7


func deploy_limit() -> int:
	return 12


func extra_deploy_slots() -> Array:
	return DEPLOY


func extra_slots() -> Array:
	return DEPLOY


func is_final() -> bool:
	return true


func foes() -> Dictionary:
	return {
		"general": foe("general", 12, {"weapons": ["silver_lance", "steel_axe"]}), "sage": foe("sage", 12, {"weapons": ["bolganone"]}),
		"sniper": foe("sniper", 11), "paladin": foe("paladin", 12, {"weapons": ["silver_lance", "steel_sword"]}),
		"puppet": foe("puppet", 20, {"hp": 52, "pwr": 18, "dfn": 19}),
		"myrm": foe("myrm", 12, {"weapons": ["steel_sword"]}), "darkmage": foe("darkmage", 20, {"weapons": ["nosferatu"]}),
		"graycloak": foe("graycloak", 11), "cleric": foe("cleric", 11),
	}


func shop_items() -> Array:
	return ["vulnerary", "elixir", "silver_sword", "killing_edge", "silver_lance", "killer_lance", "silver_axe", "silver_bow",
		"killer_bow", "bolganone", "divine", "fenrir", "mend_staff"]


## 还没点亮的封印柱（金框）
func goal_label() -> String:
	return "封印柱"


func goal_tiles() -> Array:
	var out: Array = []
	for p in PILLARS:
		if not flags.get("pillar_%d_%d" % [p.x, p.y], false):
			out.append(p)
	return out


func _unlit() -> int:
	return goal_tiles().size()


func is_won() -> bool:
	var m = battle.get_unit("morgan")
	return m != null and not m.is_alive()


func win_condition() -> String:
	return tr("击败与炎龙融合的莫尔甘（点亮封印柱能削弱他）")


# ==================== 事件 ====================

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())


func on_turn_start(t: int) -> void:
	# 炎龙的再生：没点亮的柱子越多回得越多
	var m = battle.get_unit("morgan")
	if t > 1 and m != null and m.is_alive() and m.hp < m.max_hp and _unlit() > 0:
		var n := mini(_unlit() * REGEN_PER, m.max_hp - m.hp)
		m.heal(n)
		battle.notify(tr("炎龙之火让莫尔甘恢复了 %d HP") % n)
	if _wave(t, WAVES):
		if t == 2:
			await battle.play_dialogue(_wave2())
	if t == 2 and not flags.get("hint", false):
		flags["hint"] = true
		await battle.play_dialogue(_turn2_hint())
	if t >= AWAKEN_TURN and not flags.get("awakened", false):
		await _awaken()


## 站上封印柱：点亮它，削弱莫尔甘
func on_action_end(u) -> void:
	if not u.is_alive() or not u.is_player() or not PILLARS.has(u.grid_pos):
		return
	var key := "pillar_%d_%d" % [u.grid_pos.x, u.grid_pos.y]
	if flags.get(key, false):
		return
	flags[key] = true
	battle.board.goal_tiles = goal_tiles()
	var m = battle.get_unit("morgan")
	if m != null and m.is_alive():
		m.dfn = maxi(0, m.dfn - PILLAR_CUT)
		m.res = maxi(0, m.res - PILLAR_CUT)
		m.queue_redraw()
	Audio.play_sfx("promote")
	battle.show_banner(tr("封印柱亮了！"), Color(1.0, 0.85, 0.4))
	battle.notify(tr("莫尔甘的守备、魔防各 -%d") % PILLAR_CUT)
	await battle.play_dialogue(_pillar_lit(u.unit_id))


func on_before_combat(att, def) -> void:
	var ids := [att.unit_id, def.unit_id]
	if "morgan" in ids:
		var other = def if att.unit_id == "morgan" else att
		if other.unit_id == "tia" and not flags.get("awakened", false):
			await _awaken()
		if not flags.get("boss", false):
			flags["boss"] = true
			await battle.play_dialogue(_boss(other.unit_id))
		elif other.unit_id == "seven" and not flags.get("boss_seven", false):
			flags["boss_seven"] = true
			await battle.play_dialogue(_boss_seven())


func on_after_combat(_att, _def, _def_died: bool) -> void:
	var m = battle.get_unit("morgan")
	if m != null and not m.is_alive() and not flags.get("boss_down", false):
		flags["boss_down"] = true
		await battle.play_dialogue(_boss_death())


## 守护之火：缇娅得到专属武器；炎刃使满 Lv10 再转职为不灭巫女
func _awaken() -> void:
	flags["awakened"] = true
	var tia = battle.get_unit("tia")
	if tia == null or not tia.is_alive():
		return
	await battle.play_dialogue(_awaken_lines())
	Audio.play_sfx("awaken")
	tia.weapons.insert(0, "guardian_flame")
	tia.weapon_uses.insert(0, tia.max_uses("guardian_flame"))
	var promoted := false
	if tia.class_label == "炎刃使" and tia.level >= 5:
		tia.promote("不灭巫女", {"hp": 5, "pwr": 3, "skl": 2, "spd": 2, "dfn": 3, "res": 5, "mov": 1})
		tia.hair_color = Color(1.0, 0.78, 0.35)
		tia.armor_color = Color(0.95, 0.85, 0.60)
		promoted = true
	tia.queue_redraw()
	Audio.play_sfx("promote")
	Audio.play_sfx("fire")
	Campaign.flags["tia_guardian"] = true
	if promoted:
		battle.show_banner(tr("觉醒 · 不灭巫女"), Color(1.0, 0.7, 0.3))
		battle.notify(tr("缇娅转职为不灭巫女！"))
	else:
		battle.show_banner(tr("觉醒 · 守护之火"), Color(1.0, 0.7, 0.3))
	battle.notify(tr("缇娅 得到了 守护之火"))
	battle._update_hover_info()


func talks() -> Array:
	var out: Array = [["edric", "tia", "edric_tia_30"], ["gareth", "edric", "gareth_edric_30"]]
	if _name_talk_ok():
		out.append_array(_name_talk())
	return out


func talk_lines(key: String) -> Array:
	match key:
		"seven_name":
			return _name_lines()
		"edric_tia_30":
			return [
				_l("艾德里克", C_EDRIC, "缇娅。还记得神殿那次的约定吗？"),
				_l("缇娅", C_TIA, "一起回灰岩村，看巴尔托。……我记得。"),
				_l("艾德里克", C_EDRIC, "那就别做傻事。不管那团火要什么，都不许拿你自己去换。"),
				_l("缇娅", C_TIA, "……艾琳也是被人这么叮嘱过的吧。"),
				_l("缇娅", C_TIA, "放心。我不当锁。我要当守火的人。"),
			]
	return [
		_l("加雷斯", C_GARETH, "艾德里克。王都骑士学校那年，你说你以后要当一个「不用拔剑的领主」。"),
		_l("艾德里克", C_EDRIC, "……你还记得。"),
		_l("加雷斯", C_GARETH, "记得。所以今天这一剑，我替你拔。你只管往前走。"),
		_l("艾德里克", C_EDRIC, "不。今天这一剑，我们一起拔。"),
	]


func on_talked(key: String, _u, _partner) -> void:
	if key == "seven_name":
		_on_name_talked()


## 结局判定：七号在队、此刻在地图上活着、并且聊过「名字」→ 真结局
func true_ending() -> bool:
	var s = battle.get_unit("seven")
	return bool(Campaign.flags.get("seven_joined", false)) and s != null and s.is_alive() and s.is_player() \
		and bool(Campaign.flags.get("seven_named", false))


## 七号在普通结局里的去向："dead" 第 27 章战死 / "ash" 入队但没能陪到最后 / "left" 陪到最后但还没有名字 / "none" 从没见过
func seven_fate() -> String:
	if Campaign.flags.get("seven_dead", false):
		return "dead"
	if not Campaign.flags.get("seven_joined", false):
		return "none"
	var s = battle.get_unit("seven")
	if s != null and s.is_alive() and s.is_player():
		return "left"
	return "ash"


func on_victory() -> void:
	var good := true_ending()
	Campaign.flags["ending"] = "true" if good else "normal"
	flags["fate"] = seven_fate()
	if good:
		VICTORY_TITLE = "真结局「黎明之火」 · 完"
		VICTORY_SUB = "火焰无善恶，在于为何而燃。——《炎烬之誓》 完"
	else:
		VICTORY_TITLE = "结局「余烬」 · 完"
		VICTORY_SUB = "火被锁了回去。总有一天，会有人学会守护它。"
	await battle.play_dialogue(_finale_true() if good else _finale_normal())


# ==================== 台词 ====================

func _pre_battle() -> Array:
	var lines: Array = [
		_l("", C_NARR, "满月升到了神殿的正上方。封印台下的心跳，响得像擂鼓。"),
		_l("莫尔甘", C_MORGAN, "来了。……刚好，月亮也到了。"),
		_l("缇娅", C_TIA, "我在这里。可你拿不到我的血。"),
		_l("莫尔甘", C_MORGAN, "不需要了。你在净火塔里待了七天，每天流的血——我都收着。"),
		_l("莫尔甘", C_MORGAN, "你逃出了塔，可你的血，留下了。"),
		_l("", C_NARR, "莫尔甘把一只小小的瓶子倒扣在封印台上。八件圣器同时发出了尖锐的鸣响。"),
		_l("", C_NARR, "封印裂开了。白色的火从裂缝里喷涌而出，扑向站在台上的那个人——"),
		_l("莫尔甘·炎龙", C_MORGAN, "啊……啊啊……这就是……不灭……！"),
		_l("", C_NARR, "火没有烧掉他。火钻进了他灰做的身体，把灰一粒一粒地烧成了赤红的鳞。"),
		_l("莫尔甘·炎龙", C_MORGAN, "八百年。我终于不是灰了。"),
		_l("加雷斯", C_GARETH, "……变成龙了？！开什么玩笑！"),
	]
	if _here("owen"):
		lines.append(_l("欧文", C_OWEN, "四座封印柱还在！八英雄留下的，不止是钥匙——点亮柱子，就能压住龙火！"))
	else:
		lines.append(_l("艾德里克", C_EDRIC, "四个角上的柱子……和英灵廊墓碑上画的一样！点亮它们，能压住龙火！"))
	if _here("seven"):
		lines.append(_l("七号", C_SEVEN, "缇娅。……我站在你前面。"))
	lines.append(_l("艾德里克", C_EDRIC, "全员——上！这是最后一战！"))
	return lines


func _turn2_hint() -> Array:
	return [
		_l("艾德里克", C_EDRIC, "金框的是封印柱。站上去点亮：每亮一座，莫尔甘的守备和魔防都会下降。"),
		_l("艾德里克", C_EDRIC, "柱子没亮之前，龙火会不停地给他回血。……先亮柱子，再一起压上去！"),
	]


func _wave2() -> Array:
	return [
		_l("莫尔甘·炎龙", C_MORGAN, "灰啊，从地底爬起来。……你们的主人，终于成了火。"),
	]


func _pillar_lit(by_id: String) -> Array:
	var left := _unlit()
	var lines: Array = []
	if left == 3:
		lines.append(_l("", C_NARR, "封印柱亮起了金色的光。莫尔甘身上的鳞，「咔」地裂开了一片。"))
	elif left == 0:
		lines.append(_l("", C_NARR, "四座封印柱同时亮起。金色的光在大厅里连成了一个圆，把龙火死死地压在台上。"))
		lines.append(_l("莫尔甘·炎龙", C_MORGAN, "八个死人……八百年了，还要来碍事……！"))
	else:
		lines.append(_l("", C_NARR, "又一座封印柱亮了。龙火的咆哮，低了一截。"))
	if by_id == "owen" and left == 3:
		lines.append(_l("欧文", C_OWEN, "先祖们……守墓人，来替你们守火了。"))
	return lines


func _awaken_lines() -> Array:
	var lines: Array = [
		_l("", C_NARR, "缇娅的手心，忽然烫得像要烧起来。"),
		_l("莫尔甘·炎龙", C_MORGAN, "感觉到了吗，巫女？你的血在回应龙火。来——成为锁，或者成为灰。"),
		_l("缇娅", C_TIA, "……都不要。"),
		_l("缇娅", C_TIA, "火不可封，唯可守。……艾琳，我知道你为什么要用自己当锁了。因为那时候，没有人陪你守。"),
		_l("缇娅", C_TIA, "可我不一样。"),
	]
	var friends: Array = []
	for id in ["edric", "gareth", "balto", "seven"]:
		if _here(id):
			friends.append(id)
	if "edric" in friends:
		lines.append(_l("艾德里克", C_EDRIC, "缇娅！"))
	if "gareth" in friends:
		lines.append(_l("加雷斯", C_GARETH, "巫女，别一个人扛！"))
	if "balto" in friends:
		lines.append(_l("巴尔托", C_BALTO, "丫头——你的火，是暖的！"))
	if "seven" in friends:
		lines.append(_l("七号", C_SEVEN, "缇娅。……我在。"))
	lines.append_array([
		_l("缇娅·守护之火", C_TIA, "火焰无善恶，在于为何而燃。"),
		_l("缇娅·守护之火", C_TIA, "我的火——为了守护而燃！"),
		_l("", C_NARR, "红色的火从缇娅身上升起。不烫，不烈，像冬夜里炉膛里的火。"),
	])
	return lines


func _boss(foe_id: String) -> Array:
	var lines: Array = []
	match foe_id:
		"tia":
			lines.append(_l("莫尔甘·炎龙", C_MORGAN, "守护？八百年前艾琳也这么说。然后她死了。"))
			lines.append(_l("缇娅", C_TIA, "她没有死。她一直在这团火里——等着有人来接她回家。"))
		"edric":
			lines.append(_l("莫尔甘·炎龙", C_MORGAN, "菲恩家的孩子。你父亲没走完的路，你也走不完。"))
			lines.append(_l("艾德里克", C_EDRIC, "父亲的剑说，它是用来守护的。……今天，它守护的是所有人。"))
		"gareth":
			lines.append(_l("莫尔甘·炎龙", C_MORGAN, "布罗登的王子。你父王的宫廷里，有一半是我的人。"))
			lines.append(_l("加雷斯", C_GARETH, "那就回去以后再清理。先把你这一半劈了！"))
		_:
			lines.append(_l("莫尔甘·炎龙", C_MORGAN, "蝼蚁。火面前，一切都是灰。"))
	return lines


func _boss_seven() -> Array:
	return [
		_l("莫尔甘·炎龙", C_MORGAN, "七号。你也是灰。灰，回到火里来吧。"),
		_l("七号", C_SEVEN, "我是灰。……灰，是火烧完以后，还愿意留下来的东西。"),
		_l("七号", C_SEVEN, "所以我留下来。为了她。"),
	]


func _boss_death() -> Array:
	return [
		_l("莫尔甘·炎龙", C_MORGAN, "不……我才刚……刚变成火……"),
		_l("莫尔甘·炎龙", C_MORGAN, "不想……回到灰里……好冷……"),
		_l("", C_NARR, "赤红的鳞片一片片剥落。龙火从莫尔甘的身体里挣脱出来，在大厅里横冲直撞。"),
	]


## 真结局：烬用灰烬之身接住龙火的一瞬，缇娅把它化成大陆各地的炉火
func _finale_true() -> Array:
	return [
		_l("缇娅", C_TIA, "龙火……没有锁，它会烧掉整座神殿！"),
		_l("烬", C_SEVEN, "缇娅。我来接住它。"),
		_l("缇娅", C_TIA, "烬？！"),
		_l("烬", C_SEVEN, "灰，是火烧完以后剩下的东西。所以，灰装得下火。……一瞬间，就够了。"),
		_l("", C_NARR, "烬张开双臂。龙火撞进了她灰做的身体，她的身体变得通红，像一块烧透的炭。"),
		_l("缇娅·守护之火", C_TIA, "……谢谢。剩下的，交给我。"),
		_l("", C_NARR, "缇娅握住了烬的手。守护之火顺着两个人的手，一点一点地，把龙火接了过去。"),
		_l("缇娅·守护之火", C_TIA, "回去吧。……回到每一家的炉膛里去。不要再当谁的锁，也不要再当谁的武器。"),
		_l("", C_NARR, "龙火化成了千万颗火星，穿过神殿的穹顶，飞向满月下的大陆。"),
		_l("", C_NARR, "那一夜，卡尔迪亚大陆上所有熄灭了的炉膛，都重新亮了起来。"),
		_l("", C_NARR, "封印台上，烬跪坐在地上。她灰色的手背上，透出了一点淡淡的、温热的红。"),
		_l("烬", C_SEVEN, "……缇娅。我的手，是暖的。"),
		_l("缇娅", C_TIA, "嗯。……你的名字，也是暖的。烬。"),
	]


## 普通结局：八圣器与缇娅的血重新封印，缇娅的火熄灭了
func _finale_normal() -> Array:
	var lines: Array = [
		_l("缇娅", C_TIA, "龙火……没有锁，它会烧掉整座神殿！"),
		_l("艾德里克", C_EDRIC, "缇娅，退后——！"),
		_l("缇娅", C_TIA, "……对不起，艾德里克。只能这样了。"),
		_l("", C_NARR, "缇娅划破手心，把血洒上了封印台。八件圣器同时亮起，龙火发出最后一声咆哮，被拖回了地底。"),
		_l("", C_NARR, "封印合上了。缇娅身上的火，也跟着一起，熄灭了。"),
		_l("艾德里克", C_EDRIC, "缇娅！"),
		_l("缇娅", C_TIA, "……我没事。只是，好冷啊。"),
	]
	match str(flags.get("fate", "")):
		"left":
			lines.append(_l("七号", C_SEVEN, "……缇娅。我想，我还缺一样东西。等我找到了，再回来。"))
		"ash":
			lines.append(_l("缇娅", C_TIA, "七号……她的核，没能撑过这个晚上。……要是她在这里就好了。"))
		"dead":
			lines.append(_l("缇娅", C_TIA, "（脖子上的布袋，忽然变得很轻。）"))
	return lines


# ============ 开场与尾声 ============

func prologue() -> Dictionary:
	return {"place": "temple", "from": "temple", "lines": [
		_moon(0),
		_l("", CB_NARR, "圣焰神殿的最深处。八百年前，巫女艾琳在这里，用自己锁住了不灭之火。"),
		_l("", CB_NARR, "八百年后，她的血脉站在了同一个地方。"),
	]}


func epilogue() -> Array:
	if Campaign.flags.get("ending", "") == "true":
		return _epilogue_true()
	return _epilogue_normal()


func _epilogue_true() -> Array:
	var square: Array = [
		_l("", CB_NARR, "满月之后的第七天。圣都的大广场上，挤满了人。"),
	]
	if Campaign.alive_in_story("silas") or _here("silas"):
		square.append(_l("塞拉斯", CB_SILAS, "我是审判官塞拉斯。今天，我要审判的，是教会自己。"))
		square.append(_l("塞拉斯", CB_SILAS, "八百年前，失控的不是巫女，是大司祭莫尔甘。巫女艾琳，是救了这片大陆的人。"))
	else:
		square.append(_l("艾德里克", C_EDRIC, "我是菲恩领的艾德里克。今天，我把父亲用命换来的真相，念给大家听。"))
		square.append(_l("艾德里克", C_EDRIC, "八百年前，失控的不是巫女，是大司祭莫尔甘。巫女艾琳，是救了这片大陆的人。"))
	if Campaign.alive_in_story("owen") or _here("owen"):
		square.append(_l("欧文", C_OWEN, "英灵廊的墓碑，会重新刻上她的名字。……守墓人，下山了。"))
	square.append(_l("", CB_NARR, "广场上很久没有人说话。然后，有人点起了一盏油灯——教会禁了八百年的、私人的火。"))
	square.append(_l("", CB_NARR, "一盏，两盏，一千盏。"))
	var village: Array = [
		_l("", CB_NARR, "一年后。灰岩村。"),
		_l("", CB_NARR, "村子里盖了十九间房子。每一间的炉膛里，都烧着火。"),
	]
	if Campaign.alive_in_story("balto") or _here("balto"):
		village.append(_l("巴尔托", C_BALTO, "丫头，柴劈好了没有？握斧子的手往下压半寸。"))
		village.append(_l("缇娅", C_TIA, "知道啦！……这句话你要说到什么时候？"))
		village.append(_l("巴尔托", C_BALTO, "说到你教你自己的孩子为止。"))
	village.append_array([
		_l("烬", CB_SEVEN, "缇娅。门口有两个人。一个骑马的，一个……扛着一整只羊。"),
		_l("缇娅", C_TIA, "（笑）是艾德里克和加雷斯。……烬，去拿碗。今天大家一起吃。"),
		_l("烬", CB_SEVEN, "……嗯。"),
		_l("", CB_NARR, "烬现在会笑了。笑起来的时候，灰色的眼睛里，有一点小小的火光。"),
		_l("", CB_NARR, "火焰无善恶，在于为何而燃。"),
		_l("", CB_NARR, "——《炎烬之誓》 完。"),
	])
	return [
		{"title": "圣都 · 大广场", "mood": "church", "lines": square},
		{"title": "灰岩村 · 一年后", "mood": "camp", "lines": village},
	]


func _epilogue_normal() -> Array:
	var church: Array = [
		_l("", CB_NARR, "满月之后。教会宣布：大司祭莫尔甘「为封印不灭之火而殉道」。"),
		_l("", CB_NARR, "新的大司祭登上了大圣堂。书库的门，又一次锁上了。"),
	]
	if Campaign.alive_in_story("silas") or _here("silas"):
		church.append(_l("塞拉斯", CB_SILAS, "……没关系。我抄了一份。总有一天，会有人愿意听。"))
	else:
		church.append(_l("艾德里克", C_EDRIC, "……我抄了一份编年史。总有一天，会有人愿意听。"))
	var village: Array = [
		_l("", CB_NARR, "灰岩村。缇娅回到了村子里。她再也点不着手心里的火了。"),
		_l("缇娅", C_TIA, "……其实也挺好。冬天就和大家一样，围着炉子烤火。"),
	]
	match str(flags.get("fate", "")):
		"dead":
			village.append(_l("", CB_NARR, "她脖子上一直挂着一个小布袋。里面装着一捧灰——有时候，摸上去是温的。"))
		"ash":
			village.append(_l("", CB_NARR, "村口多了一块小小的石碑，上面没有名字，只刻着一个「七」。"))
		"left":
			village.append(_l("", CB_NARR, "七号在满月那夜之后就不见了。缇娅的窗台上，留着一张纸条：「去找我的名字。」"))
	village.append_array([
		_l("艾德里克", C_EDRIC, "缇娅。……下次满月，我还会来。"),
		_l("缇娅", C_TIA, "嗯。……炉子给你留着。"),
		_l("", CB_NARR, "火被锁了回去。可是八英雄的誓言还刻在英灵廊上：「火不可封，唯可守。」"),
		_l("", CB_NARR, "——也许，还有另一种结局。"),
	])
	return [
		{"title": "圣都 · 大圣堂", "mood": "church", "lines": church},
		{"title": "灰岩村", "mood": "night", "lines": village},
	]
