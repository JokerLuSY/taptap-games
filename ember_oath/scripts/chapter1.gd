class_name Chapter1
extends RefCounted
## 第一章「边境的少女」：地图、单位配置、全部剧情事件

const CHAPTER_TITLE := "第一章 · 边境的少女"
const VICTORY_TITLE := "第一章 · 完"
const VICTORY_SUB := "缇娅的身世之谜，才刚刚开始……"
const DEFEAT_SUB := "灰岩村的命运，到此为止……"

## 不用手绘底图：和第二章一样走 CC0 图块（MapTiles）。'X' 画成岩壁。
const BG := ""

## 逻辑网格与 AI 手绘背景对齐: 道路/桥在第 5 列(手绘如此), 水井在 (8,2), 高台麦田在 11-13 列 x 1-2 行
## 'X' = 手绘崖壁/石梯田墙 (不可通行, 只存在于背景中)
const MAP := [
	"FFFFFFFFFFFFFFF",
	"F..H.R...H.gggF",
	".ff..R..W.gXX..",
	".H...R.....HX..",
	"s....R.........",
	"~~~~~B~~~~~~~~~",
	".....R........s",
	"..M..R....M....",
	".....R.........",
	".....R.........",
]

## 高度层: 0=水面/沙滩, 1=陆地, 2=高地（攀爬 +2 移动力, 弓箭手射程+1）
const LEVELS := [
	"222222222222222",
	"111111111112221",
	"111111111112221",
	"111111111111111",
	"011111111111111",
	"000001000000000",
	"111111111111110",
	"111111111111111",
	"111111111111111",
	"111111111111111",
]

const C_TIA := Color(1.0, 0.62, 0.45)
const C_BALTO := Color(0.62, 0.78, 1.0)
const C_NPC := Color(1.0, 0.9, 0.55)
const C_ENEMY := Color(1.0, 0.55, 0.5)
const C_BOSS := Color(1.0, 0.45, 0.35)
const C_NARR := Color(0.82, 0.82, 0.88)

const _BANDIT := {"name": "山贼", "class": "山贼", "faction": "enemy", "level": 2,
	"hp": 22, "pwr": 4, "skl": 2, "spd": 3, "dfn": 2, "mov": 5,
	"weapons": ["iron_axe"], "color": Color(0.55, 0.45, 0.35),
	"hair": "spiky", "hair_color": Color(0.25, 0.18, 0.12), "armor": Color(0.50, 0.40, 0.30)}
const _ARCHER := {"name": "弓箭手", "class": "弓箭手", "faction": "enemy", "level": 2,
	"hp": 18, "pwr": 4, "skl": 5, "spd": 5, "dfn": 2, "mov": 5,
	"weapons": ["iron_bow"], "color": Color(0.45, 0.55, 0.40),
	"hair": "hood", "armor": Color(0.38, 0.55, 0.38)}

const UNITS := [
	{"id": "tia", "name": "缇娅", "class": "剑士", "faction": "player", "level": 1,
		"hp": 20, "pwr": 5, "skl": 6, "spd": 7, "dfn": 3, "mov": 5,
		"weapons": ["iron_sword"], "items": ["vulnerary"],
		"growths": {"hp": 75, "pwr": 45, "skl": 55, "spd": 60, "dfn": 35},
		"pos": Vector2i(4, 3), "color": Color(0.85, 0.45, 0.35),
		"hair": "ponytail", "hair_color": Color(0.80, 0.22, 0.18), "armor": Color(0.62, 0.45, 0.32)},
	{"id": "balto", "name": "巴尔托", "class": "圣骑士", "faction": "player", "level": 8,
		"hp": 26, "pwr": 8, "skl": 9, "spd": 8, "dfn": 7, "mov": 7,
		"weapons": ["silver_lance", "javelin"], "items": ["vulnerary"],
		"growths": {"hp": 40, "pwr": 20, "skl": 25, "spd": 25, "dfn": 20},
		"pos": Vector2i(6, 3), "color": Color(0.45, 0.55, 0.75),
		"hair": "short", "hair_color": Color(0.75, 0.75, 0.78), "armor": Color(0.70, 0.73, 0.82)},
	# 山贼
	{"id": "bandit1", "pos": Vector2i(3, 7)}, {"id": "bandit2", "pos": Vector2i(7, 7)},
	{"id": "bandit3", "pos": Vector2i(5, 8)}, {"id": "bandit4", "pos": Vector2i(2, 8)},
	{"id": "bandit5", "pos": Vector2i(9, 8)},
	{"id": "bandit6", "pos": Vector2i(12, 7), "name": "山贼小弟"},  # 可被缇娅说得
	# 弓箭手
	{"id": "archer1", "pos": Vector2i(6, 8)}, {"id": "archer2", "pos": Vector2i(10, 7)},
	# BOSS：疤面布洛克，守桥头
	{"id": "brock", "name": "布洛克", "class": "山贼头目", "faction": "enemy", "level": 4,
		"hp": 34, "pwr": 8, "skl": 5, "spd": 4, "dfn": 5, "mov": 5,
		"weapons": ["war_axe"], "stationary": true, "boss": true,
		"pos": Vector2i(5, 6), "color": Color(0.60, 0.30, 0.25),
		"hair": "spiky", "hair_color": Color(0.12, 0.10, 0.10), "armor": Color(0.42, 0.26, 0.24), "scar": true},
]

const REINFORCEMENTS := [
	{"id": "bandit_r1", "pos": Vector2i(4, 9)},
	{"id": "bandit_r2", "pos": Vector2i(6, 9)},
]

## 支援对话: 相邻累计 points_to_c 回合后解锁 C 级
const SUPPORTS := {
	"tia|balto": {"points_to_c": 6},
}

## 可说得的敌方单位: {unit_id: {"by": 说得者 unit_id}}
const RECRUITS := {
	"bandit6": {"by": "tia"},
}

var battle = null
var visited := {}
var f_first_attack := false
var f_talk := false
var f_reinforce := false
var f_boss_met := false
var f_support := {}               # {支援对 key: 已解锁}


func export_flags() -> Dictionary:
	var visited_out: Array = []
	for k in visited:
		visited_out.append([int(k.x), int(k.y)])
	return {
		"visited": visited_out,
		"f_first_attack": f_first_attack,
		"f_talk": f_talk,
		"f_reinforce": f_reinforce,
		"f_boss_met": f_boss_met,
		"f_support": f_support.duplicate(),
	}


func import_flags(data: Dictionary) -> void:
	visited = {}
	var raw = data.get("visited", [])
	if raw is Array:
		for pair in raw:
			if typeof(pair) != TYPE_ARRAY or pair.size() < 2:
				continue
			visited[Vector2i(int(pair[0]), int(pair[1]))] = true
	f_first_attack = bool(data.get("f_first_attack", false))
	f_talk = bool(data.get("f_talk", false))
	f_reinforce = bool(data.get("f_reinforce", false))
	f_boss_met = bool(data.get("f_boss_met", false))
	var fs = data.get("f_support", {})
	f_support = fs.duplicate() if fs is Dictionary else {}


## 合并模板（山贼/弓箭手只写 id 和 pos 时套模板）；const 字典为只读，必须逐键拷贝到新字典
static func expand(defs: Array) -> Array:
	var out: Array = []
	for d in defs:
		var full := {}
		var id: String = d.get("id", "")
		var tmpl := {}
		if id.begins_with("archer"):
			tmpl = _ARCHER
		elif id.begins_with("bandit"):
			tmpl = _BANDIT
		for k in tmpl:
			full[k] = tmpl[k]
		for k in d:
			full[k] = d[k]
		out.append(full)
	return out


# ============ 事件钩子（battle 调用） ============

func on_battle_start() -> void:
	await battle.play_dialogue(_pre_battle())
	await battle.play_dialogue(_tutorial_move())


func on_turn_start(t: int) -> void:
	if t == 2:
		await battle.play_dialogue(_turn2_house())
	elif t == 3 and not f_reinforce:
		f_reinforce = true
		battle.spawn_units(REINFORCEMENTS)
		Audio.play_sfx("reinforce")
		battle.show_banner(tr("敌方增援！"), Color(1.0, 0.5, 0.3))
		await battle.play_dialogue(_turn3_reinforce())


func on_before_combat(att, def) -> void:
	if def.is_boss and not f_boss_met:
		f_boss_met = true
		if att.unit_id == "tia":
			await battle.play_dialogue(_boss_convo())
		else:
			await battle.play_dialogue(_boss_met())


func on_after_combat(att, def, def_died: bool) -> void:
	if att.unit_id == "tia" and not f_first_attack:
		f_first_attack = true
		await battle.play_dialogue(_tutorial_danger())
	if def.is_boss and def_died:
		await battle.play_dialogue(_boss_death())


func on_visit(u, pos: Vector2i) -> void:
	visited[pos] = true
	if pos == Vector2i(9, 1):
		await battle.play_dialogue(_visit_east())
		u.items.append("vulnerary")
		battle.notify(tr("获得 伤药"))
	elif pos == Vector2i(3, 1):
		await battle.play_dialogue(_visit_west())
		battle.add_gold(500)
		battle.notify(tr("获得 500 金币"))
	elif pos == Vector2i(1, 3):
		await battle.play_dialogue(_visit_house1())
	elif pos == Vector2i(11, 3):
		await battle.play_dialogue(_visit_house2())


## 缇娅 ↔ 巴尔托 的相邻对话（仅一次）
func get_talk_partner(u):
	if f_talk:
		return null
	var pid := ""
	if u.unit_id == "tia":
		pid = "balto"
	elif u.unit_id == "balto":
		pid = "tia"
	else:
		return null
	var p = battle.get_unit(pid)
	if p != null and p.is_alive() and GameData.dist(u.grid_pos, p.grid_pos) == 1:
		return p
	return null


func on_talk(_u) -> void:
	f_talk = true
	await battle.play_dialogue(_talk_tia_balto())
	var tia = battle.get_unit("tia")
	tia.items.append("vulnerary")
	battle.notify(tr("缇娅 获得 伤药"))


## 支援: u 的相邻格有可解锁支援的伙伴 → 返回伙伴单位
func get_support_partner(u):
	for key in SUPPORTS:
		if f_support.get(key, false):
			continue
		var pair: Array = String(key).split("|")
		if u.unit_id not in pair:
			continue
		var pid: String = pair[1] if pair[0] == u.unit_id else pair[0]
		if battle.support_points.get(key, 0) < SUPPORTS[key]["points_to_c"]:
			continue
		var p = battle.get_unit(pid)
		if p != null and p.is_alive() and GameData.dist(u.grid_pos, p.grid_pos) == 1:
			return p
	return null


func on_support(u) -> void:
	var partner = get_support_partner(u)
	if partner == null:
		return
	var key := ""
	for k in SUPPORTS:
		var pair: Array = String(k).split("|")
		if u.unit_id in pair and partner.unit_id in pair:
			key = k
	f_support[key] = true
	await battle.play_dialogue(_support_c_tia_balto())
	u.support_with[partner.unit_id] = "C"
	partner.support_with[u.unit_id] = "C"
	battle.notify(tr("缇娅 与 巴尔托 的支援提升到 C！（相邻时 命中/回避 +5）"))


## 说得: u 的相邻格有可招募的敌人 → 返回目标
func get_recruit_target(u):
	for rid in RECRUITS:
		if RECRUITS[rid]["by"] != u.unit_id:
			continue
		var t = battle.get_unit(rid)
		if t != null and t.is_alive() and not t.is_player() and GameData.dist(u.grid_pos, t.grid_pos) == 1:
			return t
	return null


func on_recruit(u) -> void:
	var t = get_recruit_target(u)
	if t == null:
		return
	await battle.play_dialogue(_recruit_bandit6())
	t.faction = "player"
	t.has_acted = true
	t.queue_redraw()
	battle.notify(tr("%s 成为同伴了！") % tr(t.display_name))


func on_victory() -> void:
	await battle.play_dialogue(_post_battle())


func on_defeat() -> void:
	var tia = battle.get_unit("tia")
	if tia == null or not tia.is_alive():
		await battle.play_dialogue(_defeat_tia())
	else:
		await battle.play_dialogue(_defeat_balto())


## 常驻胜负文案。判定本身在 battle.check_end_conditions。
func win_condition() -> String:
	return tr("击败所有敌人")


func lose_condition() -> String:
	return tr("缇娅或巴尔托阵亡")


# ============ 台词 ============

func _l(n: String, c: Color, t: String) -> Dictionary:
	# 名字保留中文键，对话框显示时再 tr()，立绘表才能对上。
	return {"name": n, "color": c, "text": tr(t)}


func _pre_battle() -> Array:
	return [
		_l("", C_NARR, "卡尔迪亚大陆西南边陲，菲恩领群山之间的小村——灰岩村。清晨。"),
		_l("缇娅", C_TIA, "……哈！嘿！……怎么样，刚才那招！"),
		_l("巴尔托", C_BALTO, "手腕太僵了。剑不是靠蛮力挥的，缇娅。"),
		_l("缇娅", C_TIA, "知道啦知道啦，这话你说了八百遍了。"),
		_l("巴尔托", C_BALTO, "说了八百遍还改不过来，说明你还差得远。"),
		_l("缇娅", C_TIA, "哼，等我哪天赢了你，看你还说什么。"),
		_l("哈洛", C_NPC, "巴、巴尔托先生！不好了！山道那边……山贼！山贼朝村子来了！"),
		_l("缇娅", C_TIA, "山贼？！"),
		_l("巴尔托", C_BALTO, "多少人？"),
		_l("哈洛", C_NPC, "七八个……也许更多！领头的是个疤脸汉子，见人就砍！"),
		_l("巴尔托", C_BALTO, "……这个时节，山道明明有领主的巡逻队。偏偏挑今天……"),
		_l("缇娅", C_TIA, "我去通知大家躲进教堂！"),
		_l("巴尔托", C_BALTO, "等等。光躲是没用的——谷仓里存着全村过冬的粮，被烧了就全完了。"),
		_l("缇娅", C_TIA, "那怎么办？村里的男人大多下山赶集去了……"),
		_l("巴尔托", C_BALTO, "……缇娅，你练剑六年了。今天，让它见见血吧。跟紧我，别逞强。"),
		_l("缇娅", C_TIA, "……嗯！"),
		_l("巴尔托", C_BALTO, "哈洛，去敲警钟，所有人撤到村后的树林里。快！"),
	]


func _tutorial_move() -> Array:
	return [
		_l("巴尔托", C_BALTO, "听好，战场上先看清四周再动手。点击缇娅，就能看到她能走到的范围。"),
		_l("巴尔托", C_BALTO, "森林难走，平地好行。选好位置再出手——别逞强。"),
	]


func _tutorial_danger() -> Array:
	return [
		_l("巴尔托", C_BALTO, "剑只能贴身，弓手正好相反。看清敌人的兵器，别站在他们的射程里逞英雄。"),
		_l("巴尔托", C_BALTO, "点击敌人可以查看它的威胁范围。也可以随时按【T】查看全军的危险范围。"),
	]


func _turn2_house() -> Array:
	return [
		_l("村民", C_NPC, "（屋内）缇娅小姐！救命！有山贼在砸我家的门！"),
		_l("巴尔托", C_BALTO, "走到民居上可以【访问】。救下他们会有谢礼——但别为了谢礼把自己搭进去。"),
	]


func _turn3_reinforce() -> Array:
	return [
		_l("山贼", C_ENEMY, "嘿嘿，听说这村里藏着「红头发的丫头」……老大说了，找到重重有赏！"),
		_l("缇娅", C_TIA, "……红头发？他们在说什么？"),
		_l("巴尔托", C_BALTO, "……别分心！先解决眼前的敌人！"),
	]


func _boss_convo() -> Array:
	return [
		_l("缇娅", C_TIA, "你们到底想干什么？抢粮也就算了，为什么挨家挨户地搜？！"),
		_l("布洛克", C_BOSS, "哼，告诉你也无妨。有位「大人物」出钱，要找一个红头发的小丫头——"),
		_l("布洛克", C_BOSS, "……等等。你这头发……哈哈！踏破铁鞋无觅处！"),
		_l("缇娅", C_TIA, "？！"),
		_l("布洛克", C_BOSS, "乖乖跟老子走，还能留这村子一条活路！"),
		_l("缇娅", C_TIA, "做梦——！村子由我来保护！"),
	]


func _boss_met() -> Array:
	return [
		_l("布洛克", C_BOSS, "啧，村里居然还有拿剑的？管你是谁——挡老子财路的，都得死！"),
	]


func _boss_death() -> Array:
	return [
		_l("布洛克", C_BOSS, "咳……怎么可能……老子居然……栽在一个小丫头手里……"),
	]


func _talk_tia_balto() -> Array:
	return [
		_l("缇娅", C_TIA, "巴尔托，你脸色不太好……旧伤又疼了？"),
		_l("巴尔托", C_BALTO, "少废话。拿着这个。"),
		_l("巴尔托", C_BALTO, "记住，受了伤就退下来用【道具】。死人可当不了剑士。"),
	]


func _visit_east() -> Array:
	return [
		_l("村民", C_NPC, "缇娅小姐！这个给你——是我男人留下的伤药，拿着吧！"),
		_l("缇娅", C_TIA, "谢谢！我一定会守住村子！"),
	]


func _visit_west() -> Array:
	return [
		_l("老奶奶", C_NPC, "老婆子我就这点棺材本了……拜托你们，保护好村子。"),
		_l("缇娅", C_TIA, "婆婆……嗯！我答应你！"),
	]


func _visit_house1() -> Array:
	return [
		_l("村民", C_NPC, "谢、谢谢你们！请一定要守住村子！"),
	]


func _visit_house2() -> Array:
	return [
		_l("村民", C_NPC, "山道上的巡逻队今天一个都没来……太奇怪了。"),
		_l("巴尔托", C_BALTO, "（巡逻队没出现，山贼却来了……这不是巧合。）"),
	]


func _post_battle() -> Array:
	return [
		_l("", C_NARR, "黄昏。灰岩村保住了。"),
		_l("缇娅", C_TIA, "结束……了吗……"),
		_l("巴尔托", C_BALTO, "嗯。第一次实战能活下来，就算合格了。"),
		_l("缇娅", C_TIA, "（看着剑上的血，手微微发抖）我……杀了人……"),
		_l("巴尔托", C_BALTO, "记住这双手的颤抖。哪天你杀人时不再发抖，那才真的可怕。"),
		_l("缇娅", C_TIA, "……嗯。"),
		_l("缇娅", C_TIA, "对了巴尔托，那些山贼说的话，你听到了吧？他们在找「红头发的丫头」……这附近，红头发的不就是我吗？"),
		_l("巴尔托", C_BALTO, "…………"),
		_l("缇娅", C_TIA, "你知道些什么，对不对？"),
		_l("巴尔托", C_BALTO, "……缇娅，今晚来我家一趟。有些事，关于你的身世——老夫本想带进棺材里的。"),
		_l("缇娅", C_TIA, "我的……身世？"),
		_l("巴尔托", C_BALTO, "（捡起布洛克掉落的一枚黑色徽章）……黑烬的徽记。普通山贼，怎么会有这种东西……"),
		_l("缇娅", C_TIA, "巴尔托？"),
		_l("巴尔托", C_BALTO, "……没什么。回去吧。今晚之后，你平静的日子，恐怕要到头了。"),
	]


func _support_c_tia_balto() -> Array:
	return [
		_l("缇娅", C_TIA, "巴尔托，你说……我的亲生父母，到底是什么样的人？"),
		_l("巴尔托", C_BALTO, "……现在问这个做什么。"),
		_l("缇娅", C_TIA, "那些山贼是冲我来的，对吧？你别当我傻。"),
		_l("巴尔托", C_BALTO, "…………等这阵风头过了，我会把一切都告诉你。"),
		_l("缇娅", C_TIA, "哼，又拿这句话搪塞我。……算了，反正你答应我了，不许耍赖。"),
		_l("巴尔托", C_BALTO, "（叹气）……嗯，我答应你。"),
	]


func _recruit_bandit6() -> Array:
	return [
		_l("山贼小弟", C_ENEMY, "别、别杀我！我……我只是被他们抓来充数的！"),
		_l("缇娅", C_TIA, "你也是被胁迫的？……那就放下斧头，跟我们走吧。"),
		_l("山贼小弟", C_ENEMY, "诶？……真、真的可以吗？"),
		_l("缇娅", C_TIA, "嗯！一起保护村子，也算将功赎罪。"),
		_l("山贼小弟", C_ENEMY, "……好！我这条命就交给你了！"),
	]


func _defeat_tia() -> Array:
	return [
		_l("缇娅", C_TIA, "对……不起……巴尔托……"),
		_l("", C_NARR, "缇娅倒下了。灰岩村的命运，到此为止……"),
	]


func _defeat_balto() -> Array:
	return [
		_l("巴尔托", C_BALTO, "咳咳……老夫……也到此为止了吗……缇娅，快跑……"),
		_l("", C_NARR, "巴尔托倒下了。失去了最后的屏障，村庄陷入火海……"),
	]
