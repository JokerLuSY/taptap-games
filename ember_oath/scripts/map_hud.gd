class_name MapHud
extends Control
## 地图上的浮动信息窗（火纹式）：地图全屏，信息窗是几块半透明小窗，总是停在光标的另一侧。
## - 目标窗：章节名、回合 / 阶段、金钱、胜负条件（常驻）
## - 单位窗：光标下（或选中）的单位：立绘、能力、武器、道具
## - 地形窗：光标所在格的地形、守备 / 回避、回复
## - 提示条：底部居中的一行操作提示
## 所有窗都不吃鼠标，点击照样落到地图上。

const W_GOAL := 330.0
const W_UNIT := 360.0
const W_TERRAIN := 220.0
const GAP := 8.0

var goal_win: PanelContainer
var unit_win: PanelContainer
var terrain_win: PanelContainer
var hint_win: PanelContainer

var lbl_chapter: Label
var lbl_turn: Label
var lbl_gold: Label
var lbl_win: Label
var lbl_lose: Label
var unit_label: Label
var portrait_frame: Panel
var portrait: TextureRect
var terrain_label: Label
var hint_label: Label

var side := "right"                 # 信息窗当前停靠的一侧
var forced_side := ""               # 整备界面开着时强制停左边
var _tween: Tween


func _init() -> void:
	name = "MapHud"
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_win = _window(Color(0.85, 0.72, 0.38))
	goal_win.name = "GoalWindow"
	var gv := VBoxContainer.new()
	gv.add_theme_constant_override("separation", 2)
	gv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goal_win.add_child(gv)
	lbl_chapter = _label(gv, 15, Color(1.0, 0.86, 0.5))
	lbl_chapter.name = "ChapterLabel"
	lbl_chapter.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	lbl_chapter.clip_text = true
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gv.add_child(row)
	lbl_turn = _label(row, 18, Color(0.92, 0.94, 1.0))
	lbl_turn.name = "TurnLabel"
	lbl_gold = _label(row, 18, Color(1.0, 0.9, 0.55))
	lbl_gold.name = "GoldLabel"
	lbl_win = _label(gv, 15, Color(0.96, 0.86, 0.45))
	lbl_win.name = "WinCondition"
	lbl_win.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_win.custom_minimum_size = Vector2(W_GOAL - 24, 0)
	lbl_lose = _label(gv, 15, Color(0.95, 0.62, 0.48))
	lbl_lose.name = "LoseCondition"
	lbl_lose.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_lose.custom_minimum_size = Vector2(W_GOAL - 24, 0)
	goal_win.custom_minimum_size = Vector2(W_GOAL, 0)
	lbl_chapter.custom_minimum_size = Vector2(W_GOAL - 24, 0)

	unit_win = _window(Color(0.55, 0.7, 1.0))
	unit_win.name = "UnitWindow"
	unit_win.custom_minimum_size = Vector2(W_UNIT, 0)
	var uh := HBoxContainer.new()
	uh.add_theme_constant_override("separation", 10)
	uh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	unit_win.add_child(uh)
	portrait_frame = Panel.new()
	portrait_frame.custom_minimum_size = Vector2(72, 72)
	portrait_frame.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pb := StyleBoxFlat.new()
	pb.bg_color = Color(0.10, 0.13, 0.22)
	pb.border_color = Color(0.85, 0.75, 0.45)
	pb.set_border_width_all(2)
	pb.set_corner_radius_all(6)
	portrait_frame.add_theme_stylebox_override("panel", pb)
	uh.add_child(portrait_frame)
	portrait = TextureRect.new()
	portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_frame.add_child(portrait)
	unit_label = _label(uh, 15, Color(0.94, 0.95, 1.0))
	unit_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	unit_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unit_win.visible = false

	terrain_win = _window(Color(0.6, 0.8, 0.5))
	terrain_win.name = "TerrainWindow"
	terrain_win.custom_minimum_size = Vector2(W_TERRAIN, 0)
	terrain_label = _label(terrain_win, 16, Color(0.94, 0.95, 1.0))

	hint_win = _window(Color(0.4, 0.45, 0.6), 0.7)
	hint_win.name = "HintWindow"
	hint_label = _label(hint_win, 16, Color(0.8, 0.85, 0.95))
	hint_win.visible = false

	for w in [goal_win, unit_win, terrain_win, hint_win]:
		add_child(w)


func _window(border: Color, alpha := 0.82) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, alpha)
	sb.border_color = Color(border, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	p.add_theme_stylebox_override("panel", sb)
	return p


func _label(parent: Node, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l


func set_hint(text: String) -> void:
	hint_label.text = text
	hint_win.visible = text != ""
	_layout_hint()


func show_unit(text: String, tex: Texture2D) -> void:
	unit_label.text = text
	portrait.texture = tex
	portrait_frame.visible = tex != null
	unit_win.visible = true
	unit_win.reset_size()
	_layout(false)


func hide_unit() -> void:
	unit_win.visible = false


func show_terrain(text: String) -> void:
	terrain_label.text = text
	terrain_win.reset_size()
	_layout(false)


## 光标在屏幕上的位置变了：信息窗停到另一侧
func follow(cursor_screen: Vector2) -> void:
	var want := "right" if cursor_screen.x < 640.0 else "left"
	if forced_side != "":
		want = forced_side
	if want != side:
		side = want
		_layout(true)


func refresh() -> void:
	goal_win.reset_size()
	unit_win.reset_size()
	terrain_win.reset_size()
	_layout(false)


func _layout(animate: bool) -> void:
	var safe := SafeArea.rect()
	var gs := goal_win.get_combined_minimum_size()
	var us := unit_win.get_combined_minimum_size()
	var ts := terrain_win.get_combined_minimum_size()
	var right := side == "right"
	var gx := safe.end.x - gs.x if right else safe.position.x
	var ux := safe.end.x - us.x if right else safe.position.x
	var tx := safe.end.x - ts.x if right else safe.position.x
	var targets := {
		goal_win: Vector2(gx, safe.position.y),
		unit_win: Vector2(ux, safe.position.y + gs.y + GAP),
		terrain_win: Vector2(tx, safe.end.y - ts.y),
	}
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if animate and is_inside_tree():
		_tween = create_tween().set_parallel(true)
		for w in targets:
			_tween.tween_property(w, "position", targets[w], 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		for w in targets:
			w.position = targets[w]
	_layout_hint()


func _layout_hint() -> void:
	var safe := SafeArea.rect()
	hint_win.reset_size()
	var hs := hint_win.get_combined_minimum_size()
	hint_win.position = Vector2(640.0 - hs.x / 2.0, safe.end.y - hs.y)
