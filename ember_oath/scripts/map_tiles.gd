class_name MapTiles
extends Node2D
## 地图静态层：Ninja Adventure（CC0）16px 图块按 ×4 拼成 64px 格子，载入地图时只画一次。
## 地面与物件统一按 ×2（16px 图块 → 32px 子格，每格 2×2 子格）；地面走子格自动拼接，物件立在格子底边。
## 逻辑仍以 Board 的 ASCII MAP / LEVELS 为准，这里只负责画。

const TILE := 64
const SUB := 32.0                   # 地面子格：16px 图块 ×2
const DIR := "res://art/cc0/ninja_adventure/tiles/"

## 地面自动拼接套（3×3：角、边、中）的左上角（像素）。列 = 左右邻接，行 = 上下邻接。
const ROAD_SET := Vector2i(0, 112)          # TilesetFloor：草地上的土路
const WATER_SET := Vector2i(0, 96)          # TilesetWater：草岸水面
const HAY_SET := Vector2i(208, 64)          # TilesetElement：麦田（3×3 套）
const GRASS := [Vector2i(0, 192), Vector2i(0, 192), Vector2i(0, 192), Vector2i(16, 192), Vector2i(32, 192), Vector2i(48, 192)]
const SAND := Vector2i(16, 16)
const PLANK_SET := Vector2i(0, 192)         # TilesetWater：竖向木板（左缘列 / 右缘列相隔 2 格）
const WALL_SET := Vector2i(64, 80)          # TilesetRelief：岩台 3×3（顶沿 / 岩壁 / 墙脚）
const CLIFF_FACE := Rect2(80, 112, 16, 16)  # TilesetRelief：岩壁底段（高低差的南立面）
const CLIFF_H := 24.0
## 第二章（火场、夜里）：深绿草地 + 深色土路套，焦土在同一套上再叠烟灰斑
const GRASS_DARK := [Vector2i(176, 192), Vector2i(176, 192), Vector2i(176, 192), Vector2i(192, 192), Vector2i(208, 192), Vector2i(224, 192)]
const ROAD_SET_DARK := Vector2i(176, 112)

## 大物件源矩形（按透明包围盒裁好）
const TREES := [Rect2(0, 0, 32, 32), Rect2(32, 0, 32, 32), Rect2(256, 0, 32, 32), Rect2(288, 0, 32, 32)]
const DEAD_TREE := Rect2(64, 0, 32, 32)
const ROCKS := [Rect2(210, 132, 29, 27), Rect2(258, 132, 29, 27)]
const HUTS := [Rect2(3, 120, 42, 39), Rect2(48, 128, 47, 32)]
const WELL := Rect2(80, 64, 16, 16)
const RUBBLE := Rect2(224, 80, 32, 16)
const FLOWERS := [Rect2(0, 176, 16, 16), Rect2(16, 176, 16, 16), Rect2(48, 176, 16, 16)]

var board: Board
var burning := false                # 第二章：树换枯树、焦土更暗
var _tex := {}


static func available() -> bool:
	for n in ["TilesetFloor", "TilesetWater", "TilesetNature", "TilesetHouse", "TilesetVillageAbandoned", "TilesetElement", "TilesetRelief"]:
		if not ResourceLoader.exists(DIR + n + ".png"):
			return false
	return true


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for n in ["TilesetFloor", "TilesetWater", "TilesetNature", "TilesetHouse", "TilesetVillageAbandoned", "TilesetElement", "TilesetRelief"]:
		_tex[n] = load(DIR + n + ".png")


func _draw() -> void:
	if board == null or board.rows.is_empty():
		return
	for y in board.height:
		for x in board.width:
			_draw_ground(Vector2i(x, y))
	for y in board.height:
		for x in board.width:
			_draw_cliff(Vector2i(x, y))
	for y in board.height:
		for x in board.width:
			_draw_object(Vector2i(x, y))
	var grid_col := Color(0, 0, 0, 0.06)
	for x in board.width + 1:
		draw_line(Vector2(x * TILE, 0), Vector2(x * TILE, board.height * TILE), grid_col)
	for y in board.height + 1:
		draw_line(Vector2(0, y * TILE), Vector2(board.width * TILE, y * TILE), grid_col)


# ---------------- 地面 ----------------

## 地面按 ×2 画：每格拆成 2×2 个 32px 子格，每个子格是一张 16px 图块。
## 自动拼接按子格算邻居（同一格里的另外三个子格天然同类），所以一格宽的河 / 路两侧都有完整的岸和草边。
func _draw_ground(p: Vector2i) -> void:
	var t := board.tile_at(p)
	for dy in 2:
		for dx in 2:
			var sub := Vector2i(dx, dy)
			var dst := Rect2(Vector2(p) * TILE + Vector2(sub) * SUB, Vector2(SUB, SUB))
			var grass: Array = GRASS_DARK if burning else GRASS
			var g: Vector2i = grass[_hash(p * 2 + sub) % grass.size()]
			_blit("TilesetFloor", Rect2(g, Vector2(16, 16)), dst)
			var road: Vector2i = ROAD_SET_DARK if burning else ROAD_SET
			match t:
				"R":
					_blit("TilesetFloor", _sub3(road, p, sub, "RB"), dst)
				"C", "E", "Z":
					_blit("TilesetFloor", _sub3(road, p, sub, "CEZ"), dst)
					_soot(p, sub)
				"~":
					_blit("TilesetWater", _sub3(WATER_SET, p, sub, "~B"), dst)
				"B":
					_blit("TilesetWater", _sub3(WATER_SET, p, sub, "~B"), dst)
					_blit("TilesetWater", Rect2(PLANK_SET + Vector2i(dx * 32, 16), Vector2(16, 16)), dst)
				"f":
					_blit("TilesetElement", _sub3(HAY_SET, p, sub, "f"), dst)
				"s":
					_blit("TilesetFloor", Rect2(SAND, Vector2(16, 16)), dst)
				"X":
					_blit("TilesetRelief", _sub3(WALL_SET, p, sub, "X"), dst)


## 焦土烟灰斑：只落在子格中间，不压到草边
func _soot(p: Vector2i, sub: Vector2i) -> void:
	var h := _hash(p * 2 + sub)
	var c := Vector2(p) * TILE + Vector2(sub) * SUB + Vector2(SUB / 2.0, SUB / 2.0)
	var off := Vector2(float(h % 7) - 3.0, float(h % 5) - 2.0) * 2.0
	draw_circle(c + off, 9.0 + float(h % 4), Color(0.06, 0.04, 0.03, 0.35))
	draw_circle(c + off * -1.5, 5.0, Color(0.06, 0.04, 0.03, 0.25))
	if h % 3 == 0:
		draw_rect(Rect2(c + Vector2(6, -4), Vector2(4, 4)), Color(1.0, 0.45, 0.15, 0.8))


## 3×3 套里取子格对应的图块：子格朝格内的那一侧总是同类，只看朝格外那一侧的邻格
func _sub3(origin: Vector2i, p: Vector2i, sub: Vector2i, group: String) -> Rect2:
	var hn := _same(p + Vector2i(-1 if sub.x == 0 else 1, 0), group)
	var vn := _same(p + Vector2i(0, -1 if sub.y == 0 else 1), group)
	var col := 1 if hn else (0 if sub.x == 0 else 2)
	var row := 1 if vn else (0 if sub.y == 0 else 2)
	return Rect2(origin + Vector2i(col, row) * 16, Vector2(16, 16))


func _same(p: Vector2i, group: String) -> bool:
	if not board.in_bounds(p):
		return true
	return group.contains(board.tile_at(p))


# ---------------- 高低差 ----------------

## 高处南边比下面一格高，就在下面那格顶上画一段岩壁立面（下面是水时由水岸图块收口，不画）
func _draw_cliff(p: Vector2i) -> void:
	var below := p + Vector2i.DOWN
	if not board.in_bounds(below):
		return
	if board.level_at(p) <= board.level_at(below):
		return
	if "~B".contains(board.tile_at(below)) or board.tile_at(p) == "B":
		return
	var top := Vector2(p.x * TILE, below.y * TILE)
	_blit("TilesetRelief", CLIFF_FACE, Rect2(top, Vector2(TILE, CLIFF_H)))
	draw_rect(Rect2(top + Vector2(0, CLIFF_H), Vector2(TILE, 6)), Color(0, 0, 0, 0.18))


# ---------------- 物件 ----------------

func _draw_object(p: Vector2i) -> void:
	var t := board.tile_at(p)
	var h := _hash(p)
	match t:
		"F":
			if burning:
				_stand("TilesetNature", DEAD_TREE, p, 2.0)
			else:
				_stand("TilesetNature", TREES[h % TREES.size()], p, 2.0)
		"M":
			_stand("TilesetNature", ROCKS[h % ROCKS.size()], p, 2.0)
		"H":
			_stand("TilesetHouse", HUTS[h % HUTS.size()], p, 2.0 if HUTS[h % HUTS.size()].size.x <= 32 else 1.5)
		"W":
			_stand("TilesetVillageAbandoned", WELL, p, 3.0)
		"Z":
			_stand("TilesetVillageAbandoned", RUBBLE, p, 2.0)
		".":
			if h % 11 == 0 and not burning:
				var fl: Rect2 = FLOWERS[h % FLOWERS.size()]
				var c := Vector2(p) * TILE + Vector2(16 + (h % 3) * 8, 18 + (h % 2) * 10)
				_blit("TilesetNature", fl, Rect2(c, fl.size * 2.0))


## 物件立在格子底边中央，脚下一圈影子；超出格子宽度的部分往两侧对称溢出
func _stand(sheet: String, src: Rect2, p: Vector2i, scale: float) -> void:
	var size := src.size * scale
	var base := Vector2(p.x * TILE + TILE / 2.0, (p.y + 1) * TILE - 4)
	draw_set_transform(base + Vector2(0, -2), 0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, size.x * 0.42, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_blit(sheet, src, Rect2(base - Vector2(size.x / 2.0, size.y), size))


func _blit(sheet: String, src: Rect2, dst: Rect2, mod := Color.WHITE) -> void:
	var tex: Texture2D = _tex.get(sheet)
	if tex != null:
		draw_texture_rect_region(tex, dst, src, mod)


func _hash(p: Vector2i) -> int:
	return absi(p.x * 73 + p.y * 149 + p.x * p.y * 31)
