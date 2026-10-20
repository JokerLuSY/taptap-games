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
const SAND_SET := Vector2i(0, 0)            # TilesetFloor：沙地 3×3（草边）
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
const TUFTS := [Rect2(0, 160, 16, 16), Rect2(16, 160, 16, 16), Rect2(48, 160, 16, 16), Rect2(64, 160, 16, 16), Rect2(128, 160, 16, 16)]
const PEBBLES := [Rect2(272, 208, 16, 16), Rect2(288, 208, 16, 16), Rect2(304, 208, 16, 16)]
const BIG_ROCK := Rect2(208, 128, 32, 32)
const STUMP := Rect2(64, 128, 16, 16)
## 雪地：TilesetFloor 积雪地、TilesetNature 雪松 / 雪石
const GRASS_SNOW := [Vector2i(0, 304), Vector2i(0, 304), Vector2i(0, 304), Vector2i(16, 304), Vector2i(32, 304), Vector2i(48, 304), Vector2i(64, 304)]
const TREES_SNOW := [Rect2(128, 0, 32, 32), Rect2(160, 0, 32, 32), Rect2(192, 0, 32, 32)]
const ROCK_SNOW := Rect2(32, 192, 32, 32)
const SHOP_VENDOR := Rect2(256, 0, 48, 48)                             # TilesetHouse：挂碗招牌的小店
const SHOP_ARMORY := Rect2(352, 0, 48, 48)                             # TilesetHouse：石砌铁匠铺
const CHEST_CLOSED := Rect2(0, 0, 16, 16)                               # Chest：大宝箱（关）
const CHEST_OPEN := Rect2(16, 0, 16, 16)                                # Chest：大宝箱（开）
const FORT_WALL := [Rect2(176, 144, 16, 16), Rect2(192, 144, 16, 16)]   # TilesetHouse：带垛口的石墙
const FORT_POST := Rect2(176, 128, 16, 16)                              # TilesetHouse：石柱
const CASTLE_WALL := Vector2i(64, 0)                                    # TilesetRelief：灰石墙 3×3
const STONE_FLOOR := Rect2(320, 128, 32, 32)                            # TilesetInteriorFloor：灰石地砖（×2 正好一格）
const THRONE_SEAT := Rect2(0, 16, 16, 16)                               # TilesetDungeon：红坐垫
const FORT_SET := Vector2i(16, 0)                                       # TilesetRelief：灰白石台 3×3
const TENT := Rect2(64, 0, 48, 48)                  # TilesetCamp：帆布营帐
const STAKES := Rect2(176, 80, 16, 16)              # TilesetHouse：木桩墙（横）
const POST := Rect2(176, 64, 16, 16)                # TilesetHouse：木桩（竖）

var board: Board
var burning := false                # 第二章：树换枯树、焦土更暗
var snow := false                   # 雪地：草地换积雪、树换雪松、石头盖雪、道路换泥路
## 地图比屏幕小时（宽屏手机上的第一章），四周画一圈装饰用的树林盖住空档：border = 左右各几格、上下各几格
var border := Vector2i.ZERO
var _tex := {}


static func available() -> bool:
	for n in ["TilesetFloor", "TilesetWater", "TilesetNature", "TilesetHouse", "TilesetVillageAbandoned", "TilesetElement", "TilesetRelief"]:
		if not ResourceLoader.exists(DIR + n + ".png"):
			return false
	return true


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for n in ["TilesetFloor", "TilesetWater", "TilesetNature", "TilesetHouse", "TilesetVillageAbandoned", "TilesetElement", "TilesetRelief", "TilesetCamp", "TilesetInteriorFloor", "TilesetDungeon", "Chest"]:
		if ResourceLoader.exists(DIR + n + ".png"):
			_tex[n] = load(DIR + n + ".png")


func _draw() -> void:
	if board == null or board.rows.is_empty():
		return
	_draw_border()
	for y in board.height:
		for x in board.width:
			_draw_ground(Vector2i(x, y))
	for y in board.height:
		for x in board.width:
			_draw_cliff(Vector2i(x, y))
			_draw_floor(Vector2i(x, y))
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
			var grass: Array = GRASS_SNOW if snow else (GRASS_DARK if burning else GRASS)
			var g: Vector2i = grass[_hash(p * 2 + sub) % grass.size()]
			_blit("TilesetFloor", Rect2(g, Vector2(16, 16)), dst)
			var road: Vector2i = ROAD_SET_DARK if burning else ROAD_SET
			match t:
				"R":
					if snow:
						_blit("TilesetFloor", _sub3(SAND_SET, p, sub, "RBT"), dst, Color(0.78, 0.66, 0.6))
					else:
						_blit("TilesetFloor", _sub3(road, p, sub, "RBT"), dst)
				"C", "E", "Z":
					_blit("TilesetFloor", _sub3(road, p, sub, "CEZ" if burning else "CEZRBT"), dst)
					_soot(p, sub)
				"T":
					_blit("TilesetRelief", _sub3(FORT_SET, p, sub, "T"), dst, Color(0.82, 0.78, 0.74) if burning else Color.WHITE)
				"~":
					_blit("TilesetWater", _sub3(WATER_SET, p, sub, "~Bw"), dst)
					if snow:
						draw_rect(dst, Color(0.92, 0.96, 1.0, 0.45))     # 结冰的湖面
				"w":
					_blit("TilesetWater", _sub3(WATER_SET, p, sub, "~Bw"), dst)
					draw_rect(dst, Color(0.85, 0.82, 0.55, 0.28))
				"B":
					_blit("TilesetWater", _sub3(WATER_SET, p, sub, "~Bw"), dst)
					_blit("TilesetWater", Rect2(PLANK_SET + Vector2i(dx * 32, 16), Vector2(16, 16)), dst)
				"f":
					_blit("TilesetElement", _sub3(HAY_SET, p, sub, "f"), dst)
				"s":
					_blit("TilesetFloor", _sub3(SAND_SET, p, sub, "sB~w"), dst)
				"X":
					_blit("TilesetRelief", _sub3(WALL_SET, p, sub, "X"), dst)
				"#":
					_blit("TilesetRelief", _sub3(CASTLE_WALL, p, sub, "#"), dst)


## 焦土烟灰斑：只落在子格中间，不压到草边
func _soot(p: Vector2i, sub: Vector2i) -> void:
	var h := _hash(p * 2 + sub)
	var c := Vector2(p) * TILE + Vector2(sub) * SUB + Vector2(SUB / 2.0, SUB / 2.0)
	var off := Vector2(float(h % 7) - 3.0, float(h % 5) - 2.0) * 2.0
	draw_circle(c + off, 9.0 + float(h % 4), Color(0.06, 0.04, 0.03, 0.35))
	draw_circle(c + off * -1.5, 5.0, Color(0.06, 0.04, 0.03, 0.25))
	if h % 3 == 0 and burning:
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


# ---------------- 城堡 ----------------

## 石地类（石地、城门、王座、石柱）整格铺灰石砖；城墙顶上一排垛口
func _draw_floor(p: Vector2i) -> void:
	var t := board.tile_at(p)
	var o := Vector2(p) * TILE
	if "SGKI".contains(t):
		_blit("TilesetInteriorFloor", STONE_FLOOR, Rect2(o, Vector2(TILE, TILE)))
		# 跟非石地相邻的一侧压一道暗边，石地块的轮廓清楚些
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var q: Vector2i = p + d
			if board.in_bounds(q) and not "SGKI#".contains(board.tile_at(q)):
				var r := Rect2(o + Vector2(maxf(0, d.x) * (TILE - 4), maxf(0, d.y) * (TILE - 4)), Vector2(4 if d.x != 0 else TILE, 4 if d.y != 0 else TILE))
				draw_rect(r, Color(0.12, 0.14, 0.12, 0.45))
	elif t == "#":
		var up := p + Vector2i.UP
		if board.in_bounds(up) and board.tile_at(up) == "#":
			return
		# 垛口：墙顶外缘一排凸起的石块
		for i in 4:
			var m := Rect2(o + Vector2(2 + i * 16, -8), Vector2(10, 12))
			draw_rect(m, Color(0.62, 0.66, 0.6))
			draw_rect(m, Color(0.16, 0.18, 0.16), false, 2.0)


func _gate(p: Vector2i) -> void:
	var o := Vector2(p) * TILE
	# 两侧门柱接城墙，头顶拱券、铁闸
	for x in [0.0, 50.0]:
		draw_rect(Rect2(o + Vector2(x, -10), Vector2(14, 60)), Color(0.5, 0.54, 0.5))
		draw_rect(Rect2(o + Vector2(x, -10), Vector2(14, 60)), Color(0.16, 0.18, 0.16), false, 2.0)
	draw_rect(Rect2(o + Vector2(12, -10), Vector2(40, 10)), Color(0.5, 0.54, 0.5))
	draw_rect(Rect2(o + Vector2(12, -10), Vector2(40, 10)), Color(0.16, 0.18, 0.16), false, 2.0)
	for i in 5:
		draw_line(o + Vector2(16 + i * 8, 0), o + Vector2(16 + i * 8, 8), Color(0.2, 0.2, 0.22), 2.0)


func _throne(p: Vector2i) -> void:
	var o := Vector2(p) * TILE
	# 红地毯 + 金边高背椅，椅背高出格子，单位坐上去头后还露出椅背
	draw_rect(Rect2(o + Vector2(12, 0), Vector2(40, TILE)), Color(0.55, 0.1, 0.12))
	draw_rect(Rect2(o + Vector2(12, 0), Vector2(40, TILE)), Color(0.85, 0.66, 0.25), false, 2.0)
	var back := Rect2(o + Vector2(14, -22), Vector2(36, 44))
	draw_rect(back, Color(0.7, 0.52, 0.18))
	draw_rect(back.grow(-4), Color(0.6, 0.12, 0.14))
	draw_rect(back, Color(0.2, 0.12, 0.06), false, 2.0)
	draw_circle(o + Vector2(32, -22), 6.0, Color(0.9, 0.72, 0.28))
	_blit("TilesetDungeon", THRONE_SEAT, Rect2(o + Vector2(16, 20), Vector2(SUB, SUB)))


func _pillar(p: Vector2i) -> void:
	var o := Vector2(p) * TILE
	draw_set_transform(o + Vector2(32, 56), 0, Vector2(1.0, 0.4))
	draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	var shaft := Rect2(o + Vector2(20, -14), Vector2(24, 64))
	draw_rect(shaft, Color(0.66, 0.68, 0.64))
	draw_rect(Rect2(shaft.position, Vector2(8, shaft.size.y)), Color(0.8, 0.82, 0.78))
	draw_rect(Rect2(shaft.position + Vector2(17, 0), Vector2(7, shaft.size.y)), Color(0.5, 0.52, 0.5))
	draw_rect(shaft, Color(0.16, 0.18, 0.16), false, 2.0)
	for y in [-20.0, 46.0]:
		var cap := Rect2(o + Vector2(14, y), Vector2(36, 10))
		draw_rect(cap, Color(0.72, 0.74, 0.7))
		draw_rect(cap, Color(0.16, 0.18, 0.16), false, 2.0)


# ---------------- 高低差 ----------------

## 高处南边比下面一格高，就在下面那格顶上画一段岩壁立面（下面是水时由水岸图块收口，不画）
func _draw_cliff(p: Vector2i) -> void:
	var below := p + Vector2i.DOWN
	if not board.in_bounds(below):
		return
	if board.level_at(p) <= board.level_at(below):
		return
	if "~Bw".contains(board.tile_at(below)) or board.tile_at(p) == "B":
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
			if snow:
				_stand("TilesetNature", TREES_SNOW[h % TREES_SNOW.size()], p, 2.0)
			elif burning:
				_stand("TilesetNature", DEAD_TREE, p, 2.0)
			else:
				_stand("TilesetNature", TREES[h % TREES.size()], p, 2.0)
		"M":
			if snow:
				_stand("TilesetNature", ROCK_SNOW, p, 2.0)
			else:
				_stand("TilesetNature", ROCKS[h % ROCKS.size()], p, 2.0)
		"Q":
			var o := Vector2(p) * TILE
			draw_set_transform(o + Vector2(32, 52), 0, Vector2(1.0, 0.35))
			draw_circle(Vector2.ZERO, 20.0, Color(0, 0, 0, 0.25))
			draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
			_blit("Chest", CHEST_OPEN if board.opened.has(p) else CHEST_CLOSED, Rect2(o + Vector2(8, 4), Vector2(48, 48)))
		"H":
			_stand("TilesetHouse", HUTS[h % HUTS.size()], p, 2.0 if HUTS[h % HUTS.size()].size.x <= 32 else 1.5)
		"W":
			_stand("TilesetVillageAbandoned", WELL, p, 3.0)
		"Z":
			_stand("TilesetVillageAbandoned", RUBBLE, p, 2.0)
		"D":
			# 火场里是烧着的屋子：压暗，火苗由 MapFx 加
			var hut: Rect2 = HUTS[(h + 1) % HUTS.size()]
			_stand("TilesetHouse", hut, p, 1.5, Color(0.45, 0.36, 0.32) if burning else Color.WHITE)
		"T":
			_fort(p)
		"V", "Y":
			_shop(p, t == "Y")
		"G":
			_gate(p)
		"K":
			_throne(p)
		"I":
			_pillar(p)
		"A":
			_stand("TilesetCamp", TENT, p, 1.5)
		"P":
			_palisade(p)
		"h":
			_hills(p, h)
		"w":
			_ford(p, h)
		".":
			if snow:
				if h % 13 == 0:
					_deco("TilesetNature", PEBBLES[h % PEBBLES.size()], p, h)
			elif burning:
				if h % 9 == 0:
					_deco("TilesetNature", STUMP, p, h)
			elif h % 11 == 0:
				_deco("TilesetNature", FLOWERS[h % FLOWERS.size()], p, h)
			elif h % 7 == 0:
				_deco("TilesetNature", TUFTS[h % TUFTS.size()], p, h)
			elif h % 23 == 3:
				_deco("TilesetNature", PEBBLES[h % PEBBLES.size()], p, h)


## 平地上的小点缀：花、草丛、碎石（×2，位置按格子哈希错开）
func _deco(sheet: String, src: Rect2, p: Vector2i, h: int) -> void:
	var c := Vector2(p) * TILE + Vector2(8 + (h % 3) * 8, 10 + (h % 2) * 14)
	_blit(sheet, src, Rect2(c, src.size * 2.0))


## 丘陵：一块大石 + 两侧碎石草丛，让它和平地一眼区分开
func _hills(p: Vector2i, h: int) -> void:
	var o := Vector2(p) * TILE
	draw_set_transform(o + Vector2(32, 44), 0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 30.0, Color(0.12, 0.2, 0.05, 0.28))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	if burning:
		_blit("TilesetNature", PEBBLES[h % PEBBLES.size()], Rect2(o + Vector2(2, 30), Vector2(32, 32)), Color(0.6, 0.5, 0.45))
	else:
		_blit("TilesetNature", TUFTS[h % TUFTS.size()], Rect2(o + Vector2(0, 30), Vector2(32, 32)))
	_blit("TilesetNature", PEBBLES[(h + 1) % PEBBLES.size()], Rect2(o + Vector2(34, 34), Vector2(28, 28)))
	_blit("TilesetNature", BIG_ROCK, Rect2(o + Vector2(14, 2), Vector2(40, 40)), Color(0.95, 0.95, 0.9) if not burning else Color(0.6, 0.5, 0.45))


## 堡垒：后面一道带垛口的石墙、两侧石柱，单位站在墙前（头顶露出垛口，两侧露出石柱）
func _fort(p: Vector2i) -> void:
	var o := Vector2(p) * TILE
	var mod := Color(0.78, 0.72, 0.68) if burning else Color.WHITE
	_blit("TilesetHouse", FORT_WALL[0], Rect2(o + Vector2(0, -16), Vector2(SUB, SUB)), mod)
	_blit("TilesetHouse", FORT_WALL[1], Rect2(o + Vector2(SUB, -16), Vector2(SUB, SUB)), mod)
	for x in [-10.0, 44.0]:
		_blit("TilesetHouse", FORT_POST, Rect2(o + Vector2(x, -18), Vector2(SUB, SUB)), mod)
		_blit("TilesetHouse", FORT_POST, Rect2(o + Vector2(x, 34), Vector2(SUB, SUB)), mod)
	# 旗杆 + 三角旗：单位站上去挡住石台时，头顶这面旗还认得出是堡垒
	draw_line(o + Vector2(54, -34), o + Vector2(54, -6), Color(0.22, 0.16, 0.12), 3.0)
	draw_colored_polygon(PackedVector2Array([o + Vector2(55, -34), o + Vector2(70, -28), o + Vector2(55, -22)]), Color(0.75, 0.16, 0.12) if not burning else Color(0.45, 0.12, 0.1))


## 商店：店面 + 门口挂一块小招牌（武器店画剑、道具店画药瓶），一眼能认出来
func _shop(p: Vector2i, armory: bool) -> void:
	_stand("TilesetHouse", SHOP_ARMORY if armory else SHOP_VENDOR, p, 1.3)
	var o := Vector2(p) * TILE + Vector2(40, 2)
	var wood := Color(0.55, 0.36, 0.2)
	draw_line(o + Vector2(8, -4), o + Vector2(8, 2), Color(0.25, 0.16, 0.1), 2.0)
	draw_rect(Rect2(o + Vector2(0, 2), Vector2(18, 18)), wood)
	draw_rect(Rect2(o + Vector2(0, 2), Vector2(18, 18)), Color(0.2, 0.12, 0.06), false, 2.0)
	if armory:
		draw_line(o + Vector2(4, 17), o + Vector2(14, 6), Color(0.85, 0.88, 0.95), 3.0)
		draw_line(o + Vector2(5, 11), o + Vector2(10, 16), Color(0.9, 0.75, 0.3), 2.0)
	else:
		draw_circle(o + Vector2(9, 14), 5.0, Color(0.85, 0.25, 0.3))
		draw_rect(Rect2(o + Vector2(7, 5), Vector2(4, 5)), Color(0.8, 0.85, 0.9))


## 浅滩：水面上一排踏脚石
func _ford(p: Vector2i, h: int) -> void:
	var o := Vector2(p) * TILE
	for i in 4:
		var c := o + Vector2(10 + i * 14 + (h + i) % 3 * 2, 20 + ((h + i * 5) % 4) * 7)
		draw_set_transform(c, 0, Vector2(1.0, 0.65))
		draw_circle(Vector2(0, 2), 7.0, Color(0.15, 0.2, 0.25, 0.45))
		draw_circle(Vector2.ZERO, 6.5, Color(0.62, 0.6, 0.55))
		draw_circle(Vector2(-1.5, -1.5), 3.5, Color(0.78, 0.76, 0.7))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)


## 栅栏：下半格一排木桩墙；上下有相连的栅栏时在正中立一根竖桩接过去
func _palisade(p: Vector2i) -> void:
	var o := Vector2(p) * TILE
	var up := _same(p + Vector2i.UP, "P") and board.in_bounds(p + Vector2i.UP)
	var down := _same(p + Vector2i.DOWN, "P") and board.in_bounds(p + Vector2i.DOWN)
	draw_rect(Rect2(o + Vector2(0, 58), Vector2(TILE, 6)), Color(0, 0, 0, 0.2))
	if up:
		_blit("TilesetHouse", POST, Rect2(o + Vector2(16, -8), Vector2(SUB, SUB)))
		_blit("TilesetHouse", POST, Rect2(o + Vector2(16, 12), Vector2(SUB, SUB)))
	_blit("TilesetHouse", STAKES, Rect2(o + Vector2(0, SUB), Vector2(SUB, SUB)))
	_blit("TilesetHouse", STAKES, Rect2(o + Vector2(SUB, SUB), Vector2(SUB, SUB)))
	if down:
		_blit("TilesetHouse", POST, Rect2(o + Vector2(16, 48), Vector2(SUB, 16)))


## 物件立在格子底边中央，脚下一圈影子；超出格子宽度的部分往两侧对称溢出
func _stand(sheet: String, src: Rect2, p: Vector2i, scale: float, mod := Color.WHITE) -> void:
	var size := src.size * scale
	var base := Vector2(p.x * TILE + TILE / 2.0, (p.y + 1) * TILE - 4)
	draw_set_transform(base + Vector2(0, -2), 0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, size.x * 0.42, Color(0, 0, 0, 0.22))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
	_blit(sheet, src, Rect2(base - Vector2(size.x / 2.0, size.y), size), mod)


func _blit(sheet: String, src: Rect2, dst: Rect2, mod := Color.WHITE) -> void:
	var tex: Texture2D = _tex.get(sheet)
	if tex != null:
		draw_texture_rect_region(tex, dst, src, mod)


## 地图外圈：草地 + 树林，压暗一点，看得出是地图边界外（不能走、不能点）
func _draw_border() -> void:
	if border == Vector2i.ZERO:
		return
	var grass: Array = GRASS_SNOW if snow else (GRASS_DARK if burning else GRASS)
	var cells: Array = []
	for y in range(-border.y, board.height + border.y):
		for x in range(-border.x, board.width + border.x):
			var p := Vector2i(x, y)
			if board.in_bounds(p):
				continue
			cells.append(p)
			for dy in 2:
				for dx in 2:
					var sub := Vector2i(dx, dy)
					var g: Vector2i = grass[_hash(p * 2 + sub) % grass.size()]
					_blit("TilesetFloor", Rect2(g, Vector2(16, 16)), Rect2(Vector2(p) * TILE + Vector2(sub) * SUB, Vector2(SUB, SUB)))
	for p in cells:
		var h := _hash(p)
		if h % 4 == 0:
			continue
		if snow:
			_stand("TilesetNature", TREES_SNOW[h % TREES_SNOW.size()], p, 2.0)
		elif burning:
			_stand("TilesetNature", DEAD_TREE, p, 2.0)
		else:
			_stand("TilesetNature", TREES[h % TREES.size()], p, 2.0)
	for p in cells:
		draw_rect(Rect2(Vector2(p) * TILE, Vector2(TILE, TILE)), Color(0.02, 0.03, 0.06, 0.32))


func _hash(p: Vector2i) -> int:
	return absi(p.x * 73 + p.y * 149 + p.x * p.y * 31)
