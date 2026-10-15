class_name Board
extends Node2D
## 地图：GBA 火纹风地形（程序纹理 + 噪点色斑）、移动范围（BFS）、寻路、高亮

const TILE := 64
const DIRS4 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## 地形底色（纹理以此为基础做明暗噪点；整体偏 GBA 的低饱和暖色调）
const BASE_COLORS := {
	".": Color(0.47, 0.61, 0.35),
	"R": Color(0.74, 0.65, 0.47),
	"F": Color(0.26, 0.46, 0.25),
	"H": Color(0.47, 0.61, 0.35),
	"B": Color(0.17, 0.37, 0.62),
	"~": Color(0.17, 0.37, 0.62),
	"M": Color(0.50, 0.47, 0.42),
	"f": Color(0.56, 0.44, 0.29),
	"W": Color(0.47, 0.61, 0.35),
	"X": Color(0.50, 0.47, 0.42),
}

## AI 手绘纹理（res://art/terrain/<base>_<0..3>.png）
const TEX_FILES := {
	".": "grass", "g": "hill", "R": "dirt", "~": "water", "B": "water",
	"F": "forest", "f": "dirt", "M": "mount", "H": "grass", "W": "grass", "s": "sand",
	"X": "mount", "rock": "rock",
}

var rows: Array = []
var levels: Array = []              # 高度层（字符串数组, 与 rows 同尺寸）
var width := 0
var height := 0
var units: Array = []               # 与 battle.units 共享同一数组引用
var bg_texture: Texture2D = null    # AI 手绘地图背景（有则进入整图模式）

# 高亮状态
var move_tiles: Dictionary = {}
var atk_tiles: Dictionary = {}
var danger_tiles: Dictionary = {}
var path_tiles: Array = []

var _t := 0.0                       # 水面动画时钟
var _tex_cache := {}
var _noise := FastNoiseLite.new()
var _noise2 := FastNoiseLite.new()  # 低频大块明暗

const CLIFF_S := 16.0               # 南面悬崖高度
const CLIFF_W := 10.0               # 侧面悬崖宽度


func _ready() -> void:
	_noise.seed = 20261010
	_noise.frequency = 0.22
	_noise2.seed = 777
	_noise2.frequency = 0.07


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func load_map(map_rows: Array, map_levels: Array = [], bg_path := "") -> void:
	rows = map_rows
	levels = map_levels
	height = rows.size()
	width = rows[0].length()
	if bg_path != "" and ResourceLoader.exists(bg_path):
		bg_texture = load(bg_path)
	queue_redraw()


func level_at(p: Vector2i) -> int:
	if levels.is_empty() or not in_bounds(p):
		return 1
	return levels[p.y].substr(p.x, 1).to_int()


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func tile_at(p: Vector2i) -> String:
	if not in_bounds(p):
		return "~"
	return rows[p.y].substr(p.x, 1)


func terrain(p: Vector2i) -> Dictionary:
	return GameData.TERRAIN[tile_at(p)]


func unit_at(p: Vector2i) -> Unit:
	for u in units:
		if u.is_alive() and u.grid_pos == p:
			return u
	return null


func passable(p: Vector2i, for_unit: Unit) -> bool:
	if not in_bounds(p):
		return false
	if not terrain(p)["pass"]:
		return false
	var occ := unit_at(p)
	if occ != null and occ != for_unit and occ.faction != for_unit.faction:
		return false
	return true


## BFS 移动范围: {格子: 到达后剩余移动力}，不含其他单位占据的格子
func move_range(u: Unit) -> Dictionary:
	if u.stationary:
		return {u.grid_pos: u.mov}
	var result := {u.grid_pos: u.mov}
	var frontier: Array = [u.grid_pos]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		var left: int = result[cur]
		for d in DIRS4:
			var np: Vector2i = cur + d
			if not passable(np, u):
				continue
			var remain: int = left - _enter_cost(cur, np)
			if remain < 0:
				continue
			if result.has(np) and result[np] >= remain:
				continue
			result[np] = remain
			frontier.append(np)
	for other in units:
		if other != u and other.is_alive():
			result.erase(other.grid_pos)
	return result


## 进入 np 的代价 = 地形消耗 + 爬升高度差 ×2（下坡不加价）
func _enter_cost(from_p: Vector2i, np: Vector2i) -> int:
	var climb: int = maxi(0, level_at(np) - level_at(from_p)) * 2
	return terrain(np)["cost"] + climb


## 从 p 出发、给定射程列表（曼哈顿距离）的所有攻击格
func attack_from(p: Vector2i, ranges: Array) -> Array:
	var out: Array = []
	for r in ranges:
		for dx in range(-r, r + 1):
			var dy: int = r - absi(dx)
			var signs: Array = [1] if dy == 0 else [1, -1]
			for s in signs:
				var np := Vector2i(p.x + dx, p.y + dy * s)
				if in_bounds(np) and np not in out:
					out.append(np)
	return out


## 有效射程（弓箭手站高地 +1 射程）
func eff_ranges(u: Unit) -> Array:
	var r: Array = u.weapon_ranges().duplicate()
	if _range_bonus(u) > 0:
		for i in range(1, _range_bonus(u) + 1):
			r.append(2 + i)
	return r


func _range_bonus(u: Unit) -> int:
	return 1 if u.weapon_kind() == "bow" and level_at(u.grid_pos) >= 2 else 0


func can_hit_from(u: Unit, d: int, wi: int) -> bool:
	if u.can_hit(d, wi):
		return true
	return u.weapon(wi)["type"] == "bow" and _range_bonus(u) > 0 and d > 2 and d <= 2 + _range_bonus(u)


## 移动后可攻击的全部格子
func full_attack_area(u: Unit, move: Dictionary) -> Dictionary:
	var area := {}
	var ranges: Array = eff_ranges(u)
	for tile in move.keys():
		for t in attack_from(tile, ranges):
			area[t] = true
	return area


## 在移动范围内回溯一条路径（含 dst，不含起点）
func find_path(u: Unit, dst: Vector2i, range_dict: Dictionary) -> Array:
	if dst == u.grid_pos:
		return []
	var parent := {u.grid_pos: Vector2i(-99, -99)}
	var cost_left := {u.grid_pos: u.mov}
	var frontier: Array = [u.grid_pos]
	while not frontier.is_empty():
		var cur: Vector2i = frontier.pop_front()
		if cur == dst:
			break
		for d in DIRS4:
			var np: Vector2i = cur + d
			if not range_dict.has(np):
				continue
			if not passable(np, u):
				continue
			var remain: int = cost_left[cur] - _enter_cost(cur, np)
			if remain < 0:
				continue
			if cost_left.has(np) and cost_left[np] >= remain:
				continue
			cost_left[np] = remain
			parent[np] = cur
			frontier.append(np)
	if not parent.has(dst):
		return []
	var path: Array = []
	var c := dst
	while c != u.grid_pos:
		path.push_front(c)
		c = parent[c]
	return path


# ---------- 高亮 ----------

func show_move(move: Dictionary, atk: Dictionary) -> void:
	move_tiles = move
	atk_tiles = atk
	queue_redraw()


func clear_highlights() -> void:
	move_tiles = {}
	atk_tiles = {}
	path_tiles = []
	queue_redraw()


func set_danger(tiles: Dictionary) -> void:
	danger_tiles = tiles
	queue_redraw()


func set_path(path: Array) -> void:
	path_tiles = path
	queue_redraw()


# ---------- 地形纹理生成 ----------

## 加载 AI 手绘纹理（缺失时回退到程序生成）
func _terrain_tex(t: String, variant: int) -> Texture2D:
	var key := "%s:%d" % [t, variant]
	if _tex_cache.has(key):
		return _tex_cache[key]
	var base: String = TEX_FILES.get(t, "grass")
	var path := "res://art/terrain/%s_%d.png" % [base, variant]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	else:
		tex = _gen_fallback_tex(t, variant)
	_tex_cache[key] = tex
	return tex


## 程序生成回退纹理（带噪点明暗 + 色斑）
func _gen_fallback_tex(t: String, variant: int) -> ImageTexture:
	var img := Image.create(TILE, TILE, false, Image.FORMAT_RGBA8)
	var base: Color = BASE_COLORS[t]
	for y in TILE:
		for x in TILE:
			var n := _noise.get_noise_2d(x + variant * 137, y + variant * 61)
			var n2 := _noise2.get_noise_2d(x + variant * 57, y + variant * 91)
			var b := (1.0 + n * 0.11) * (1.0 + n2 * 0.10)
			img.set_pixel(x, y, Color(
				clampf(base.r * b, 0.0, 1.0),
				clampf(base.g * b, 0.0, 1.0),
				clampf(base.b * b, 0.0, 1.0)))
	# 色斑颗粒（模拟手绘点彩）
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%s:%d" % [t, variant])
	for i in 46:
		var px := rng.randi_range(0, TILE - 1)
		var py := rng.randi_range(0, TILE - 1)
		var cc: Color = base.darkened(0.10) if rng.randf() < 0.55 else base.lightened(0.10)
		img.set_pixel(px, py, cc)
	return ImageTexture.create_from_image(img)


func _fill_tex(p: Vector2i, t: String) -> void:
	draw_texture(_terrain_tex(t, _hash(p) % 4), Vector2(p) * TILE)


# ---------- 绘制 ----------

func _fill(p: Vector2i, c: Color) -> void:
	draw_rect(Rect2(Vector2(p) * TILE, Vector2(TILE, TILE)), c)


func _hash(p: Vector2i) -> int:
	return (p.x * 73 + p.y * 149 + p.x * p.y * 31) % 100


func _draw() -> void:
	if bg_texture != null:
		draw_texture(bg_texture, Vector2.ZERO)
		_draw_painted_landmarks()
	else:
		for y in height:
			for x in width:
				_draw_tile(Vector2i(x, y))
		_draw_cliffs()
	# 网格线
	var grid_col := Color(0, 0, 0, 0.05)
	for x in width + 1:
		draw_line(Vector2(x * TILE, 0), Vector2(x * TILE, height * TILE), grid_col)
	for y in height + 1:
		draw_line(Vector2(0, y * TILE), Vector2(width * TILE, y * TILE), grid_col)
	# 高亮：危险 -> 移动 -> 攻击
	for p in danger_tiles:
		_fill(p, Color(1, 0.2, 0.2, 0.16))
	for p in move_tiles:
		_fill(p, Color(0.3, 0.6, 1.0, 0.30))
	for p in atk_tiles:
		_fill(p, Color(1.0, 0.25, 0.2, 0.38))
	# 路径预览
	if path_tiles.size() >= 2:
		var pts := PackedVector2Array()
		for p in path_tiles:
			pts.append(Vector2(p) * TILE + Vector2(TILE / 2.0, TILE / 2.0))
		draw_polyline(pts, Color(1, 1, 1, 0.75), 4.0)


func _draw_tile(p: Vector2i) -> void:
	var t := tile_at(p)
	var c := Vector2(p) * TILE
	match t:
		".":
			_fill_tex(p, ".")
			_draw_grass_detail(p, c)
		"R":
			_fill_tex(p, ".")
			_draw_road(p, c)
		"F":
			_fill_tex(p, "F")
			_draw_tree(p, c)
		"H":
			_fill_tex(p, ".")
			_draw_house(p, c)
		"B":
			_draw_bridge(p, c)
		"~":
			_draw_water(p, c)
		"M":
			_fill_tex(p, "M")
			_draw_mountain(c)
		"X":
			_fill_tex(p, "X")
		"f":
			_draw_field(p, c)
		"g":
			_fill_tex(p, "g")
			_draw_grass_detail(p, c)
		"s":
			_fill_tex(p, "s")
			_draw_sand_detail(p, c)
		"W":
			_fill_tex(p, ".")
			_draw_well(c)
		_:
			_fill(p, Color.MAGENTA)
	# 岸边装饰
	_draw_rocks(p, c)
	_draw_reeds(p, c)


func _is_lowland(t: String) -> bool:
	return t == "s"


var _sprite_cache := {}


func _sprite_tex(spr_name: String) -> Texture2D:
	if not _sprite_cache.has(spr_name):
		var path := "res://art/sprites/%s.png" % spr_name
		_sprite_cache[spr_name] = load(path) if ResourceLoader.exists(path) else null
	return _sprite_cache[spr_name]


## 以格子中心偏下为基座点绘制精灵（底边贴地, 顶部自然探出格子上沿, 3/4 视角）
func _jit(h: int, k: int) -> float:
	return float((h * (k + 2)) % 7) - 3.0


func _draw_sprite(spr_name: String, tile_center: Vector2, w: float) -> void:
	var tex := _sprite_tex(spr_name)
	if tex == null:
		return
	var h: float = w * tex.get_height() / tex.get_width()
	var base := Vector2(tile_center.x, tile_center.y + 16.0)
	# 落地阴影（双层压扁椭圆, 内层贴住精灵底边, 外层向外晕开）
	draw_set_transform(base + Vector2(0, 2), 0, Vector2(w / 32.0, 0.30))
	draw_circle(Vector2.ZERO, 14.0, Color(0.04, 0.07, 0.03, 0.30))
	draw_set_transform(base + Vector2(0, 5), 0, Vector2(w / 26.0, 0.26))
	draw_circle(Vector2.ZERO, 14.0, Color(0.04, 0.07, 0.03, 0.15))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	draw_texture_rect(tex, Rect2(tile_center.x - w / 2, base.y - h, w, h), false)


## 整图模式：只叠加手绘无法表达的逻辑地标（精灵/农田/波光），
## 道路/木桥/高台麦田/梯田石墙/沙滩全部交给手绘背景（逻辑网格已与手绘对齐）
func _draw_painted_landmarks() -> void:
	for y in height:
		for x in width:
			var p := Vector2i(x, y)
			var c := Vector2(p) * TILE
			var center := c + Vector2(TILE / 2.0, TILE / 2.0)
			match tile_at(p):
				"H":
					_draw_sprite("house", center, 78)
				"W":
					_draw_sprite("well", center, 54)
				"M":
					_draw_sprite("mountain", center, 66)
				"f":
					_draw_field_painted(p, c)
				"~":
					_draw_water_sparkles(p, c)


## 只画漂移波光（整图模式下叠加在手绘河面上）
func _draw_water_sparkles(p: Vector2i, c: Vector2) -> void:
	var h := _hash(p)
	for i in 3:
		var sx := c.x + fmod(h * 7 + i * 19 + _t * 6.0, 64.0)
		var sy := c.y + 14 + i * 16 + sin(_t * 2.0 + i * 1.7) * 2.0
		var tw := 0.30 + 0.28 * sin(_t * 3.0 + i * 2.1 + h)
		draw_circle(Vector2(sx, sy), 1.4, Color(0.85, 0.95, 1.0, tw))


func _is_water(p: Vector2i) -> bool:
	return tile_at(p) == "~"


## 水边芦苇（临水陆地, 按 hash 稀疏分布）
func _draw_reeds(p: Vector2i, c: Vector2) -> void:
	var t := tile_at(p)
	if _is_water(p) or t == "B" or t == "s":
		return
	var h := _hash(p)
	if h % 3 != 0:
		return
	var base := Vector2(-99, -99)
	if _is_water(p + Vector2i(0, 1)):
		base = c + Vector2(10 + h % 40, TILE - 3)
	elif _is_water(p + Vector2i(0, -1)):
		base = c + Vector2(10 + h % 40, 3)
	elif _is_water(p + Vector2i(-1, 0)):
		base = c + Vector2(3, 10 + h % 40)
	elif _is_water(p + Vector2i(1, 0)):
		base = c + Vector2(TILE - 3, 10 + h % 40)
	if base.x < 0:
		return
	var reed_col := Color(0.35, 0.50, 0.22)
	for i in 4:
		var rx := base.x + i * 3 - 5
		var rh := 9 + (i + h) % 4
		draw_line(Vector2(rx, base.y), Vector2(rx - 1, base.y - rh), reed_col, 1.5)
	draw_rect(Rect2(base.x - 6, base.y - 13, 2.5, 5), Color(0.45, 0.32, 0.18))
	draw_rect(Rect2(base.x + 3, base.y - 11, 2.5, 4), Color(0.45, 0.32, 0.18))


## 东缘瀑布（河水跌出地图）
func _draw_waterfall(c: Vector2) -> void:
	var x0 := c.x + TILE - 16.0
	for i in 5:
		var wx := x0 + i * 3.0
		var off := fmod(_t * 40.0 + i * 13.0, 22.0)
		draw_line(Vector2(wx, c.y + 4 + off), Vector2(wx, c.y + 20 + off), Color(0.85, 0.95, 1.0, 0.75), 2.2)
	draw_circle(c + Vector2(TILE - 6, 54), 8.0 + sin(_t * 3.0) * 2.0, Color(0.85, 0.95, 1.0, 0.35))
	draw_circle(c + Vector2(TILE - 10, 58), 5.0 + cos(_t * 2.4) * 1.5, Color(0.85, 0.95, 1.0, 0.28))


## 沙滩细节（湿沙线 + 贝壳）
func _draw_sand_detail(p: Vector2i, c: Vector2) -> void:
	if _is_water(p + Vector2i(0, 1)):
		draw_rect(Rect2(c + Vector2(0, TILE - 6), Vector2(TILE, 6)), Color(0.68, 0.60, 0.44, 0.55))
	if _is_water(p + Vector2i(0, -1)):
		draw_rect(Rect2(c, Vector2(TILE, 6)), Color(0.68, 0.60, 0.44, 0.55))
	if _is_water(p + Vector2i(-1, 0)):
		draw_rect(Rect2(c, Vector2(6, TILE)), Color(0.68, 0.60, 0.44, 0.55))
	if _is_water(p + Vector2i(1, 0)):
		draw_rect(Rect2(c + Vector2(TILE - 6, 0), Vector2(6, TILE)), Color(0.68, 0.60, 0.44, 0.55))
	var h := _hash(p)
	if h % 4 == 0:
		draw_circle(c + Vector2(20 + h % 20, 24 + h % 3 * 8), 2.0, Color(0.92, 0.88, 0.80))
		draw_circle(c + Vector2(21 + h % 20, 24 + h % 3 * 8), 1.0, Color(0.80, 0.72, 0.62))


## 岸边散落礁石
func _draw_rocks(p: Vector2i, c: Vector2) -> void:
	var near_water := false
	for d in DIRS4:
		if _is_water(p + d):
			near_water = true
	if not near_water:
		return
	var h := _hash(p)
	if h % 5 != 0:
		return
	var rx := c.x + 12 + (h % 7) * 5
	var ry := c.y + 14 + (h % 5) * 7
	draw_circle(Vector2(rx + 1, ry + 1), 4.2, Color(0.25, 0.24, 0.23))
	draw_circle(Vector2(rx, ry), 4.0, Color(0.55, 0.53, 0.50))
	draw_circle(Vector2(rx - 1, ry - 1), 1.6, Color(0.70, 0.68, 0.64))
	draw_circle(Vector2(rx + 7, ry + 3), 2.6, Color(0.25, 0.24, 0.23))
	draw_circle(Vector2(rx + 6.5, ry + 2.5), 2.4, Color(0.50, 0.48, 0.45))


## 第二遍：凡是有高度差的相邻地块都画悬崖立面
func _draw_cliffs() -> void:
	for y in height:
		for x in width:
			var p := Vector2i(x, y)
			var t := tile_at(p)
			if t == "B":
				continue
			var lv := level_at(p)
			var c := Vector2(p) * TILE
			if level_at(p + Vector2i(0, 1)) < lv:
				_draw_cliff_south(c, p)
			if level_at(p + Vector2i(-1, 0)) < lv:
				_draw_cliff_side(c, -1)
			if level_at(p + Vector2i(1, 0)) < lv:
				_draw_cliff_side(c, 1)


func _draw_cliff_south(c: Vector2, p: Vector2i) -> void:
	# 岩壁纹理
	var rock: Texture2D = _terrain_tex("rock", _hash(p) % 4)
	draw_texture_rect(rock, Rect2(c + Vector2(0, TILE - 1), Vector2(TILE, CLIFF_S + 2)), false)
	# 底部暗边
	draw_line(c + Vector2(2, TILE + CLIFF_S), c + Vector2(TILE - 2, TILE + CLIFF_S), Color(0.25, 0.18, 0.12), 2.5)
	# 顶部草唇
	draw_line(c + Vector2(0, TILE - 1), c + Vector2(TILE, TILE - 1), Color(0.62, 0.71, 0.42), 2.2)
	# 垂草
	var h := _hash(p)
	for i in 3:
		var gx := c.x + 10 + ((h + i * 17) % 44)
		var gl := 4 + (h + i * 5) % 4
		draw_line(Vector2(gx, TILE - 1 + c.y), Vector2(gx - 1, TILE - 1 + c.y + gl), Color(0.34, 0.48, 0.22), 1.8)
	# 崖底是水面 → 投影 + 沙带 + 泡沫
	if _is_water(p + Vector2i(0, 1)):
		draw_rect(Rect2(c + Vector2(2, TILE + CLIFF_S - 1), Vector2(TILE - 4, 4)), Color(0.05, 0.12, 0.25, 0.35))
		draw_line(c + Vector2(0, TILE + CLIFF_S + 3), c + Vector2(TILE, TILE + CLIFF_S + 3), Color(0.83, 0.75, 0.57), 3.2)
		draw_line(c + Vector2(0, TILE + CLIFF_S + 5.5), c + Vector2(TILE, TILE + CLIFF_S + 5.5), Color(0.78, 0.90, 1.0, 0.7), 1.8)


func _draw_cliff_side(c: Vector2, side: int) -> void:
	# side: -1 西, 1 东
	var x0: float = c.x if side < 0 else c.x + TILE
	var out := -CLIFF_W * side
	var top := Vector2(x0, c.y + 6)
	var mid := Vector2(x0, c.y + TILE - 6)
	var bot := Vector2(x0 + out, c.y + TILE - 10)
	var bot2 := Vector2(x0 + out, c.y + 10)
	draw_colored_polygon(PackedVector2Array([top, mid, bot, bot2]), Color(0.50, 0.38, 0.25))
	draw_line(top, bot2, Color(0.43, 0.32, 0.21), 1.4)
	draw_line(Vector2(x0, c.y + 6), Vector2(x0, c.y + TILE - 6), Color(0.62, 0.71, 0.42), 1.6)


func _draw_grass_detail(p: Vector2i, c: Vector2) -> void:
	var h := _hash(p)
	if h % 13 == 0:
		var gx := c.x + 12 + (h % 3) * 14
		var gy := c.y + 40 + (h % 2) * 10
		var gcol := Color(0.30, 0.52, 0.26)
		draw_line(Vector2(gx, gy), Vector2(gx - 2, gy - 8), gcol, 1.6)
		draw_line(Vector2(gx + 3, gy), Vector2(gx + 3, gy - 9), gcol, 1.6)
		draw_line(Vector2(gx + 6, gy), Vector2(gx + 8, gy - 8), gcol, 1.6)
	if h % 17 == 0:
		var fx := c.x + 16 + (h % 4) * 10
		var fy := c.y + 18 + (h % 3) * 12
		var fcol: Color = [Color(0.95, 0.90, 0.55), Color(0.95, 0.75, 0.80), Color(0.90, 0.90, 0.95)][h % 3]
		draw_circle(Vector2(fx, fy), 2.2, fcol)
		draw_circle(Vector2(fx + 4, fy + 2), 1.6, fcol)


func _draw_road(p: Vector2i, c: Vector2) -> void:
	draw_texture(_terrain_tex("R", _hash(p) % 4), c)
	# 与草地交界处的不规则描边（低透明度, 软过渡）
	var edge_col := Color(0.60, 0.50, 0.34, 0.45)
	var w := 4.0
	if tile_at(p + Vector2i(0, -1)) != "R" and tile_at(p + Vector2i(0, -1)) != "B":
		draw_rect(Rect2(c, Vector2(TILE, w)), edge_col)
	if tile_at(p + Vector2i(0, 1)) != "R" and tile_at(p + Vector2i(0, 1)) != "B":
		draw_rect(Rect2(c + Vector2(0, TILE - w), Vector2(TILE, w)), edge_col)
	if tile_at(p + Vector2i(-1, 0)) != "R" and tile_at(p + Vector2i(-1, 0)) != "B":
		draw_rect(Rect2(c, Vector2(w, TILE)), edge_col)
	if tile_at(p + Vector2i(1, 0)) != "R" and tile_at(p + Vector2i(1, 0)) != "B":
		draw_rect(Rect2(c + Vector2(TILE - w, 0), Vector2(w, TILE)), edge_col)
	# 路面碎石
	var h := _hash(p)
	draw_circle(c + Vector2(18 + h % 20, 20 + h % 3 * 8), 1.8, Color(0.62, 0.52, 0.38))
	draw_circle(c + Vector2(38 - h % 15, 44 - h % 2 * 6), 1.4, Color(0.66, 0.56, 0.40))


func _draw_tree(p: Vector2i, c: Vector2) -> void:
	var h := _hash(p)
	if h % 10 < 3:
		_draw_pine(c)
		return
	var off := float(h % 5) - 2.0
	# 阴影
	draw_set_transform(c + Vector2(32, 47), 0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 15, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# 树干
	draw_rect(Rect2(c + Vector2(28.5, 30), Vector2(7, 17)), Color(0.13, 0.10, 0.09))
	draw_rect(Rect2(c + Vector2(29.5, 30), Vector2(5, 16)), Color(0.36, 0.26, 0.16))
	# 树冠：成簇圆球（GBA 花椰菜式），先描边后填色
	var dark := Color(0.14, 0.34, 0.16)
	var outline := Color(0.08, 0.20, 0.10)
	var blobs := [
		[Vector2(32 + off * 0.5, 24), 12.0],
		[Vector2(24, 30), 9.0],
		[Vector2(40, 30), 9.0],
		[Vector2(28, 19), 8.0],
		[Vector2(36, 19), 8.0],
	]
	for b in blobs:
		draw_circle(c + b[0], b[1] + 1.6, outline)
	for b in blobs:
		draw_circle(c + b[0], b[1], dark)
	# 受光面
	var light := Color(0.22, 0.46, 0.21)
	draw_circle(c + Vector2(27, 20), 5.5, light)
	draw_circle(c + Vector2(35, 18), 4.0, light)
	draw_circle(c + Vector2(23, 27), 3.0, light)


## 针叶松（三层三角）
func _draw_pine(c: Vector2) -> void:
	var outline := Color(0.08, 0.20, 0.10)
	# 阴影
	draw_set_transform(c + Vector2(32, 47), 0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 13, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# 树干
	draw_rect(Rect2(c + Vector2(29.5, 34), Vector2(5, 13)), Color(0.36, 0.26, 0.16))
	var layers := [
		[15.0, 46.0, 26.0, Color(0.12, 0.30, 0.15)],
		[19.0, 36.0, 17.0, Color(0.15, 0.37, 0.18)],
		[23.0, 26.0, 8.0, Color(0.19, 0.44, 0.21)],
	]
	for layer in layers:
		var half_w: float = layer[0]
		var base_y: float = layer[1]
		var top_y: float = layer[2]
		var col: Color = layer[3]
		var tri := PackedVector2Array([
			c + Vector2(32 - half_w, base_y), c + Vector2(32 + half_w, base_y), c + Vector2(32, top_y)])
		draw_colored_polygon(tri, outline)
		var tri_in := PackedVector2Array([
			c + Vector2(32 - half_w + 2, base_y - 1), c + Vector2(32 + half_w - 2, base_y - 1), c + Vector2(32, top_y + 2.5)])
		draw_colored_polygon(tri_in, col)
	# 左侧受光
	draw_line(c + Vector2(32, 10), c + Vector2(22, 44), Color(0.26, 0.52, 0.26), 2.0)


func _draw_house(p: Vector2i, c: Vector2) -> void:
	var h := _hash(p)
	var outline := Color(0.16, 0.12, 0.10)
	# 阴影
	draw_rect(Rect2(c + Vector2(15, 50), Vector2(38, 6)), Color(0, 0, 0, 0.25))
	# 墙体（上亮下暗）
	draw_rect(Rect2(c + Vector2(13, 25), Vector2(38, 27)), outline)
	draw_rect(Rect2(c + Vector2(14, 26), Vector2(36, 25)), Color(0.78, 0.68, 0.50))
	draw_rect(Rect2(c + Vector2(14, 40), Vector2(36, 11)), Color(0.66, 0.56, 0.40))
	# 木框架
	var timber := Color(0.42, 0.30, 0.19)
	draw_rect(Rect2(c + Vector2(14, 26), Vector2(3, 25)), timber)
	draw_rect(Rect2(c + Vector2(47, 26), Vector2(3, 25)), timber)
	draw_rect(Rect2(c + Vector2(14, 38), Vector2(36, 2.5)), timber)
	# 屋顶（描边 + 瓦垄线）
	var roof := PackedVector2Array([c + Vector2(9, 28), c + Vector2(32, 6), c + Vector2(55, 28)])
	draw_colored_polygon(roof, outline)
	var roof_in := PackedVector2Array([c + Vector2(11.5, 27), c + Vector2(32, 8.5), c + Vector2(52.5, 27)])
	draw_colored_polygon(roof_in, Color(0.68, 0.28, 0.20))
	for i in 3:
		var yy := 24.0 - i * 6.0
		var half_w := 21.0 - i * 5.4
		draw_line(c + Vector2(32 - half_w, yy), c + Vector2(32 + half_w, yy), Color(0.52, 0.20, 0.14), 1.6)
	draw_line(c + Vector2(32, 8.5), c + Vector2(32, 27), Color(0.52, 0.20, 0.14), 1.4)
	# 烟囱
	if h % 2 == 0:
		draw_rect(Rect2(c + Vector2(39, 6), Vector2(7, 13)), outline)
		draw_rect(Rect2(c + Vector2(40, 7), Vector2(5, 12)), Color(0.55, 0.50, 0.48))
	# 门和窗
	draw_rect(Rect2(c + Vector2(27, 37), Vector2(11, 15)), outline)
	draw_rect(Rect2(c + Vector2(28, 38), Vector2(9, 14)), Color(0.40, 0.28, 0.16))
	draw_circle(c + Vector2(35, 45), 1.0, Color(0.75, 0.65, 0.4))
	draw_rect(Rect2(c + Vector2(17, 30), Vector2(8, 8)), outline)
	draw_rect(Rect2(c + Vector2(18, 31), Vector2(6, 6)), Color(0.55, 0.75, 0.85))
	draw_rect(Rect2(c + Vector2(40, 30), Vector2(8, 8)), outline)
	draw_rect(Rect2(c + Vector2(41, 31), Vector2(6, 6)), Color(0.55, 0.75, 0.85))


func _draw_water(p: Vector2i, c: Vector2) -> void:
	draw_texture(_terrain_tex("~", _hash(p) % 4), c)
	# 桥底阴影
	if tile_at(p + Vector2i(-1, 0)) == "B":
		draw_rect(Rect2(c, Vector2(6, TILE)), Color(0.04, 0.10, 0.22, 0.4))
	if tile_at(p + Vector2i(1, 0)) == "B":
		draw_rect(Rect2(c + Vector2(TILE - 6, 0), Vector2(6, TILE)), Color(0.04, 0.10, 0.22, 0.4))
	# 近岸深水暗线
	var deep := Color(0.12, 0.26, 0.48, 0.55)
	if tile_at(p + Vector2i(0, -1)) != "~" and tile_at(p + Vector2i(0, -1)) != "B":
		draw_rect(Rect2(c, Vector2(TILE, 5)), deep)
	if tile_at(p + Vector2i(0, 1)) != "~" and tile_at(p + Vector2i(0, 1)) != "B":
		draw_rect(Rect2(c + Vector2(0, TILE - 5), Vector2(TILE, 5)), deep)
	if tile_at(p + Vector2i(-1, 0)) != "~" and tile_at(p + Vector2i(-1, 0)) != "B":
		draw_rect(Rect2(c, Vector2(5, TILE)), deep)
	if tile_at(p + Vector2i(1, 0)) != "~" and tile_at(p + Vector2i(1, 0)) != "B":
		draw_rect(Rect2(c + Vector2(TILE - 5, 0), Vector2(5, TILE)), deep)
	# 动态波纹
	var w1 := sin(_t * 2.0 + p.x * 1.3 + p.y * 0.7) * 3.0
	var w2 := cos(_t * 1.6 + p.x * 0.9 - p.y * 1.1) * 3.0
	var wave_col := Color(0.55, 0.75, 1.0, 0.5)
	draw_arc(c + Vector2(18 + w1, 26), 7, 0, PI, 8, wave_col, 2.0)
	draw_arc(c + Vector2(44 + w2, 42), 7, 0, PI, 8, wave_col, 2.0)
	# 漂移波光
	var h := _hash(p)
	for i in 3:
		var sx := c.x + fmod(h * 7 + i * 19 + _t * 6.0, 64.0)
		var sy := c.y + 14 + i * 16 + sin(_t * 2.0 + i * 1.7) * 2.0
		var tw := 0.35 + 0.3 * sin(_t * 3.0 + i * 2.1 + h)
		draw_circle(Vector2(sx, sy), 1.4, Color(0.85, 0.95, 1.0, tw))
	# 睡莲
	if h % 6 == 0:
		var lx := c.x + 14 + (h % 5) * 8
		var ly := c.y + 18 + (h % 4) * 10
		draw_circle(Vector2(lx + 1, ly + 1), 5.0, Color(0.10, 0.24, 0.30, 0.5))
		draw_circle(Vector2(lx, ly), 5.0, Color(0.24, 0.48, 0.24))
		draw_circle(Vector2(lx, ly), 2.2, Color(0.30, 0.58, 0.28))
		if h % 12 == 0:
			draw_circle(Vector2(lx + 2, ly - 3), 2.0, Color(0.95, 0.72, 0.80))
	# 东缘瀑布
	if p.x == width - 1:
		_draw_waterfall(c)
	# 海岸泡沫线
	var foam := Color(0.78, 0.90, 1.0, 0.75)
	if tile_at(p + Vector2i(0, -1)) != "~" and tile_at(p + Vector2i(0, -1)) != "B":
		draw_line(c + Vector2(0, 1.5), c + Vector2(TILE, 1.5), foam, 3.0)
	if tile_at(p + Vector2i(0, 1)) != "~" and tile_at(p + Vector2i(0, 1)) != "B":
		draw_line(c + Vector2(0, TILE - 1.5), c + Vector2(TILE, TILE - 1.5), foam, 3.0)
	if tile_at(p + Vector2i(-1, 0)) != "~" and tile_at(p + Vector2i(-1, 0)) != "B":
		draw_line(c + Vector2(1.5, 0), c + Vector2(1.5, TILE), foam, 3.0)
	if tile_at(p + Vector2i(1, 0)) != "~" and tile_at(p + Vector2i(1, 0)) != "B":
		draw_line(c + Vector2(TILE - 1.5, 0), c + Vector2(TILE - 1.5, TILE), foam, 3.0)


func _draw_bridge(p: Vector2i, c: Vector2) -> void:
	draw_texture(_terrain_tex("~", _hash(p) % 4), c)
	var outline := Color(0.20, 0.14, 0.08)
	# 木板
	draw_rect(Rect2(c + Vector2(0, 5), Vector2(TILE, TILE - 10)), outline)
	draw_rect(Rect2(c + Vector2(0, 6), Vector2(TILE, TILE - 12)), Color(0.62, 0.45, 0.28))
	for i in 4:
		draw_line(c + Vector2(0, 12 + i * 13), c + Vector2(TILE, 12 + i * 13), Color(0.45, 0.32, 0.18), 1.8)
	# 木板高光
	draw_line(c + Vector2(0, 8), c + Vector2(TILE, 8), Color(0.72, 0.55, 0.36), 1.4)
	# 两侧护栏
	draw_rect(Rect2(c + Vector2(0, 2), Vector2(TILE, 5)), outline)
	draw_rect(Rect2(c + Vector2(0, 3), Vector2(TILE, 3)), Color(0.42, 0.30, 0.17))
	draw_rect(Rect2(c + Vector2(0, TILE - 7), Vector2(TILE, 5)), outline)
	draw_rect(Rect2(c + Vector2(0, TILE - 6), Vector2(TILE, 3)), Color(0.42, 0.30, 0.17)
	)
	draw_rect(Rect2(c + Vector2(8, 0), Vector2(4, 10)), Color(0.38, 0.26, 0.14))
	draw_rect(Rect2(c + Vector2(8, TILE - 10), Vector2(4, 10)), Color(0.38, 0.26, 0.14))


func _draw_mountain(c: Vector2) -> void:
	var outline := Color(0.22, 0.20, 0.19)
	var back := PackedVector2Array([c + Vector2(2, 48), c + Vector2(22, 20), c + Vector2(42, 48)])
	draw_colored_polygon(back, Color(0.38, 0.36, 0.34))
	var tri := PackedVector2Array([c + Vector2(12, 48), c + Vector2(32, 14), c + Vector2(52, 48)])
	draw_colored_polygon(tri, outline)
	var tri_in := PackedVector2Array([c + Vector2(14, 47), c + Vector2(32, 16), c + Vector2(50, 47)])
	draw_colored_polygon(tri_in, Color(0.48, 0.46, 0.44))
	# 山脊线
	draw_line(c + Vector2(32, 16), c + Vector2(24, 47), Color(0.36, 0.34, 0.33), 1.8)
	var snow := PackedVector2Array([c + Vector2(24, 30), c + Vector2(32, 14), c + Vector2(40, 30)])
	draw_colored_polygon(snow, Color(0.88, 0.88, 0.90))


## 整图模式农田: 手绘风有机色块（三层嵌套抖动多边形=伪羽化边缘 + 麦丛）,
## 与邻格农田的共享边外扩衔接成整片, 外缘抖动打破矩形贴片感
func _field_octagon(c: Vector2, h: int, f_l: bool, f_r: bool, f_u: bool, f_d: bool, inset: float, js: int) -> PackedVector2Array:
	var x0 := c.x + 3.0 + inset + _jit(h, 1 + js)
	var x1 := c.x + TILE - 3.0 - inset + _jit(h, 2 + js)
	var y0 := c.y + 3.0 + inset + _jit(h, 3 + js)
	var y1 := c.y + TILE - 3.0 - inset + _jit(h, 4 + js)
	var xm := c.x + TILE / 2.0 + _jit(h, 5 + js)
	var ym := c.y + TILE / 2.0 + _jit(h, 6 + js)
	var t_out := -6.0 if f_u else inset + _jit(h, 8 + js)
	var b_out := TILE + 6.0 if f_d else TILE - inset + _jit(h, 11 + js)
	var l_out := -6.0 if f_l else inset + _jit(h, 12 + js)
	var r_out := TILE + 6.0 if f_r else TILE - inset + _jit(h, 9 + js)
	return PackedVector2Array([
		Vector2(x0, y0),
		Vector2(xm + _jit(h, 7 + js), c.y + t_out),
		Vector2(x1, y0),
		Vector2(c.x + r_out, ym),
		Vector2(x1, y1),
		Vector2(xm + _jit(h, 10 + js), c.y + b_out),
		Vector2(x0, y1),
		Vector2(c.x + l_out, ym),
	])


func _draw_field_painted(p: Vector2i, c: Vector2) -> void:
	var h := _hash(p)
	var f_l := tile_at(p + Vector2i(-1, 0)) == "f"
	var f_r := tile_at(p + Vector2i(1, 0)) == "f"
	var f_u := tile_at(p + Vector2i(0, -1)) == "f"
	var f_d := tile_at(p + Vector2i(0, 1)) == "f"
	# 三层嵌套: 外淡内浓, 边缘三级渐变
	var soil := Color(0.35, 0.27, 0.16)
	draw_colored_polygon(_field_octagon(c, h, f_l, f_r, f_u, f_d, -4.0, 0), Color(soil.r, soil.g, soil.b, 0.30))
	draw_colored_polygon(_field_octagon(c, h, f_l, f_r, f_u, f_d, 0.0, 7), Color(soil.r, soil.g, soil.b, 0.62))
	draw_colored_polygon(_field_octagon(c, h, f_l, f_r, f_u, f_d, 4.0, 14), Color(soil.r, soil.g, soil.b, 0.92))
	# 内部暖金叠色
	var pts_in := _field_octagon(c, h, f_l, f_r, f_u, f_d, 10.0, 21)
	var xm := c.x + TILE / 2.0
	var ym := c.y + TILE / 2.0
	var pts_mid := PackedVector2Array()
	for q in pts_in:
		pts_mid.append(Vector2((q.x + xm) / 2.0, (q.y + ym) / 2.0))
	draw_colored_polygon(pts_mid, Color(0.62, 0.52, 0.24, 0.16))
	# 深色土斑
	for i in 4:
		var bx := c.x + 14 + ((h * 7 + i * 19) % 36)
		var by := c.y + 14 + ((h * 13 + i * 23) % 36)
		draw_set_transform(Vector2(bx, by), 0, Vector2(1.6, 0.7))
		draw_circle(Vector2.ZERO, 7.0, Color(0.26, 0.20, 0.11, 0.30))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# 田垄弧线
	for i in 2:
		var ly := c.y + 20 + i * 22 + (h % 5)
		draw_line(c + Vector2(8, ly), c + Vector2(TILE - 8, ly + (h % 3) - 1), Color(0.24, 0.18, 0.10, 0.55), 2.0)
	# 散布麦丛: 每丛 1-3 株, 高低/倾斜/颜色都不同
	for i in 12:
		var sx := c.x + 7 + ((h * 13 + i * 29) % 51)
		var sy := c.y + 12 + ((h * 31 + i * 17) % 46)
		var stalks := 1 + (h + i) % 3
		for s in stalks:
			var ox := ((h * 5 + i * 3 + s * 7) % 7) - 3
			var gy := sy + ((h + s * 11) % 5) - 2
			var gh := 6 + (h + i + s) % 4
			var golden := Color(0.82, 0.68, 0.26) if (h + i + s) % 3 != 0 else Color(0.66, 0.54, 0.20)
			var lean := 2.0 if (h + i + s) % 2 == 0 else -2.0
			draw_line(Vector2(sx + ox, gy), Vector2(sx + ox + lean, gy - gh), golden, 1.6)


## 程序模式农田（无手绘背景时使用纹理版）
func _draw_field(p: Vector2i, c: Vector2) -> void:
	draw_texture(_terrain_tex("f", _hash(p) % 4), c)
	var h := _hash(p)
	# 田垄（两条低调横线, 带轻微起伏）
	for i in 2:
		var ly := 20 + i * 22 + (h % 5)
		draw_line(c + Vector2(6, ly), c + Vector2(TILE - 6, ly + (h % 3) - 1), Color(0.42, 0.31, 0.20, 0.5), 2.0)
	# 散布麦丛: 每丛 1-3 株, 高低/倾斜/颜色都不同, 无完美网格感
	for i in 12:
		var sx := c.x + 7 + ((h * 13 + i * 29) % 51)
		var sy := c.y + 12 + ((h * 31 + i * 17) % 46)
		var stalks := 1 + (h + i) % 3
		for s in stalks:
			var ox := ((h * 5 + i * 3 + s * 7) % 7) - 3
			var gy := sy + ((h + s * 11) % 5) - 2
			var gh := 6 + (h + i + s) % 4
			var golden := Color(0.82, 0.68, 0.26) if (h + i + s) % 3 != 0 else Color(0.66, 0.54, 0.20)
			var lean := 2.0 if (h + i + s) % 2 == 0 else -2.0
			draw_line(Vector2(sx + ox, gy), Vector2(sx + ox + lean, gy - gh), golden, 1.6)
	# 边缘碎草点（打破矩形贴片感; 只画在邻格非农田的边）
	var edge := Color(0.40, 0.53, 0.30, 0.9)
	for i in 5:
		var t := (h * 17 + i * 31) % 60
		if tile_at(p + Vector2i(0, -1)) != "f":
			draw_circle(c + Vector2(2 + t, 3 + (h + i) % 4), 1.6, edge)
		if tile_at(p + Vector2i(0, 1)) != "f":
			draw_circle(c + Vector2(2 + (t + 17) % 60, TILE - 3 - (h + i) % 4), 1.6, edge)
	if tile_at(p + Vector2i(-1, 0)) != "f":
		for i in 4:
			draw_circle(c + Vector2(3 + (h + i * 9) % 4, 8 + ((h * 7 + i * 13) % 48)), 1.6, edge)
	if tile_at(p + Vector2i(1, 0)) != "f":
		for i in 4:
			draw_circle(c + Vector2(TILE - 3 - (h + i * 9) % 4, 8 + ((h * 11 + i * 7) % 48)), 1.6, edge)


func _draw_well(c: Vector2) -> void:
	var outline := Color(0.18, 0.16, 0.14)
	# 阴影
	draw_set_transform(c + Vector2(32, 45), 0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	# 石圈
	draw_circle(c + Vector2(32, 36), 15, outline)
	draw_circle(c + Vector2(32, 36), 14, Color(0.56, 0.55, 0.53))
	draw_circle(c + Vector2(32, 36), 9.5, outline)
	draw_circle(c + Vector2(32, 36), 8.5, Color(0.18, 0.20, 0.26))
	# 砖纹
	draw_arc(c + Vector2(32, 36), 11.5, 0.3, 1.2, 6, Color(0.42, 0.41, 0.40), 1.6)
	draw_arc(c + Vector2(32, 36), 11.5, 2.6, 3.5, 6, Color(0.42, 0.41, 0.40), 1.6)
	# 支架
	draw_rect(Rect2(c + Vector2(19, 13), Vector2(4.5, 21)), outline)
	draw_rect(Rect2(c + Vector2(20, 14), Vector2(2.5, 20)), Color(0.45, 0.32, 0.20))
	draw_rect(Rect2(c + Vector2(40.5, 13), Vector2(4.5, 21)), outline)
	draw_rect(Rect2(c + Vector2(41.5, 14), Vector2(2.5, 20)), Color(0.45, 0.32, 0.20))
	# 小屋顶
	var roof := PackedVector2Array([c + Vector2(15, 16), c + Vector2(32, 3), c + Vector2(49, 16)])
	draw_colored_polygon(roof, outline)
	var roof_in := PackedVector2Array([c + Vector2(17.5, 15), c + Vector2(32, 5), c + Vector2(46.5, 15)])
	draw_colored_polygon(roof_in, Color(0.68, 0.28, 0.20))
