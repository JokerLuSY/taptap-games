extends Control
## 关卡视图: 读 JSON 数据驱动一关的全部内容
## 流程: 进场旁白 -> 点击热点拿证据 -> 集齐必得证据 -> 线索板配对 -> 过关旁白

signal level_finished(level_id: int)

const BoardScene := preload("res://scenes/evidence_board.tscn")
const InventoryScene := preload("res://scenes/inventory_ui.tscn")

var level_data: Dictionary = {}
var _ev_by_id: Dictionary = {}
var _hotspots: Array = []
var _solved := false
var _pending_board_open := false
var _narr_token := 0

var _bg: TextureRect
var _hotspot_layer: Control
var _title_label: Label
var _narration: PanelContainer
var _narration_label: Label
var _board_button: Button
var _board: Control
var _inventory: Control
var _obtain_popup: PanelContainer
var _obtain_icon: TextureRect
var _obtain_name: Label
var _obtain_text: Label
var _settings_popup: PanelContainer
var _click_sfx: AudioStreamPlayer
var _success_sfx: AudioStreamPlayer


func _ready() -> void:
	_build_ui()
	GameState.hint_flash_requested.connect(_on_hint_flash)
	GameState.hint_board_requested.connect(_on_hint_board)
	load_level(GameState.current_level)


func _build_ui() -> void:
	_bg = TextureRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)

	_hotspot_layer = Control.new()
	_hotspot_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hotspot_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_hotspot_layer)

	_click_sfx = AudioStreamPlayer.new()
	_click_sfx.stream = load("res://audio/click.wav")
	add_child(_click_sfx)
	_success_sfx = AudioStreamPlayer.new()
	_success_sfx.stream = load("res://audio/success.wav")
	add_child(_success_sfx)

	# 顶栏: 关卡名 + 设置
	var top := HBoxContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_top = 24
	top.offset_left = 32
	top.offset_right = -32
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top)
	_title_label = Label.new()
	_title_label.add_theme_font_size_override("font_size", 44)
	_title_label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.96))
	top.add_child(_title_label)
	var spring := Control.new()
	spring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spring)
	var settings_btn := Button.new()
	settings_btn.text = GameState.ui_text("settings")
	settings_btn.add_theme_font_size_override("font_size", 36)
	settings_btn.pressed.connect(_open_settings)
	settings_btn.pressed.connect(_click_sfx.play)
	top.add_child(settings_btn)

	# 底栏: 背包 + 线索板
	var bottom := HBoxContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_bottom = -32
	bottom.offset_left = 32
	bottom.offset_right = -32
	bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	bottom.add_theme_constant_override("separation", 80)
	add_child(bottom)
	var inv_btn := Button.new()
	inv_btn.text = GameState.ui_text("inventory_title")
	inv_btn.custom_minimum_size = Vector2(360, 110)
	inv_btn.add_theme_font_size_override("font_size", 44)
	inv_btn.pressed.connect(_open_inventory)
	inv_btn.pressed.connect(_click_sfx.play)
	bottom.add_child(inv_btn)
	_board_button = Button.new()
	_board_button.text = GameState.ui_text("board_title")
	_board_button.custom_minimum_size = Vector2(360, 110)
	_board_button.add_theme_font_size_override("font_size", 44)
	_board_button.pressed.connect(open_board)
	_board_button.pressed.connect(_click_sfx.play)
	bottom.add_child(_board_button)

	# 旁白条
	_narration = PanelContainer.new()
	_narration.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_narration.offset_bottom = -170
	_narration.offset_top = -430
	_narration.offset_left = 40
	_narration.offset_right = -40
	_narration.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.045, 0.09, 0.88)))
	_narration.visible = false
	_narration.gui_input.connect(_on_narration_input)
	add_child(_narration)
	_narration_label = Label.new()
	_narration_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_narration_label.add_theme_font_size_override("font_size", 40)
	_narration_label.add_theme_color_override("font_color", Color(0.92, 0.93, 0.97))
	_narration.add_child(_narration_label)

	_build_obtain_popup()
	_build_settings_popup()

	_inventory = InventoryScene.instantiate()
	add_child(_inventory)
	_board = BoardScene.instantiate()
	add_child(_board)
	_board.solved.connect(_on_board_solved)
	_board.failed.connect(_on_board_failed)


func _build_obtain_popup() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_obtain_popup = PanelContainer.new()
	_obtain_popup.custom_minimum_size = Vector2(820, 0)
	_obtain_popup.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.07, 0.13, 0.98)))
	_obtain_popup.visible = false
	center.add_child(_obtain_popup)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 24)
	_obtain_popup.add_child(vb)
	_obtain_icon = TextureRect.new()
	_obtain_icon.custom_minimum_size = Vector2(220, 220)
	_obtain_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_obtain_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_obtain_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vb.add_child(_obtain_icon)
	_obtain_name = Label.new()
	_obtain_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_obtain_name.add_theme_font_size_override("font_size", 52)
	_obtain_name.add_theme_color_override("font_color", Color(1.0, 0.87, 0.62))
	vb.add_child(_obtain_name)
	_obtain_text = Label.new()
	_obtain_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_obtain_text.add_theme_font_size_override("font_size", 38)
	vb.add_child(_obtain_text)
	var take_btn := Button.new()
	take_btn.text = GameState.ui_text("take")
	take_btn.custom_minimum_size = Vector2(300, 96)
	take_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	take_btn.add_theme_font_size_override("font_size", 40)
	take_btn.pressed.connect(_close_obtain)
	take_btn.pressed.connect(_click_sfx.play)
	vb.add_child(take_btn)


func _build_settings_popup() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_settings_popup = PanelContainer.new()
	_settings_popup.custom_minimum_size = Vector2(640, 0)
	_settings_popup.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.07, 0.13, 0.98)))
	_settings_popup.visible = false
	center.add_child(_settings_popup)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 28)
	_settings_popup.add_child(vb)
	var title := Label.new()
	title.text = GameState.ui_text("settings")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	vb.add_child(title)
	var resume_btn := Button.new()
	resume_btn.text = GameState.ui_text("resume")
	resume_btn.custom_minimum_size = Vector2(440, 100)
	resume_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	resume_btn.add_theme_font_size_override("font_size", 40)
	resume_btn.pressed.connect(func() -> void: _settings_popup.visible = false)
	resume_btn.pressed.connect(_click_sfx.play)
	vb.add_child(resume_btn)
	var title_btn := Button.new()
	title_btn.text = GameState.ui_text("back_to_title")
	title_btn.custom_minimum_size = Vector2(440, 100)
	title_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_btn.add_theme_font_size_override("font_size", 40)
	title_btn.pressed.connect(_back_to_title)
	title_btn.pressed.connect(_click_sfx.play)
	vb.add_child(title_btn)


# ---------------- 关卡加载 ----------------

func load_level(level_id: int) -> void:
	_solved = false
	_pending_board_open = false
	GameState.set_level(level_id)
	var data: Variant = GameState.load_json("res://data/levels/level_%02d.json" % level_id)
	if typeof(data) != TYPE_DICTIONARY:
		push_error("关卡数据缺失: level_%02d" % level_id)
		return
	level_data = data
	_ev_by_id.clear()
	for ev in level_data.get("evidences", []):
		_ev_by_id[ev.get("id", "")] = ev

	_bg.texture = load(level_data.get("bg", ""))
	_title_label.text = GameState.ui_text("level_title_fmt") % [level_id, level_data.get("title", "")]

	for hs in _hotspots:
		hs.queue_free()
	_hotspots.clear()
	for h in level_data.get("hotspots", []):
		var hs := Hotspot.new()
		hs.setup(h)
		hs.pressed.connect(_on_hotspot_pressed)
		_hotspot_layer.add_child(hs)
		_hotspots.append(hs)

	_board.setup(level_data.get("board", {}), level_data.get("evidences", []))
	_inventory.setup(level_data.get("evidences", []))
	_board_button.modulate.a = 1.0

	GameState.notify_progress()
	show_narration(level_data.get("intro", ""), 6.0)


# ---------------- 热点 ----------------

func _on_hotspot_pressed(hs: Hotspot) -> void:
	var ev: Dictionary = _ev_by_id.get(hs.evidence_id, {})
	if ev.is_empty():
		return
	var obtain_text: String = ""
	for h in level_data.get("hotspots", []):
		if h.get("id") == hs.hotspot_id:
			obtain_text = h.get("obtain", "")
			break
	if GameState.is_collected(GameState.current_level, hs.evidence_id):
		_show_obtain(ev, ev.get("desc", ""))
		return
	GameState.collect(GameState.current_level, hs.evidence_id)
	_click_sfx.play()
	_inventory.refresh()
	_show_obtain(ev, obtain_text if obtain_text != "" else ev.get("desc", ""))
	if _all_required_collected() and not _solved:
		_pending_board_open = true


func _all_required_collected() -> bool:
	for hs in _hotspots:
		if hs.required and not GameState.is_collected(GameState.current_level, hs.evidence_id):
			return false
	return true


func _show_obtain(ev: Dictionary, text: String) -> void:
	_obtain_icon.texture = load(ev.get("icon", ""))
	_obtain_name.text = ev.get("name", "")
	_obtain_text.text = text
	_obtain_popup.visible = true


func _close_obtain() -> void:
	_obtain_popup.visible = false
	if _pending_board_open:
		_pending_board_open = false
		show_narration(GameState.ui_text("all_required_toast"), 2.0)
		await get_tree().create_timer(1.2).timeout
		open_board()


# ---------------- 线索板 ----------------

func open_board() -> void:
	_board.refresh_shelf()
	_board.visible = true


func _on_board_solved() -> void:
	if _solved:
		return
	_solved = true
	_board.visible = false
	_success_sfx.play()
	show_narration(level_data.get("board", {}).get("success_line", ""), 0.0)
	await get_tree().create_timer(2.4).timeout
	level_finished.emit(int(level_data.get("id", GameState.current_level)))


func _on_board_failed() -> void:
	show_narration(level_data.get("board", {}).get("fail_line", ""), 2.2)


# ---------------- 提示系统 ----------------

func _on_hint_flash() -> void:
	for hs in _hotspots:
		if not GameState.is_collected(GameState.current_level, hs.evidence_id):
			hs.flash_once()


func _on_hint_board() -> void:
	if _solved:
		return
	open_board()
	_board.highlight_correct_pair()


# ---------------- 旁白 / 弹窗 ----------------

func show_narration(text: String, auto_hide_sec: float) -> void:
	if text == "":
		return
	_narr_token += 1
	var token := _narr_token
	_narration_label.text = text
	_narration.visible = true
	_narration.modulate.a = 1.0
	if auto_hide_sec > 0.0:
		await get_tree().create_timer(auto_hide_sec).timeout
		if token == _narr_token:
			_hide_narration()


func _hide_narration() -> void:
	_narr_token += 1
	var t := create_tween()
	t.tween_property(_narration, "modulate:a", 0.0, 0.3)
	t.tween_callback(func() -> void: _narration.visible = false)


func _on_narration_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_hide_narration()


func _open_inventory() -> void:
	_inventory.refresh()
	_inventory.visible = true


func _open_settings() -> void:
	_settings_popup.visible = true


func _back_to_title() -> void:
	GameState.stop_hint_timers()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _panel_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(16)
	sb.set_content_margin_all(32)
	sb.border_color = Color(0.35, 0.4, 0.55)
	sb.set_border_width_all(2)
	return sb
