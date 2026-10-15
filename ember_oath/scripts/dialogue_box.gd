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

const BODY_FONT_SIZE := 22
const NAME_FONT_SIZE := 20
const BODY_LINE_RATIO := 1.35
## 正文区高度：3 行 × 字号 1.35，约 90–100px
const BODY_AREA_H := 96.0
const PORTRAIT_ORIGIN := Vector2(18, 22)
const PORTRAIT_SIZE := Vector2(124, 124)
const TEXT_GAP := 16.0
const TEXT_TOP := 36.0
## 正文右缘。无立绘时左缘 24、宽 1184
const TEXT_RIGHT := 1208.0

var _lines: Array = []
var _idx := 0
var _typing := false
var _active := false
var _line_text := ""
var _tween: Tween = null
var _tex_cache := {}

var _name_label: Label
var _text_label: Label
var _portrait_frame: Panel
var _portrait: TextureRect


func _ready() -> void:
	visible = false
	set_process_input(false)
	# 底部停靠：1280x720 下位于 y 530..704
	anchor_left = 0.0
	anchor_top = 1.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 24
	offset_right = -24
	offset_top = -190
	offset_bottom = -16

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
	_name_label.position = Vector2(20, -16)
	_name_label.add_theme_font_size_override("font_size", NAME_FONT_SIZE)
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
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_text_label.add_theme_font_size_override("font_size", BODY_FONT_SIZE)
	# CJK 打字机按字裁切，不用 visible_ratio（ratio 会在成形前把字形挤到同一位置）
	_text_label.visible_characters_behavior = TextServer.VC_CHARS_BEFORE_SHAPING
	_text_label.visible_characters = -1
	add_child(_text_label)
	_apply_body_line_spacing()
	_layout_body(false)

	# 立绘框
	_portrait_frame = Panel.new()
	_portrait_frame.position = PORTRAIT_ORIGIN
	_portrait_frame.size = PORTRAIT_SIZE
	_portrait_frame.clip_contents = true
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
	hint.position = Vector2(1196, 136)
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
	_name_label.text = speaker
	_name_label.visible = speaker != ""
	_name_label.add_theme_color_override("font_color", line.get("color", Color.WHITE))
	# 立绘在左时，正文左缘 = 框右缘 + 16（124 框 → x=158）
	var with_portrait := PORTRAITS.has(speaker)
	if with_portrait:
		_portrait.texture = _get_portrait(PORTRAITS[speaker])
		_portrait_frame.visible = true
	else:
		_portrait_frame.visible = false
	_layout_body(with_portrait)
	_line_text = str(line.get("text", ""))
	_text_label.text = _line_text
	_text_label.visible_characters = 0
	_typing = _line_text.length() > 0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if not _typing:
		return
	_tween = create_tween()
	var dur: float = clampf(_line_text.length() * 0.035, 0.2, 3.0)
	_tween.tween_method(_set_shown_chars, 0.0, float(_line_text.length()), dur)
	_tween.tween_callback(func() -> void: _typing = false)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	elif event.is_action_pressed("ui_accept"):
		advance = true
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_text_label.visible_characters = -1
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


func _layout_body(with_portrait: bool) -> void:
	var left := 24.0
	if with_portrait:
		left = PORTRAIT_ORIGIN.x + PORTRAIT_SIZE.x + TEXT_GAP
	_text_label.position = Vector2(left, TEXT_TOP)
	_text_label.size = Vector2(TEXT_RIGHT - left, BODY_AREA_H)


func _apply_body_line_spacing() -> void:
	var font := _text_label.get_theme_font("font")
	var font_h := font.get_height(BODY_FONT_SIZE)
	var min_line := int(ceil(float(BODY_FONT_SIZE) * BODY_LINE_RATIO))
	_text_label.add_theme_constant_override("line_spacing", maxi(0, min_line - font_h))


## 按字推进。visible_characters 在成形前截断，避免 CJK 叠字。
func _set_shown_chars(shown: float) -> void:
	var n := clampi(int(shown), 0, _line_text.length())
	if _text_label.visible_characters != n:
		_text_label.visible_characters = n


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
