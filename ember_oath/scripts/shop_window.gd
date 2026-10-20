class_name ShopWindow
extends Control
## 地图上的武器店 / 道具店：单位站上去打开。左边是货架（买），右边是这个人的背包（半价卖）。
## 买的东西进这个人的背包，满了送进道具库。关店时做过买卖就算这个人行动结束（火纹规矩）。

signal closed(traded: bool)

var battle = null
var unit: Unit = null
var kind := "item"                  # "weapon" 武器店 / "item" 道具店
var goods: Array = []
var traded := false
var _goods_box: VBoxContainer
var _bag_box: VBoxContainer
var _gold: Label
var _title: Label


func open(b, u: Unit, shop_kind: String, items: Array) -> void:
	battle = b
	unit = u
	kind = shop_kind
	goods = items
	name = "ShopWindow"
	position = Vector2.ZERO
	size = Vector2(1280, 720)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.size = size
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.08, 0.07, 0.96)
	sb.border_color = Color(0.85, 0.7, 0.4)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	p.add_theme_stylebox_override("panel", sb)
	p.position = Vector2(SafeArea.MARGIN_X + 60, SafeArea.MARGIN_Y)
	p.custom_minimum_size = Vector2(1280 - (SafeArea.MARGIN_X + 60) * 2, 720 - SafeArea.MARGIN_Y * 2)
	add_child(p)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	p.add_child(vb)
	var head := HBoxContainer.new()
	vb.add_child(head)
	_title = _label(head, 26, Color(1.0, 0.86, 0.5))
	_title.text = tr("武器店") if kind == "weapon" else tr("道具店")
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gold = _label(head, 22, Color(1.0, 0.9, 0.55))
	var greet := _label(vb, 17, Color(0.85, 0.85, 0.8))
	greet.text = tr("店主：欢迎光临！看看需要什么？") if kind == "item" else tr("铁匠：好铁打好刃，挑一把趁手的吧。")
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 24)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(cols)
	_goods_box = _column(cols, tr("货架（买进 %s 的背包）") % tr(u.display_name))
	_bag_box = _column(cols, tr("%s 的背包（半价卖出）") % tr(u.display_name))
	var close := Button.new()
	close.name = "ShopClose"
	close.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	close.text = tr("离开")
	close.custom_minimum_size = Vector2(200, SafeArea.MIN_HIT)
	close.size_flags_horizontal = Control.SIZE_SHRINK_END
	close.pressed.connect(close_shop)
	vb.add_child(close)
	refresh()


func _label(parent: Node, fs: int, c: Color) -> Label:
	var l := Label.new()
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", c)
	parent.add_child(l)
	return l


func _column(parent: Node, title: String) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	parent.add_child(v)
	var t := _label(v, 18, Color(0.8, 0.9, 1.0))
	t.text = title
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 420)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 6)
	sc.add_child(box)
	return box


func refresh() -> void:
	_gold.text = tr("金钱 %d G") % battle.gold
	for c in _goods_box.get_children():
		c.queue_free()
	for c in _bag_box.get_children():
		c.queue_free()
	for id in goods:
		var price := GameData.item_price(id)
		var iid: String = id
		var info := _goods_info(id)
		_row(_goods_box, "%s  %s" % [tr(PrepScreen.item_name(id)), info], "%d G" % price, battle.gold >= price, func() -> void: buy(iid))
	var inv := PrepScreen.inventory(unit)
	if inv.is_empty():
		_label(_bag_box, 16, Color(0.7, 0.7, 0.7)).text = tr("（空）")
	for k in inv.size():
		var e: Dictionary = inv[k]
		var kk: int = k
		var val := PrepScreen.sell_price(e["id"], e["uses"])
		_row(_bag_box, "%s %s" % [tr(PrepScreen.item_name(e["id"])), PrepScreen.uses_label(e["id"], e["uses"])],
			("+%d G" % val) if val > 0 else tr("不收"), val > 0, func() -> void: sell(kk))


func _goods_info(id: String) -> String:
	if GameData.WEAPONS.has(id):
		var w: Dictionary = GameData.WEAPONS[id]
		return tr("%s级 攻%d 命%d") % [str(w.get("rank", "E")), int(w.get("mt", 0)), int(w.get("hit", 0))]
	return tr(str(GameData.ITEMS.get(id, {}).get("desc", "")))


func _row(parent: Node, text: String, price: String, enabled: bool, cb: Callable) -> void:
	var b := Button.new()
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.text = "%s    %s" % [text, price]
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.disabled = not enabled
	b.custom_minimum_size = Vector2(0, SafeArea.MIN_HIT)
	b.pressed.connect(cb)
	parent.add_child(b)


func buy(id: String) -> void:
	var price := GameData.item_price(id)
	if battle.gold < price:
		return
	battle.gold -= price
	traded = true
	if not unit.give(id):
		Campaign.convoy.append([id, Unit.max_uses(id)])
		battle.notify(tr("%s 的背包满了，%s 送进了道具库") % [tr(unit.display_name), tr(PrepScreen.item_name(id))])
	Audio.play_sfx("coin")
	battle.update_topbar()
	refresh()


func sell(k: int) -> void:
	var e: Dictionary = PrepScreen.inventory(unit)[k]
	var val := PrepScreen.sell_price(e["id"], e["uses"])
	if val <= 0:
		return
	PrepScreen.take_out(unit, k)
	battle.gold += val
	traded = true
	Audio.play_sfx("coin")
	battle.update_topbar()
	refresh()


func close_shop() -> void:
	closed.emit(traded)
	queue_free()
