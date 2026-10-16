extends Node2D
## 《炎烬之誓》战斗场景：回合制战棋主循环（第一章原型）

const TILE := 64

enum S { STORY, IDLE, MOVE_SEL, ACTION_MENU, WEAPON_SEL, TARGET_SEL, ITEM_MENU, COMBAT, ENEMY, OVER }

var state: int = S.STORY
var board: Board
var cursor: MapCursor
var units: Array = []
var turn := 1
var gold := 0
var chapter := Chapter1.new()
var support_points := {}          # {支援对 key: 点数}

var selected: Unit = null
var sel_weapon := 0
var move_dict: Dictionary = {}
var pre_move_pos := Vector2i.ZERO
var targets: Array = []
var danger_on := false

# ---- UI ----
var ui: CanvasLayer
var lbl_chapter: Label
var lbl_turn: Label
var lbl_gold: Label
var btn_threat: Button
var info_label: Label
var info_portrait_frame: Panel
var info_portrait: TextureRect
var hint_label: Label
var toast_label: Label
var banner_label: Label
var menu_panel: PanelContainer
var menu_box: VBoxContainer
var forecast_panel: PanelContainer
var forecast_att: Label
var forecast_def: Label
var levelup_panel: PanelContainer
var levelup_label: Label
var end_overlay: ColorRect
var end_title: Label
var end_sub: Label
var end_btn: Button
var dialogue: DialogueBox
var combat_scene: CombatScene

var _forecast_target: Unit = null
var _banner_tween: Tween = null


func _ready() -> void:
	chapter.battle = self
	_build_board()
	_build_units()
	_build_ui()
	Audio.play_music("map")
	_start_chapter.call_deferred()


# ==================== 构建 ====================

func _build_board() -> void:
	board = Board.new()
	board.position = Vector2(0, 48)
	board.units = units
	add_child(board)
	board.load_map(chapter.MAP, chapter.LEVELS, chapter.BG)
	cursor = MapCursor.new()
	cursor.set_grid(Vector2i(4, 3))
	board.add_child(cursor)


func _build_units() -> void:
	spawn_units(chapter.UNITS)


func spawn_units(defs: Array) -> void:
	for def in Chapter1.expand(defs):
		var u := Unit.new()
		u.setup(def)
		if board.unit_at(u.grid_pos) != null:
			u.grid_pos = _nearest_free(u.grid_pos)
			u.position = u.tile_center()
		board.add_child(u)
		units.append(u)
	update_topbar()


func _nearest_free(p: Vector2i) -> Vector2i:
	for r in range(1, 6):
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var np := Vector2i(p.x + dx, p.y + dy)
				if board.in_bounds(np) and board.terrain(np)["pass"] and board.unit_at(np) == null:
					return np
	return p


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	# GBA 风暖色滤镜（微降饱和）
	var tint := ColorRect.new()
	tint.color = Color(1.0, 0.88, 0.66, 0.05)
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(tint)
	# 顶栏占住上安全区；贴边的主操作再内缩 EDGE_ACTION
	var top := Panel.new()
	top.position = Vector2.ZERO
	top.size = Vector2(1280, SafeArea.MARGIN_Y)
	_style_panel(top, Color(0.08, 0.10, 0.16, 0.95))
	ui.add_child(top)
	lbl_chapter = _make_label(top, Vector2(SafeArea.MARGIN_X, 12), tr("第一章 · 边境的少女"), 22)
	lbl_chapter.name = "ChapterLabel"
	lbl_turn = _make_label(top, Vector2(SafeArea.MARGIN_X, 12), "", 22)
	lbl_turn.name = "TurnLabel"
	lbl_gold = _make_label(top, Vector2(SafeArea.MARGIN_X, 12), "", 22)
	lbl_gold.name = "GoldLabel"
	var end_size := Vector2(156, SafeArea.MIN_HIT)
	# 「Threat Range (T)」在 210 宽里刚好放下，不要再加长。
	var danger_size := Vector2(210, SafeArea.MIN_HIT)
	var end_pos := Vector2(1280.0 - SafeArea.EDGE_ACTION - end_size.x, 0)
	var danger_pos := Vector2(end_pos.x - 8 - danger_size.x, 0)
	btn_threat = _make_button(tr("危险范围 (T)"), danger_pos, danger_size, toggle_danger)
	btn_threat.name = "ThreatButton"
	top.add_child(btn_threat)
	var btn_end := _make_button(tr("回合结束"), end_pos, end_size, on_end_turn)
	btn_end.name = "EndTurnButton"
	top.add_child(btn_end)
	update_topbar()
	# 右侧信息栏
	var side := Panel.new()
	side.position = Vector2(960, 48)
	side.size = Vector2(320, 640)
	_style_panel(side, Color(0.08, 0.10, 0.16, 0.92))
	ui.add_child(side)
	# 立绘框（默认隐藏）
	info_portrait_frame = Panel.new()
	info_portrait_frame.position = Vector2(16, 16)
	info_portrait_frame.size = Vector2(128, 128)
	info_portrait_frame.visible = false
	var ipb := StyleBoxFlat.new()
	ipb.bg_color = Color(0.10, 0.13, 0.22)
	ipb.border_color = Color(0.85, 0.75, 0.45)
	ipb.set_border_width_all(2)
	ipb.set_corner_radius_all(6)
	info_portrait_frame.add_theme_stylebox_override("panel", ipb)
	side.add_child(info_portrait_frame)
	info_portrait = TextureRect.new()
	info_portrait.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	info_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	info_portrait_frame.add_child(info_portrait)
	info_label = _make_label(side, Vector2(16, 16), "", 20)
	info_label.size = Vector2(320 - 16 - SafeArea.MARGIN_X, 600)
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# 底部提示栏
	var bottom := Panel.new()
	bottom.position = Vector2(0, 688)
	bottom.size = Vector2(1280, 32)
	_style_panel(bottom, Color(0.08, 0.10, 0.16, 0.95))
	ui.add_child(bottom)
	hint_label = _make_label(bottom, Vector2(SafeArea.MARGIN_X, 3), "", 18)
	hint_label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	# 中央阶段横幅
	banner_label = Label.new()
	banner_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	banner_label.position = Vector2(0, 290)
	banner_label.size = Vector2(1280, 90)
	banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_label.add_theme_font_size_override("font_size", 56)
	banner_label.modulate.a = 0.0
	ui.add_child(banner_label)
	# 顶部 toast
	toast_label = Label.new()
	toast_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	toast_label.position = Vector2(0, 58)
	toast_label.size = Vector2(1280, 36)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 24)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	toast_label.modulate.a = 0.0
	ui.add_child(toast_label)
	# 行动菜单
	menu_panel = PanelContainer.new()
	menu_panel.visible = false
	var msb := StyleBoxFlat.new()
	msb.bg_color = Color(0.10, 0.13, 0.22, 0.97)
	msb.border_color = Color(0.85, 0.75, 0.45)
	msb.set_border_width_all(2)
	msb.set_corner_radius_all(6)
	msb.content_margin_left = 8
	msb.content_margin_right = 8
	msb.content_margin_top = 8
	msb.content_margin_bottom = 8
	menu_panel.add_theme_stylebox_override("panel", msb)
	menu_box = VBoxContainer.new()
	menu_panel.add_child(menu_box)
	ui.add_child(menu_panel)
	_build_forecast_panel()
	_build_levelup_panel()
	_build_end_overlay()
	dialogue = DialogueBox.new()
	ui.add_child(dialogue)
	combat_scene = CombatScene.new()
	add_child(combat_scene)


func _build_forecast_panel() -> void:
	forecast_panel = PanelContainer.new()
	forecast_panel.position = Vector2(340, 190)
	forecast_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.16, 0.97)
	sb.border_color = Color(0.85, 0.75, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	forecast_panel.add_theme_stylebox_override("panel", sb)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	forecast_panel.add_child(vb)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(hb)
	forecast_att = Label.new()
	forecast_att.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	forecast_att.custom_minimum_size = Vector2(250, 0)
	forecast_att.add_theme_font_size_override("font_size", 21)
	hb.add_child(forecast_att)
	var vs := Label.new()
	vs.text = "VS"
	vs.custom_minimum_size = Vector2(70, 0)
	vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vs.add_theme_font_size_override("font_size", 30)
	vs.add_theme_color_override("font_color", Color(1.0, 0.75, 0.3))
	hb.add_child(vs)
	forecast_def = Label.new()
	forecast_def.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	forecast_def.custom_minimum_size = Vector2(250, 0)
	forecast_def.add_theme_font_size_override("font_size", 21)
	hb.add_child(forecast_def)
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_row.add_theme_constant_override("separation", 24)
	vb.add_child(btn_row)
	var ok := Button.new()
	ok.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	ok.text = tr("确认攻击")
	ok.custom_minimum_size = Vector2(168, SafeArea.MIN_HIT)
	ok.pressed.connect(_on_forecast_ok)
	btn_row.add_child(ok)
	var cancel := Button.new()
	cancel.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	cancel.text = tr("取消")
	cancel.custom_minimum_size = Vector2(168, SafeArea.MIN_HIT)
	cancel.pressed.connect(_on_forecast_cancel)
	btn_row.add_child(cancel)
	ui.add_child(forecast_panel)


func _build_levelup_panel() -> void:
	levelup_panel = PanelContainer.new()
	levelup_panel.position = Vector2(490, 240)
	levelup_panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.10, 0.97)
	sb.border_color = Color(0.6, 0.9, 0.5)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 28
	sb.content_margin_right = 28
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	levelup_panel.add_theme_stylebox_override("panel", sb)
	levelup_label = Label.new()
	levelup_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	levelup_label.add_theme_font_size_override("font_size", 24)
	levelup_panel.add_child(levelup_label)
	ui.add_child(levelup_panel)


func _build_end_overlay() -> void:
	end_overlay = ColorRect.new()
	end_overlay.color = Color(0, 0, 0, 0.85)
	end_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	end_overlay.visible = false
	ui.add_child(end_overlay)
	end_title = Label.new()
	end_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_title.position = Vector2(0, 210)
	end_title.size = Vector2(1280, 90)
	end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_title.add_theme_font_size_override("font_size", 64)
	end_overlay.add_child(end_title)
	end_sub = Label.new()
	end_sub.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_sub.position = Vector2(0, 330)
	end_sub.size = Vector2(1280, 40)
	end_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_sub.add_theme_font_size_override("font_size", 26)
	end_sub.add_theme_color_override("font_color", Color(0.8, 0.78, 0.72))
	end_overlay.add_child(end_sub)
	end_btn = Button.new()
	end_btn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	end_btn.custom_minimum_size = Vector2(220, maxi(56, SafeArea.MIN_HIT))
	end_btn.position = Vector2(530, 460)
	end_btn.add_theme_font_size_override("font_size", 26)
	end_overlay.add_child(end_btn)


func _style_panel(p: Panel, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	p.add_theme_stylebox_override("panel", sb)


func _make_label(parent: Node, pos: Vector2, text: String, size: int) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.position = pos
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l


func _make_button(text: String, pos: Vector2, min_size: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.text = text
	b.position = pos
	b.custom_minimum_size = min_size
	b.size = min_size
	b.pressed.connect(cb)
	return b


# ==================== 章节流程 ====================

func _start_chapter() -> void:
	state = S.STORY
	update_topbar()
	await chapter.on_battle_start()
	start_player_phase(true)


func start_player_phase(first := false) -> void:
	for u in units:
		if u.is_player() and u.is_alive():
			u.has_acted = false
			u.queue_redraw()
	if not first:
		turn += 1
	state = S.STORY
	update_topbar()
	Audio.play_sfx("phase")
	show_banner(tr("第 %d 回合 · 我方回合") % turn, Color(0.45, 0.7, 1.0))
	_gain_support_points()
	await chapter.on_turn_start(turn)
	if state == S.OVER:
		return
	state = S.IDLE
	hint(tr("点击我方单位行动 · 点击敌人查看其威胁范围"))
	_update_hover_info()


func enemy_phase() -> void:
	if state == S.OVER:
		return
	state = S.ENEMY
	_clear_menu()
	forecast_panel.visible = false
	selected = null
	danger_on = false
	board.set_danger({})
	board.clear_highlights()
	update_topbar()
	Audio.play_sfx("phase", 0.85)
	show_banner(tr("敌方回合"), Color(1.0, 0.45, 0.4))
	await get_tree().create_timer(0.9).timeout
	for e in units.duplicate():
		if state == S.OVER:
			return
		if e.is_player() or not e.is_alive():
			continue
		var players: Array = units.filter(func(x) -> bool: return x.is_player() and x.is_alive())
		if players.is_empty():
			return
		var act: Dictionary = EnemyAI.choose(e, board, players)
		var mv: Vector2i = act["move_to"]
		if mv != e.grid_pos:
			var erange := board.move_range(e)
			var path := board.find_path(e, mv, erange)
			await _animate_move(e, path)
			e.grid_pos = mv
			e.position = e.tile_center()
		if act.get("target") != null:
			await do_combat(e, act["target"], act.get("weapon", 0))
			if state == S.OVER:
				return
		e.has_acted = true
		e.queue_redraw()
		await get_tree().create_timer(0.12).timeout
	start_player_phase()


# ==================== 输入 ====================

func _unhandled_input(event: InputEvent) -> void:
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	if PointerInput.is_pointer_move(event):
		var p := board.tile_at_viewport(PointerInput.viewport_position(event))
		if board.in_bounds(p) and p != cursor.grid_pos:
			cursor.set_grid(p)
			_on_cursor_moved()
	elif PointerInput.is_primary_press(event):
		click_tile(board.tile_at_viewport(PointerInput.viewport_position(event)))
	elif PointerInput.is_secondary_press(event):
		cancel()
	elif event.is_action_pressed("ui_accept"):
		click_tile(cursor.grid_pos)
	elif event.is_action_pressed("ui_cancel"):
		cancel()
	elif event.is_action_pressed("ui_up"):
		_move_cursor(Vector2i(0, -1))
	elif event.is_action_pressed("ui_down"):
		_move_cursor(Vector2i(0, 1))
	elif event.is_action_pressed("ui_left"):
		_move_cursor(Vector2i(-1, 0))
	elif event.is_action_pressed("ui_right"):
		_move_cursor(Vector2i(1, 0))
	elif event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_T:
		toggle_danger()


func _move_cursor(d: Vector2i) -> void:
	var np := cursor.grid_pos + d
	if board.in_bounds(np):
		cursor.set_grid(np)
		_on_cursor_moved()


func _on_cursor_moved() -> void:
	_update_hover_info()
	Audio.play_sfx("cursor")
	if state == S.MOVE_SEL and selected != null:
		if move_dict.has(cursor.grid_pos):
			board.set_path(board.find_path(selected, cursor.grid_pos, move_dict))
		else:
			board.set_path([])


func click_tile(p: Vector2i) -> void:
	if not board.in_bounds(p):
		return
	match state:
		S.IDLE:
			_idle_click(p)
		S.MOVE_SEL:
			_move_click(p)
		S.TARGET_SEL:
			_target_click(p)


func cancel() -> void:
	Audio.play_sfx("cancel")
	match state:
		S.MOVE_SEL:
			_deselect()
		S.ACTION_MENU:
			_cancel_action_menu()
		S.WEAPON_SEL:
			_open_action_menu(selected)
		S.TARGET_SEL:
			forecast_panel.visible = false
			_open_action_menu(selected)
		S.ITEM_MENU:
			_open_action_menu(selected)
		S.IDLE:
			board.clear_highlights()


# ==================== 选择与移动 ====================

func _idle_click(p: Vector2i) -> void:
	var u := board.unit_at(p)
	if u == null:
		board.clear_highlights()
		return
	if u.is_player() and not u.has_acted:
		select_unit(u)
	elif not u.is_player():
		_preview_enemy(u)
	else:
		_update_hover_info()


func select_unit(u: Unit) -> void:
	selected = u
	Audio.play_sfx("select")
	pre_move_pos = u.grid_pos
	sel_weapon = 0
	move_dict = board.move_range(u)
	var atk := board.full_attack_area(u, move_dict)
	for t in move_dict:
		atk.erase(t)
	board.show_move(move_dict, atk)
	state = S.MOVE_SEL
	hint(tr("%s：选择移动位置（右键取消）") % tr(u.display_name))
	_update_hover_info()


func _deselect() -> void:
	selected = null
	move_dict = {}
	board.clear_highlights()
	state = S.IDLE
	hint(tr("点击我方单位行动 · 点击敌人查看其威胁范围"))


func _move_click(p: Vector2i) -> void:
	if selected == null:
		state = S.IDLE
		return
	if move_dict.has(p):
		_player_move(selected, p)
		return
	var u := board.unit_at(p)
	if u != null and u.is_player() and not u.has_acted and u != selected:
		select_unit(u)
	else:
		cancel()


func _player_move(u: Unit, dst: Vector2i) -> void:
	state = S.COMBAT
	Audio.play_sfx("move")
	board.clear_highlights()
	board.set_path([])
	var path := board.find_path(u, dst, move_dict)
	await _animate_move(u, path)
	u.grid_pos = dst
	u.position = u.tile_center()
	_open_action_menu(u)


func _animate_move(u: Unit, path: Array) -> void:
	if path.is_empty():
		return
	var t := create_tween()
	for step in path:
		t.tween_property(u, "position", Vector2(step) * TILE + Vector2(TILE / 2.0, TILE / 2.0), 0.11)
	await t.finished


func _preview_enemy(u: Unit) -> void:
	var move := board.move_range(u)
	var area := board.full_attack_area(u, move)
	for t in move:
		area[t] = true
	board.show_move({}, area)
	hint(tr("%s 的威胁范围（右键清除）") % tr(u.display_name))
	_update_hover_info()


# ==================== 行动菜单 ====================

## 回合开始时：相邻的支援对 +1 点数
func _gain_support_points() -> void:
	for key in chapter.SUPPORTS:
		var pair: Array = String(key).split("|")
		var a := get_unit(pair[0])
		var b := get_unit(pair[1])
		if a == null or b == null or not a.is_alive() or not b.is_alive():
			continue
		if GameData.dist(a.grid_pos, b.grid_pos) != 1:
			continue
		var need: int = chapter.SUPPORTS[key]["points_to_c"]
		if support_points.get(key, 0) < need:
			support_points[key] = support_points.get(key, 0) + 1
			if support_points[key] == need:
				notify(tr("%s 与 %s 的羁绊加深了……（相邻时可用【支援】）") % [tr(a.display_name), tr(b.display_name)])


func _open_action_menu(u: Unit) -> void:
	state = S.ACTION_MENU
	Audio.play_sfx("select")
	var opts: Array = []
	opts.append({"label": tr("攻击"), "enabled": not find_targets(u, -1).is_empty(), "cb": _on_menu_attack})
	if board.tile_at(u.grid_pos) == "H" and not chapter.visited.has(u.grid_pos):
		opts.append({"label": tr("访问"), "enabled": true, "cb": _on_menu_visit})
	if chapter.get_talk_partner(u) != null:
		opts.append({"label": tr("对话"), "enabled": true, "cb": _on_menu_talk})
	if chapter.get_support_partner(u) != null:
		opts.append({"label": tr("支援"), "enabled": true, "cb": _on_menu_support})
	if chapter.get_recruit_target(u) != null:
		opts.append({"label": tr("说得"), "enabled": true, "cb": _on_menu_recruit})
	if not u.items.is_empty():
		opts.append({"label": tr("道具"), "enabled": true, "cb": _on_menu_item})
	opts.append({"label": tr("待机"), "enabled": true, "cb": _on_menu_wait})
	_fill_menu(opts)
	_place_menu(u)
	hint(tr("选择行动（右键返回移动）"))


func _fill_menu(opts: Array) -> void:
	for c in menu_box.get_children():
		c.queue_free()
	for o in opts:
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.text = o["label"]
		b.custom_minimum_size = Vector2(170, SafeArea.MIN_HIT)
		b.disabled = not o["enabled"]
		b.pressed.connect(o["cb"])
		menu_box.add_child(b)
	menu_panel.visible = true


func _place_menu(u: Unit) -> void:
	var gp := u.get_global_position()
	var pos := gp + Vector2(44, -10)
	pos.x = clampf(pos.x, 8, 1280 - 200)
	pos.y = clampf(pos.y, 56, 620)
	menu_panel.position = pos


func _clear_menu() -> void:
	menu_panel.visible = false
	for c in menu_box.get_children():
		c.queue_free()


func _cancel_action_menu() -> void:
	_clear_menu()
	selected.grid_pos = pre_move_pos
	selected.position = selected.tile_center()
	move_dict = board.move_range(selected)
	var atk := board.full_attack_area(selected, move_dict)
	for t in move_dict:
		atk.erase(t)
	board.show_move(move_dict, atk)
	state = S.MOVE_SEL
	hint(tr("%s：选择移动位置（右键取消）") % tr(selected.display_name))


func _on_menu_attack() -> void:
	if selected.weapons.size() > 1:
		state = S.WEAPON_SEL
		var opts: Array = []
		for i in selected.weapons.size():
			var w: Dictionary = selected.weapon(i)
			var idx := i
			opts.append({
				"label": tr("%s (攻%d 命%d)") % [tr(w["name"]), w["mt"], w["hit"]],
				"enabled": not find_targets(selected, i).is_empty(),
				"cb": func() -> void: _on_weapon_chosen(idx),
			})
		_fill_menu(opts)
		hint(tr("选择武器（右键返回）"))
	else:
		sel_weapon = 0
		_enter_target_select()


func _on_weapon_chosen(idx: int) -> void:
	sel_weapon = idx
	_enter_target_select()


func _enter_target_select() -> void:
	targets = find_targets(selected, sel_weapon)
	if targets.is_empty():
		_open_action_menu(selected)
		return
	state = S.TARGET_SEL
	_clear_menu()
	var tiles := {}
	for t in targets:
		tiles[t.grid_pos] = true
	board.show_move({}, tiles)
	hint(tr("用【%s】选择攻击目标（右键返回）") % tr(selected.weapon(sel_weapon)["name"]))


func _target_click(p: Vector2i) -> void:
	var u := board.unit_at(p)
	if u != null and u in targets:
		_show_forecast(selected, u, sel_weapon)


func _on_menu_visit() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_visit(selected, selected.grid_pos)
	_finish_action(selected)


func _on_menu_talk() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_talk(selected)
	_finish_action(selected)


func _on_menu_support() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_support(selected)
	_finish_action(selected)


func _on_menu_recruit() -> void:
	_clear_menu()
	state = S.COMBAT
	await chapter.on_recruit(selected)
	_finish_action(selected)


func _on_menu_item() -> void:
	state = S.ITEM_MENU
	var opts: Array = []
	for i in selected.items.size():
		var item: Dictionary = GameData.ITEMS[selected.items[i]]
		var idx := i
		opts.append({"label": tr("%s（%s）") % [tr(item["name"]), tr(item["desc"])], "enabled": true, "cb": func() -> void: _on_use_item(idx)})
	_fill_menu(opts)
	hint(tr("选择要使用的道具（右键返回）"))


func _on_use_item(idx: int) -> void:
	var item: Dictionary = GameData.ITEMS[selected.items[idx]]
	selected.items.remove_at(idx)
	selected.heal(item["heal"])
	Audio.play_sfx("heal")
	_float_text(selected, "HP +%d" % item["heal"], Color(0.5, 1.0, 0.5))
	_clear_menu()
	_finish_action(selected)


func _on_menu_wait() -> void:
	_clear_menu()
	_finish_action(selected)


func _finish_action(u: Unit) -> void:
	u.has_acted = true
	u.queue_redraw()
	board.clear_highlights()
	selected = null
	if state == S.OVER:
		return
	state = S.IDLE
	_update_hover_info()
	after_player_action()


func after_player_action() -> void:
	update_topbar()
	for u in units:
		if u.is_player() and u.is_alive() and not u.has_acted:
			hint(tr("点击我方单位行动"))
			return
	hint(tr("全军行动完毕……"))
	await get_tree().create_timer(0.6).timeout
	if state == S.IDLE:
		enemy_phase()


func on_end_turn() -> void:
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	_clear_menu()
	forecast_panel.visible = false
	selected = null
	board.clear_highlights()
	enemy_phase()


func toggle_danger() -> void:
	if state == S.STORY or state == S.COMBAT or state == S.ENEMY or state == S.OVER:
		return
	danger_on = not danger_on
	board.set_danger(_compute_danger() if danger_on else {})


func _compute_danger() -> Dictionary:
	var all := {}
	for e in units:
		if e.is_player() or not e.is_alive():
			continue
		var move := board.move_range(e)
		for t in move:
			all[t] = true
		var area := board.full_attack_area(e, move)
		for t in area:
			all[t] = true
	return all


# ==================== 战斗 ====================

func find_targets(u: Unit, wi: int) -> Array:
	var out: Array = []
	for e in units:
		if e.is_player() == u.is_player() or not e.is_alive():
			continue
		var d: int = GameData.dist(u.grid_pos, e.grid_pos)
		if wi == -1:
			for i in u.weapons.size():
				if board.can_hit_from(u, d, i):
					out.append(e)
					break
		elif board.can_hit_from(u, d, wi):
			out.append(e)
	return out


func _show_forecast(att: Unit, def: Unit, wi: int) -> void:
	_forecast_target = def
	var f: Dictionary = Combat.forecast(att, def, wi, board)
	forecast_att.text = _forecast_text(att, att.weapon(wi), f["a_dmg"], f["a_hit"], f["a_times"], f["a_crit"])
	if f["d_can"]:
		var dwi: int = def.counter_weapon(GameData.dist(att.grid_pos, def.grid_pos))
		forecast_def.text = _forecast_text(def, def.weapon(dwi), f["d_dmg"], f["d_hit"], f["d_times"], f["d_crit"])
	else:
		forecast_def.text = _forecast_text(def, def.weapon(), 0, 0, 0, 0) + "\n" + tr("（无法反击）")
	forecast_panel.visible = true


func _forecast_text(u: Unit, w: Dictionary, dmg: int, hit: int, times: int, crit: int) -> String:
	var wname := tr(str(w.get("name", "")))
	var s := tr("%s  Lv%d %s") % [tr(u.display_name), u.level, tr(u.class_label)]
	s += "\nHP %d/%d" % [u.hp, u.max_hp]
	s += "\n" + wname
	s += "\n" + (tr("攻击 %d") % dmg)
	if times == 2:
		s += "×2"
	s += "\n" + (tr("命中 %d   必杀 %d") % [hit, crit])
	return s


func _on_forecast_ok() -> void:
	forecast_panel.visible = false
	if _forecast_target != null and selected != null:
		do_combat(selected, _forecast_target, sel_weapon)


func _on_forecast_cancel() -> void:
	forecast_panel.visible = false


func do_combat(att: Unit, def: Unit, wi: int) -> void:
	state = S.COMBAT
	_clear_menu()
	board.clear_highlights()
	await chapter.on_before_combat(att, def)
	state = S.COMBAT
	var events := Combat.resolve(att, def, wi, board)
	await combat_scene.play(att, def, wi, events, board.tile_at(def.grid_pos))
	for u in [att, def]:
		if not u.is_alive() and u.visible:
			await _death_anim(u)
	if att.is_alive() and att.is_player():
		var xp: int = Combat.xp_gain(att, def, not def.is_alive())
		await _give_xp(att, xp)
	await chapter.on_after_combat(att, def, not def.is_alive())
	if await check_end_conditions():
		return
	att.has_acted = true
	att.queue_redraw()
	if att.is_player():
		selected = null
		state = S.IDLE
		_update_hover_info()
		after_player_action()
	else:
		state = S.ENEMY


func _give_xp(u: Unit, n: int) -> void:
	var res: Dictionary = u.gain_xp(n)
	_float_text(u, "EXP +%d" % n, Color(0.6, 0.9, 1.0))
	await get_tree().create_timer(0.35).timeout
	if res.is_empty():
		return
	Audio.play_sfx("levelup")
	var lines: Array = [tr("%s 升级了！  Lv %d") % [tr(u.display_name), res["level"]], ""]
	var gains: Dictionary = res["gains"]
	if gains.is_empty():
		lines.append(tr("（能力没有提升……）"))
	else:
		var names := {"hp": "HP", "pwr": tr("力量"), "skl": tr("技巧"), "spd": tr("速度"), "dfn": tr("守备")}
		for k in gains:
			lines.append("%s +1" % names[k])
	levelup_label.text = "\n".join(PackedStringArray(lines))
	levelup_panel.visible = true
	await get_tree().create_timer(1.5).timeout
	levelup_panel.visible = false


# ==================== 胜负 ====================

func check_end_conditions() -> bool:
	var tia := get_unit("tia")
	var balto := get_unit("balto")
	if tia == null or not tia.is_alive() or balto == null or not balto.is_alive():
		await _game_over()
		return true
	for u in units:
		if not u.is_player() and u.is_alive():
			return false
	await _victory()
	return true


func _victory() -> void:
	state = S.OVER
	hide_banner()
	update_topbar()
	Audio.stop_music()
	Audio.play_sfx("victory")
	await get_tree().create_timer(0.7).timeout
	await chapter.on_victory()
	_show_end(tr("第一章 · 完"), tr("缇娅的身世之谜，才刚刚开始……"), tr("回到标题"), "res://scenes/title.tscn")


func _game_over() -> void:
	state = S.OVER
	hide_banner()
	Audio.stop_music()
	Audio.play_sfx("defeat")
	await get_tree().create_timer(0.6).timeout
	await chapter.on_defeat()
	_show_end(tr("战  败"), tr("灰岩村的命运，到此为止……"), tr("重试本章"), "res://scenes/battle.tscn")


func _show_end(title: String, sub: String, btn_text: String, scene: String) -> void:
	end_title.text = title
	end_sub.text = sub
	end_btn.text = btn_text
	for c in end_btn.pressed.get_connections():
		end_btn.pressed.disconnect(c["callable"])
	end_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file(scene))
	end_overlay.visible = true


func get_unit(id: String) -> Unit:
	for u in units:
		if u.unit_id == id:
			return u
	return null


# ==================== 表现 ====================

func play_dialogue(lines: Array) -> void:
	var prev := state
	state = S.STORY
	dialogue.play(lines)
	await dialogue.all_finished
	if state == S.STORY:
		state = prev


func hint(text: String) -> void:
	if hint_label != null:
		hint_label.text = text


func notify(text: String) -> void:
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.modulate.a = 1.0
	var t := create_tween()
	t.tween_interval(1.4)
	t.tween_property(toast_label, "modulate:a", 0.0, 0.5)


func show_banner(text: String, color: Color) -> void:
	if banner_label == null:
		return
	_stop_banner_tween()
	banner_label.visible = true
	banner_label.text = text
	banner_label.add_theme_color_override("font_color", color)
	banner_label.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_property(banner_label, "modulate:a", 1.0, 0.25)
	_banner_tween.tween_interval(0.8)
	_banner_tween.tween_property(banner_label, "modulate:a", 0.0, 0.4)


## 结算层是半透明黑底，相位横幅不关掉会从「战败」上透出来。
func hide_banner() -> void:
	if banner_label == null:
		return
	_stop_banner_tween()
	banner_label.modulate.a = 0.0
	banner_label.visible = false


func _stop_banner_tween() -> void:
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner_tween = null


func update_topbar() -> void:
	if lbl_turn == null or lbl_chapter == null or lbl_gold == null:
		return
	var phase := tr("敌方回合") if state == S.ENEMY else tr("我方回合")
	lbl_turn.text = tr("第 %d 回合 · %s") % [turn, phase]
	lbl_gold.text = tr("金钱 %d G") % gold
	_layout_topbar()


## 章节列先按中文标题宽 ×1.3 预留，当前文案更长时再加宽，然后排回合和金钱。
## 横坐标随文案走，避免英文标题顶到「Turn」。排不下时裁章节，不侵占回合或危险范围按钮。
func _layout_topbar() -> void:
	var gap := 16.0
	var row_h := 28.0
	var zh_w := _top_text_width("第一章 · 边境的少女")
	var chapter_w := _top_text_width(lbl_chapter.text)
	var slot := maxf(zh_w * 1.3, chapter_w)
	var player_w := _top_text_width(tr("第 %d 回合 · %s") % [turn, tr("我方回合")])
	var enemy_w := _top_text_width(tr("第 %d 回合 · %s") % [turn, tr("敌方回合")])
	var turn_w := maxf(player_w, enemy_w)
	var gold_w := _top_text_width(lbl_gold.text)
	var threat_left := btn_threat.position.x if btn_threat != null else 826.0
	var max_slot := threat_left - gap - turn_w - gap - gold_w - gap - SafeArea.MARGIN_X
	if slot > max_slot:
		slot = maxf(max_slot, 0.0)
	var shown := minf(chapter_w, slot)
	lbl_chapter.position = Vector2(SafeArea.MARGIN_X, 12)
	lbl_chapter.size = Vector2(shown, row_h)
	lbl_chapter.clip_text = chapter_w > shown + 0.5
	lbl_chapter.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS if lbl_chapter.clip_text else TextServer.OVERRUN_NO_TRIMMING
	var turn_x := SafeArea.MARGIN_X + slot + gap
	lbl_turn.position = Vector2(turn_x, 12)
	lbl_turn.size = Vector2(_top_text_width(lbl_turn.text), row_h)
	lbl_gold.position = Vector2(turn_x + turn_w + gap, 12)
	lbl_gold.size = Vector2(gold_w, row_h)


func _top_text_width(text: String) -> float:
	var font := lbl_chapter.get_theme_font("font")
	if font == null:
		return 0.0
	var font_size := lbl_chapter.get_theme_font_size("font_size")
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x


func add_gold(n: int) -> void:
	gold += n
	Audio.play_sfx("coin")
	update_topbar()


func _update_hover_info() -> void:
	if info_label == null:
		return
	var u: Unit = selected if selected != null else board.unit_at(cursor.grid_pos)
	if u != null:
		var portrait_key := _unit_portrait_key(u)
		if portrait_key != "":
			info_portrait.texture = load("res://art/portraits/%s.jpg" % portrait_key)
			info_portrait_frame.visible = true
			info_label.position = Vector2(16, 156)
		else:
			info_portrait_frame.visible = false
			info_label.position = Vector2(16, 16)
		info_label.text = _unit_info_text(u)
	else:
		info_portrait_frame.visible = false
		info_label.position = Vector2(16, 16)
		var t: Dictionary = board.terrain(cursor.grid_pos)
		var lv := board.level_at(cursor.grid_pos)
		info_label.text = tr("【%s】 高度 Lv%d") % [tr(t["name"]), lv] + "\n" + tr("守备 +%d   回避 +%d") % [t["dfn"], t["avo"]]


func _unit_portrait_key(u: Unit) -> String:
	match u.unit_id:
		"tia":
			return "portrait_tia"
		"balto":
			return "portrait_balto"
		"brock":
			return "portrait_brock"
	if u.unit_id.begins_with("bandit"):
		return "portrait_bandit"
	return ""


func _unit_info_text(u: Unit) -> String:
	var lines: Array = []
	var side := tr("我方") if u.is_player() else tr("敌方")
	lines.append(tr("%s  Lv%d %s（%s）") % [tr(u.display_name), u.level, tr(u.class_label), side])
	lines.append("HP %d/%d   EXP %d" % [u.hp, u.max_hp, u.xp])
	lines.append(tr("力 %d   技 %d   速 %d") % [u.pwr, u.skl, u.spd])
	lines.append(tr("守 %d   移 %d") % [u.dfn, u.mov])
	var wnames: Array = []
	for w in u.weapons:
		wnames.append(tr(GameData.WEAPONS[w]["name"]))
	lines.append(tr("武器：") + tr("、").join(PackedStringArray(wnames)))
	if not u.items.is_empty():
		var inames: Array = []
		for it in u.items:
			inames.append(tr(GameData.ITEMS[it]["name"]))
		lines.append(tr("道具：") + tr("、").join(PackedStringArray(inames)))
	return "\n".join(PackedStringArray(lines))


func _float_text(u: Unit, text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 22)
	l.add_theme_color_override("font_color", color)
	l.position = u.position + Vector2(-24, -52)
	board.add_child(l)
	var t := create_tween().set_parallel(true)
	t.tween_property(l, "position:y", l.position.y - 30, 0.8)
	t.tween_property(l, "modulate:a", 0.0, 0.8)
	t.finished.connect(l.queue_free)


func _death_anim(u: Unit) -> void:
	var t := create_tween().set_parallel(true)
	t.tween_property(u, "modulate:a", 0.0, 0.5)
	t.tween_property(u, "scale", Vector2(0.5, 0.5), 0.5)
	await t.finished
	u.visible = false
