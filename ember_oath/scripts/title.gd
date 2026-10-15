extends Control
## 标题画面：暗色背景 + 上升的余烬粒子

var _embers: Array = []


func _ready() -> void:
	Audio.play_music("map")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.04, 0.05)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "余烬之誓"
	title.add_theme_font_size_override("font_size", 84)
	title.add_theme_color_override("font_color", Color(1.0, 0.62, 0.3))
	title.position = Vector2(0, 170)
	title.size = Vector2(1280, 120)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)

	var sub := Label.new()
	sub.text = "Vow of Embers · 战棋原型"
	sub.add_theme_font_size_override("font_size", 26)
	sub.add_theme_color_override("font_color", Color(0.8, 0.75, 0.7))
	sub.position = Vector2(0, 305)
	sub.size = Vector2(1280, 40)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(sub)

	var btn := Button.new()
	btn.text = "开始游戏"
	btn.custom_minimum_size = Vector2(240, 64)
	btn.position = Vector2(520, 450)
	btn.add_theme_font_size_override("font_size", 30)
	btn.pressed.connect(_on_start)
	add_child(btn)

	# 缇娅立绘装饰
	var portrait := TextureRect.new()
	portrait.texture = load("res://art/portraits/portrait_tia.jpg")
	portrait.position = Vector2(920, 180)
	portrait.size = Vector2(300, 300)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.modulate = Color(1, 1, 1, 0.92)
	add_child(portrait)
	var frame := Panel.new()
	frame.position = Vector2(920, 180)
	frame.size = Vector2(300, 300)
	var fb := StyleBoxFlat.new()
	fb.bg_color = Color(0, 0, 0, 0)
	fb.border_color = Color(0.85, 0.65, 0.35)
	fb.set_border_width_all(3)
	fb.set_corner_radius_all(8)
	frame.add_theme_stylebox_override("panel", fb)
	add_child(frame)

	var note := Label.new()
	note.text = "第一章 · 边境的少女（原型 v0.1）"
	note.add_theme_font_size_override("font_size", 18)
	note.add_theme_color_override("font_color", Color(0.55, 0.52, 0.5))
	note.position = Vector2(0, 640)
	note.size = Vector2(1280, 30)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(note)

	# 余烬粒子
	for i in 24:
		var e := ColorRect.new()
		e.color = Color(1.0, randf_range(0.4, 0.7), 0.2, randf_range(0.35, 0.85))
		var s := randf_range(2.0, 5.0)
		e.size = Vector2(s, s)
		e.position = Vector2(randf_range(0, 1280), randf_range(200, 720))
		add_child(e)
		_embers.append({"node": e, "speed": randf_range(15.0, 55.0), "drift": randf_range(-14.0, 14.0)})


func _process(delta: float) -> void:
	for e in _embers:
		var n: ColorRect = e["node"]
		n.position.y -= e["speed"] * delta
		n.position.x += e["drift"] * delta
		if n.position.y < -10:
			n.position.y = 730
			n.position.x = randf_range(0, 1280)


func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/narration.tscn")
