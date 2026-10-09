extends Control
## 线索板: 证据图标手动拖拽到结论槽; 拖入即判定
## 规则: 槽位 i 由 solution[i] 的证据组合解开; 装饰证据永远配对失败

signal solved
signal failed

var _board_data: Dictionary = {}
var _ev_by_id: Dictionary = {}
var _slots: Array = []           ## {zone: PanelContainer, placed: Array[String], done: bool}
var _shelf: GridContainer
var _shelf_buttons: Dictionary = {}  ## ev_id -> Button
var _drag_preview: TextureRect = null
var _drag_ev_id: String = ""
var _solved := false
var _click_sfx: AudioStreamPlayer
var _fail_sfx: AudioStreamPlayer


func _ready() -> void:
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	_click_sfx = AudioStreamPlayer.new()
	_click_sfx.stream = load("res://audio/click.wav")
	add_child(_click_sfx)
	_fail_sfx = AudioStreamPlayer.new()
	_fail_sfx.stream = load("res://audio/fail.wav")
	add_child(_fail_sfx)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(960, 1500)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.07, 0.13, 0.97)))
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 28)
	panel.add_child(vbox)

	var head := HBoxContainer.new()
	vbox.add_child(head)
	var title := Label.new()
	title.text = GameState.ui_text("board_title")
	title.add_theme_font_size_override("font_size", 52)
	head.add_child(title)
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

	var slots_box := VBoxContainer.new()
	slots_box.add_theme_constant_override("separation", 24)
	slots_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(slots_box)
	_slots_container = slots_box

	vbox.add_child(HSeparator.new())

	_shelf = GridContainer.new()
	_shelf.columns = 4
	_shelf.add_theme_constant_override("h_separation", 20)
	_shelf.add_theme_constant_override("v_separation", 20)
	vbox.add_child(_shelf)


var _slots_container: VBoxContainer


func setup(board_data: Dictionary, evidences: Array) -> void:
	_board_data = board_data
	_ev_by_id.clear()
	for ev in evidences:
		_ev_by_id[ev.get("id", "")] = ev
	_solved = false
	_cancel_drag()
	_rebuild_slots()
	refresh_shelf()


func _rebuild_slots() -> void:
	for c in _slots_container.get_children():
		c.queue_free()
	_slots.clear()
	for i in _board_data.get("slots", []).size():
		var question: String = _board_data["slots"][i]
		var slot_panel := PanelContainer.new()
		slot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.12, 0.2, 1.0)))
		_slots_container.add_child(slot_panel)
		var vb := VBoxContainer.new()
		vb.add_theme_constant_override("separation", 12)
		slot_panel.add_child(vb)
		var q := Label.new()
		q.text = question
		q.add_theme_font_size_override("font_size", 44)
		q.add_theme_color_override("font_color", Color(1.0, 0.87, 0.62))
		vb.add_child(q)
		var zone := PanelContainer.new()
		zone.custom_minimum_size = Vector2(0, 170)
		zone.add_theme_stylebox_override("panel", _zone_style(Color(0.35, 0.4, 0.55)))
		vb.add_child(zone)
		var placed_box := HBoxContainer.new()
		placed_box.add_theme_constant_override("separation", 16)
		zone.add_child(placed_box)
		_slots.append({"zone": zone, "box": placed_box, "placed": [], "done": false})


## 货架: 本关已收集的证据(含装饰证据)
func refresh_shelf() -> void:
	for c in _shelf.get_children():
		c.queue_free()
	_shelf_buttons.clear()
	var got: Array = GameState.collected_of(GameState.current_level)
	for ev_id in got:
		if not _ev_by_id.has(ev_id):
			continue
		if _is_placed(ev_id):
			continue
		var ev: Dictionary = _ev_by_id[ev_id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(190, 190)
		b.icon = load(ev.get("icon", ""))
		b.expand_icon = true
		b.tooltip_text = ev.get("name", "")
		b.gui_input.connect(_on_shelf_gui_input.bind(ev_id, b))
		_shelf.add_child(b)
		_shelf_buttons[ev_id] = b


func _is_placed(ev_id: String) -> bool:
	for s in _slots:
		if ev_id in s.placed:
			return true
	return false


# ---------------- 手动拖拽 ----------------

func _on_shelf_gui_input(event: InputEvent, ev_id: String, btn: Button) -> void:
	if _solved:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		_begin_drag(ev_id, btn)


func _begin_drag(ev_id: String, btn: Button) -> void:
	_cancel_drag()
	_drag_ev_id = ev_id
	_drag_preview = TextureRect.new()
	_drag_preview.texture = btn.icon
	_drag_preview.custom_minimum_size = Vector2(170, 170)
	_drag_preview.size = Vector2(170, 170)
	_drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_drag_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_preview.modulate.a = 0.9
	add_child(_drag_preview)
	_drag_preview.global_position = get_global_mouse_position() - Vector2(85, 85)
	btn.modulate.a = 0.35


func _input(event: InputEvent) -> void:
	if _drag_preview == null:
		return
	if event is InputEventMouseMotion:
		_drag_preview.global_position = event.position - Vector2(85, 85)
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_end_drag(event.position)


func _end_drag(pos: Vector2) -> void:
	var ev_id := _drag_ev_id
	var btn: Button = _shelf_buttons.get(ev_id)
	if btn:
		btn.modulate.a = 1.0
	for i in _slots.size():
		var zone: PanelContainer = _slots[i].zone
		if zone.get_global_rect().has_point(pos):
			_drag_preview.queue_free()
			_drag_preview = null
			_try_place(ev_id, i)
			return
	_cancel_drag()


func _cancel_drag() -> void:
	if _drag_preview != null:
		_drag_preview.queue_free()
		_drag_preview = null
	if _drag_ev_id != "" and _shelf_buttons.has(_drag_ev_id):
		_shelf_buttons[_drag_ev_id].modulate.a = 1.0
	_drag_ev_id = ""


# ---------------- 配对判定 ----------------

func _try_place(ev_id: String, slot_idx: int) -> void:
	if _solved:
		return
	var slot: Dictionary = _slots[slot_idx]
	var solution: Array = _board_data.get("solution", [])
	var want: Array = solution[slot_idx] if slot_idx < solution.size() else []
	if ev_id in want and not slot.done:
		slot.placed.append(ev_id)
		var icon := TextureRect.new()
		icon.texture = load(_ev_by_id[ev_id].get("icon", ""))
		icon.custom_minimum_size = Vector2(130, 130)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot.box.add_child(icon)
		if _shelf_buttons.has(ev_id):
			_shelf_buttons[ev_id].queue_free()
			_shelf_buttons.erase(ev_id)
		_click_sfx.play()
		if _slot_complete(slot_idx):
			slot.done = true
			slot.zone.add_theme_stylebox_override("panel", _zone_style(Color(0.4, 0.85, 0.5)))
		if _all_slots_done():
			_solved = true
			await get_tree().create_timer(0.5).timeout
			solved.emit()
	else:
		_fail_sfx.play()
		_flash_zone_red(slot.zone)
		failed.emit()


func _slot_complete(slot_idx: int) -> bool:
	var want: Array = _board_data["solution"][slot_idx]
	for ev_id in want:
		if not ev_id in _slots[slot_idx].placed:
			return false
	return true


func _all_slots_done() -> bool:
	for s in _slots:
		if not s.done:
			return false
	return true


func _flash_zone_red(zone: PanelContainer) -> void:
	var normal := _zone_style(Color(0.35, 0.4, 0.55))
	var red := _zone_style(Color(0.9, 0.3, 0.3))
	zone.add_theme_stylebox_override("panel", red)
	var t := create_tween()
	t.tween_interval(0.45)
	t.tween_callback(func() -> void: zone.add_theme_stylebox_override("panel", normal))


## 卡关提示: 高亮一对正确组合(第一个未完成槽位 + 其一个已收集证据)
func highlight_correct_pair() -> void:
	for i in _slots.size():
		if _slots[i].done:
			continue
		var want: Array = _board_data["solution"][i]
		for ev_id in want:
			if GameState.is_collected(GameState.current_level, ev_id) and not ev_id in _slots[i].placed:
				_pulse(_slots[i].zone)
				if _shelf_buttons.has(ev_id):
					_pulse(_shelf_buttons[ev_id])
				return
		return


func _pulse(node: Control) -> void:
	var t := create_tween()
	for j in 3:
		t.tween_property(node, "modulate:a", 0.3, 0.3)
		t.tween_property(node, "modulate:a", 1.0, 0.3)


func _panel_style(bg: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(20)
	sb.set_content_margin_all(36)
	sb.border_color = Color(0.35, 0.4, 0.55)
	sb.set_border_width_all(2)
	return sb


func _zone_style(border: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.04, 0.08, 0.9)
	sb.set_corner_radius_all(12)
	sb.set_content_margin_all(16)
	sb.border_color = border
	sb.set_border_width_all(3)
	return sb
