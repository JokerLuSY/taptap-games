extends Control
## 背包: 当前关卡已获证据, 点击查看描述

var _evidences: Array = []
var _grid: GridContainer
var _count_label: Label
var _detail_name: Label
var _detail_desc: Label
var _click_sfx: AudioStreamPlayer


func _ready() -> void:
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_click_sfx = AudioStreamPlayer.new()
	_click_sfx.stream = load("res://audio/click.wav")
	add_child(_click_sfx)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(920, 1240)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	panel.add_child(vbox)

	var head := HBoxContainer.new()
	vbox.add_child(head)
	var title := Label.new()
	title.text = GameState.ui_text("inventory_title")
	title.add_theme_font_size_override("font_size", 52)
	head.add_child(title)
	_count_label = Label.new()
	_count_label.add_theme_font_size_override("font_size", 36)
	_count_label.add_theme_color_override("font_color", Color(0.7, 0.74, 0.86))
	head.add_child(_count_label)
	var spring := Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spring)
	var close_btn := Button.new()
	close_btn.text = GameState.ui_text("close")
	close_btn.add_theme_font_size_override("font_size", 36)
	close_btn.pressed.connect(func() -> void: visible = false)
	close_btn.pressed.connect(_click_sfx.play)
	head.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 24)
	_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_grid)

	vbox.add_child(HSeparator.new())

	_detail_name = Label.new()
	_detail_name.add_theme_font_size_override("font_size", 44)
	_detail_name.add_theme_color_override("font_color", Color(1.0, 0.87, 0.62))
	vbox.add_child(_detail_name)

	_detail_desc = Label.new()
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_desc.custom_minimum_size = Vector2(0, 180)
	_detail_desc.add_theme_font_size_override("font_size", 36)
	vbox.add_child(_detail_desc)


func setup(evidences: Array) -> void:
	_evidences = evidences
	_detail_name.text = ""
	_detail_desc.text = ""
	refresh()


func refresh() -> void:
	for c in _grid.get_children():
		c.queue_free()
	var got := 0
	for ev in _evidences:
		var has_it: bool = GameState.is_collected(GameState.current_level, ev.get("id", ""))
		if has_it:
			got += 1
		var b := Button.new()
		b.custom_minimum_size = Vector2(220, 220)
		if has_it:
			b.icon = load(ev.get("icon", ""))
			b.expand_icon = true
			b.pressed.connect(_show_detail.bind(ev))
			b.pressed.connect(_click_sfx.play)
		else:
			b.text = "?"
			b.disabled = true
			b.add_theme_font_size_override("font_size", 72)
		_grid.add_child(b)
	_count_label.text = "  %d/%d" % [got, _evidences.size()]


func _show_detail(ev: Dictionary) -> void:
	_detail_name.text = ev.get("name", "")
	_detail_desc.text = ev.get("desc", "")


func _panel_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.13, 0.97)
	sb.set_corner_radius_all(20)
	sb.set_content_margin_all(40)
	sb.border_color = Color(0.35, 0.4, 0.55)
	sb.set_border_width_all(2)
	return sb
