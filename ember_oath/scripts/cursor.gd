class_name MapCursor
extends Node2D
## 地图光标：黄色四角括号，带呼吸脉冲；换格时短距离滑动

const TILE := 64
const GLIDE_TIME := 0.06

var grid_pos := Vector2i.ZERO
var _t := 0.0
var _glide: Tween


func _ready() -> void:
	z_index = 10


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## grid_pos 立即生效（逻辑以它为准），画面位置滑过去；snap=true 直接跳
func set_grid(p: Vector2i, snap := false) -> void:
	grid_pos = p
	var target := Vector2(p) * TILE
	if _glide != null and _glide.is_valid():
		_glide.kill()
	if snap or not is_inside_tree() or position.distance_to(target) > TILE * 6:
		position = target
		return
	_glide = create_tween()
	_glide.tween_property(self, "position", target, GLIDE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	var pulse := 1.0 + sin(_t * 6.0) * 0.15
	var col := Color(1.0, 0.9, 0.2, 0.95)
	var shadow := Color(0.10, 0.06, 0.02, 0.55)
	var m := 3.0
	var seg := 14.0 * pulse
	var s := TILE - m * 2
	var corners := [Vector2(m, m), Vector2(m + s, m), Vector2(m, m + s), Vector2(m + s, m + s)]
	var dirs := [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for i in 4:
		var o: Vector2 = corners[i]
		var d: Vector2 = dirs[i]
		# 先画一层深色描边，亮黄在任何地形上都看得清
		draw_line(o, o + Vector2(d.x * seg, 0), shadow, 6.0)
		draw_line(o, o + Vector2(0, d.y * seg), shadow, 6.0)
	for i in 4:
		var o: Vector2 = corners[i]
		var d: Vector2 = dirs[i]
		draw_line(o, o + Vector2(d.x * seg, 0), col, 3.0)
		draw_line(o, o + Vector2(0, d.y * seg), col, 3.0)
