extends Control
## 结局演出: 医院揭示(文本来自 level_12.json 的 ending 块) -> 二选一 -> 回主菜单

var _data: Dictionary = {}
var _lines: Array = []
var _idx := -1
var _phase := "main"  ## main -> epilogue -> done

var _label: Label
var _hint: Label
var _choices: VBoxContainer
var _back_btn: Button
var _click_sfx: AudioStreamPlayer


func _ready() -> void:
	GameState.stop_hint_timers()
	var level12: Variant = GameState.load_json("res://data/levels/level_12.json")
	if typeof(level12) == TYPE_DICTIONARY:
		_data = level12.get("ending", {})
	_build_ui()
	_lines = _data.get("lines", [])
	_advance()


func _build_ui() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://art/bg/ending.png")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.06, 0.25)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	_click_sfx = AudioStreamPlayer.new()
	_click_sfx.stream = load("res://audio/click.wav")
	add_child(_click_sfx)

	# 全屏点击推进(置于底层, 按钮在其上)
	var tap := Control.new()
	tap.set_anchors_preset(Control.PRESET_FULL_RECT)
	tap.gui_input.connect(_on_tap)
	add_child(tap)

	# 底部文本区
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_bottom = -60
	panel.offset_top = -620
	panel.offset_left = 50
	panel.offset_right = -50
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.045, 0.09, 0.85)
	sb.set_corner_radius_all(18)
	sb.set_content_margin_all(44)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 30)
	panel.add_child(vb)

	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.add_theme_font_size_override("font_size", 46)
	_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.98))
	_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_label)

	_hint = Label.new()
	_hint.text = "▽ 点击继续"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 30)
	_hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	vb.add_child(_hint)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 24)
	_choices.visible = false
	vb.add_child(_choices)
	var btn_a := Button.new()
	btn_a.text = _data.get("choice_a", GameState.ui_text("ending_choice_a"))
	btn_a.custom_minimum_size = Vector2(0, 100)
	btn_a.add_theme_font_size_override("font_size", 40)
	btn_a.pressed.connect(_on_choice.bind(true))
	btn_a.pressed.connect(_click_sfx.play)
	_choices.add_child(btn_a)
	var btn_b := Button.new()
	btn_b.text = _data.get("choice_b", GameState.ui_text("ending_choice_b"))
	btn_b.custom_minimum_size = Vector2(0, 100)
	btn_b.add_theme_font_size_override("font_size", 40)
	btn_b.pressed.connect(_on_choice.bind(false))
	btn_b.pressed.connect(_click_sfx.play)
	_choices.add_child(btn_b)

	_back_btn = Button.new()
	_back_btn.text = GameState.ui_text("ending_back")
	_back_btn.custom_minimum_size = Vector2(360, 100)
	_back_btn.visible = false
	_back_btn.add_theme_font_size_override("font_size", 40)
	_back_btn.pressed.connect(_back_to_title)
	_back_btn.pressed.connect(_click_sfx.play)
	vb.add_child(_back_btn)


func _on_tap(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_advance()


func _advance() -> void:
	if _phase == "done" or _choices.visible:
		return
	_idx += 1
	if _idx < _lines.size():
		_label.text = _lines[_idx]
		_click_sfx.play()
		return
	if _phase == "main":
		_hint.visible = false
		_label.text = "她看着你，等一个回答。"
		_choices.visible = true
	else:
		_phase = "done"
		_back_btn.visible = true


func _on_choice(choice_a: bool) -> void:
	GameState.mark_ending_seen()
	_choices.visible = false
	_phase = "epilogue"
	_lines = _data.get("a_lines" if choice_a else "b_lines", [])
	_idx = -1
	_advance()


func _back_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
