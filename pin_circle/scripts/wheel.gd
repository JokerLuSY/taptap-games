extends Node2D
class_name Wheel
## 旋转轮盘: 自绘圆环 + 已插入的针; 角度碰撞判定

const PIN_LEN := 70.0
const PIN_HEAD := 17.0
const COLLIDE_DEG := 9.0

var radius := 260.0
var angular_speed := 90.0        ## 度/秒, 负值反向
var stuck_angles: Array = []     ## 轮盘局部坐标系角度(度)
var wheel_color := Color(0.35, 0.85, 1.0)
var pin_color := Color(1.0, 0.72, 0.35)
var spinning := true

var _center_label: Label


func _ready() -> void:
	_center_label = Label.new()
	_center_label.add_theme_font_size_override("font_size", 150)
	_center_label.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	_center_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_center_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_center_label.set_anchors_preset(Control.PRESET_CENTER)
	_center_label.custom_minimum_size = Vector2(300, 300)
	_center_label.position = Vector2(-150, -150)
	add_child(_center_label)


func _process(delta: float) -> void:
	if spinning:
		rotation_degrees += angular_speed * delta
	_center_label.rotation_degrees = -rotation_degrees  ## 数字保持正立


func set_count(n: int) -> void:
	_center_label.text = str(n) if n > 0 else ""


## 针从轮盘正下方(全局 90°)插入; 返回是否成功
func try_stick() -> bool:
	var local_a := wrapf(90.0 - rotation_degrees, 0.0, 360.0)
	for a in stuck_angles:
		if absf(wrapf(local_a - a, -180.0, 180.0)) < COLLIDE_DEG:
			return false
	stuck_angles.append(local_a)
	queue_redraw()
	pulse()
	return true


func pulse() -> void:
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.06, 1.06), 0.07)
	t.tween_property(self, "scale", Vector2.ONE, 0.12)


func shake() -> void:
	var t := create_tween()
	for i in 4:
		t.tween_property(self, "position:x", position.x + (14 if i % 2 == 0 else -14), 0.04)
	t.tween_property(self, "position:x", 540.0, 0.05)


func _draw() -> void:
	# 柔光(同心圆近似径向渐变)
	for i in 5:
		draw_circle(Vector2.ZERO, radius + 64.0 - i * 13.0, Color(wheel_color, 0.045))
	# 盘面: 中心深 -> 边缘微亮的径向层次
	var steps := 24
	for i in range(steps, 0, -1):
		var t := float(i) / steps
		var c := wheel_color.lerp(Color(0.04, 0.05, 0.11), 1.0 - t * 0.55)
		draw_circle(Vector2.ZERO, radius * t, c)
	# 旋转刻度(让转动可见)
	for k in 12:
		var dir := Vector2.RIGHT.rotated(TAU * k / 12.0)
		draw_line(dir * (radius * 0.86), dir * (radius * 0.94), Color(wheel_color, 0.35), 5.0, true)
	# 外环 + 内细环
	draw_arc(Vector2.ZERO, radius, 0, TAU, 128, wheel_color, 12.0, true)
	draw_arc(Vector2.ZERO, radius * 0.78, 0, TAU, 96, Color(wheel_color, 0.25), 3.0, true)
	# 已插入的针
	for a in stuck_angles:
		var dir := Vector2.RIGHT.rotated(deg_to_rad(a))
		var head: Vector2 = dir * (radius + PIN_LEN)
		draw_line(dir * (radius - 14), head, pin_color, 7.0, true)
		draw_circle(head, PIN_HEAD, pin_color)
		draw_circle(head + Vector2(-4, -4), 7, Color(1, 1, 1, 0.85))
		draw_circle(head, PIN_HEAD, Color(pin_color, 0.35), false, 3.0)
