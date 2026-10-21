class_name SafeArea
extends RefCounted
## 触控安全区（设计分辨率 1280×720，单位 px）。
## 左右留白、上下留白、贴边主操作再内缩、最小热区。美术联调时只改这里。
##
## 宽屏手机：项目是 stretch aspect = expand，比 16:9 宽的屏幕上视口会变宽（例如 1600×720），
## 多出来的宽度全在右边。地图和信息窗按 screen() 铺满；按 1280 设计的全屏画面用 fit() 居中，
## 背景再往两边延伸，免得右边露出一条黑框。

const DESIGN := Vector2(1280, 720)
const MARGIN_X := 64
const MARGIN_Y := 48
const EDGE_ACTION := 80
const MIN_HIT := 56


## 当前实际可见的画面大小（设计坐标）。拿不到时按 1280×720。
static func screen() -> Vector2:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return DESIGN
	var s := tree.root.get_visible_rect().size
	if s.x < 1.0 or s.y < 1.0:
		return DESIGN
	return s


## 1280 宽的设计画面居中时，左右各空出的宽度
static func pad_x() -> float:
	return maxf(0.0, floorf((screen().x - DESIGN.x) / 2.0))


static func rect(viewport: Vector2 = Vector2.ZERO) -> Rect2:
	var v := viewport if viewport != Vector2.ZERO else screen()
	return Rect2(
		MARGIN_X,
		MARGIN_Y,
		v.x - MARGIN_X * 2.0,
		v.y - MARGIN_Y * 2.0
	)


## 把按 1280×720 设计的全屏 Control 居中；它直接挂着的 1280×720 底色 / 遮罩拉宽到整屏
static func fit(ctrl: Control) -> void:
	ctrl.position.x = pad_x()
	widen(ctrl)


## 整个场景（标题、旁白）按 1280×720 设计：根节点居中，铺满全屏的底色 / 遮罩改成盖住整屏。
## 在场景 _ready 末尾调用（子节点都建好以后）。
static func fit_scene(root: Control) -> void:
	var pad := pad_x()
	var s := screen()
	root.set_anchors_preset(Control.PRESET_TOP_LEFT)
	root.position = Vector2(pad, 0)
	root.size = DESIGN
	for c in root.get_children():
		if c is Control and c.anchor_left == 0.0 and c.anchor_top == 0.0 and c.anchor_right == 1.0 and c.anchor_bottom == 1.0:
			c.set_anchors_preset(Control.PRESET_TOP_LEFT)
			c.position = Vector2(-pad, 0)
			c.size = s
			# 全屏遮罩里的内容仍按 1280 排：挪回设计区
			for cc in c.get_children():
				if cc is Control:
					cc.position.x += pad


## 靠右停的全屏界面（例如出击准备，面板在右边）：整块贴右边
static func fit_right(ctrl: Control) -> void:
	ctrl.position.x = maxf(0.0, screen().x - DESIGN.x)
	widen(ctrl)


## ctrl 已经被挪到 ctrl.global x 处时，把它直接挂着的 1280 宽底色 / 遮罩拉宽，盖住整屏
static func widen(ctrl: Control) -> void:
	var w := screen().x
	var left := ctrl.get_global_transform().origin.x if ctrl.is_inside_tree() else ctrl.position.x
	for c in ctrl.get_children():
		if c is ColorRect and c.position.x <= 0.0 and c.size.x >= DESIGN.x - 1.0 and not c.has_meta("no_widen"):
			c.position.x = -left
			c.size.x = w
