extends Node2D
## 深空背景: 竖向渐变 + 漂移闪烁星星 + 轮盘后柔光

var stars: Array = []
var glow_pos := Vector2(540, 640)
var glow_color := Color(0.35, 0.85, 1.0)


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 90:
		stars.append({
			"pos": Vector2(rng.randf_range(0, 1080), rng.randf_range(0, 1920)),
			"speed": rng.randf_range(6.0, 22.0),
			"size": rng.randf_range(1.5, 4.0),
			"phase": rng.randf_range(0.0, TAU),
		})


func _process(delta: float) -> void:
	for s in stars:
		var p: Vector2 = s["pos"]
		p.y += s["speed"] * delta
		if p.y > 1924:
			p.y = -4.0
			p.x = randf() * 1080.0
		s["pos"] = p
		s["phase"] = s["phase"] + delta * 2.0
	queue_redraw()


func _draw() -> void:
	# 竖向渐变(深靛 -> 暗蓝)
	# 按舞台实际覆盖范围绘制: 长屏上舞台比设计尺寸(1920)更高,
	# 只画到 1920 会在上下露出窗口底色
	var h := 1920.0
	var top := 0.0
	var parent := get_parent() as Control
	if parent and parent.scale.y > 0.0:
		var vp_h := get_viewport_rect().size.y
		top = -parent.position.y / parent.scale.y
		h = vp_h / parent.scale.y
	var steps := 32
	for i in steps:
		var t := float(i) / steps
		var c := Color(0.03, 0.04, 0.10).lerp(Color(0.09, 0.11, 0.24), t)
		draw_rect(Rect2(0, top + t * h, 1080, h / steps + 1), c)
	# 轮盘后柔光(同心圆近似径向渐变)
	for i in 6:
		draw_circle(glow_pos, 520.0 - i * 80.0, Color(glow_color, 0.028))
	# 星星(呼吸闪烁)
	for s in stars:
		var a := 0.3 + 0.35 * (0.5 + 0.5 * sin(s["phase"]))
		draw_circle(s["pos"], s["size"], Color(0.8, 0.86, 1.0, a))
