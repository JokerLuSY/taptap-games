class_name BoardOverlay
extends Node2D
## 棋盘高亮层：移动 / 攻击 / 危险范围 + 火纹式路径箭头
## 数据仍放在 Board（move_tiles / atk_tiles / danger_tiles / path_tiles），这里只负责画

const TILE := 64
const MOVE_FILL := Color(0.30, 0.58, 1.0, 0.40)
const MOVE_EDGE := Color(0.70, 0.88, 1.0, 0.90)
const ATK_FILL := Color(1.0, 0.28, 0.22, 0.36)
const ATK_EDGE := Color(1.0, 0.70, 0.62, 0.90)
const DANGER_FILL := Color(1.0, 0.20, 0.20, 0.22)
const DANGER_EDGE := Color(1.0, 0.32, 0.28, 0.85)
const ARROW_FILL := Color(0.62, 0.86, 1.0, 1.0)
const ARROW_LIGHT := Color(0.92, 0.98, 1.0, 1.0)
const ARROW_OUTLINE := Color(0.08, 0.14, 0.32, 0.95)
const GOAL_FILL := Color(1.0, 0.82, 0.30, 0.22)
const GOAL_EDGE := Color(1.0, 0.86, 0.40, 0.95)

var board: Board
var _t := 0.0


func _process(delta: float) -> void:
	if board == null:
		return
	if board.move_tiles.is_empty() and board.atk_tiles.is_empty() and board.danger_tiles.is_empty() and board.path_tiles.size() < 2 and board.goal_tiles.is_empty():
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if board == null:
		return
	# 呼吸：整块范围的透明度轻微起伏
	var breathe := 0.86 + 0.14 * sin(_t * 3.0)
	# 撤离点 / 目标格：金色常驻
	if not board.goal_tiles.is_empty():
		var goal := {}
		for p in board.goal_tiles:
			goal[p] = true
		_draw_region(goal, GOAL_FILL, GOAL_EDGE, 0.75 + 0.25 * sin(_t * 2.0), false)
	_draw_region(board.danger_tiles, DANGER_FILL, DANGER_EDGE, 1.0, true)
	_draw_region(board.move_tiles, MOVE_FILL, MOVE_EDGE, breathe, false)
	_draw_region(board.atk_tiles, ATK_FILL, ATK_EDGE, breathe, false)
	_draw_arrow(board.path_tiles)


func _cell(p: Vector2i) -> Rect2:
	return Rect2(Vector2(p) * TILE, Vector2(TILE, TILE))


## 区域：每格内缩一圈填色 + 格内细亮框；区域外轮廓描粗边（危险范围只描虚线外轮廓）
func _draw_region(tiles: Dictionary, fill: Color, edge: Color, k: float, dashed: bool) -> void:
	if tiles.is_empty():
		return
	var f := fill
	f.a *= k
	for p in tiles:
		var r := _cell(p).grow(-1.0)
		draw_rect(r, f)
		if dashed:
			# 危险范围加两道斜线：火焰图、红土地上也看得出，也不只靠颜色分辨
			var hc := edge
			hc.a = 0.35
			draw_line(r.position + Vector2(0, TILE * 0.5), r.position + Vector2(TILE * 0.5, 0), hc, 1.5)
			draw_line(r.position + Vector2(TILE * 0.5, TILE - 2), r.position + Vector2(TILE - 2, TILE * 0.5), hc, 1.5)
		if not dashed:
			var inner := edge
			inner.a *= 0.28 * k
			draw_rect(r.grow(-3.0), inner, false, 1.0)
	var e := edge
	e.a *= k
	for p in tiles:
		var o := Vector2(p) * TILE
		var sides := [
			[Vector2i(0, -1), o, o + Vector2(TILE, 0)],
			[Vector2i(0, 1), o + Vector2(0, TILE), o + Vector2(TILE, TILE)],
			[Vector2i(-1, 0), o, o + Vector2(0, TILE)],
			[Vector2i(1, 0), o + Vector2(TILE, 0), o + Vector2(TILE, TILE)],
		]
		for s in sides:
			var n: Vector2i = p + (s[0] as Vector2i)
			if tiles.has(n):
				continue
			if dashed:
				draw_dashed_line(s[1], s[2], e, 2.0, 6.0)
			else:
				draw_line(s[1], s[2], e, 2.5)


func _center(p: Vector2i) -> Vector2:
	return Vector2(p) * TILE + Vector2(TILE / 2.0, TILE / 2.0)


## 路径箭头：圆头起点、粗身、终点三角箭头；先整段描深色边再填亮色
func _draw_arrow(path: Array) -> void:
	if path.size() < 2:
		return
	var pts := PackedVector2Array()
	for p in path:
		pts.append(_center(p))
	var last_dir := (pts[pts.size() - 1] - pts[pts.size() - 2]).normalized()
	var tip := pts[pts.size() - 1] + last_dir * 14.0
	# 箭身收在箭头底边，不戳出三角
	var body := pts.duplicate()
	body[body.size() - 1] = pts[pts.size() - 1] - last_dir * 6.0
	var head := _arrow_head(tip, last_dir, 30.0, 34.0)
	var head_in := _arrow_head(tip - last_dir * 4.0, last_dir, 21.0, 25.0)
	# 描边层
	draw_circle(body[0], 11.0, ARROW_OUTLINE)
	for i in body.size():
		if i > 0:
			draw_line(body[i - 1], body[i], ARROW_OUTLINE, 20.0)
		draw_circle(body[i], 10.0, ARROW_OUTLINE)
	draw_colored_polygon(head, ARROW_OUTLINE)
	# 填色层
	draw_circle(body[0], 7.5, ARROW_FILL)
	for i in body.size():
		if i > 0:
			draw_line(body[i - 1], body[i], ARROW_FILL, 13.0)
		draw_circle(body[i], 6.5, ARROW_FILL)
	draw_colored_polygon(head_in, ARROW_FILL)
	# 中线高光
	for i in range(1, body.size()):
		draw_line(body[i - 1], body[i], ARROW_LIGHT, 3.0)


func _arrow_head(tip: Vector2, dir: Vector2, length: float, width: float) -> PackedVector2Array:
	var n := Vector2(-dir.y, dir.x)
	var base := tip - dir * length
	return PackedVector2Array([tip, base + n * width / 2.0, base - n * width / 2.0])
