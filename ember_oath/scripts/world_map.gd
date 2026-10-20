class_name WorldMap
extends Control
## 火纹式大陆地图：章节开场先看一眼「我们在哪、从哪来」。
## 卡尔迪亚大陆用噪声在 320×180 的小图上生成（海、沙滩、草原、森林、山、雪峰、大河），×4 最近邻放大成像素风；
## 地点图标、来路虚线、当前地点的脉动光圈画在上面一层。旁白走 battle 的对话框。

const LOW := Vector2i(320, 180)
const SCALE := 4

## 地点：名字、在 1280×720 上的位置、图标类型
const PLACES := {
	"fenn": {"name": "菲恩城", "pos": Vector2(292, 168), "icon": "castle"},
	"grayrock": {"name": "灰岩村", "pos": Vector2(228, 292), "icon": "village"},
	"fortress": {"name": "北山道要塞", "pos": Vector2(340, 236), "icon": "fort"},
	"ferry": {"name": "大河渡口", "pos": Vector2(300, 372), "icon": "ferry"},
	"inn": {"name": "雪山旅店", "pos": Vector2(476, 404), "icon": "inn"},
	"whitewall": {"name": "白垣镇", "pos": Vector2(660, 430), "icon": "town"},
	"capital": {"name": "王都", "pos": Vector2(836, 446), "icon": "castle"},
	"holy": {"name": "圣都", "pos": Vector2(960, 214), "icon": "holy"},
}
## 大陆上画出来的路（地点之间的虚线）
const ROADS := [["grayrock", "fenn"], ["grayrock", "fortress"], ["grayrock", "ferry"], ["ferry", "inn"], ["inn", "whitewall"],
	["whitewall", "capital"], ["capital", "holy"], ["fenn", "holy"]]

static var _tex: ImageTexture = null

var place := ""
var from := ""
var _t := 0.0
var _route_k := 0.0                 # 来路虚线画到哪（0–1）
var _overlay: Control
var _title: Label


static func land_texture() -> ImageTexture:
	if _tex != null:
		return _tex
	var img := Image.create(LOW.x, LOW.y, false, Image.FORMAT_RGBA8)
	var n := FastNoiseLite.new()
	n.seed = 8800
	n.frequency = 0.012
	n.fractal_octaves = 4
	var f := FastNoiseLite.new()
	f.seed = 31
	f.frequency = 0.05
	var m := FastNoiseLite.new()
	m.seed = 77
	m.frequency = 0.03
	m.fractal_type = FastNoiseLite.FRACTAL_RIDGED
	var sea_d := Color8(28, 52, 92)
	var sea := Color8(44, 82, 132)
	var shallow := Color8(74, 124, 168)
	var sand := Color8(214, 196, 140)
	var grass := Color8(112, 156, 74)
	var grass2 := Color8(92, 138, 62)
	var forest := Color8(52, 98, 52)
	var hill := Color8(136, 130, 92)
	var mount := Color8(118, 104, 92)
	var snow := Color8(236, 238, 240)
	for y in LOW.y:
		for x in LOW.x:
			var u := (float(x) / LOW.x) * 2.0 - 1.0
			var v := (float(y) / LOW.y) * 2.0 - 1.0
			# 大陆：中间高、四周落进海里，噪声扰动海岸线
			var h := n.get_noise_2d(x, y) * 0.55 + 0.55 - (u * u * 0.75 + v * v * 0.95)
			var c := sea_d
			if h < -0.12:
				c = sea_d
			elif h < -0.02:
				c = sea
			elif h < 0.03:
				c = shallow
			elif h < 0.07:
				c = sand
			else:
				var ridge := m.get_noise_2d(x, y)
				# 山脉：北部一条东西向山脊（菲恩领与圣都之间）、西南群山（灰岩村）、雪岭（雪山旅店）
				var band := exp(-pow((float(y) - 50.0 + float(x) * 0.04) / 12.0, 2.0)) * 0.9 * clampf((float(x) - 100.0) / 40.0, 0.0, 1.0)
				band += exp(-pow((Vector2(x, y) - Vector2(46, 62)).length() / 24.0, 2.0)) * 0.85
				band += exp(-pow((Vector2(x, y) - Vector2(122, 104)).length() / 16.0, 2.0)) * 1.0
				var mtn := ridge * 0.45 + band * 0.75 + h * 0.15
				if mtn > 0.86:
					c = snow
				elif mtn > 0.6:
					c = mount
				elif mtn > 0.48:
					c = hill
				elif f.get_noise_2d(x, y) > 0.18:
					c = forest
				else:
					c = grass if f.get_noise_2d(x * 3.0 + 500.0, y * 3.0) < 0.1 else grass2
			img.set_pixel(x, y, c)
	# 大河：从西边群山流向东南
	var river := [Vector2(8, 88), Vector2(40, 90), Vector2(75, 94), Vector2(105, 90), Vector2(140, 84), Vector2(180, 80), Vector2(230, 76), Vector2(280, 74), Vector2(318, 72)]
	for i in river.size() - 1:
		var a: Vector2 = river[i]
		var b: Vector2 = river[i + 1]
		for k in 40:
			var p := a.lerp(b, k / 40.0)
			for dy in 2:
				var px := int(p.x)
				var py := int(p.y) + dy
				if px >= 0 and px < LOW.x and py >= 0 and py < LOW.y and img.get_pixel(px, py) != sea_d:
					img.set_pixel(px, py, shallow)
	_tex = ImageTexture.create_from_image(img)
	return _tex


func setup(place_id: String, from_id: String, title: String) -> void:
	place = place_id
	from = from_id
	name = "WorldMap"
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := ColorRect.new()
	bg.color = Color8(20, 36, 66)
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var tr_ := TextureRect.new()
	tr_.texture = land_texture()
	tr_.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr_.size = Vector2(LOW * SCALE)
	tr_.stretch_mode = TextureRect.STRETCH_SCALE
	tr_.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr_)
	_overlay = Control.new()
	_overlay.size = size
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	for id in PLACES:
		var l := Label.new()
		l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		l.text = tr(PLACES[id]["name"])
		l.add_theme_font_size_override("font_size", 18 if id == place else 15)
		l.add_theme_color_override("font_color", Color(1.0, 0.92, 0.6) if id == place else Color(0.95, 0.95, 0.9))
		l.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.1))
		l.add_theme_constant_override("outline_size", 6)
		l.position = PLACES[id]["pos"] + Vector2(14, -12)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(l)
	_title = Label.new()
	_title.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	_title.text = title
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
	_title.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.02))
	_title.add_theme_constant_override("outline_size", 8)
	_title.position = Vector2(SafeArea.MARGIN_X, SafeArea.MARGIN_Y - 8)
	add_child(_title)
	var region := Label.new()
	region.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	region.text = tr("卡尔迪亚大陆")
	region.add_theme_font_size_override("font_size", 16)
	region.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 0.8))
	region.position = Vector2(1280 - SafeArea.MARGIN_X - 120, SafeArea.MARGIN_Y)
	add_child(region)


## 淡入 + 来路虚线慢慢画出来
func intro() -> void:
	modulate.a = 0.0
	var t := create_tween()
	t.tween_property(self, "modulate:a", 1.0, 0.4)
	t.tween_property(self, "_route_k", 1.0, 1.0 if from != "" else 0.01)
	await t.finished


func outro() -> void:
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.35)
	await t.finished


func _process(delta: float) -> void:
	_t += delta
	if _overlay != null:
		_overlay.queue_redraw()


func _draw_overlay() -> void:
	for r in ROADS:
		var a: Vector2 = PLACES[r[0]]["pos"]
		var b: Vector2 = PLACES[r[1]]["pos"]
		_dashes(a, b, Color(0.95, 0.88, 0.7, 0.45), 1.0)
	if from != "" and PLACES.has(from) and PLACES.has(place):
		_dashes(PLACES[from]["pos"], PLACES[place]["pos"], Color(1.0, 0.45, 0.25), _route_k, 4.0)
	for id in PLACES:
		_icon(id, PLACES[id]["pos"], PLACES[id]["icon"])
	if PLACES.has(place):
		var c: Vector2 = PLACES[place]["pos"]
		var r := 16.0 + 6.0 * (0.5 + 0.5 * sin(_t * 4.0))
		_overlay.draw_arc(c, r, 0, TAU, 32, Color(1.0, 0.6, 0.2, 0.9), 3.0)
		_overlay.draw_arc(c, r + 6, 0, TAU, 32, Color(1.0, 0.85, 0.4, 0.35), 2.0)


func _dashes(a: Vector2, b: Vector2, col: Color, k: float, w := 2.0) -> void:
	var dist := a.distance_to(b)
	var n := int(dist / 12.0)
	for i in n:
		var t0 := float(i) / n
		if t0 > k:
			break
		var p0 := a.lerp(b, t0)
		var p1 := a.lerp(b, minf(t0 + 0.5 / n, k))
		_overlay.draw_line(p0, p1, col, w)


func _icon(id: String, c: Vector2, kind: String) -> void:
	var o := _overlay
	var dark := Color(0.15, 0.1, 0.08)
	match kind:
		"castle", "holy":
			var col := Color(0.92, 0.9, 0.85) if kind == "holy" else Color(0.75, 0.72, 0.68)
			o.draw_rect(Rect2(c + Vector2(-9, -8), Vector2(18, 14)), col)
			for i in 3:
				o.draw_rect(Rect2(c + Vector2(-9 + i * 7, -12), Vector2(4, 4)), col)
			o.draw_rect(Rect2(c + Vector2(-3, -1), Vector2(6, 7)), dark)
			o.draw_rect(Rect2(c + Vector2(-9, -12), Vector2(18, 18)), dark, false, 1.5)
			if kind == "holy":
				o.draw_line(c + Vector2(0, -20), c + Vector2(0, -12), Color(1.0, 0.85, 0.3), 2.0)
				o.draw_line(c + Vector2(-3, -17), c + Vector2(3, -17), Color(1.0, 0.85, 0.3), 2.0)
		"fort":
			o.draw_rect(Rect2(c + Vector2(-7, -8), Vector2(14, 12)), Color(0.55, 0.5, 0.45))
			o.draw_rect(Rect2(c + Vector2(-7, -8), Vector2(14, 12)), dark, false, 1.5)
			o.draw_line(c + Vector2(5, -8), c + Vector2(5, -16), dark, 1.5)
			o.draw_colored_polygon(PackedVector2Array([c + Vector2(5, -16), c + Vector2(12, -14), c + Vector2(5, -12)]), Color(0.2, 0.18, 0.2))
		"village", "town", "inn":
			var roof := Color(0.78, 0.36, 0.22) if kind != "inn" else Color(0.9, 0.95, 1.0)
			o.draw_rect(Rect2(c + Vector2(-7, -3), Vector2(14, 9)), Color(0.86, 0.76, 0.58))
			o.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, -3), c + Vector2(0, -11), c + Vector2(9, -3)]), roof)
			o.draw_rect(Rect2(c + Vector2(-7, -3), Vector2(14, 9)), dark, false, 1.5)
			if kind == "town":
				o.draw_rect(Rect2(c + Vector2(4, -10), Vector2(5, 16)), Color(0.75, 0.72, 0.68))
		"ferry":
			o.draw_line(c + Vector2(-10, 4), c + Vector2(10, 4), Color(0.6, 0.4, 0.22), 4.0)
			o.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, 0), c + Vector2(7, 0), c + Vector2(4, 6), c + Vector2(-4, 6)]), Color(0.5, 0.32, 0.18))
			o.draw_line(c + Vector2(0, 0), c + Vector2(0, -12), dark, 1.5)
			o.draw_colored_polygon(PackedVector2Array([c + Vector2(1, -12), c + Vector2(8, -3), c + Vector2(1, -3)]), Color(0.95, 0.95, 0.9))
	if id == place:
		o.draw_circle(c + Vector2(0, 10), 3.0, Color(1.0, 0.5, 0.2))
