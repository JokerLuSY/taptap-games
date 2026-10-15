class_name DialogueBox
extends Control
## 底部对话框：打字机效果，点击 / 回车推进

signal all_finished

## 说话人 -> 立绘文件名（res://art/portraits/<name>.jpg）
const PORTRAITS := {
	"缇娅": "portrait_tia",
	"巴尔托": "portrait_balto",
	"布洛克": "portrait_brock",
	"山贼": "portrait_bandit",
	"哈洛": "portrait_villager",
	"村民": "portrait_villager",
	"老奶奶": "portrait_granny",
}

var _lines: Array = []
var _idx := 0
var _typing := false
var _active := false
var _tween: Tween = null
var _tex_cache := {}

var _name_label: Label
var _text_label: Label
var _portrait_frame: Panel
var _portrait: TextureRect


func _ready() -> void:
	visible = false
	set_process_input(false)
	# 底部停靠，左右/下边让出安全区。净高保持 174，避免挤掉三行正文。
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = SafeArea.MARGIN_X
	offset_right = -SafeArea.MARGIN_X
	offset_bottom = -SafeArea.MARGIN_Y
	offset_top = -(SafeArea.MARGIN_Y + 174)

	var panel := Panel.new()
	panel.set_anchors_preset(PRESET_FULL_RECT)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.12, 0.93)
	sb.border_color = Color(0.85, 0.75, 0.45)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	_name_label = Label.new()
	_name_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_name_label.position = Vector2(20, -16)
	_name_label.add_theme_font_size_override("font_size", 20)
	var nb := StyleBoxFlat.new()
	nb.bg_color = Color(0.10, 0.13, 0.22)
	nb.border_color = Color(0.85, 0.75, 0.45)
	nb.set_border_width_all(1)
	nb.set_corner_radius_all(6)
	nb.content_margin_left = 12
	nb.content_margin_right = 12
	_name_label.add_theme_stylebox_override("normal", nb)
	add_child(_name_label)

	_text_label = Label.new()
	_text_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_text_label.position = Vector2(24, 36)
	_text_label.size = Vector2(1184, 122)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.add_theme_font_size_override("font_size", 23)
	add_child(_text_label)

	# 立绘框
	_portrait_frame = Panel.new()
	_portrait_frame.position = Vector2(18, 22)
	_portrait_frame.size = Vector2(124, 124)
	_portrait_frame.visible = false
	var pb := StyleBoxFlat.new()
	pb.bg_color = Color(0.10, 0.13, 0.22)
	pb.border_color = Color(0.85, 0.75, 0.45)
	pb.set_border_width_all(2)
	pb.set_corner_radius_all(6)
	_portrait_frame.add_theme_stylebox_override("panel", pb)
	add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.set_anchors_preset(PRESET_FULL_RECT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_portrait_frame.add_child(_portrait)

	var hint := Label.new()
	hint.text = "▼"
	hint.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.offset_left = -36
	hint.offset_top = -32
	hint.offset_right = -12
	hint.offset_bottom = -8
	hint.add_theme_color_override("font_color", Color(0.85, 0.75, 0.45))
	add_child(hint)


## lines: [{name, text, color}]
func play(lines: Array) -> void:
	_lines = lines
	_idx = 0
	_active = true
	visible = true
	set_process_input(true)
	_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_idx]
	Audio.play_sfx("talk")
	var speaker: String = line.get("name", "")
	_name_label.text = tr(speaker)
	_name_label.visible = speaker != ""
	_name_label.add_theme_color_override("font_color", line.get("color", Color.WHITE))
	# 立绘
	if PORTRAITS.has(speaker):
		_portrait.texture = _get_portrait(PORTRAITS[speaker])
		_portrait_frame.visible = true
		_fit_text(true)
	else:
		_portrait_frame.visible = false
		_fit_text(false)
	_text_label.text = line.get("text", "")
	_text_label.visible_ratio = 0.0
	_typing = true
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	var dur: float = clampf(_text_label.text.length() * 0.035, 0.2, 3.0)
	_tween.tween_property(_text_label, "visible_ratio", 1.0, dur)
	_tween.tween_callback(func() -> void: _typing = false)


func _fit_text(with_portrait: bool) -> void:
	var width := size.x
	if width < 200.0:
		width = 1280.0 - SafeArea.MARGIN_X * 2
	var right_pad := 40.0
	if with_portrait:
		_text_label.position = Vector2(158, 36)
		_text_label.size = Vector2(maxf(width - 158.0 - right_pad, 200), 122)
	else:
		_text_label.position = Vector2(24, 36)
		_text_label.size = Vector2(maxf(width - 24.0 - right_pad, 200), 122)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	if not PointerInput.is_primary_press(event) and not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if _typing:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_text_label.visible_ratio = 1.0
		_typing = false
	else:
		_idx += 1
		if _idx >= _lines.size():
			_finish()
		else:
			_show_line()


func _finish() -> void:
	_active = false
	visible = false
	set_process_input(false)
	all_finished.emit()


func _get_portrait(key: String) -> Texture2D:
	if not _tex_cache.has(key):
		_tex_cache[key] = load("res://art/portraits/%s.jpg" % key)
	return _tex_cache[key]


## 测试 / 跳过用：立即结束当前对话
func skip_all() -> void:
	if not _active:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_finish()
