extends Control
## 见缝插针: 点击射针, 全插上过关, 碰到已有针失败
## 状态机: TITLE -> PLAYING -> CLEAR -> GAME_OVER

enum State { TITLE, PLAYING, CLEAR, OVER }

const SAVE_PATH := "user://pin_save.json"
const WHEEL_POS := Vector2(540, 640)
const PIN_SPAWN := Vector2(540, 1560)

var state: State = State.TITLE
var level := 1
var remaining := 0
var best := 0
var _flying := false
var _flip_halfway := false
var _flip_at := -1
var _stuck_this_level := 0

var _wheel: Wheel
var _bg: Node2D
var _level_label: Label
var _best_label: Label
var _queue_view: Control
var _title_overlay: CenterContainer
var _over_overlay: CenterContainer
var _over_title: Label
var _over_detail: Label
var _flash: ColorRect
var _particles: CPUParticles2D
var _tick_sfx: Array[AudioStreamPlayer] = []
var _fail_sfx: AudioStreamPlayer
var _win_sfx: AudioStreamPlayer


func _ready() -> void:
	_load_save()

	var bg := Node2D.new()
	bg.set_script(preload("res://scripts/background.gd"))
	add_child(bg)
	_bg = bg

	_wheel = Wheel.new()
	_wheel.position = WHEEL_POS
	add_child(_wheel)

	# 过关粒子
	_particles = CPUParticles2D.new()
	_particles.position = WHEEL_POS
	_particles.emitting = false
	_particles.one_shot = true
	_particles.explosiveness = 1.0
	_particles.amount = 60
	_particles.lifetime = 0.9
	_particles.direction = Vector2(0, -1)
	_particles.spread = 180.0
	_particles.initial_velocity_min = 500.0
	_particles.initial_velocity_max = 900.0
	_particles.gravity = Vector2(0, 900)
	_particles.scale_amount_min = 6.0
	_particles.scale_amount_max = 12.0
	_particles.color = Color(1.0, 0.8, 0.4)
	add_child(_particles)

	_level_label = Label.new()
	_level_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_level_label.position = Vector2(-300, 60)
	_level_label.custom_minimum_size = Vector2(600, 100)
	_level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_label.add_theme_font_size_override("font_size", 72)
	_level_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	add_child(_level_label)

	_best_label = Label.new()
	_best_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_best_label.position = Vector2(-300, 160)
	_best_label.custom_minimum_size = Vector2(600, 60)
	_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_best_label.add_theme_font_size_override("font_size", 36)
	_best_label.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
	add_child(_best_label)

	_queue_view = Control.new()
	_queue_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_queue_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_queue_view)
	_queue_view.draw.connect(_draw_queue)

	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.modulate.a = 0.0
	add_child(_flash)

	for i in 8:
		var p := AudioStreamPlayer.new()
		p.stream = load("res://audio/tick_%d.wav" % i)
		add_child(p)
		_tick_sfx.append(p)
	_fail_sfx = AudioStreamPlayer.new()
	_fail_sfx.stream = load("res://audio/fail.wav")
	add_child(_fail_sfx)
	_win_sfx = AudioStreamPlayer.new()
	_win_sfx.stream = load("res://audio/win.wav")
	add_child(_win_sfx)

	_build_title_overlay()
	_build_over_overlay()
	_show_title()


# ---------------- 输入 ----------------
## 用 _input 而非 _unhandled_input: 全屏根 Control 会消费 GUI 事件导致后者不触发

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_spawn_ripple(event.position)
		_handle_tap()


func _handle_tap() -> void:
	match state:
		State.TITLE:
			_start_game()
		State.PLAYING:
			_shoot()
		State.OVER:
			if _over_overlay.visible:  # 死亡动画期间的点击不触发重试, 避免竞态
				_retry()


# ---------------- 关卡系统 ----------------

func _level_params(n: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + n
	var pins: int = mini(4 + n, 18)
	var speed: float = minf(80.0 + n * 14.0, 260.0)
	var dir: float = 1.0 if n % 3 != 0 else -1.0
	var pre: Array = []
	if n >= 3:
		var count: int = mini(n - 2, 7)
		var tries := 0
		while pre.size() < count and tries < 300:
			var a := rng.randf_range(0.0, 360.0)
			var ok := true
			for b in pre:
				if absf(wrapf(a - b, -180.0, 180.0)) < 30.0:
					ok = false
					break
			if ok:
				pre.append(a)
			tries += 1
	return {"pins": pins, "speed": speed * dir, "pre": pre, "flip": n >= 8}


func _start_level(n: int) -> void:
	level = n
	var p := _level_params(n)
	remaining = p.pins
	_stuck_this_level = 0
	_flip_halfway = p.flip
	_flip_at = int(ceil(p.pins / 2.0)) if p.flip else -1
	_wheel.stuck_angles = p.pre.duplicate()
	_wheel.angular_speed = p.speed
	_wheel.spinning = true
	_wheel.wheel_color = Color.from_hsv(fmod(0.55 + n * 0.07, 1.0), 0.65, 1.0)
	_bg.glow_color = _wheel.wheel_color
	_wheel.queue_redraw()
	_wheel.set_count(remaining)
	_level_label.text = "第 %d 关" % n
	_best_label.text = "最佳: 第 %d 关" % best if best > 0 else ""
	_queue_view.queue_redraw()
	state = State.PLAYING


# ---------------- 射针 ----------------

func _shoot() -> void:
	if _flying or remaining <= 0:
		return
	_flying = true
	var pin := preload("res://scenes/flying_pin.tscn").instantiate()
	pin.position = PIN_SPAWN
	pin.color = _wheel.pin_color
	add_child(pin)
	var target := Vector2(PIN_SPAWN.x, WHEEL_POS.y + _wheel.radius + Wheel.PIN_LEN)
	var t := create_tween()
	t.tween_property(pin, "position", target, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(_on_pin_arrived.bind(pin))


func _on_pin_arrived(pin: Node2D) -> void:
	_flying = false
	if _wheel.try_stick():
		pin.queue_free()
		_stuck_this_level += 1
		_tick_sfx[mini(_stuck_this_level - 1, 7)].play()
		remaining -= 1
		_wheel.set_count(remaining)
		_queue_view.queue_redraw()
		if _flip_halfway and _stuck_this_level == _flip_at:
			_wheel.angular_speed *= -1.0
			_flash_once(Color(0.4, 0.7, 1.0), 0.12)
		if remaining <= 0:
			_on_level_clear()
	else:
		_on_collision(pin)


func _on_level_clear() -> void:
	state = State.CLEAR
	_win_sfx.play()
	_particles.emitting = true
	_flash_once(Color(1.0, 0.9, 0.6), 0.18)
	if level > best:
		best = level
		_save()
	await get_tree().create_timer(1.1).timeout
	_start_level(level + 1)


func _on_collision(pin: Node2D) -> void:
	state = State.OVER
	_fail_sfx.play()
	_wheel.spinning = false
	_flash_once(Color(0.9, 0.15, 0.2), 0.3)
	_wheel.shake()
	# 针弹飞
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(pin, "position", pin.position + Vector2(120, 500), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(pin, "rotation_degrees", 200.0, 0.5)
	t.tween_property(pin, "modulate:a", 0.0, 0.5)
	t.chain().tween_callback(pin.queue_free)
	if level > best:
		best = level
		_save()
	await get_tree().create_timer(0.7).timeout
	if state != State.OVER:
		return  # 玩家已在死亡动画期间重试, 不再弹失败窗
	_over_title.text = "碰到针了！"
	_over_detail.text = "止步第 %d 关 · 最佳第 %d 关" % [level, best]
	_over_overlay.visible = true


func _retry() -> void:
	_over_overlay.visible = false
	_flying = false
	_start_level(level)


# ---------------- 标题 / 结束界面 ----------------

func _build_title_overlay() -> void:
	_title_overlay = _make_overlay()
	var vb := _overlay_vbox(_title_overlay)
	var title := Label.new()
	title.text = "见缝插针"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 130)
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	vb.add_child(title)
	var tip := Label.new()
	tip.text = "点击屏幕，把针插进旋转的圆盘\n别碰到其他针"
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.add_theme_font_size_override("font_size", 44)
	tip.add_theme_color_override("font_color", Color(0.85, 0.88, 0.96))
	vb.add_child(tip)
	var start := Label.new()
	start.text = "▽ 点击开始"
	start.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start.add_theme_font_size_override("font_size", 48)
	start.add_theme_color_override("font_color", Color(1.0, 0.78, 0.4))
	vb.add_child(start)


func _build_over_overlay() -> void:
	_over_overlay = _make_overlay()
	var vb := _overlay_vbox(_over_overlay)
	_over_title = Label.new()
	_over_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_over_title.add_theme_font_size_override("font_size", 90)
	_over_title.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	vb.add_child(_over_title)
	_over_detail = Label.new()
	_over_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_over_detail.add_theme_font_size_override("font_size", 44)
	_over_detail.add_theme_color_override("font_color", Color(0.85, 0.88, 0.96))
	vb.add_child(_over_detail)
	var retry := Label.new()
	retry.text = "▽ 点击重试"
	retry.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	retry.add_theme_font_size_override("font_size", 48)
	retry.add_theme_color_override("font_color", Color(1.0, 0.78, 0.4))
	vb.add_child(retry)


func _make_overlay() -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.visible = false
	add_child(c)
	return c


func _overlay_vbox(c: CenterContainer) -> VBoxContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = Vector2(900, 520)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.06, 0.12, 0.92)
	sb.set_corner_radius_all(24)
	sb.set_content_margin_all(50)
	sb.border_color = Color(0.35, 0.5, 0.7)
	sb.set_border_width_all(2)
	p.add_theme_stylebox_override("panel", sb)
	c.add_child(p)
	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 50)
	p.add_child(vb)
	return vb


func _show_title() -> void:
	state = State.TITLE
	_wheel.spinning = true
	_wheel.set_count(0)
	_level_label.text = ""
	_best_label.text = "最佳: 第 %d 关" % best if best > 0 else ""
	_title_overlay.visible = true


func _start_game() -> void:
	_title_overlay.visible = false
	_start_level(1)


# ---------------- 反馈 ----------------

func _flash_once(c: Color, strength: float) -> void:
	_flash.color = c
	_flash.modulate.a = strength
	var t := create_tween()
	t.tween_property(_flash, "modulate:a", 0.0, 0.35)


## 点击涟漪: 让每次点击都有即时视觉反馈
func _spawn_ripple(pos: Vector2) -> void:
	var ripple := Node2D.new()
	ripple.set_script(preload("res://scripts/ripple.gd"))
	ripple.position = pos
	ripple.color = _wheel.wheel_color
	add_child(ripple)
	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(ripple, "radius", 70.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(ripple, "modulate:a", 0.0, 0.4)
	t.chain().tween_callback(ripple.queue_free)


func _draw_queue() -> void:
	# 底部待射针队列(小圆点)
	var n: int = mini(remaining, 12)
	for i in n:
		var pos := Vector2(540 - (n - 1) * 24 + i * 48, 1740)
		_queue_view.draw_circle(pos, 12, _wheel.pin_color)


# ---------------- 存档 ----------------

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"best": best}))
		f.close()


func _load_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) == TYPE_DICTIONARY:
		best = int(data.get("best", 0))
