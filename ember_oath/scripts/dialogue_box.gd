class_name DialogueBox
extends Control
## 底部对话框：打字机效果，点击 / 回车推进

signal all_finished

## 说话人 -> 像素立绘（res://art/portraits/px/<key>.png，64×64，框里 ×2 显示）。
## 立绘由 tools/pixelart/fe_portraits.py 生成；杂兵、路人共用职业 / 身份立绘。
const PORTRAITS := {
	"缇娅": "tia", "缇娅·觉醒": "tia", "巴尔托": "balto", "哈洛": "harlo", "托比": "toby", "山贼小弟": "toby",
	"妮娜": "nina", "凯因": "kain", "艾德里克": "edric", "诺雅": "noya", "西里尔": "cyril", "小雀": "sparrow",
	"塞拉斯": "silas", "莫尔甘": "morgan", "薇拉": "vera", "格雷": "gray", "霍克": "hawk", "七号": "seven",
	"埃德蒙": "edmund", "兰斯": "lance", "布洛克": "brock", "马尔科": "marco", "巴雷特": "barrett",
	"奥古斯特": "august", "罗伦兹": "lorenz",
	"葛温": "knight", "奥斯卡": "knight", "米拉": "villager_w", "维克多": "mage", "布鲁诺": "smith", "赛莲": "villager_w", "加雷斯": "knight", "哈根": "smith", "莉丝": "villager_w", "朔": "merc", "杰拉德": "elder", "艾薇": "granny", "伊万": "church", "塔莉亚": "villager_w", "本笃": "elder", "琪拉": "villager_w", "洛克": "knight",
	"山贼": "bandit", "探子": "scout", "黑烬佣兵": "merc", "圣焰教会兵": "church", "圣焰骑士": "knight",
	"教会弓兵": "archer", "弓箭手": "archer", "教会魔道士": "mage",
	"卡斯帕": "scout", "阿德琳": "church", "奥斯瓦尔德": "mage", "布罗登国王": "elder", "欧蕾莉亚": "mage", "伊格纳兹": "knight", "瓦伦": "knight", "格里姆": "knight", "灰袍众": "scout", "赫尔曼": "mage", "贝尔纳": "knight", "卡尔顿": "knight", "西蒙": "archer", "巴洛": "knight", "斯卡尔": "brock", "老学者": "elder", "国王": "elder", "老修士": "elder", "押送兵": "church", "摆渡人": "villager", "老水手": "elder", "旅店老板娘": "villager_w", "锁匠": "smith", "老水道工": "elder", "牧羊人": "villager", "磨坊主": "villager", "宰相": "mage", "牧人": "villager", "村妇": "villager_w", "老兵": "elder", "小孩": "villager", "退役骑士": "elder", "教会使者": "church", "沼泽强盗": "bandit", "清理部队枪兵": "church", "海盗": "bandit", "王国骑士": "knight", "布罗登叛兵": "merc", "灰袍盗贼": "scout", "王城重甲兵": "knight",
	"奥瑞恩": "archer", "欧文": "mage", "莉莉丝": "villager_w", "罗兰": "merc", "烬": "seven",
	"赫克托": "knight", "维尔纳": "mage", "渡鸦": "scout", "马库斯": "mage", "零号": "seven", "阿尔班": "church",
	"莫尔甘·炎龙": "morgan", "缇娅·守护之火": "tia", "义勇兵": "villager", "神殿杂役": "villager",
	"村民": "villager", "店主": "villager", "猎人": "villager", "猎户": "villager", "樵夫": "villager",
	"铁匠": "smith", "农妇": "villager_w", "寡妇": "villager_w", "老人": "elder", "老奶奶": "granny",
}

const BODY_FONT_SIZE := 22
const NAME_FONT_SIZE := 20
const BODY_LINE_RATIO := 1.35
## 正文区高度：3 行 × 字号 1.35，约 90–100px
const BODY_AREA_H := 96.0
const PORTRAIT_ORIGIN := Vector2(18, 22)
const PORTRAIT_SIZE := Vector2(128, 128)
const TEXT_GAP := 16.0
const TEXT_TOP := 36.0
const TEXT_LEFT := 24.0
const TEXT_RIGHT_PAD := 24.0

var _lines: Array = []
var _idx := 0
var _typing := false
var _active := false
var _line_text := ""
var _tween: Tween = null
var _tex_cache := {}

var _name_label: Label
var _text_label: Label
## 跳过整段对话：点一次变成「再点一次跳过」，第二次才真的跳（防误触）
var skip_btn: Button
var _skip_armed := false
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
	_text_label.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
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
	_portrait.stretch_mode = TextureRect.STRETCH_SCALE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
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

	skip_btn = Button.new()
	skip_btn.name = "SkipButton"
	skip_btn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	skip_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	skip_btn.offset_left = -210
	skip_btn.offset_right = 0
	skip_btn.offset_top = -(SafeArea.MIN_HIT + 10)
	skip_btn.offset_bottom = -10
	skip_btn.add_theme_font_size_override("font_size", 20)
	skip_btn.focus_mode = Control.FOCUS_NONE
	add_child(skip_btn)


## lines: [{name, text, color}]
func play(lines: Array) -> void:
	_lines = lines
	_idx = 0
	_active = true
	visible = true
	_skip_armed = false
	skip_btn.text = tr("跳过 ▶▶")
	skip_btn.visible = lines.size() >= 3
	set_process_input(true)
	_show_line()


func _show_line() -> void:
	var line: Dictionary = _lines[_idx]
	Audio.play_sfx("talk")
	var speaker: String = line.get("name", "")
	_name_label.text = tr(speaker)
	_name_label.visible = speaker != ""
	_name_label.add_theme_color_override("font_color", line.get("color", Color.WHITE))
	# 立绘在左时，正文左缘 = 框右缘 + 16（124 框 → x=158）
	var with_portrait := PORTRAITS.has(speaker)
	if with_portrait:
		_portrait.texture = _get_portrait(PORTRAITS[speaker])
		# TODO(M3): 暖色调制只是觉醒立绘缺图时的临时区分，正式立绘到位后去掉。
		_portrait.modulate = Color(1.0, 0.78, 0.62) if speaker == "缇娅·觉醒" else Color.WHITE
		_portrait_frame.visible = true
	else:
		_portrait.modulate = Color.WHITE
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
	if not PointerInput.is_primary_press(event) and not event.is_action_pressed("ui_accept"):
		return
	get_viewport().set_input_as_handled()
	if PointerInput.is_primary_press(event) and skip_btn.visible and skip_btn.get_global_rect().has_point(PointerInput.viewport_position(event)):
		press_skip()
		return
	if _skip_armed:
		_skip_armed = false
		skip_btn.text = tr("跳过 ▶▶")
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
	var width := size.x
	if width < 200.0:
		width = 1280.0 - SafeArea.MARGIN_X * 2.0
	var left := TEXT_LEFT
	if with_portrait:
		left = PORTRAIT_ORIGIN.x + PORTRAIT_SIZE.x + TEXT_GAP
	var right := width - TEXT_RIGHT_PAD
	_text_label.position = Vector2(left, TEXT_TOP)
	_text_label.size = Vector2(maxf(right - left, 200), BODY_AREA_H)


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
		_tex_cache[key] = load("res://art/portraits/px/%s.png" % key)
	return _tex_cache[key]


## 正在打字（演示录像按「打完一句再等一会儿」的节奏翻页）
func is_typing() -> bool:
	return _active and _typing


## 等同点一下：打字中先显示整句，否则翻到下一句
func advance() -> void:
	if not _active:
		return
	if _typing:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_text_label.visible_characters = -1
		_typing = false
		return
	_idx += 1
	if _idx >= _lines.size():
		_finish()
	else:
		_show_line()


## 跳过按钮：第一次只确认，第二次结束整段对话
func press_skip() -> void:
	if not _skip_armed:
		_skip_armed = true
		skip_btn.text = tr("再点一次跳过")
		Audio.play_sfx("cursor")
		return
	Audio.play_sfx("cancel")
	skip_all()


## 测试 / 跳过用：立即结束当前对话
func skip_all() -> void:
	if not _active:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_finish()
