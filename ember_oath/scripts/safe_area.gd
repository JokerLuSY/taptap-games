class_name SafeArea
extends RefCounted
## 触控安全区（设计分辨率 1280×720，单位 px）。
## 左右留白、上下留白、贴边主操作再内缩、最小热区。美术联调时只改这里。

const MARGIN_X := 64
const MARGIN_Y := 48
const EDGE_ACTION := 80
const MIN_HIT := 48


static func rect(viewport: Vector2 = Vector2(1280, 720)) -> Rect2:
	return Rect2(
		MARGIN_X,
		MARGIN_Y,
		viewport.x - MARGIN_X * 2.0,
		viewport.y - MARGIN_Y * 2.0
	)
