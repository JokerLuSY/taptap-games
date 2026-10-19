class_name PointerInput
extends RefCounted
## 鼠标与触控共用的主指针。
## 点格子、点单位、对话推进走这里；菜单和标题按钮仍用 Button（控件同时接收鼠标与触摸）。
##
## 工程默认开启 emulate_mouse_from_touch：第一根手指会合成鼠标事件。
## 此时只认鼠标，避免同一次触摸触发两次。关掉该选项后改为直接消费 ScreenTouch / ScreenDrag。
## 第二根手指始终视为取消（它不会被模拟成鼠标右键）。


static func touch_emulates_mouse() -> bool:
	return bool(ProjectSettings.get_setting("input_devices/pointing/emulate_mouse_from_touch", true))


static func is_primary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch and not touch_emulates_mouse():
		var st := event as InputEventScreenTouch
		return st.pressed and st.index == 0
	return false


static func is_primary_release(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return not mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventScreenTouch and not touch_emulates_mouse():
		var st := event as InputEventScreenTouch
		return not st.pressed and st.index == 0
	return false


static func is_secondary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		return st.pressed and st.index >= 1
	return false


static func is_pointer_move(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		return true
	if event is InputEventScreenDrag and not touch_emulates_mouse():
		return (event as InputEventScreenDrag).index == 0
	return false


## Esc 与 Android 返回可能在几十毫秒内各投递一次。只接受第一次。
static var _last_back_ms := 0


static func accept_back() -> bool:
	var now := Time.get_ticks_msec()
	if now - _last_back_ms < 80:
		return false
	_last_back_ms = now
	return true


static func viewport_position(event: InputEvent) -> Vector2:
	if event is InputEventMouse:
		return (event as InputEventMouse).position
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.ZERO
