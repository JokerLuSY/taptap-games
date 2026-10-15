extends Control
## 标题画面：暗色背景 + 上升的余烬粒子
## 开始 / 语言是 Button，鼠标点击与触摸共用 pressed。

var _embers: Array = []
var _title: Label
var _sub: Label
var _note: Label
var _start: Button
var _lang: Button


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
	_start = Button.new()
	_start.name = "StartButton"
	_start.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_start.custom_minimum_size = start_size
	_start.size = start_size
	var start_x := clampf((1280.0 - start_size.x) * 0.5, SafeArea.EDGE_ACTION, 1280.0 - SafeArea.EDGE_ACTION - start_size.x)
	_start.position = Vector2(start_x, 450)
	_start.add_theme_font_size_override("font_size", 30)
	_start.pressed.connect(_on_start)
	add_child(_start)

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

	if not GameLocale.locale_changed.is_connected(_apply_locale):
		GameLocale.locale_changed.connect(_apply_locale)
	_apply_locale(GameLocale.code)


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
	_title.text = tr("余烬之誓")
	_sub.text = tr("Vow of Embers · 战棋原型")
	_note.text = tr("第一章 · 边境的少女（原型 v0.1）")
	_start.text = tr("开始游戏")
	_lang.text = tr("LANG_SWITCH")


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


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/narration.tscn")
