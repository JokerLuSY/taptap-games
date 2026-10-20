extends Control
## 标题画面：暗色背景 + 上升的余烬粒子
## 新游戏 / 继续 / 章节选择 / 语言 / 菜单是 Button，鼠标点击与触摸共用 pressed。
## 已有存档时，新游戏先确认才会覆盖 user://save.cfg。
## 打到过第二章以后出现「章节选择」：回到某一章开场时的队伍重新打（之后的进度作废）。

var _embers: Array = []
var _title: Label
var _sub: Label
var _note: Label
var _start: Button
var _continue: Button
var _select: Button
var _select_overlay: ColorRect
var _select_label: Label
var _select_box: VBoxContainer
var _select_cancel: Button
var _lang: Button
var _menu: Button
var _system
var _confirm: ColorRect
var _confirm_label: Label
var _confirm_yes: Button
var _confirm_no: Button


func _ready() -> void:
	Audio.play_music("map")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.05)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var text_pos := Vector2(SafeArea.MARGIN_X, 170)
	var text_size := Vector2(1280 - SafeArea.MARGIN_X * 2, 120)
	_title = _label(84, Color(1.0, 0.62, 0.3), text_pos, text_size)
	_sub = _label(26, Color(0.8, 0.75, 0.7), Vector2(SafeArea.MARGIN_X, 305), Vector2(text_size.x, 40))

	# 缇娅立绘：源图 1024²。先定 280×360 的裁切框（右缘 1240≤1260），
	# 再让贴图按框适配，避免 IGNORE_SIZE 之前按原图尺寸从 (920,180) 铺出窗口。
	var portrait_box := Control.new()
	portrait_box.position = Vector2(960, 160)
	portrait_box.size = Vector2(280, 360)
	portrait_box.clip_contents = true
	portrait_box.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(portrait_box)

	var portrait := TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_FIT_HEIGHT_PROPORTIONAL
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = MOUSE_FILTER_IGNORE
	portrait.modulate = Color(1, 1, 1, 0.92)
	portrait.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	portrait_box.add_child(portrait)
	portrait.texture = load("res://art/portraits/portrait_tia.jpg")
	portrait.set_anchors_and_offsets_preset(PRESET_FULL_RECT)

	var frame := Panel.new()
	frame.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	frame.mouse_filter = MOUSE_FILTER_IGNORE
	var fb := StyleBoxFlat.new()
	fb.bg_color = Color(0, 0, 0, 0)
	fb.border_color = Color(0.85, 0.65, 0.35)
	fb.set_border_width_all(3)
	fb.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", fb)
	portrait_box.add_child(frame)

	_note = _label(18, Color(0.55, 0.52, 0.5), Vector2(SafeArea.MARGIN_X, 720 - SafeArea.MARGIN_Y - 28), Vector2(text_size.x, 28))

	for i in 24:
		var e := ColorRect.new()
		e.color = Color(1.0, randf_range(0.4, 0.7), 0.2, randf_range(0.35, 0.85))
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var s := randf_range(2.0, 5.0)
		e.size = Vector2(s, s)
		e.position = Vector2(randf_range(0, 1280), randf_range(200, 720))
		add_child(e)
		_embers.append({"node": e, "speed": randf_range(15.0, 55.0), "drift": randf_range(-14.0, 14.0)})

	var start_size := Vector2(240, maxf(64, SafeArea.MIN_HIT))
	_continue = Button.new()
	_continue.name = "ContinueButton"
	_continue.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_continue.custom_minimum_size = start_size
	_continue.size = start_size
	_continue.add_theme_font_size_override("font_size", 30)
	_continue.pressed.connect(_on_continue)
	_continue.visible = false
	add_child(_continue)

	_start = Button.new()
	_start.name = "StartButton"
	_start.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_start.custom_minimum_size = start_size
	_start.size = start_size
	_start.add_theme_font_size_override("font_size", 30)
	_start.pressed.connect(_on_start)
	add_child(_start)

	var sel_size := Vector2(240, maxf(56, SafeArea.MIN_HIT))
	_select = Button.new()
	_select.name = "ChapterSelectButton"
	_select.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_select.custom_minimum_size = sel_size
	_select.size = sel_size
	_select.add_theme_font_size_override("font_size", 26)
	_select.pressed.connect(_on_select)
	add_child(_select)

	var lang_size := Vector2(160, SafeArea.MIN_HIT)
	_lang = Button.new()
	_lang.name = "LangButton"
	_lang.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_lang.custom_minimum_size = lang_size
	_lang.size = lang_size
	_lang.position = Vector2(1280.0 - SafeArea.EDGE_ACTION - lang_size.x, SafeArea.MARGIN_Y)
	_lang.add_theme_font_size_override("font_size", 22)
	_lang.pressed.connect(_on_lang)
	add_child(_lang)

	var menu_size := Vector2(120, SafeArea.MIN_HIT)
	_menu = Button.new()
	_menu.name = "MenuButton"
	_menu.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_menu.custom_minimum_size = menu_size
	_menu.size = menu_size
	_menu.position = Vector2(SafeArea.MARGIN_X, SafeArea.MARGIN_Y)
	_menu.add_theme_font_size_override("font_size", 22)
	_menu.pressed.connect(_on_menu)
	add_child(_menu)

	_build_confirm()
	_build_select()
	_system = load("res://scripts/system_menu.gd").new()
	_system.show_title_button = false
	add_child(_system)
	if not get_tree().root.go_back_requested.is_connected(_on_android_back):
		get_tree().root.go_back_requested.connect(_on_android_back)

	if not GameLocale.locale_changed.is_connected(_apply_locale):
		GameLocale.locale_changed.connect(_apply_locale)
	_apply_locale(GameLocale.code)
	SafeArea.fit_scene(self)        # 宽屏手机：画面居中，底色铺满


func _label(size: int, color: Color, pos: Vector2, box: Vector2) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.position = pos
	l.size = box
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func _apply_locale(_code: String) -> void:
	_title.text = tr("炎烬之誓")
	_sub.text = tr("Emberflame Oath · 战棋原型")
	_note.text = tr("第一篇 · 灰烬之芽（第 1–7 章，原型 v0.3）")
	_start.text = tr("新游戏")
	_continue.text = tr("继续游戏")
	_select.text = tr("选择章节")
	_select_label.text = tr("从所选章节的开头重新打起，之后的进度会被覆盖。")
	_select_cancel.text = tr("取消")
	_fill_select()
	_lang.text = tr("LANG_SWITCH")
	_menu.text = tr("菜单")
	_confirm_label.text = tr("开始新游戏会覆盖当前存档，确定吗？")
	_confirm_yes.text = tr("确定")
	_confirm_no.text = tr("取消")
	_place_main_buttons()


func _place_main_buttons() -> void:
	var start_size := _start.size
	var start_x := clampf((1280.0 - start_size.x) * 0.5, SafeArea.EDGE_ACTION, 1280.0 - SafeArea.EDGE_ACTION - start_size.x)
	var has := CampaignSave.has_save() and not CampaignSave.is_cleared()
	_continue.visible = has
	if has:
		_continue.position = Vector2(start_x, 400)
		_start.position = Vector2(start_x, 484)
	else:
		_start.position = Vector2(start_x, 450)
	var sel_x := clampf((1280.0 - _select.size.x) * 0.5, SafeArea.EDGE_ACTION, 1280.0 - SafeArea.EDGE_ACTION - _select.size.x)
	_select.position = Vector2(sel_x, _start.position.y + start_size.y + 16)
	_select.visible = _reached_chapters().size() > 1


func _process(delta: float) -> void:
	for e in _embers:
		var n: ColorRect = e["node"]
		n.position.y -= e["speed"] * delta
		n.position.x += e["drift"] * delta
		if n.position.y < -10:
			n.position.y = 730
			n.position.x = randf_range(0, 1280)


func _on_lang() -> void:
	GameLocale.toggle()


func _on_menu() -> void:
	if _system.is_open():
		_system.close()
	else:
		_system.open()


func _on_start() -> void:
	if CampaignSave.has_save():
		_confirm.visible = true
		return
	_begin_new_game()


func _on_continue() -> void:
	if not CampaignSave.has_save():
		return
	load("res://scripts/battle.gd").queue_chapter(null)
	CampaignSave.request_continue()
	get_tree().change_scene_to_file("res://scenes/battle.tscn")


func _begin_new_game() -> void:
	_confirm.visible = false
	CampaignSave.clear()
	Campaign.reset()
	load("res://scripts/battle.gd").queue_chapter(null)
	get_tree().change_scene_to_file("res://scenes/narration.tscn")


func _on_android_back() -> void:
	if not is_inside_tree():
		return
	if not PointerInput.accept_back():
		return
	_handle_back()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _system.is_open():
		return
	if not PointerInput.accept_back():
		return
	_handle_back()


func _handle_back() -> void:
	if _system.is_open():
		_system.close()
		return
	if _confirm.visible:
		_confirm.visible = false
		return
	if _select_overlay.visible:
		_select_overlay.visible = false
		return
	_system.open()


func _build_confirm() -> void:
	_confirm = ColorRect.new()
	_confirm.name = "ConfirmOverlay"
	_confirm.color = Color(0, 0, 0, 0.72)
	_confirm.set_anchors_preset(PRESET_FULL_RECT)
	_confirm.visible = false
	_confirm.mouse_filter = MOUSE_FILTER_STOP
	add_child(_confirm)
	_confirm_label = Label.new()
	_confirm_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_confirm_label.position = Vector2(SafeArea.MARGIN_X, 250)
	_confirm_label.size = Vector2(1280 - SafeArea.MARGIN_X * 2, 80)
	_confirm_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_confirm_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_confirm_label.add_theme_font_size_override("font_size", 28)
	_confirm.add_child(_confirm_label)
	_confirm_yes = Button.new()
	_confirm_yes.name = "ConfirmButton"
	_confirm_yes.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_confirm_yes.custom_minimum_size = Vector2(180, SafeArea.MIN_HIT)
	_confirm_yes.size = _confirm_yes.custom_minimum_size
	_confirm_yes.position = Vector2(430, 380)
	_confirm_yes.add_theme_font_size_override("font_size", 24)
	_confirm_yes.pressed.connect(_begin_new_game)
	_confirm.add_child(_confirm_yes)
	_confirm_no = Button.new()
	_confirm_no.name = "ConfirmCancelButton"
	_confirm_no.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_confirm_no.custom_minimum_size = Vector2(180, SafeArea.MIN_HIT)
	_confirm_no.size = _confirm_no.custom_minimum_size
	_confirm_no.position = Vector2(670, 380)
	_confirm_no.add_theme_font_size_override("font_size", 24)
	_confirm_no.pressed.connect(func() -> void: _confirm.visible = false)
	_confirm.add_child(_confirm_no)


# ==================== 章节选择 ====================

## 存档里记过开场快照的章节（打到过的章节）
func _reached_chapters() -> Array:
	if not CampaignSave.has_save():
		return []
	var payload := CampaignSave.read()
	var c = payload.get("campaign", null)
	if not c is Dictionary:
		return [0]
	var starts = c.get("starts", {})
	var out: Array = []
	if starts is Dictionary:
		for k in starts:
			var i := int(k)
			if i < Campaign.chapter_count():
				out.append(i)
	out.sort()
	return out


func _build_select() -> void:
	_select_overlay = ColorRect.new()
	_select_overlay.name = "SelectOverlay"
	_select_overlay.color = Color(0, 0, 0, 0.82)
	_select_overlay.set_anchors_preset(PRESET_FULL_RECT)
	_select_overlay.visible = false
	_select_overlay.mouse_filter = MOUSE_FILTER_STOP
	add_child(_select_overlay)
	_select_label = Label.new()
	_select_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_select_label.position = Vector2(SafeArea.MARGIN_X, 90)
	_select_label.size = Vector2(1280 - SafeArea.MARGIN_X * 2, 40)
	_select_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_select_label.add_theme_font_size_override("font_size", 22)
	_select_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.72))
	_select_overlay.add_child(_select_label)
	_select_box = VBoxContainer.new()
	_select_box.position = Vector2(400, 150)
	_select_box.size = Vector2(480, 400)
	_select_box.add_theme_constant_override("separation", 10)
	_select_overlay.add_child(_select_box)
	_select_cancel = Button.new()
	_select_cancel.name = "SelectCancelButton"
	_select_cancel.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_select_cancel.custom_minimum_size = Vector2(200, SafeArea.MIN_HIT)
	_select_cancel.size = _select_cancel.custom_minimum_size
	_select_cancel.position = Vector2(540, 720 - SafeArea.MARGIN_Y - SafeArea.MIN_HIT - 12)
	_select_cancel.add_theme_font_size_override("font_size", 24)
	_select_cancel.pressed.connect(func() -> void: _select_overlay.visible = false)
	_select_overlay.add_child(_select_cancel)


func _fill_select() -> void:
	if _select_box == null:
		return
	for c in _select_box.get_children():
		c.queue_free()
	for i in _reached_chapters():
		var b := Button.new()
		b.name = "SelectChapter%d" % (i + 1)
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.custom_minimum_size = Vector2(480, maxf(56, SafeArea.MIN_HIT))
		b.add_theme_font_size_override("font_size", 24)
		b.text = tr(str(Campaign.chapter_script(i).CHAPTER_TITLE))
		var idx: int = i
		b.pressed.connect(func() -> void: _start_from_chapter(idx))
		_select_box.add_child(b)


func _on_select() -> void:
	_fill_select()
	_select_overlay.visible = true


func _start_from_chapter(idx: int) -> void:
	Campaign.load_payload(CampaignSave.read())
	if not Campaign.restore_start(idx):
		return
	CampaignSave.write_chapter_start()
	load("res://scripts/battle.gd").queue_chapter(null)
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
