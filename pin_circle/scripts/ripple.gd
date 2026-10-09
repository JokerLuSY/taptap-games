extends Node2D
## 点击涟漪: 扩散的圆环

var radius := 12.0
var color := Color(0.4, 0.9, 1.0)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0, TAU, 48, color, 4.0, true)
