class_name Board
extends Node2D
## 地图：地形数据、移动范围（BFS）、寻路、高亮。地面由 MapTiles（静态图块）+ MapFx（动画）+ 氛围层渲染。

const TILE := 64
const DIRS4 := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

## 地形底色：只在 CC0 图块缺失时的纯色兜底网格里用（正常渲染走 MapTiles）
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
	"C": Color(0.20, 0.14, 0.11),
	"E": Color(0.45, 0.12, 0.04),
	"Z": Color(0.34, 0.28, 0.24),
}

var rows: Array = []
var levels: Array = []              # 高度层（字符串数组, 与 rows 同尺寸）
var width := 0
var height := 0
var units: Array = []               # 与 battle.units 共享同一数组引用

# 高亮状态
var move_tiles: Dictionary = {}
var atk_tiles: Dictionary = {}
var danger_tiles: Dictionary = {}
var path_tiles: Array = []
var goal_tiles: Array = []:         # 撤离点等目标格（Vector2i 列表）
	set(v):
		goal_tiles = v
		_redraw_overlay()

var overlay: BoardOverlay
var tiles: MapTiles = null          # 静态地面（只画一次）
var fx: MapFx = null                # 水面涟漪 / 火焰 / 烟
var atmosphere: ColorRect = null    # 云影 + 调色 + 暗角


func _ready() -> void:
	# 单位按 y 排序，下排的人压在上排前面；高亮层停在 y=0 永远垫在单位底下
	y_sort_enabled = true
	overlay = BoardOverlay.new()
	overlay.board = self
	add_child(overlay)


## bg_path 仅为兼容旧调用保留，已不再使用（地图统一走 CC0 图块）
func load_map(map_rows: Array, map_levels: Array = [], _bg_path := "") -> void:
	rows = map_rows
	levels = map_levels
	height = rows.size()
	width = rows[0].length()
	if MapTiles.available():
		_build_tile_layers()
	queue_redraw()


func is_burning() -> bool:
	for r in rows:
		if str(r).contains("E"):
			return true
	return false


## 图块模式：静态地面 → 动态层 → （高亮、单位）→ 氛围层。z 小于 0 的画在高亮与单位下面。
func _build_tile_layers() -> void:
	var burn := is_burning()
	tiles = MapTiles.new()
	tiles.name = "MapTiles"
	tiles.board = self
	tiles.burning = burn
	tiles.z_index = -2
	add_child(tiles)
	fx = MapFx.new()
	fx.name = "MapFx"
	fx.z_index = -1
	add_child(fx)
	fx.setup(self, burn)
	atmosphere = ColorRect.new()
	atmosphere.name = "Atmosphere"
	atmosphere.size = Vector2(width * TILE, height * TILE)
	atmosphere.mouse_filter = Control.MOUSE_FILTER_IGNORE
	atmosphere.z_index = 6
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/map_atmosphere.gdshader")
	var nt := NoiseTexture2D.new()
	nt.width = 256
	nt.height = 256
	nt.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.012
	n.fractal_octaves = 3
	nt.noise = n
	mat.set_shader_parameter("noise", nt)
	if burn:
		mat.set_shader_parameter("cloud_strength", 0.22)
		mat.set_shader_parameter("cloud_speed", Vector2(0.02, -0.006))
		# 夜里的火场：整体压暗偏橙，暗角更重；火光在 MapFx 里画在这层之上
		mat.set_shader_parameter("grade", Color(0.22, 0.07, 0.03, 0.30))
		mat.set_shader_parameter("vignette", 0.45)
	atmosphere.material = mat
	add_child(atmosphere)
	if burn:
		var embers := CPUParticles2D.new()
		embers.name = "Embers"
		embers.z_index = 7
		embers.amount = 40
		embers.lifetime = 5.0
		embers.preprocess = 5.0
		embers.position = Vector2(width * TILE / 2.0, height * TILE * 0.35)
		embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		embers.emission_rect_extents = Vector2(width * TILE / 2.0, TILE * 1.5)
		embers.direction = Vector2(0.3, -1)
		embers.spread = 30.0
		embers.gravity = Vector2(6, -14)
		embers.initial_velocity_min = 12.0
		embers.initial_velocity_max = 30.0
		embers.scale_amount_min = 2.0
		embers.scale_amount_max = 3.5
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1.0, 0.75, 0.3, 0.9))
		ramp.set_color(1, Color(1.0, 0.3, 0.1, 0.0))
		embers.color_ramp = ramp
		add_child(embers)


func level_at(p: Vector2i) -> int:
	if levels.is_empty() or not in_bounds(p):
		return 1
	return levels[p.y].substr(p.x, 1).to_int()


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


## 视口坐标 → 格子。鼠标与触摸事件的 position 都走这里。
func tile_at_viewport(viewport_pos: Vector2) -> Vector2i:
	var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * viewport_pos
	return Vector2i((local / float(TILE)).floor())


func tile_at(p: Vector2i) -> String:
	if not in_bounds(p):
		return "~"
	return rows[p.y].substr(p.x, 1)


func terrain(p: Vector2i) -> Dictionary:
	return GameData.TERRAIN[tile_at(p)]


func unit_at(p: Vector2i) -> Unit:
	for u in units:
		if u.on_map() and u.grid_pos == p:
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
	_redraw_overlay()


func clear_highlights() -> void:
	move_tiles = {}
	atk_tiles = {}
	path_tiles = []
	_redraw_overlay()


func set_danger(tiles: Dictionary) -> void:
	danger_tiles = tiles
	_redraw_overlay()


func set_path(path: Array) -> void:
	path_tiles = path
	_redraw_overlay()


func _redraw_overlay() -> void:
	if overlay != null:
		overlay.queue_redraw()


## 兜底：CC0 图块缺失时画纯色网格，保证地图永远不是一片空白。
## 正常情况下地面在 MapTiles，高亮与箭头在 BoardOverlay，这里什么都不画。
func _draw() -> void:
	if tiles != null:
		return
	var fallback: Color = BASE_COLORS["."]
	for y in height:
		for x in width:
			var p := Vector2i(x, y)
			var c: Color = BASE_COLORS.get(tile_at(p), fallback)
			draw_rect(Rect2(Vector2(p) * TILE, Vector2(TILE, TILE)), c)
	var grid_col := Color(0, 0, 0, 0.12)
	for x in width + 1:
		draw_line(Vector2(x * TILE, 0), Vector2(x * TILE, height * TILE), grid_col)
	for y in height + 1:
		draw_line(Vector2(0, y * TILE), Vector2(width * TILE, y * TILE), grid_col)
