class_name TradeWindow
extends Control
## 战斗中的物品交换（火纹式）：两个相邻的我方单位，左右两栏各 5 格。
## 点一边的一件物品选中它，再点另一边的一格：那格有东西就互换，空着就直接给过去。点「完成」关闭。
## 交换过以后不能再撤销移动，但还能攻击 / 待机（火纹规矩）。

signal closed(traded: bool)

const SLOT_W := 380.0
const SLOT_H := 56.0

var battle = null
var a: Unit = null
var b: Unit = null
var traded := false
var _sel_unit: Unit = null
var _sel_k := -1
var _cols: Array = []           # [VBoxContainer 左, VBoxContainer 右]
var _hint: Label


func open(bt, u1: Unit, u2: Unit) -> void:
	battle = bt
	a = u1
	b = u2
	name = "TradeWindow"
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.08, 0.12, 0.97)
	sb.border_color = Color(0.45, 0.65, 1.0)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 18
	sb.content_margin_bottom = 18
	p.add_theme_stylebox_override("panel", sb)
	p.position = Vector2(170, 90)
	p.custom_minimum_size = Vector2(940, 540)
	add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	p.add_child(vb)
	var title := _label(vb, 26, Color(1.0, 0.86, 0.5))
	title.text = tr("交换")
	_hint = _label(vb, 19, Color(0.8, 0.84, 0.92))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 56)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(row)
	for u in [a, b]:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 8)
		row.add_child(col)
		var nm := _label(col, 22, Color(0.75, 0.85, 1.0))
		nm.text = "%s  Lv%d %s" % [tr(u.display_name), u.level, tr(u.class_label)]
		var slots := VBoxContainer.new()
		slots.add_theme_constant_override("separation", 6)
		col.add_child(slots)
		_cols.append(slots)
	var done := Button.new()
	done.text = tr("完成")
	done.custom_minimum_size = Vector2(200, 52)
	done.add_theme_font_size_override("font_size", 22)
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(close)
	vb.add_child(done)
	_refresh()
	Audio.play_sfx("select")


func close() -> void:
	if is_queued_for_deletion():
		return
	closed.emit(traded)
	queue_free()


func _refresh() -> void:
	for i in 2:
		var u: Unit = [a, b][i]
		var slots: VBoxContainer = _cols[i]
		for c in slots.get_children():
			c.queue_free()
		var inv := PrepScreen.inventory(u)
		for k in Unit.BAG_LIMIT:
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(SLOT_W, SLOT_H)
			btn.add_theme_font_size_override("font_size", 20)
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			btn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
			if k < inv.size():
				var e: Dictionary = inv[k]
				btn.text = "  %s%s   %s" % ["E " if (e["weapon"] and e["idx"] == 0) else "", tr(PrepScreen.item_name(e["id"])), PrepScreen.uses_label(e["id"], e["uses"])]
			else:
				btn.text = "  —"
			if u == _sel_unit and k == _sel_k:
				btn.modulate = Color(1.0, 0.85, 0.4)
			var uu: Unit = u
			var kk: int = k
			btn.pressed.connect(func() -> void: _on_slot(uu, kk))
			slots.add_child(btn)
	if _sel_unit == null:
		_hint.text = tr("点一件物品，再点另一边的一格：有东西就互换，空格就直接给过去")
	else:
		_hint.text = tr("选中了 %s 的物品：点另一边的一格放过去（点它自己取消）") % tr(_sel_unit.display_name)


func _on_slot(u: Unit, k: int) -> void:
	var n := PrepScreen.inventory(u).size()
	if _sel_unit == null:
		if k < n:
			_sel_unit = u
			_sel_k = k
			Audio.play_sfx("select")
		_refresh()
		return
	if u == _sel_unit:
		# 同一边：点自己取消，点别的换选中
		if k == _sel_k or k >= n:
			_sel_unit = null
			_sel_k = -1
		else:
			_sel_k = k
		_refresh()
		return
	_move(_sel_unit, _sel_k, u, k)
	_sel_unit = null
	_sel_k = -1
	_refresh()


## from 的第 fk 件给 to；to 的第 tk 格有东西就换回来
func _move(from: Unit, fk: int, to: Unit, tk: int) -> void:
	var it := PrepScreen.take_out(from, fk)
	if tk < PrepScreen.inventory(to).size():
		var back := PrepScreen.take_out(to, tk)
		from.give(back[0], back[1])
	if not to.give(it[0], it[1]):
		from.give(it[0], it[1])
		return
	traded = true
	Audio.play_sfx("coin")


func _label(parent: Control, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	parent.add_child(l)
	return l
