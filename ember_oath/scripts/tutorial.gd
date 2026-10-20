class_name Tutorial
extends Control
## 新手教程：
## - 第一章开场问一次要不要教程（Campaign.flags["tutorial"]），选了就走「分步引导」：
##   顶部教程条一步一步说做什么，金框标出要点的格子，玩家做到了自动进下一步（不锁操作）。
## - 情境提示：教程开着时，每样新东西（预报、克制、地形、访问、说得、增援、首领、整备……）第一次出现弹一次，
##   看过的记在 Campaign.flags["tips_seen"]，跨章节保留。
## - 地图菜单【教程】随时翻看全部条目。
## battle 在各处调用 on_event(名字, 数据)；本节点挂在 battle.ui 上，不吃地图点击（只有按钮吃）。

signal answered

const TIPS := {
	"basics": ["基本操作",
		"点我方单位 → 蓝色格子是能走到的地方、红色是能打到的地方 → 点蓝格移动 → 弹出菜单选行动。\\n点空白处取消；点空地打开地图菜单（回合结束、危险范围、系统菜单、教程）。"],
	"forecast": ["战斗预报",
		"上面是对手、下面是自己。攻击＝打中一次扣的血，×2＝速度比对方快 4 点以上会追击打两次；命中＝打中的概率；必杀＝打出三倍伤害的概率。对手打得到你就会反击。"],
	"triangle": ["武器克制",
		"剑克斧、斧克枪、枪克剑：克制时命中 +10、伤害 +1，被克制时反过来。弓不能打贴身的敌人；魔法打的是魔防，重甲兵最怕魔法。"],
	"terrain": ["地形",
		"森林、丘陵、废墟能提高回避或守备，但走进去更费移动力；堡垒、城门、王座还会在回合开始回血。光标停在格子上，地形窗里能看到效果。"],
	"exp": ["经验与升级",
		"攻击、治疗、击败敌人都能拿经验，满 100 升一级，各项能力按成长率随机提升。Lv10 以上可以用转职道具转成上级职业。"],
	"visit": ["访问民居",
		"站到有门的民居上，菜单里选【访问】：村民会送道具或金钱，有时还会告诉你重要的事。每户只能访问一次，被山贼抢先就没了。"],
	"talk": ["对话与说得",
		"【对话】是同伴之间聊天，常常会送东西或加深感情；【说得】能劝特定的敌人加入我方，只有特定的人才说得动特定的人。"],
	"item": ["道具与永久死亡",
		"受伤了就退到后面，用【道具】里的伤药回血（会用掉这回合的行动）。同伴倒下就是阵亡，之后的章节不会再出场；主角倒下直接败北。"],
	"reinforce": ["增援",
		"敌人会在某些回合从地图边、营地或城门冒出来。别把伤员留在入口附近。"],
	"boss": ["首领",
		"首领通常守着不动，能力比杂兵强得多，站在堡垒、城门上还会回血。有的章节击败首领就能过关。"],
	"prep": ["出击准备",
		"开战前可以选谁出击、布阵（点地图上的蓝框换位置）、在同伴和道具库之间整理物品、去商店买东西。锁定的人必须出击。"],
	"shop": ["商店",
		"站到武器店、道具店上，菜单里会出现【武器店】【道具店】：买的东西进这个人的背包（满了进道具库），也可以卖掉用不着的东西。"],
	"durability": ["武器耐久",
		"武器、魔导书、杖都有使用次数，名字后面的数字就是剩下的次数，用完就坏了。记得在商店补货。"],
	"rescue": ["救出",
		"体格大的人能把相邻的同伴背起来带走（背着的人不会被攻击，但自己技巧、速度减半）。之后可以【放下】，或【交给】别人。"],
	"support": ["支援",
		"有羁绊的两个人并肩作战（相邻）会积累点数，攒够了在菜单里选【支援】对话。支援等级越高，彼此 3 格内命中、回避越高。"],
	"magic": ["魔法与治疗",
		"魔法攻击的是对方的魔防，射程 1–2；重甲兵魔防很低。修女的治疗杖能给同伴回血，也能拿经验。"],
	"npc": ["中立单位",
		"绿色的是中立单位：敌我都不会攻击它。走到旁边用【对话】，有的人会加入我方。"],
	"chest": ["宝箱",
		"只有盗贼能开宝箱：让盗贼站到宝箱上，菜单里选【开宝箱】。"],
}
## 地图菜单【教程】里的顺序
const ORDER := ["basics", "forecast", "triangle", "terrain", "exp", "item", "visit", "talk", "reinforce", "boss",
	"prep", "shop", "durability", "rescue", "support", "magic", "npc", "chest"]

var battle = null
var asking := false                 # 开场正在问要不要教程
var guided := false                 # 分步引导进行中
var _step := -1
var _steps: Array = []
var _panel: PanelContainer
var _title: Label
var _body: Label
var _btn_ok: Button
var _btn_skip: Button
var _ask: Control
var _browser: Control
var _marker: TutorialMarker = null


func setup(b) -> void:
	battle = b
	name = "Tutorial"
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel = PanelContainer.new()
	_panel.name = "CoachPanel"
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.08, 0.04, 0.9)
	sb.border_color = Color(1.0, 0.82, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	_panel.add_child(vb)
	_title = _label(vb, 19, Color(1.0, 0.86, 0.45))
	_body = _label(vb, 17, Color(0.96, 0.94, 0.9))
	_body.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_body.custom_minimum_size = Vector2(520, 0)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", 10)
	vb.add_child(row)
	_btn_skip = _button(row, tr("跳过教程"), _on_skip)
	_btn_ok = _button(row, tr("知道了"), _on_ok)
	_panel.visible = false
	add_child(_panel)


func _label(parent: Node, fs: int, c: Color) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", c)
	parent.add_child(l)
	return l


func _button(parent: Node, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.text = text
	b.custom_minimum_size = Vector2(120, SafeArea.MIN_HIT)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


static func enabled() -> bool:
	return bool(Campaign.flags.get("tutorial", true))


static func seen(id: String) -> bool:
	return id in Campaign.flags.get("tips_seen", [])


static func mark_seen(id: String) -> void:
	var arr: Array = Campaign.flags.get("tips_seen", [])
	if not id in arr:
		arr.append(id)
	Campaign.flags["tips_seen"] = arr


# ==================== 开场询问 ====================

## 第一章开场问一次；之前回答过就直接返回结果
func ask() -> bool:
	if Campaign.flags.has("tutorial"):
		return enabled()
	asking = true
	_ask = Control.new()
	_ask.name = "TutorialAsk"
	_ask.size = Vector2(1280, 720)
	_ask.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ask.add_child(dim)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel.get_theme_stylebox("panel"))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	p.add_child(vb)
	var t := _label(vb, 24, Color(1.0, 0.86, 0.45))
	t.text = tr("要看新手教程吗？")
	var d := _label(vb, 18, Color(0.96, 0.94, 0.9))
	d.text = tr("第一次玩战棋，建议跟着教程走一遍：会一步步教你选人、移动、攻击和看预报。\\n之后遇到新东西还会弹出说明；地图菜单里的【教程】可以随时翻看。").replace("\\n", "\n")
	d.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	d.custom_minimum_size = Vector2(560, 0)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	vb.add_child(row)
	var yes := _button(row, tr("需要教程"), func() -> void: choose(true))
	yes.name = "TutorialYes"
	yes.custom_minimum_size = Vector2(200, 56)
	var no := _button(row, tr("跳过（玩过火纹）"), func() -> void: choose(false))
	no.name = "TutorialNo"
	no.custom_minimum_size = Vector2(200, 56)
	_ask.add_child(p)
	add_child(_ask)
	SafeArea.widen(_ask)  # 宽屏：遮罩盖满整屏
	p.reset_size()
	p.position = (Vector2(1280, 720) - p.get_combined_minimum_size()) / 2.0
	await answered
	return enabled()


func choose(on: bool) -> void:
	Campaign.flags["tutorial"] = on
	asking = false
	if _ask != null:
		_ask.queue_free()
		_ask = null
	answered.emit()


# ==================== 分步引导（第一章第 1–2 回合） ====================

func start_guided() -> void:
	if not enabled():
		return
	guided = true
	var tia = battle.get_unit("tia")
	var balto = battle.get_unit("balto")
	_steps = [
		{"title": "第一步 · 选择单位", "text": "点一下缇娅（金框）。\\n蓝色格子是她这回合能走到的地方，红色格子是她能打到的地方。",
			"tile": func(): return tia.grid_pos if tia != null else null,
			"done": func(n, d): return n == "select" and d == tia},
		{"title": "第二步 · 移动", "text": "点一个蓝色格子，缇娅就会走过去。路线上会显示箭头。\\n试试走到桥头前面（金框），也可以走别处；点空白处能取消选择。",
			"tile": func(): return Vector2i(5, 4),
			"done": func(n, d): return n == "menu" and d == tia},
		{"title": "第三步 · 行动菜单", "text": "移动后会弹出行动菜单：身边有敌人就能【攻击】，没有就选【待机】结束她这回合的行动。\\n点菜单外面能撤销刚才的移动。",
			"tile": func(): return null,
			"done": func(n, d): return n == "acted" and d == tia},
		{"title": "第四步 · 巴尔托", "text": "巴尔托是骑马的圣骑士，移动力 7，比缇娅走得远，也更能打。\\n用同样的方法让他行动：点他 → 点蓝格 → 选行动。",
			"tile": func(): return balto.grid_pos if balto != null and not balto.has_acted else null,
			"done": func(n, d): return n == "acted" and d == balto},
		{"title": "第五步 · 回合结束", "text": "我方所有人都行动完，就会自动进入敌方回合。\\n（还有人没动也想结束的话：点空地打开地图菜单，选【回合结束】。）",
			"tile": func(): return null,
			"done": func(n, _d): return n == "enemy_phase"},
		{"title": "敌方回合", "text": "敌人会靠近进攻。被攻击的一方，只要武器打得到就会自动反击。\\n看着就好，等它们动完。",
			"tile": func(): return null,
			"done": func(n, _d): return n == "player_phase"},
		{"title": "看清敌人", "text": "点一下敌人，能看到它的移动和攻击范围；点空地菜单里的【显示危险范围】，能看到所有敌人这回合能打到的地方。\\n站在范围外最安全。试试点一个敌人。",
			"tile": func(): return null,
			"done": func(n, _d): return n in ["preview", "danger", "acted"]},
		{"title": "教程完成", "text": "基本操作就是这些：选人、移动、行动、回合结束。\\n之后遇到新东西还会弹出说明；地图菜单里的【教程】可以随时翻看。去把山贼赶出村子吧！",
			"tile": func(): return null,
			"done": func(n, _d): return n in ["acted", "enemy_phase"], "final": true},
	]
	_step = -1
	_next_step()


func _next_step() -> void:
	_step += 1
	if _step >= _steps.size():
		_end_guided()
		return
	var st: Dictionary = _steps[_step]
	_show(tr(st["title"]), tr(st["text"]), st.get("final", false), true)
	_update_marker()


func _end_guided() -> void:
	guided = false
	mark_seen("basics")
	_hide()


func _update_marker() -> void:
	if not guided or _step < 0 or _step >= _steps.size():
		_clear_marker()
		return
	var p = _steps[_step]["tile"].call()
	if p == null:
		_clear_marker()
		return
	if _marker == null or not is_instance_valid(_marker):
		_marker = TutorialMarker.new()
		_marker.z_index = 9
		battle.board.add_child(_marker)
	_marker.grid = p
	_marker.visible = true


func _clear_marker() -> void:
	if _marker != null and is_instance_valid(_marker):
		_marker.visible = false


func current_step() -> int:
	return _step if guided else -1


# ==================== 事件 ====================

func on_event(n: String, d = null) -> void:
	if guided and _step >= 0 and _step < _steps.size():
		if _steps[_step]["done"].call(n, d):
			_next_step()
			return
		_update_marker()
	if not enabled():
		return
	match n:
		"forecast":
			var f: Dictionary = d
			if f.get("triangle", 0) != 0:
				tip("triangle")
			elif f.get("magic", false):
				tip("magic")
			else:
				tip("forecast")
		"levelup":
			tip("exp")
		"menu_opts":
			var labels: Array = d
			if tr("访问") in labels:
				tip("visit")
			elif tr("说得") in labels or tr("对话") in labels:
				tip("talk")
			elif tr("救出") in labels:
				tip("rescue")
			elif tr("支援") in labels:
				tip("support")
			elif tr("开宝箱") in labels:
				tip("chest")
			elif tr("武器店") in labels or tr("道具店") in labels:
				tip("shop")
		"hover_unit":
			if d.is_npc():
				tip("npc")
			elif d.is_boss and not d.is_player():
				tip("boss")
			elif d.weapon_kind() in ["anima", "light", "dark", "staff"]:
				tip("magic")
		"hover_tile":
			var t: Dictionary = battle.board.terrain(d)
			if battle.board.tile_at(d) == "Q":
				tip("chest")
			elif int(t.get("avo", 0)) > 0 or int(t.get("dfn", 0)) > 0:
				tip("terrain")
		"spawn":
			tip("reinforce")
		"prep":
			tip("prep")
		"player_phase":
			for u in battle.units:
				if u.is_player() and u.on_map() and u.hp * 2 < u.max_hp:
					tip("item")
					break
			if battle.chapter.chapter_id() != "ch1" and battle.turn == 1:
				tip("durability")
		"weapon_broke":
			tip("durability")


## 情境提示：没看过才弹；分步引导进行中先不打断（引导结束后再遇到会弹）
func tip(id: String) -> void:
	if guided or seen(id) or not TIPS.has(id) or not enabled():
		return
	mark_seen(id)
	_show(tr(TIPS[id][0]), tr(TIPS[id][1]), true, false)


func _show(title: String, text: String, ok: bool, skip: bool) -> void:
	_title.text = ("▶ " if guided else "◆ ") + title
	_body.text = text.replace("\\n", "\n")
	_btn_ok.visible = ok
	_btn_skip.visible = skip and guided
	_panel.visible = true
	_panel.reset_size()
	var ps := _panel.get_combined_minimum_size()
	_panel.position = Vector2(640.0 - ps.x / 2.0, SafeArea.MARGIN_Y + 92.0)


func _hide() -> void:
	_panel.visible = false
	_clear_marker()


func is_showing() -> bool:
	return _panel.visible


func _on_ok() -> void:
	if guided and _step >= 0 and _step < _steps.size() and _steps[_step].get("final", false):
		_end_guided()
		return
	_hide()


func _on_skip() -> void:
	_end_guided()


# ==================== 教程手册（地图菜单） ====================

func open_browser() -> void:
	if _browser != null and is_instance_valid(_browser):
		return
	_browser = Control.new()
	_browser.name = "TutorialBrowser"
	_browser.size = Vector2(1280, 720)
	_browser.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_browser.add_child(dim)
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _panel.get_theme_stylebox("panel"))
	p.position = Vector2(SafeArea.MARGIN_X + 40, SafeArea.MARGIN_Y)
	p.custom_minimum_size = Vector2(1280 - SafeArea.MARGIN_X * 2 - 80, 720 - SafeArea.MARGIN_Y * 2)
	_browser.add_child(p)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	p.add_child(hb)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(240, 560)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	hb.add_child(sc)
	var list := VBoxContainer.new()
	sc.add_child(list)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	var t := _label(right, 24, Color(1.0, 0.86, 0.45))
	var body := _label(right, 19, Color(0.96, 0.94, 0.9))
	body.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	body.custom_minimum_size = Vector2(600, 0)
	for id in ORDER:
		var key: String = id
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = tr(TIPS[key][0])
		b.custom_minimum_size = Vector2(220, 44)
		b.pressed.connect(func() -> void:
			t.text = tr(TIPS[key][0])
			body.text = tr(TIPS[key][1]).replace("\\n", "\n"))
		list.add_child(b)
	t.text = tr(TIPS["basics"][0])
	body.text = tr(TIPS["basics"][1]).replace("\\n", "\n")
	var close := _button(right, tr("关闭"), close_browser)
	close.name = "TutorialClose"
	add_child(_browser)
	SafeArea.widen(_browser)  # 宽屏：遮罩盖满整屏


func close_browser() -> void:
	if _browser != null and is_instance_valid(_browser):
		_browser.queue_free()
	_browser = null


func browser_open() -> bool:
	return _browser != null and is_instance_valid(_browser)


## 金框：标出教程要点的格子（呼吸闪烁）
class TutorialMarker extends Node2D:
	var grid := Vector2i.ZERO:
		set(v):
			grid = v
			position = Vector2(v) * 64
			queue_redraw()
	var _t := 0.0

	func _process(delta: float) -> void:
		_t += delta
		modulate.a = 0.55 + 0.45 * sin(_t * 5.0)

	func _draw() -> void:
		draw_rect(Rect2(Vector2(2, 2), Vector2(60, 60)), Color(1.0, 0.85, 0.3), false, 4.0)
		draw_rect(Rect2(Vector2(-2, -2), Vector2(68, 68)), Color(1.0, 0.95, 0.6, 0.5), false, 2.0)
