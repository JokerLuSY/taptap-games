class_name MapFx
extends Node2D
## 地图动态层：水面涟漪（Ninja Adventure 涟漪帧，只在帧号变化时重画）、火焰格的火苗与烟、全图氛围。
## 静态地面在 MapTiles，这一层叠在它上面、高亮与单位下面。

const TILE := 64
const DIR := "res://art/cc0/ninja_adventure/tiles/"
const RIPPLE_FPS := 4.0

var board: Board
var burning := false
var _ripples: Array = []            # [格子, 相位]
var _ripple_tex: Texture2D
var _t := 0.0
var _frame := -1


func setup(b: Board, is_burning: bool) -> void:
	board = b
	burning = is_burning
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(DIR + "WaterRipples.png"):
		_ripple_tex = load(DIR + "WaterRipples.png")
	for y in board.height:
		for x in board.width:
			var p := Vector2i(x, y)
			var t := board.tile_at(p)
			var h := absi(x * 73 + y * 149 + x * y * 31)
			if t == "~" and h % 2 == 0 and b.theme != "snow":
				_ripples.append([p, h % 4])
			elif t == "E" or (t == "D" and burning):
				_add_flame(p, h)


func _process(delta: float) -> void:
	_t += delta
	# 火光忽明忽暗
	for g in _glows:
		var spr: Sprite2D = g[0]
		spr.modulate.a = 0.75 + 0.25 * sin(_t * 7.0 + g[1]) * sin(_t * 3.1 + g[1] * 2.0)
	if _ripples.is_empty():
		return
	var f := int(_t * RIPPLE_FPS)
	if f != _frame:
		_frame = f
		queue_redraw()


func _draw() -> void:
	if _ripple_tex == null:
		return
	for r in _ripples:
		var p: Vector2i = r[0]
		var k: int = (_frame + int(r[1])) % 4
		# 涟漪帧自带水色底，×2 贴在格子水面带的正中
		var dst := Rect2(Vector2(p) * TILE + Vector2(16, 16), Vector2(32, 32))
		draw_texture_rect_region(_ripple_tex, dst, Rect2(k * 16, 0, 16, 16))


var _glows: Array = []


## 火焰格：火苗 + 一团加亮的火光 + 上飘的烟。火光和火苗画在氛围层之上（z 相对 +8），夜里也是亮的。
func _add_flame(p: Vector2i, h: int) -> void:
	var c := Vector2(p) * TILE + Vector2(TILE / 2.0, TILE * 0.8)
	var add := CanvasItemMaterial.new()
	add.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	var glow := Sprite2D.new()
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	var gg := Gradient.new()
	gg.set_color(0, Color(1.0, 0.55, 0.2, 0.55))
	gg.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
	gt.gradient = gg
	gt.width = 64
	gt.height = 64
	glow.texture = gt
	glow.scale = Vector2(3.2, 2.6)
	glow.position = c + Vector2(0, -14)
	glow.material = add
	glow.z_index = 8
	add_child(glow)
	_glows.append([glow, float(h % 10) * 0.7])
	var fire := CPUParticles2D.new()
	fire.local_coords = true          # 粒子跟着地图走，拖动地图时火苗不会留在原地
	fire.material = add
	fire.z_index = 8
	if ResourceLoader.exists(DIR + "Fire.png"):
		var at := AtlasTexture.new()
		at.atlas = load(DIR + "Fire.png")
		at.region = Rect2(24, 0, 12, 12)
		fire.texture = at
	fire.amount = 14
	fire.lifetime = 0.8
	fire.preprocess = 1.0
	fire.position = c
	fire.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fire.emission_rect_extents = Vector2(18, 4)
	fire.direction = Vector2(0, -1)
	fire.spread = 12.0
	fire.gravity = Vector2(0, -60)
	fire.initial_velocity_min = 20.0
	fire.initial_velocity_max = 45.0
	fire.scale_amount_min = 2.5
	fire.scale_amount_max = 4.0
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.6))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1, 0.1))
	fire.scale_amount_curve = curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 0.95, 0.7, 1.0))
	ramp.set_color(1, Color(1.0, 0.35, 0.1, 0.0))
	fire.color_ramp = ramp
	fire.randomness = 0.4
	fire.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(fire)
	var smoke := CPUParticles2D.new()
	smoke.local_coords = true
	smoke.amount = 5
	smoke.lifetime = 2.6
	smoke.preprocess = 2.6
	smoke.position = c + Vector2(0, -28)
	smoke.direction = Vector2(0.3, -1)
	smoke.spread = 15.0
	smoke.gravity = Vector2(8, -10)
	smoke.initial_velocity_min = 15.0
	smoke.initial_velocity_max = 25.0
	smoke.scale_amount_min = 10.0
	smoke.scale_amount_max = 16.0
	var sramp := Gradient.new()
	sramp.set_color(0, Color(0.3, 0.27, 0.25, 0.45))
	sramp.set_color(1, Color(0.4, 0.38, 0.36, 0.0))
	smoke.color_ramp = sramp
	smoke.randomness = 0.5 + float(h % 3) * 0.1
	smoke.z_index = 7
	add_child(smoke)
