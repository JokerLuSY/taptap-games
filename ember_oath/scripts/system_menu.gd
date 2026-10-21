extends CanvasLayer
## 暂停 / 系统菜单。PROCESS_MODE_ALWAYS，打开时暂停场景树。
## 继续关闭菜单；回到标题由宿主听 title_requested（标题画面隐藏该按钮）。
## 重来本回合由宿主听 restart_requested；两者都会丢掉本回合的进度，所以要点第二次确认。
## 战斗动画、敌方回合速度两个开关存在 GameSettings。

signal title_requested
signal restart_requested

var show_title_button := true
## 宿主设：本回合有没有可以回去的检查点
var can_restart := false

var _open := false
var _armed := ""          # 正在等第二次确认的按钮："title" / "restart"
var _panel: PanelContainer
var _title_label: Label
var _resume_btn: Button
var _restart_btn: Button
var _title_btn: Button
var _anim_btn: Button
var _speed_btn: Button
var _bgm_label: Label
var _sfx_label: Label
var _bgm_slider: HSlider
var _sfx_slider: HSlider


func _init() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 50
	name = "SystemMenu"


func _ready() -> void:
	_build()
	visible = false
	if not GameLocale.locale_changed.is_connected(_apply_locale):
		GameLocale.locale_changed.connect(_apply_locale)
	_apply_locale("")


func is_open() -> bool:
	return _open


func open() -> void:
	if _open:
		return
	_open = true
	visible = true
	_armed = ""
	_apply_locale("")
	# 宽屏：面板水平居中
	_panel.reset_size()
	_panel.position.x = floorf((SafeArea.screen().x - _panel.size.x) / 2.0)
	_bgm_slider.set_value_no_signal(Audio.bgm_percent)
	_sfx_slider.set_value_no_signal(Audio.sfx_percent)
	get_tree().paused = true


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	if get_tree() != null:
		get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event.is_action_pressed("ui_cancel") or PointerInput.is_secondary_press(event):
		# 与打开菜单的同一次 Esc / 返回键去重，避免刚打开就被关掉。
		if PointerInput.accept_back():
			close()
		get_viewport().set_input_as_handled()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	_panel = panel
	panel.position = Vector2(390, 56)
	panel.custom_minimum_size = Vector2(500, 0)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.10, 0.16, 0.97)
	sb.border_color = Color(0.85, 0.75, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 20
	sb.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	panel.add_child(vb)

	_title_label = Label.new()
	_title_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	vb.add_child(_title_label)

	_resume_btn = _button("ResumeButton")
	_resume_btn.pressed.connect(close)
	vb.add_child(_resume_btn)

	_restart_btn = _button("RestartButton")
	_restart_btn.pressed.connect(_on_restart)
	vb.add_child(_restart_btn)

	_title_btn = _button("TitleButton")
	_title_btn.pressed.connect(_on_title)
	_title_btn.visible = show_title_button
	vb.add_child(_title_btn)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vb.add_child(row)
	_anim_btn = _button("AnimButton")
	_anim_btn.custom_minimum_size.x = 220
	_anim_btn.pressed.connect(func() -> void:
		GameSettings.set_battle_anim(not GameSettings.battle_anim)
		_apply_locale(""))
	row.add_child(_anim_btn)
	_speed_btn = _button("SpeedButton")
	_speed_btn.custom_minimum_size.x = 220
	_speed_btn.pressed.connect(func() -> void:
		GameSettings.set_fast_enemy(not GameSettings.fast_enemy)
		_apply_locale(""))
	row.add_child(_speed_btn)

	_bgm_label = _small_label()
	vb.add_child(_bgm_label)
	_bgm_slider = _slider("BgmSlider")
	_bgm_slider.value_changed.connect(func(v: float) -> void: Audio.set_bgm_percent(v))
	vb.add_child(_bgm_slider)

	_sfx_label = _small_label()
	vb.add_child(_sfx_label)
	_sfx_slider = _slider("SfxSlider")
	_sfx_slider.value_changed.connect(func(v: float) -> void: Audio.set_sfx_percent(v))
	vb.add_child(_sfx_slider)


func _button(node_name: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(452, SafeArea.MIN_HIT)
	b.add_theme_font_size_override("font_size", 24)
	return b


func _small_label() -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_size_override("font_size", 20)
	return l


func _slider(node_name: String) -> HSlider:
	var s := HSlider.new()
	s.name = node_name
	s.min_value = 0
	s.max_value = 100
	s.step = 1
	s.value = 100
	s.custom_minimum_size = Vector2(452, SafeArea.MIN_HIT)
	return s


func _apply_locale(_code: String) -> void:
	if _title_label == null:
		return
	_title_label.text = tr("系统")
	_resume_btn.text = tr("继续")
	_restart_btn.text = tr("再点一次：本回合的行动作废") if _armed == "restart" else tr("重来本回合")
	_title_btn.text = tr("再点一次回到标题") if _armed == "title" else tr("回到标题")
	_anim_btn.text = tr("战斗动画：开") if GameSettings.battle_anim else tr("战斗动画：关")
	_speed_btn.text = tr("敌方回合：快速") if GameSettings.fast_enemy else tr("敌方回合：普通")
	_bgm_label.text = tr("音乐")
	_sfx_label.text = tr("音效")
	_title_btn.visible = show_title_button
	_restart_btn.visible = show_title_button and can_restart


func _on_title() -> void:
	if _armed != "title":
		_armed = "title"
		_apply_locale("")
		return
	close()
	title_requested.emit()


func _on_restart() -> void:
	if _armed != "restart":
		_armed = "restart"
		_apply_locale("")
		return
	close()
	restart_requested.emit()
