extends Node2D
## 飞行中的针: 针头朝下, 针尾朝上

var color := Color(1.0, 0.72, 0.35)


func _draw() -> void:
	draw_line(Vector2(0, -70), Vector2.ZERO, color, 6.0, true)
	draw_circle(Vector2.ZERO, 17, color)
	draw_circle(Vector2(-4, -4), 6, Color(1, 1, 1, 0.8))
