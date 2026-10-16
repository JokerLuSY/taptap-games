extends CanvasLayer
## 暂停 / 系统菜单。PROCESS_MODE_ALWAYS，打开时暂停场景树。
## 继续关闭菜单；回到标题由宿主听 title_requested（标题画面隐藏该按钮）。

signal title_requested

var show_title_button := true

var _open := false
var _title_label: Label
var _resume_btn: Button
var _title_btn: Button
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
	_apply_locale("")
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
	panel.position = Vector2(390, 120)
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

	_title_btn = _button("TitleButton")
	_title_btn.pressed.connect(_on_title)
	_title_btn.visible = show_title_button
	vb.add_child(_title_btn)

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
	_title_btn.text = tr("回到标题")
	_bgm_label.text = tr("音乐")
	_sfx_label.text = tr("音效")
	_title_btn.visible = show_title_button


func _on_title() -> void:
	close()
	title_requested.emit()
