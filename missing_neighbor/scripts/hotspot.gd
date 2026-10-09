extends Control
class_name Hotspot
## 可点击热点: 由关卡 JSON 的 rect 驱动, 平时隐形, 提示时描边闪烁

signal pressed(hs: Hotspot)

var hotspot_id: String = ""
var evidence_id: String = ""
var label_text: String = ""
var required: bool = false

var _outline: ReferenceRect


func setup(data: Dictionary) -> void:
	hotspot_id = data.get("id", "")
	evidence_id = data.get("evidence_id", "")
	label_text = data.get("label", "")
	required = bool(data.get("required", false))
	var r: Array = data.get("rect", [0, 0, 100, 100])
	position = Vector2(r[0], r[1])
	size = Vector2(r[2], r[3])


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_outline = ReferenceRect.new()
	_outline.border_color = Color(1.0, 0.78, 0.4)
	_outline.border_width = 6.0
	_outline.editor_only = false
	_outline.set_anchors_preset(Control.PRESET_FULL_RECT)
	_outline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_outline.visible = false
	add_child(_outline)
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		pressed.emit(self)


## 卡关提示: 描边闪一次
func flash_once() -> void:
	_outline.visible = true
	_outline.modulate.a = 0.0
	var t := create_tween()
	for i in 2:
		t.tween_property(_outline, "modulate:a", 1.0, 0.35)
		t.tween_property(_outline, "modulate:a", 0.0, 0.35)
	t.tween_callback(func() -> void: _outline.visible = false)
