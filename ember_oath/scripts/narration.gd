extends Control
## 开场旁白：黑底逐行显现，点击 / 回车推进

const LINES := [
	"卡尔迪亚大陆历 812 年。",
	"自「焚世之灾」过去，已逾八百年。",
	"在圣焰教会治理下的和平年代，\n火焰成为人们敬畏与禁忌的象征。",
	"在大陆西南边陲、菲恩领的群山之间，\n有一座名叫「灰岩」的小村庄。",
	"村中有一名少女，名叫缇娅。",
	"她还不知道自己体内沉睡着怎样的火焰——",
	"也不知道，这个清晨，\n将是她平静生活的最后一天。",
]

var _idx := 0
var _label: Label
var _tween: Tween = null


func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.03)
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	_label = Label.new()
	_label.position = Vector2(140, 260)
	_label.size = Vector2(1000, 200)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 32)
	_label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
	add_child(_label)

	var hint := Label.new()
	hint.text = "点击 / 回车 继续"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))
	hint.position = Vector2(0, 660)
	hint.size = Vector2(1280, 30)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hint)

	var skip := Button.new()
	skip.text = "跳过 >>"
	skip.position = Vector2(1140, 20)
	skip.custom_minimum_size = Vector2(120, 40)
	skip.pressed.connect(_go_battle)
	add_child(skip)

	_show()


func _show() -> void:
	_label.text = LINES[_idx]
	_label.modulate.a = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_label, "modulate:a", 1.0, 0.5)


func _input(event: InputEvent) -> void:
	var advance := false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance = true
	elif event.is_action_pressed("ui_accept"):
		advance = true
	if not advance:
		return
	if _label.modulate.a < 0.99:
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_label.modulate.a = 1.0
		return
	_idx += 1
	if _idx >= LINES.size():
		_go_battle()
	else:
		_show()


func _go_battle() -> void:
	get_tree().change_scene_to_file("res://scenes/battle.tscn")
