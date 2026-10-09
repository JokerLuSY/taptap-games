extends Control
## 游戏壳: 承载关卡视图、转场、氛围音

var _level_view: Control
var _fade: ColorRect
var _ambience: AudioStreamPlayer


func _ready() -> void:
	_ambience = AudioStreamPlayer.new()
	var stream: AudioStreamWAV = load("res://audio/ambience.wav")
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = stream.get_length() * stream.mix_rate
	_ambience.stream = stream
	_ambience.volume_db = -16.0
	_ambience.bus = "Master"
	add_child(_ambience)
	_ambience.play()

	_level_view = load("res://scenes/level_view.tscn").instantiate()
	add_child(_level_view)
	_level_view.level_finished.connect(_on_level_finished)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	_fade_in()


func _on_level_finished(level_id: int) -> void:
	if level_id >= GameState.TOTAL_LEVELS:
		await _fade_out()
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
		return
	await _fade_out()
	_level_view.load_level(level_id + 1)
	_fade_in()


func _fade_out() -> void:
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 1.0, 0.45)
	await t.finished


func _fade_in() -> void:
	_fade.modulate.a = 1.0
	var t := create_tween()
	t.tween_property(_fade, "modulate:a", 0.0, 0.45)
