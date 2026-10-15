class_name MapCursor
extends Node2D
## 地图光标：黄色四角括号，带呼吸脉冲

const TILE := 64

var grid_pos := Vector2i.ZERO
var _t := 0.0


func _ready() -> void:
	z_index = 10


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func set_grid(p: Vector2i) -> void:
	grid_pos = p
	position = Vector2(p) * TILE


func _draw() -> void:
	var pulse := 1.0 + sin(_t * 6.0) * 0.15
	var col := Color(1.0, 0.9, 0.2, 0.95)
	var m := 3.0
	var seg := 14.0 * pulse
	var s := TILE - m * 2
	var corners := [Vector2(m, m), Vector2(m + s, m), Vector2(m, m + s), Vector2(m + s, m + s)]
	var dirs := [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for i in 4:
		var o: Vector2 = corners[i]
		var d: Vector2 = dirs[i]
		draw_line(o, o + Vector2(d.x * seg, 0), col, 3.0)
		draw_line(o, o + Vector2(0, d.y * seg), col, 3.0)
